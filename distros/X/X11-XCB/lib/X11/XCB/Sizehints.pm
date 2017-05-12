package X11::XCB::Sizehints;

use Mouse;
use Data::Dumper;
use X11::XCB qw(:all);
use X11::XCB::Sizehints::Aspect;
use v5.10;

has 'window' => (is => 'ro', isa => 'Int');
has '_conn' => (is => 'ro', required => 1);

has 'aspect' => (is => 'rw', isa => 'X11::XCB::Sizehints::Aspect', trigger => \&_update_aspect);

sub _update_aspect {
    my $self = shift;
    my $aspect = $self->aspect;

    my $hints = X11::XCB::ICCCM::SizeHints->new;

    $hints->set_aspect($aspect->min_num, $aspect->min_den,
                       $aspect->max_num, $aspect->max_den);

    X11::XCB::ICCCM::set_wm_size_hints($self->_conn, $self->window, ATOM_WM_NORMAL_HINTS, $hints);
}

=head1 NAME

X11::XCB::Sizehints - size hints attribute for an X11::XCB::Window

=head1 METHODS

=cut

1
# vim:ts=4:sw=4:expandtab
