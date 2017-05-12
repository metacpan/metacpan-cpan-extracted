use Moops -strict;

# ABSTRACT: represents a note

=pod

=head1 NAME

WebService::Intercom::Note - represent a note

=head1 SYNOPSIS

  my $user = $intercom->user_get(email => 'test@example.com');
  my $note = $user->add_note(body => "This is a test note");

=head2 ATTRIBUTES

Attributes are defined at L<http://doc.intercom.io/api/#notes>

=over

=item type

=item id

=item created_at

=item user

=item body

=item author

=item intercom - the WebService::Intercom object that created this user object

=back

=cut

class WebService::Intercom::Note types WebService::Intercom::Types {
    has 'type' => (is => 'ro');
    has 'id' => (is => 'ro');
    has 'created_at' => (is => 'rw');
    has 'user' => (is => 'ro');
    has 'body' => (is => 'ro', isa => Str);
    has 'author' => ('is' => 'ro', isa => Maybe[Str]);
};

1;
