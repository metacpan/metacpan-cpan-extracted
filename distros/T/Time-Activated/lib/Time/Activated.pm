package Time::Activated;

## no critic (ProhibitSubroutinePrototypes, ProhibitAutomaticExportation)

use strict;
use warnings;

use 5.8.8;

=pod

=encoding UTF-8

=cut

=head1 NAME

Time::Activated - Syntactic sugar over time activated code supporting DateTime and ISO8601 (a.k.a. "Javascript dates").

=head1 VERSION

Version 1.01

=cut

our $VERSION = 1.01;

=head1 SYNOPSIS

	use Time::Activated;

	# simple statements
	time_activated after_moment '1985-01-01T00:00:00' => execute_logic { print "New feature beginning Jan 1st 1985!" };
	time_activated before_moment '1986-12-31T00:00:00' => execute_logic { print "This feature ends by 1986!" };
	time_activated before_moment '2000' => execute_logic { print "Let's dance like its 1999!" };
	time_activated
		between_moments '2016-01-01T00:00:00' => '2016-12-31T23:59:59' =>
		execute_logic { print "Business logic exception for 2016!" };

	# combined statements a la try {} catch {} by Try::Tiny (tm)
	time_activated
		after_moment '1985-01T00:00:00-03:00' => execute_logic { print "New business logic!" }, # <-- Gotcha! it is a ,
		before_moment '1986-12-31T00:00:00-03:00' => execute_logic { print "Old business logic!" };

	# elements get evaluated in order
	time_activated
		before_moment '1986-12-31T00:00:00-03:00' => execute_logic { print "Old business logic!" }, # <-- Switch that ;
		after_moment '1985-01-01T00:00:00-03:00' => execute_logic { print "New business logic!" }; # <-- Switch that ,

	# overlapping allowed, all matching items get executed
	time_activated
		after_moment '2018', execute_logic { print "This is from 2018-01-01 and on." },
		after_moment '2018-06-01', execute_logic { print "This is from 2018-06-01 and on. On top of the previuos." };

	# Alternate syntax
	time_activated
		after_moment '2018', execute_logic { print "Welcome to new business process for 2018!" }, #=> is a ,
		after_moment '2019', execute_logic { print "This is added on top of 2018 processes for 2019!" };

	# DateTime objects can be used to define points in time
	my $dt = DateTime->new(year=>2018, month=>10, day=>16);
	time_activated after_moment $dt => execute_logic { print "This happens after 2018-10-16!" };

=head1 DESCRIPTION

This modules aims at managing and documenting time activated code such as that which may araise from migrations and planified process changes in a way that can be
integrated and tested in advance.

You can use Time::Activated C<before>, C<after> and C<between> to state which parts of code will be executed on certain dates due to changing business rules,
programmed web service changes in endpoints/contracts or other time related events.

=head1 USAGE



=cut

use Exporter 5.57 'import';
our @EXPORT = our @EXPORT_OK = qw(time_activated before_moment after_moment between_moments execute_logic);

=head1 EXPORTS

By default Time::Activated exports C<time_activated>, C<before>, C<after>, C<between> and C<execute>.

If you need to rename the C<time_activated>, C<after>, C<before>, C<between> or C<executye> keyword consider using L<Sub::Import|Sub::Import> to
get L<Sub::Exporter|Sub::Exporter>'s flexibility.

If automatic exporting sound nasty: use Time::Activated qw();

=head1 SYNTAX

time_activated "CONDITION" "WHEN" "WHAT"

=head2 "CONDITION"

Can be any of C<after_moment>, C<before_moment>, C<between_moments>.
C<after_moment>, accepts a parameters representing a point in time B<at and after> which the execute_logic statement will be executed.
C<before_moment>, accepts a parameters representing a point in time B<before, but not including>, which the execute_logic statement will be executed.
C<between_moments>, accepts two parameters representing a range in time B<between, both limits included>, which the execute_logic statement will be executed.

=head2 "WHEN"

Is either a DateTime object or a scalar representing a iso8601 (a.k.a. Javascript date)

Expansion is supported so '2000', '2000-01', '2000-01-01' and '2000-01-01T00:00' all are equivalents to '2000-01-01T00:00:00'.

Timezones are supported and honored. Thus:

    time_activated
		after_moment '1999-12-31T23:00:00-01:00' => execute_logic { print('Matches from 2000-01-01T00:00:00 GMT!') },
		after_moment '2000-01-01T00:00:00+01:00' => execute_logic { print('Matches from 1999-01-01T23:00:00 GMT!') };

