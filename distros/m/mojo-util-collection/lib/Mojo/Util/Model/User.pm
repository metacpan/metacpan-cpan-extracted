package Mojo::Util::Model::User;
use Mojo::Util::Model -base;

our $VERSION = '0.0.11';

has [qw(id email first_name last_name age)];

=head2 full_name

Returns the full name of the user.

=cut

has 'full_name' => sub {
  my $self = shift;
  return $self->first_name . ' ' . $self->last_name;
};

1;
