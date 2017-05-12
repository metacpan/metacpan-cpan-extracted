# ABSTRACT: Represents a cloudcast in the Mixcloud API
package WWW::Mixcloud::Cloudcast;

use Moose;
use namespace::autoclean;

use Carp qw/ croak /;

our $VERSION = '0.01'; # VERSION

use WWW::Mixcloud::Cloudcast::Tag;
use WWW::Mixcloud::Cloudcast::Section;
use WWW::Mixcloud::Picture;
use WWW::Mixcloud::User;


has listener_count => (
    is       => 'ro',
    required => 1,
);


has name => (
    is       => 'ro',
    required => 1,
);


has tags => (
    isa      => 'ArrayRef[WWW::Mixcloud::Cloudcast::Tag]',
    is       => 'ro',
    required => 1,
    default  => sub { [] },
    traits   => ['Array'],
    handles  => {
        add_tag        => 'push',
        all_tags       => 'elements',
        number_of_tags => 'count',
    },
);


has url => (
    is       => 'ro',
    required => 1,
);


has pictures => (
    isa      => 'ArrayRef[WWW::Mixcloud::Picture]',
    is       => 'ro',
    required => 1,
    default  => sub { [] },
    traits   => ['Array'],
    handles  => {
        add_picture        => 'push',
        all_pictures       => 'elements',
        number_of_pictures => 'count',
    },
);


has update_time => (
    is       => 'ro',
    required => 1,
);


has play_count => (
    is       => 'ro',
    required => 1,
);


has comment_count => (
    is       => 'ro',
    required => 1,
);


has percentage_music => (
    is       => 'ro',
    required => 1,
);


has user => (
    isa      => 'WWW::Mixcloud::User',
    is       => 'ro',
    required => 1,
);


has key => (
    is       => 'ro',
    required => 1,
);


has created_time => (
    is       => 'ro',
    required => 1,
);


has audio_length => (
    is       => 'ro',
    required => 1,
);


has sections => (
    isa      => 'ArrayRef[WWW::Mixcloud::Cloudcast::Section]',
    is       => 'ro',
    required => 1,
    default  => sub { [] },
    traits   => ['Array'],
    handles  => {
        add_section        => 'push',
        all_sections       => 'elements',
        number_of_sections => 'count',
    },
);


has slug => (
    is       => 'ro',
    required => 1,
);


has description => (
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;


sub new_from_data {
    my $class = shift;
    my $data  = shift || croak 'Data reference required for construction';

    my $user = WWW::Mixcloud::User->new_from_data( $data->{user} );
    my $tags = WWW::Mixcloud::Cloudcast::Tag->new_list_from_data( $data->{tags} );
    my $pictures = WWW::Mixcloud::Picture->new_list_from_data( $data->{pictures} );
    my $sections = WWW::Mixcloud::Cloudcast::Section->new_list_from_data(
        $data->{sections}
    );

    my $cloudcast = $class->new({
        listener_count   => $data->{listener_count},
        name             => $data->{name},
        tags             => $tags,
        url              => $data->{url},
        pictures         => $pictures,
        update_time      => DateTime::Format::Atom->parse_datetime( $data->{updated_time} ),
        play_count       => $data->{play_count},
        comment_count    => $data->{comment_count},
        percentage_music => $data->{percentage_music},
        user             => $user,
        key              => $data->{key},
        created_time     => DateTime::Format::Atom->parse_datetime( $data->{created_time} ),
        audio_length     => $data->{audio_length},
        sections         => $sections,
        slug             => $data->{slug},
        description      => $data->{description},
    });
}

1;

__END__
=pod

=head1 NAME

WWW::Mixcloud::Cloudcast - Represents a cloudcast in the Mixcloud API

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 listener_count

=head2 name

=head2 tags

ArrayRef of L<WWW::Mixcloud::Cloudcast::Tag> objects.

=head2 url

=head2 pictures

ArrayRef of L<WWW::Mixcloud::Picture> objects.

=head2 update_time

L<DateTime> object.

=head2 play_count

=head2 comment_count

=head2 percentage_music

=head2 user

L<WWW::Mixcloud::User> object.

=head2 key

=head2 created_time

=head2 audio_length

=head2 sections

ArrayRef of L<WWW::Mixcloud::Cloudcast::Section> objects.

=head2 slug

=head2 description

=head1 METHODS

=head2 new_from_data

    my $cloudcast = WWW::Mixcloud::Cloudcast->new_from_data( $data )

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