C<after> includes the exact time which is used as parameter, C<before> does not.
Thus using C<after> and C<before> with the same time parameter ensures that only one statement gets executed.
i.e.:

	time_activated
		before_moment 	SOME_DATE => execute { print "Before!" },
		after_moment 	SOME_DATE => execute { print "After!" };


=head2 "WHAT"

Is either an anonymous code block or a reference to subroutine
Code that will be executed on a given conditions in many ways:

	time_activated
		after_moment '2001' => execute_logic \&my_great_new_feature; #No parameters can be passed with references...

	time_activated
		after_moment '2000' => execute_logic { print 'Y2K ready!' },
		after_moment '2001' => execute_logic (\&my_great_new_feature), #References with multilines need ()
		after_moment '2002' => execute_logic { &my_great_new_feature("We need parameters by 2002")};

=head2 CONSTANTS

It is cool to use constants documenting both time and intent.

	use constants PROCESS_X_CUTOVER_DATE => '2017-01-01T00:00:00';

	time_activated after_moment PROCESS_X_CUTOVER_DATE => execute_logic { &new_business_process($some_state) };

=cut

=head1 TESTING

L<Test::MockTime|Test::MockTime> is your friend.

	use Test::More tests => 1;
	use Time::Activated;
	use Test::MockTime;

	Test::MockTime::set_absolute_time('1986-05-27T00:00:00Z');
	time_activated after_moment '1985-01-01T00:00:00-03:00' => execute_logic { pass('Basic after') }; # this gets executed

	Test::MockTime::set_absolute_time('1984-05-27T00:00:00Z');
	time_activated after_moment '1985-01-01T00:00:00-03:00' => execute_logic { fail('Basic after') }; # this does not get executed

=cut

use Carp;
$Carp::Internal{ __PACKAGE__ }++;

use Sub::Name 0.08;
use DateTime;
use DateTime::Format::ISO8601;

=head1 SUBROUTINES/METHODS

=head2 time_activated

C<time_activated> is both the syntactical placeholder for grammar in C<Time::Activated> and the internal implementation of the modules functionality.

Syntactically the structure is like so (note the ','s and ';'):

	time_activated
		after_moment ..., execute_logic ...,
		before_moment ..., execute_logic ...,
		between_moments ..., ... execute_logic ...;

Alternatively some can be changed for a => for a fancy syntax. This abuses anonymous hashes, some inteligent selections of prototypes (stolen from L<Try::Tiny|Try::Tiny>) and probably
other clever perl-ish syntactical elements that escape my understanding. Note '=>'s, ','s and ';':

	time_activated
		after_moment ... => execute_logic ...,
		before_moment ... => execute_logic ...,
		between_moments ... => ... => execute_logic ...; #Given. This does not look so fancy but more into the weird side...

=cut

# Blatantly stolen from Try::Tiny since it really makes sence and changing it produces headaches.
# Need to prototype as @ not $$ because of the way Perl evaluates the prototype.
# Keeping it at $$ means you only ever get 1 sub because we need to eval in a list
# context & not a scalar one

sub time_activated (@) {
    my (@stanzas) = @_;
	my $activations = 0;

    my $now = DateTime->now();
    foreach my $stanza (@stanzas) {
		if (ref($stanza) eq 'Time::Activated::Before') {
			if ($now < $stanza->{before}) {
				$stanza->{code}();
				$activations++;
			}
		} elsif (ref($stanza) eq 'Time::Activated::After') {
			if ($now >= $stanza->{after}) {
				$stanza->{code}();
				$activations++;
			}
		} elsif (ref($stanza) eq 'Time::Activated::Between') {
			if ($stanza->{after} > $stanza->{before}) {
                my $before = $stanza->{after};
                $stanza->{after}  = $stanza->{before};
                $stanza->{before} = $before;
            }
			if ($now >= $stanza->{after} && $now <= $stanza->{before}) {
				$stanza->{code}();
				$activations++;
			};
		} else {
			croak('time_activated() encountered an unexpected argument (' . ( defined $stanza ? $stanza : 'undef' ) . ') - perhaps a missing semi-colon?' );
		}
    }
	return $activations;
}

=head2 before_moment

C<before_moment> defines a point in time before B<not including the exact point in time> which code is executed.

This does not happen before January 1st 2018 at 00:00 but does happen from that exact point in time and on.

	time_activated
		before_moment '2018', execute_logic { print "We are awaiting for 1/1/2018..." };

Another fancy way to say do not do that before January 1st 2018 at 00:00.

	ime_activated
		before_moment '2018' => execute_logic { print "We are awaiting for 1/1/2018..." };

