package WWW::Google::Contacts::Group;
{
    $WWW::Google::Contacts::Group::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Types qw(
  Category
);

use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

sub create_url {
    my $self = shift;
    return sprintf( "%s://www.google.com/m8/feeds/groups/default/full",
        $self->server->protocol );
}

extends 'WWW::Google::Contacts::Base';

with 'WWW::Google::Contacts::Roles::CRUD';

has id => (
    isa       => Str,
    is        => 'ro',
    writer    => '_set_id',
    predicate => 'has_id',
    traits    => ['XmlField'],
    xml_key   => 'id',
);

has etag => (
    isa            => Str,
    is             => 'ro',
    writer         => '_set_etag',
    predicate      => 'has_etag',
    traits         => ['XmlField'],
    xml_key        => 'gd:etag',
    include_in_xml => sub { 0 },      # This is set in HTTP headers
);

has category => (
    isa       => Category,
    is        => 'rw',
    predicate => 'has_category',
    traits    => ['XmlField'],
    xml_key   => 'category',
    default   => sub { undef },
    coerce    => 1,
);

has title => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_title',
    traits     => ['XmlField'],
    xml_key    => 'title',
    is_element => 1,
);

has member => (
    is         => 'ro',
    lazy_build => 1,
);

has link => (
    is             => 'rw',
    trigger        => \&_set_link,
    traits         => ['XmlField'],
    xml_key        => 'link',
    include_in_xml => sub { 0 },
);

# What to do with different link types
my $link_map =
  { 'self' => sub { my ( $self, $link ) = @_; $self->_set_id( $link->{href} ) },
  };

sub _set_link {
    my ( $self, $links ) = @_;
    $links = ref($links) eq 'ARRAY' ? $links : [$links];
    foreach my $link ( @{$links} ) {
        next unless ( defined $link_map->{ $link->{rel} } );
        my $code = $link_map->{ $link->{rel} };
        $link->{href} =~ s{/full/}{/base/};
        $self->$code($link);
    }
}

sub _build_member {
    my $self = shift;
    my $list =
      WWW::Google::Contacts::ContactList->new( server => $self->server );
    return $list->search( { group_membership => $self->id } );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 SYNOPSIS

    use WWW::Google::Contacts;

    my $google = WWW::Google::Contacts->new( username => "your.username", password => "your.password" );

    my $group = $google->new_group;
    $group->title("Lovers");

=head1 METHODS

=head2 $group->create

Writes the group to your Google account.

=head2 $group->retrieve

Fetches group details from Google account.

=head2 $group->update

Updates existing group in your Google account.

=head2 $group->delete

Deletes group from your Google account.

=head2 $group->create_or_update

Creates or updates group, depending on if it already exists

=head1 ATTRIBUTES

All these attributes are gettable and settable on Group objects.

=over 4

=item title

The title of the group

 $group->title("People I'm only 'friends' with because of the damn Facebook");

=item member

An array of members of the group

 foreach my $member (@{ $group->member }) {
   print $member->full_name . " is a member of the group.\n";
 }

=back

=head1 AUTHOR

 Magnus Erixzon <magnus@erixzon.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Magnus Erixzon / Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
