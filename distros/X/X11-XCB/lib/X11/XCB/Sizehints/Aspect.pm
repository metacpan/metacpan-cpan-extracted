package X11::XCB::Sizehints::Aspect;

use Mouse;
use Data::Dumper;
use v5.10;

has 'min_num' => (is => 'rw', isa => 'Int');
has 'min_den' => (is => 'rw', isa => 'Int');
has 'max_num' => (is => 'rw', isa => 'Int');
has 'max_den' => (is => 'rw', isa => 'Int');

=head1 NAME

X11::XCB::Sizehints::Aspect - aspect ratio size hint

=head1 METHODS

=cut

1
