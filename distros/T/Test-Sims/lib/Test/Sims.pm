package Test::Sims;

use strict;
use warnings;

our $VERSION = "20130412";

=head1 NAME

Test::Sims - Helps build semi-random data for testing

=head1 SYNOPSIS

    package My::Sims;

    use Test::Sims;

    # Creates rand_name() and exported on demand.
    make_rand name => [
        qw(Mal Zoe Jayne Kaylee Inara River Simon Wash Zoe Book)
    ];

    # Automatically exported
    sub sim_character {
        my %defaults = (
            name   => rand_name(),
            series => "Firefly",
        );

        require Character;
        return Character->new(
            %defaults, @_;
        );
    }


=head1 DESCRIPTION

B<THIS IS AN EARLY RELEASE>! While very well tested behaviors may
change.  The interface is not stable.

This is a module to help building semi-random data for testing and to
create large, nested, interesting data structures.

This module contains no new assertions, but it does tie in with
Test::Builder.

It does two things.  It contains functions which make generating
random data easier and it allows you to write repeatable, yet random,
test data.

=head2 make_rand()

    my $code = make_rand $name => \@list;
    my $code = make_rand $name => sub { ... };

Creates a subroutine called C<<rand_$name>> and exports it on request.

If a @list is given it will generate a subroutine which returns
elements out of @list at random.  It takes C<min> and C<max> arguments
to control how many.

    my @items = rand_$name(
        min => $min_random_items,
        max => $max_random_items
    );

C<min> and C<max> both default to 1.  So by default you get 1 item.

If a subroutine is given it will simply give that routine a name.
This is just to get the convenience of adding it to the exports.

Also adds it to a "rand" export tag.

    {
        package Sim::Firefly;

        make_rand crew => [
            qw(Zoe Wash Mal River Simon Book Jayne Kaylee Inara)
        ];
    }

    ...later...

    {
        use Sim::Firefly ":rand";

        my $crew = rand_crew;             # 1 name
        my @crew = rand_crew( max => 3 ); # 1, 2 or 3 names
    }


=head2 export_sims()

    export_sims();

A utility function which causes your module to export all the
functions called C<<sims_*>>.  It also creates an export tag called
"sims".

You should call this at the end of your Sim package.


=head2 Controlling randomness

You can control the random seed used by Test::Sims by setting the
C<TEST_SIMS_SEED> environment variable.  This is handy to make test runs
repeatable.

    TEST_SIMS_SEED=12345 perl -Ilib t/some_test.t

Test::Sims will output the seed used at the end of each test run.  If
the test failed it will be visible to the user, otherwise it will be a
TAP comment and only visible if the test is run verbosely.

If having new data every run is too chaotic for you, you can set
TEST_SIMS_SEED to something which will remain fixed during a
development session.  Perhaps the PID of your shell or your uid or
the date (20090704, for example).


=head2 C<sim> functions

Test::Sims doesn't do anything with functions named C<sim_*> but
export them.  Generally we recommend they're written like so:

    sub sim_thing {
        my %defaults = (
            name        => rand_name(),
            age         => rand_age(),
            motto       => rand_text(),
            picture     => rand_image(),
        );

        return Thing->new( %defaults, @_ );
    }

This way you can get a completely random Thing.

    my $thing = sim_thing();

Or you can lock down the bits you need leaving the rest to float free.

    # Joe's motto and picture remain random
    my $joe = sim_thing(
        name => "Joe",
        age  => 64
    );


=cut

use base qw(Exporter);
our @EXPORT = qw(make_rand export_sims);

