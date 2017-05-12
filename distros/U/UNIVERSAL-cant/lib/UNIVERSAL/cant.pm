package UNIVERSAL::cant;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.1');

package UNIVERSAL;

use warnings;
use strict;

sub cant {
	my ($pkg, @args) = @_;
    return if $pkg->can( @args );
    return 1;
}

sub can::t {
	goto &UNIVERSAL::cant;
}

1;

__END__

=head1 NAME

UNIVERSAL::cant - See if an object or package cant do something

=head1 VERSION

This document describes cant version 0.0.1

=head1 SYNOPSIS

    use UNIVERSAL::cant;

    ...

    if( $self->cant('dance') ) {
	    $self->take_lessons('dance') or die "Loser can't dance";
    }
    else {
	    $self->dance( { 'with' => 'Rhiannon'} );
    }

=head1 DESCRIPTION

Provides UNIVERSAL methods that is the opposite of can().

=head1 INTERFACE 

Two simple methods described below.

=head2 cant()

Takes the same arguments as can(), returns true if it can't do the specified args, returns false if it can

=head2 can't()

Same as cant() but with an apostrophy.

Thanks to Tatsuhiko Miyagawa for the idea for the apostrophy version, bravo :)

=head1 DIAGNOSTICS

cant() throws no warnings or errors itself

=head1 CONFIGURATION AND ENVIRONMENT

cant requires no configuration files or environment variables.

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cant@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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