A fancy way to combine before statements.

	time_activated
		before_moment '2018' => execute_logic { print "We are awaiting for 1/1/2018..." },
		before_moment '2019' => execute_logic { print "Not quite there for 1/1/2019..." };

=cut

sub before_moment ($$;@) {
    my ( $before, $block, @rest ) = @_;

    croak 'Useless bare before_moment()' unless wantarray;

    my $caller = caller;
    subname("${caller}::before_moment{...} " => $block);

    return (bless({before => _spawn_dt($before), code => $block},'Time::Activated::Before'), @rest);
}

=head2 after_moment

C<after_moment> defines a point in time after B<including the exact point in time> which code is executed.

	time_activated
		after_moment '2018' => execute { print "Wea are either at 1/1/2018 or after it..." };

As with C<before_moment> statements can be combined with C<before_moment>, C<after_moment> and C<between_moments> with no limit.

=cut

sub after_moment ($$;@) {
    my ( $after, $block, @rest ) = @_;

    croak 'Useless bare after_moment()' unless wantarray;

    my $caller = caller;
    subname("${caller}::after _moment{...} " => $block);

    return (bless({after => _spawn_dt($after), code => $block},'Time::Activated::After'), @rest);
}

=head2 between_moments

C<between_moments> defines two points in time between which code is executes B<including both exact points in time>.

	time_activated
		between_moment '2018' => '2018-12-31T23:59:59' => execute_logic { print "This is 2018..." };

As with C<before_moments> statements can be combined with C<before_moment>, C<after_moment> and C<between_moment> with no limit.

=cut

sub between_moments ($$$;@) {
    my ( $after, $before, $block, @rest ) = @_;

    croak 'Useless bare between_moments()' unless wantarray;

    my $caller = caller;
    subname("${caller}::between_moments{...} " => $block);

    return (bless({before => _spawn_dt($before), after => _spawn_dt($after), code => $block},'Time::Activated::Between'), @rest);
}

=head2 execute_logic

Exists for the sole reason of verbosity.
Accepts a single parameters that must be a subroutine or anonymous code block.

	execute_logic { print "This is a verbose way of saying that this will be executed!" };

=cut

sub execute_logic(&) {
	my ($code) = @_;
    return $code;
}

=head2 PRIVATES

=head3 _spawn_dt

C<_spawn_dt> is a private function defined in hopes that additional date formats can be used to define points in time.

=cut

sub _spawn_dt {
    my ($iso8601_or_datetime) = @_;

    my $dt = ref $iso8601_or_datetime && $iso8601_or_datetime->isa('DateTime')
      ? $iso8601_or_datetime
      : DateTime::Format::ISO8601->parse_datetime($iso8601_or_datetime);

    return $dt;
}

1;

__END__

=head1 DIAGNOSTICS

=over 4

=item time_activated

(F) time_activated() encountered an unexpected argument...

time_activated is not followed by either after_moment, before_moment or between_moments

	time_activated wierd_sub(); #<- Plain weird but it could somehow happen

=item after_moment before_moment between_moments

(F)	Useless bare after_moment()
(F)	Useless bare before_moment()
(F)	Useless bare between_moments()

Use of xxxxx() with no time_activated before it.
Generally the result of a ; instead of a ,.

	time_activated
		after_moment '2018' {}; #<- mind the ;
		before_moment '2018' {}; #<- This one triggers a 'Useless bare before()' since it is not part of the time_activated call

=head1 BUGS AND LIMITATIONS

No known bugs, but you cannot have this syntax.
Some , and/or => required:

	time_activated
		before_moment '2016-09-24' {}
		after_moment '2016-10-24' {};

=head1 DEPENDENCIES

L<DateTime|DateTime>, L<DateTime::Format::ISO8601|DateTime::Format::ISO8601>, L<Carp|Carp>, L<Exporter|Exporter>, L<Sub::Name|Sub::Name>.

=head1 INCOMPATIBILITIES

Versions prior to 1.00 have collission with Moose.
Naturally, Moose wins and compatibility breaks from 0.12 to 1.00.

Some old distributions that cannot set dates beyond 2038 fail some tests.

=head1 SEE ALSO

=over 4

=item L<Try::Tiny|Try::Tiny>

A non related module that became the inspiration for Time::Activated.

=back

=head1 VERSION CONTROL

L<http://github.com/gbarco/Time-Activated/>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Time-Activated>
(or L<bug-Time-Activated@rt.cpan.org|mailto:bug-Time-Activated@rt.cpan.org>).

=head1 AUTHOR

=over 4

=item *

Gonzalo Barco <gbarco uy at gmail.com, no spaces>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Gonzalo Barco.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
