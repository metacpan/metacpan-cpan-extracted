package Var::Mystic;

use 5.014; use warnings;

our $VERSION = '0.000003';

use Keyword::Declare;
use Data::Dx ();
use Variable::Magic qw< wizard cast >;

sub import {
    keyword track (          'here'?  $scoped,
                     /my|our|state/?  $declarator,
                   ScalarAccess|Var   $var,
                                '='?  $assignment
    ) {
        state $next_ID = 1;
        my $ID = 0;
        if ($scoped) {
            $ID = $next_ID++;
            $^H{"Var::Mystic tracker: $ID"} = 1;
        }

        my $sigil = substr($var,0,1);

        ( $declarator ? qq{$declarator $var;} : q{} )
        .
        ( $sigil eq '$' ? qq{ Var::Mystic::_scalar_setup(\\$var, '$var', $ID); }
        : $sigil eq '@' ? qq{  Var::Mystic::_array_setup(\\$var, '$var', $ID); }
        : $sigil eq '%' ? qq{   Var::Mystic::_hash_setup(\\$var, '$var', $ID); }
        :                 qq{BEGIN { die 'Cannot track $var'; }}
        )
        .
        ( $assignment ? qq{$var = } : q{} )
    }

    # Legacy interface...
    keyword mystic (Var $var) {{{ track my <{$var}> }}}
}

sub unimport {
    keyword track (          'here'?  ,
                     /my|our|state/?  $declarator,
                   ScalarAccess|Var   $var,
                                '='?  $assignment
    ) {
        return qq{$declarator $var = } if $declarator || $assignment;
        return  q{}
    }

    keyword mystic ()        {{{my}}}
}

sub _report {
    return if substr($_[1],-12) eq 'Data/Dump.pm';

    state $prev = q{};
    my    $dump = Data::Dump::dump($_[-1]);

    if ($dump ne $prev) {
        no warnings 'redefine';
        local *Term::ANSIColor::colored = -t *STDERR ? \&Term::ANSIColor::colored
                                                     : sub { return shift };
        Data::Dx::_format_data( @_ );
        $prev = $dump;
    }
    return;
}

sub _scalar_setup {
    my ($scalar_ref, $name, $ID) = @_;

    my (undef, $file, $line) = caller();

    cast ${$scalar_ref}, wizard
        set  => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                      return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                      _report($line, $file, $name, q{}, ${$scalar_ref});
                    },
}

sub _array_setup {
    my ($array_ref, $name, $ID) = @_;

    my (undef, $file, $line) = caller();

    cast @{$array_ref}, wizard
        set   => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                       return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                       cast my $result, wizard free => sub {
                            _report($line, $file, $name, q{}, $array_ref);
                       };
                       return \$result;
                     },
        clear => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                       return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                       cast my $result, wizard free => sub {
                            _report($line, $file, $name, q{}, $array_ref);
                       };
                       return \$result;
                     },
}

sub _hash_setup {
    my ($hash_ref, $name, $ID) = @_;

    my (undef, $file, $line) = caller();

    cast %{$hash_ref}, wizard
        delete => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                        return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                        cast my $result, wizard free => sub {
                            _report($line, $file, $name, q{}, $hash_ref);
                        };
                       return \$result;
                      },
        store  => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                        return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                        cast my $result, wizard free => sub {
                             _report($line, $file, $name, q{}, $hash_ref);
                        };
                        return \$result;
                      },
        clear  => sub { my ($file, $line, $hints) = (caller 1)[1,2,10];
                        return if $ID && !exists $hints->{"Var::Mystic tracker: $ID"};
                        cast my $result, wizard free => sub {
                             _report($line, $file, $name, q{}, $hash_ref);
                        };
                        return \$result;
                      },
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Var::Mystic - B<M>onitor B<y>our B<s>tate, B<t>racked B<i>n B<c>olour


=head1 VERSION

This document describes Var::Mystic version 0.000003


=head1 SYNOPSIS

    use Var::Mystic;

          my $untracked = 'Changes to this variable are not tracked';

    track my $tracked   = 'Changes to this variable are tracked';


    $untracked = 'new value';    # Variable updated silently

    $tracked   = 'new value';    # Change reported on STDERR


    # Can track any type of scoped variable declaration...

    track our   @array;
    track state %hash;

    # Can also track variables after they're declared...

    track $scalar;

    track @array;
    track $array[ $index ];   # Just track this one array element

    track %hash;
    track $hash{ $key };      # Just track this one hash entry


=head1 DESCRIPTION

This module allows you to track changes to the values of individual variables,
reporting those changes to STDERR.


=head1 INTERFACE

The module adds a new keyword: C<track>. When you place that keyword in
front of a variable or variable declaration (C<my>, C<our>, or C<state>),
then any subsequent changes to that variable are reported on STDERR.

If the Term::ANSIColor module is installed,
these reports are printed in glorious technicolor.


=head2 Permanent vs lexical tracking

Normally, once you start tracking a particular variable, it is
tracked until it ceases to exist, even if you start tracking it
half way through a program or in an inner scope.

However, if you only want to track a variable in a particular lexical
scope, you can specify that by adding a secondary keyword after
the C<track> keyword:

    track      $var;    // Variable is tracked for the rest of its existence

    track here $var;    // Variable is tracked only in the current lexical scope

Adding a C<here> can be useful when you suspect that your problem is occurring
within a particular block, because then you don't have to wade through hundreds
of other reports from everywhere else the variable is subsequently used.


=head2 Disabling all tracking

If the module is loaded via:

    no Var::Mystic;

the C<track> keyword is still added...but as a silent no-op.

This is useful when you have added tracking to multiple variables and
then think you've solved the problem. Rather than removing every
C<track> keyword, you can just change the C<use Var::Mystic> to C<no
Var::Mystic>, until another problem is encountered.


=head2 Legacy interface

The module previously supplied another keyword: C<mystic>.

The declaration:

    mystic $var;

was equivalent to:

    track my $var;

This keyword is still provided for backwards compatibility,
but will not be maintained and may be removed in a future release.


=head1 DIAGNOSTICS

Every change to a tracked variable is reported to STDERR in
the following format:

    #line LINE FILE
    $VARNAME = NEW_VALUE


=head1 CONFIGURATION AND ENVIRONMENT

Var::Mystic requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module depends on the Keyword::Declare, Data::Dx, and Variable::Magic modules.

The module's test suite depends on the Test::Effects module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

This module requires Perl 5.14 or later,
and does not work under the 5.20 release of Perl
(due to issues in the regex engine that
were not resolved until Perl 5.22)

The module uses the "magic" feature of Perl variables (via the
Variable::Magic module), so it is constrained by the limitations
of the built-in mechanism. The two most obvious of
those limitations are:

=over

=item *

When tracking an entire array, magic only applies to "array-oriented"
actions, so only these actions can be reported. Most significantly,
that means that any assignment to a single element of the array:

    $array[$index] = $newvalue;     // No report generated

will I<not> be reported.

The workaround here is to explicitly track that array element:

    track $array[$index] = $newvalue;     // Report generated


=item *

When an entry is deleted from a tracked hash:

    delete $hash{$key};

the change will only I<sometimes> be reported in non-void contexts.
Whether void-context deletions are reported depends on which version
of Perl you are using, and how it was compiled.

The obvious workaround here is to ensure that any deletions
you definitely want to track are performed in a non-void context:

    scalar delete $hash{$key};

=back

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-var-mystic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