# Yes, its not a great seed but it doesn't have to be secure.
my $Seed = defined $ENV{TEST_SIMS_SEED} ? $ENV{TEST_SIMS_SEED} : (time ^ ($$ * $< * $());

# XXX If something else calls srand() we're in trouble
srand $Seed;

## no critic (Subroutines::RequireArgUnpacking)
sub import {
    my $class  = shift;
    my $caller = caller;

    {
        no strict 'refs';
        unshift @{ $caller . "::ISA" }, "Exporter" unless $caller->isa("Exporter");
    }

    return __PACKAGE__->export_to_level( 1, $class, @_ );
}

sub make_rand {
    my $name  = shift;
    my $thing = shift;

    my $items = ref $thing eq "ARRAY" ? $thing : [];

    my $caller = caller;

    my $code = ref $thing eq 'CODE' ? $thing : sub {
        my %args = @_;
        $args{min} = 1 unless defined $args{min};
        $args{max} = 1 unless defined $args{max};

        my $max = int rand( $args{max} - $args{min} + 1 ) + $args{min};

        my @return;
        for( 1 .. $max ) {
            push @return, $items->[ rand @$items ];
        }

        return @return == 1 ? $return[0] : @return;
    };

    my $func = "rand_$name";
    _alias( $caller, $func, $code );
    _add_to_export_ok( $caller, $func );
    _add_to_export_tags( $caller, $func, 'rand' );

    return $code;
}

sub export_sims {
    my $caller = caller;

    my $symbols = do {
        no strict 'refs';
        \%{ $caller . '::' };
    };

    my @sim_funcs = grep { *{ $symbols->{$_} }{CODE} }
      grep /^sim_/, keys %$symbols;
    for my $func (@sim_funcs) {
        _add_to_export( $caller, $func );
        _add_to_export_tags( $caller, $func, 'sims' );
    }

    return;
}

sub _add_to_export_ok {
    my( $package, $func ) = @_;

    no strict 'refs';
    push @{ $package . '::EXPORT_OK' }, $func;

    return;
}

sub _add_to_export {
    my( $package, $func ) = @_;

    no strict 'refs';
    push @{ $package . '::EXPORT' }, $func;

    return;
}

sub _add_to_export_tags {
    my( $package, $func, $tag ) = @_;

    no strict 'refs';
    my $export_tags = \%{ $package . '::EXPORT_TAGS' };
    push @{ $export_tags->{$tag} }, $func;

    return;
}

sub _alias {
    my( $package, $func, $code ) = @_;

    no strict 'refs';
    *{ $package . '::' . $func } = $code;

    return;
}


sub _test_was_successful {
    my $tb = shift;

    if( $tb->can("history") ) {
        return $tb->history->test_was_successful;
    }
    else {
        return $tb->summary && !( grep !$_, $tb->summary );
    }
}

sub _display_seed {
    my $tb = shift;

    my $ok = _test_was_successful($tb);
    my $msg = "TEST_SIMS_SEED=$Seed";
    $ok ? $tb->note($msg) : $tb->diag($msg);

    return;
}

END {
    require Test::Builder;
    my $tb = Test::Builder->new;

    if( defined $tb->has_plan ) {
        _display_seed($tb);
    }
}

1;


=head1 EXAMPLE

Here's an example of making a simple package to generate random dates.

    package Sim::Date;

    use strict;
    use warnings;

    require DateTime;
    use Test::Sims;

    make_rand year  => [1800..2100];

    sub sim_datetime {
        my %args = @_;

        my $year = $args{year} || rand_year();
        my $date = DateTime->new( year => $year );

        my $days_in_year = $date->is_leap_year ? 366 : 365;
        my $secs = rand( $days_in_year * 24 * 60 * 60 );
        $date->add( seconds => $secs );

        $date->set( %args );

        return $date;
    }

    export_sims();

And then using it.

    use Sim::Date;

    # Random date.
    my $date = sim_datetime;

    # Random date in July 2009
    my $date = sim_datetime(
        year  => 2009,
        month => 7,
    );


=head1 ENVIRONMENT

=head3 TEST_SIMS_SEED

If defined its value will be used to make tests repeatable.  See
L<Controlling randomness>.


=head1 SEE ALSO

"Generating Test Data with The Sims"
L<http://schwern.org/talks/Generating%20Test%20Data%20With%20The%20Sims.pdf>
is a set of slides outlining the Sims testing technique which this
module is supporting.

L<Data::Random> for common rand_* routines.

L<Data::Generate> to generate random data from a set of rules.


=head1 SOURCE

The source code repository can be found at
L<http://github.com/schwern/Test-Sims>.

The latest release can be found at
L<http://search.cpan.org/dist/Test-Sims>.


=head1 BUGS

Please report bugs, problems, rough corners, feedback and suggestions
to L<http://github.com/schwern/Test-Sims/issues>.

Report early, report often.


=head1 THANKS

Thanks go to the folks at Blackstar and Grant Street Group for helping
to develop this technique.


=head1 LICENSE and COPYRIGHT

Copyright 2009 Michael G Schwern E<gt>schwern@pobox.comE<lt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

