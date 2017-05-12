use Moops -strict;

# ABSTRACT: represents a tag

=pod

=head1 NAME

WebService::Intercom::Tag - represent a tag

=head1 SYNOPSIS

  my $user = $intercom->user_get(email => 'test@example.com');

  # Add a tag to a user
  my $tag = $user->tag('test tag');

=head1 DESCRIPTION

Provides an object that represents a tag at Intercom.  

=head2 ATTRIBUTES

Tags are defined at L<http://doc.intercom.io/api/#tags>

=over

=item type

=item id

=item name

=item intercom - the WebService::Intercom object that created this user object

=back

=head2 METHODS

=over

=item save() - save any changes made to this tag back to
Intercom.io, returns a new WebService::Intercom::Tag object with the
updated tag.

=item delete() - delete this tag at Intercom.io

=back

=cut


class WebService::Intercom::Tag types WebService::Intercom::Types {
    has 'type' => (is => 'ro');
    has 'id' => (is => 'ro', isa => Str);
    has 'name' => (is => 'rw', isa => Str);
    has 'intercom' => (is => 'ro', isa => InstanceOf["WebService::Intercom"], required => 1);
    
    method save() {
        $self->intercom->tag_create_or_update($self);
    }
    
    method delete() {
        $self->intercom->tag_delete($self);
    }
};

1;
