package Test::More::Diagnostic;

use warnings;
use strict;
use Carp;
use TAP::Parser::YAMLish::Writer;

our $VERSION = '0.2';
our @ISA     = qw( Test::Builder );

use constant KNOWN_TAP_VERSION => 13;

# Bless builder into our package.
bless Test::More->builder, __PACKAGE__;

sub _should_yaml {
    my $tap_version = $ENV{TAP_VERSION};
    return defined $tap_version && $tap_version >= KNOWN_TAP_VERSION;
}

# Fix up caller
sub caller {
    my ( $self, $height ) = @_;
    $height ||= 0;
    return $self->SUPER::caller( $height + 2 );
}

{
    my $did_version = 0;

    sub _print {
        my $self = shift;
        unless ( $did_version ) {
            $self->SUPER::_print( 'TAP version ' . KNOWN_TAP_VERSION );
            $did_version++;
        }
        return $self->SUPER::_print( @_ );
    }
}

# Add YAML to OK
sub ok {
    my ( $self, $test, $name ) = @_;
    my $ok = $self->SUPER::ok( $test, $name );
    if ( !$ok && _should_yaml() ) {
        my ( $pack, $file, $line ) = $self->caller( -1 );
        TAP::Parser::YAMLish::Writer->new->write(
            {
                file => $file,
                line => $line,
            },
            sub {
                $self->_print( '  ' . $_[0] );
            }
        );
    }
    return $ok;
}

1;
__END__

=head1 NAME

Test::More::Diagnostic - Conditionally add YAML diagnostics to Test::More's output

=head1 VERSION

This document describes Test::More::Diagnostic version 0.2

=head1 SYNOPSIS

    use Test::More;              # DON'T PLAN
    use Test::More::Diagnostic;
    plan tests => 1;

Since people may not have C<Test::More::Diagnostic> installed you may
wish to do this:

    eval 'use Test::More::Diagnostic';
    diag "Test::More::Diagnostic not available' if $@;
  
=head1 DESCRIPTION

Upgrades Test::More's output to TAP version 13. See

  http://testanything.org/wiki/index.php/TAP_diagnostic_syntax

for more information about YAML diagnostics.

This module is completely experimental, kludgy and likely to fall out
of favour once Test::More natively supports YAML diagnostics. Use at
your own risk.

=head1 INTERFACE 

To add YAML diagnostics to your test output:

    use Test::More;              # DON'T PLAN
    use Test::More::Diagnostic;
    plan tests => 1;

It's important that you don't attempt to plan before loading
C<Test::More::Diagnostic>. If you do the TAP version line will appear in
the wrong place in the output.

=over

=item C<< caller >>

Overwridden from Test::Builder. Adjusts the stack depth to account for our intercept.

=item C<< ok >>

Overwridden from Test::Builder. Adds basic YAML diagnostic output to failing tests.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Test::More::Diagnostic requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-more-diagnostic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

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
