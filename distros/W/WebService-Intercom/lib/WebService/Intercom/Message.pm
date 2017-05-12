use Moops -strict;

# ABSTRACT: represents a message

=pod

=head1 NAME

WebService::Intercom::Message - represent a message

=head1 SYNOPSIS

  my $message = $intercom->create_message(from => {type => 'admin', id => 'test' }, 
                                          body => 'test message',
                                          template => 'personal',
                                          message_type => 'email',
                                          subject => 'test subject');

=head2 ATTRIBUTES

Attributes are defined at L<http://doc.intercom.io/api/#admin-initiated-conversation> 
and L<http://doc.intercom.io/api/#user-initiated-conversation>

=over

=item body

=item id

=item message_type

=item created_at

=item intercom - the WebService::Intercom object that created this user object

=back

=cut

class WebService::Intercom::Message types WebService::Intercom::Types {
    has 'type' => (is => 'ro');
    has 'id' => (is => 'ro');
    has 'body' => (is => 'ro', isa => Str);
    has 'message_type' => (is => 'ro', isa => Maybe[Str]);
    has 'template' => (is => 'ro', isa => Maybe[Str]);
    has 'owner' => (is => 'ro');
    has 'created_at' => (is => 'ro');
    has 'intercom' => (is => 'ro');
};

1;
