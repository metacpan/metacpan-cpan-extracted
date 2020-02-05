package Var::Mystic;

use 5.014; use warnings;

our $VERSION = '0.000002';

use Keyword::Declare;
use Data::Dx ();

sub import {
    keyword mystic (ScalarVar $var) {{{ my <{$var}>; Var::Mystic::_setup(<{$var}>, '<{$var}>') }}}

    keyword mystic (ArrayVar) {{{ BEGIN { die "Cannot declare an array to be mystic" } }}}
    keyword mystic (HashVar)  {{{ BEGIN { die "Cannot declare a hash to be mystic" }   }}}
}

sub _setup : lvalue {
    my (undef, $name) = @_;

    use Variable::Magic qw< wizard cast >;
    cast $_[0], wizard set => sub { my (undef, $file, $line) = caller(1);
                                    Data::Dx::_format_data($line, $file, $name, q{}, ${$_[0]}) };

    $_[0];
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Var::Mystic - C<my> C<s>calars C<t>racked C<i>n C<c>olour


=head1 VERSION

This document describes Var::Mystic version 0.000002


=head1 SYNOPSIS

    use Var::Mystic;

    my     $untracked = 'Changes to this variable are not tracked';

    mystic $tracked   = 'Changes to this variable are tracked';


    $untracked = 'new value';    # Variable updated silently

    $tracked   = 'new value';    # Change reported on STDERR



=head1 DESCRIPTION

This module allows you to declare lexically scoped scalar variables
that track any change made to them, and report those changes to
STDERR.


=head1 INTERFACE

The module adds a new keyword: C<mystic>. When you use that keyword
instead of C<my> to declare a scalar variable, any subsequent change
to that variable is reported on STDERR.

If the Term::ANSIColor module is installed, this report
is printed in glorious technicolor.


=head1 DIAGNOSTICS

Every change to a C<mystic> variable is reported to STDERR in 
the following format:

    #line LINE FILE
    $VARNAME = NEW_VALUE

Attempting to declare an array or hash with the C<mystic> keyword
produces the error:

    Cannot declare %s to be mystic


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

At present, only scalars can be declared
with C<mystic> tracking.

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
