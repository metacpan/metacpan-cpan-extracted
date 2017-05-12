package DHCPLeases::Object::Iterator;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.0';

=head1 NAME

Text::DHCPLeases::Object::Iterator - Lease object iterator class

=head1 SYNOPSIS


=head1 DESCRIPTION
=cut


sub new {
    my ($proto, $list) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{_list} = $list;
    $self->{_pos}  = 0;
    $self->{_size} = scalar @{$self->{_list}};
    bless $self, $class;
}

sub count { my ($self) = @_; return $self->{_size} };

sub first {
    my ($self) = @_;
    return $self->{_list}->[0];
}

sub last {
    my ($self) = @_;
    return $self->{_list}->[$self->{_size} - 1];
}

sub next {
    my ($self) = @_;
    return $self->{_list}->[$self->{_pos}++];
}

# Make sure to return 1
1;



=head1 AUTHOR

Carlos Vicente, <cvicente@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

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
=cut

