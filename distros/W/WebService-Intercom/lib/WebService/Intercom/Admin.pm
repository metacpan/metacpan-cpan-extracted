use Moops -strict;

# ABSTRACT: represents an admin

=pod

=head1 NAME

WebService::Intercom::Admin - represent an admin

=head1 SYNOPSIS

  my $admins = $intercom->get_admins();
  my $first_admin = $admins->[0];

=head2 ATTRIBUTES

Attributes are defined at L<http://doc.intercom.io/api/#admins>

=over


=item type

=item id

=item name

=item email 

=item intercom - the WebService::Intercom object that created this user object

=back

=cut

class WebService::Intercom::Admin types WebService::Intercom::Types {
    has 'type' => (is => 'ro');
    has 'id' => (is => 'ro');
    has 'name' => (is => 'ro');
    has 'email' => (is => 'ro');
    has 'intercom' => (is => 'ro');
};

1;
