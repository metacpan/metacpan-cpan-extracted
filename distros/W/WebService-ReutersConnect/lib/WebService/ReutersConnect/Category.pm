package WebService::ReutersConnect::Category;
use Moose;

has 'id' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'description' => ( is => 'ro' , isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

WebService::ReutersConnect::Category - A Category of Channels.

=head1 id

=head2 description

=cut

