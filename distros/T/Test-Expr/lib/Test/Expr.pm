package Test::Expr;
our $VERSION = '0.000003';

use 5.014; use warnings;
use Keyword::Declare;
use Data::Dump;
use List::Util 'max';
use Test::More;
use parent 'Exporter';
our @EXPORT = @Test::More::EXPORT;

sub _trim {
    my $str = shift;
    $str =~ s{\A\s*|\s*\Z}{}g;
    return $str;
}

my $PERL_VAR = qr{ ((?&PerlVariable)) $PPR::GRAMMAR }xms;

sub import {
    my ($package) = @_;
    $package->export_to_level(1, @_);

    keyword ok (Expr $test) {{{
        ok do{«$test»}, q{«$test»};
    }}}

    keyword ok (ListElem $test, Comma, ListElem $desc) {
        # Work out what values to report if there's a problem...
        my @vars = grep {defined} $test =~ m{$PERL_VAR}g;
        my $var_len = max map {length} @vars;
        my %seen;
        my @diagnostics
            = map {qq{diag sprintf(q{    %${var_len}s --> }, q{$_}), Data::Dump::dump($_);}}
                  grep { !$seen{$_}++ }
                       @vars;

        unshift @diagnostics, qq{diag q{  because:};}
            if @diagnostics;
        unshift @diagnostics, qq{diag q{}; diag q{  ($test) was false};}
            if (eval($desc)//'') ne qq{$test};

        # Build the test code...
        qq{
            if ($test) {
                Test::More::ok(1, $desc);
            }
            else {
                fail($desc); @diagnostics diag q{};
            }
        };
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Test::Expr - Test an expression with better error messages


=head1 VERSION

This document describes Test::Expr version 0.000003


=head1 SYNOPSIS

    use Test::Expr;

    plan tests => 5;

    ok $got == $expected;
    ok $got eq $expected;
    ok $got != $expected;
    ok $got le $expected;
    ok $got >= $expected;


=head1 DESCRIPTION

This testing module installs a single keyword: C<ok>

That keyword evaluates the expression and produces a test report entry
in the usual way (i.e. just like C<Test::Simple::ok> or C<Test::More::ok>).
Except that, if you don't give it a description argument, it uses
the test expression itself as the description.

In addition, the diagnostic message produced if the test fails is
significantly more useful than that provided by either of those other
two modules.

For example, the sample code in the Synopsis
might produce the following report:

    1..5
    ok 1 - $got == $expected
    not ok 2 - $got eq $expected
    #   Failed test '$got eq $expected'
    #   at t/synopsis.t line 13.
    #   because:
    #          $got --> "1.0"
    #     $expected --> 1
    #
    not ok 3 - $got != $expected
    #   Failed test '$got != $expected'
    #   at t/synopsis.t line 14.
    #   because:
    #          $got --> "1.0"
    #     $expected --> 1
    #
    not ok 4 - $got le $expected
    #   Failed test '$got le $expected'
    #   at t/synopsis.t line 15.
    #   because:
    #          $got --> "1.0"
    #     $expected --> 1
    #
    ok 5 - $got >= $expected
    # Looks like you failed 3 tests of 5.

In other words, this version of C<ok> reports both that
the test that was done, and the values of the variables
involved that caused the test to fail.

The idea is that you can just write every test as: C<ok EXPR>, but you
now get useful error messages. This mostly eliminates the need for the
following functions from Test::More:

    # Can write...                   # Instead of...

    ok $got eq $expected;            is        $got, $expected;
    ok $got ne $unexpected;          isnt      $got, $unexpected;
    ok $got == $expected;            is_deeply $got, $expected;
    ok $got ~~ $expected;            unlike    $got, $pattern;
    ok $got =~ $pattern;             like      $got, $pattern;
    ok $got !~ $pattern;             unlike    $got, $pattern;
    ok $obj->isa($classname);        is_ok     $got, $classname;
    ok $obj->can($methodname);       can_ok    $obj, $methodname;


=head1 INTERFACE

=head2 C<ok EXPR>

=head2 C<ok EXPR, DESC>

The C<ok> keyword works exactly like the C<ok> functions of Test::Simple
and Test::More. The only difference in behaviour is in the detail of the
diagnostics issued when the test fails.


=head1 DIAGNOSTICS

None (apart from the diagnostics issued by failing tests).


=head1 CONFIGURATION AND ENVIRONMENT

Test::Expr requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl v5.14 and the Keyword::Declare module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Due to a problem with regex compilation under Perl v5.20, this module is
absurdly and unusably slow under that release. This issue does not arise
in any other supported release of Perl.


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-expr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
