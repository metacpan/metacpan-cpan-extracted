package Tree::Transform::XSLTish::Context;
use Moose;
use Carp::Clan qw(^Tree::Transform::XSLTish);

our $VERSION='0.3';

has 'current_node' => ( is => 'rw', isa => 'Object' );
has 'node_list' => ( is => 'rw', isa => 'ArrayRef[Object]' );

__PACKAGE__->meta->make_immutable;no Moose;1;
__END__

=head1 NAME

Tree::Transform::XSLTish::Context - helper class

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=cut
