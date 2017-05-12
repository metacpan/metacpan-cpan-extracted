package XML::Atom::Lifeblog;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use Encode;
use File::Basename;
use MIME::Types;
use XML::Atom::Client;
use XML::Atom::Entry;
use XML::Atom::Lifeblog::Media;
use base qw(XML::Atom::Client);

sub postLifeblog {
    my($self, $post_uri, $title, $body, $media) = @_;
    if (!UNIVERSAL::isa($media, "XML::Atom::Lifeblog::Media") && !ref($media)) {
        $media = XML::Atom::Lifeblog::Media->new(filename => $media);
    } elsif (ref($media) eq 'HASH') {
        $media = XML::Atom::Lifeblog::Media->new(%$media);
    }

    my $atom_media = $self->_create_media($media);
    my $posted = $self->_post_entry($post_uri, $atom_media)
	or return $self->error("POST ($media) failed: " . $self->errstr);
    my $atom_body = $self->_create_body($title, $body, $posted->id, $media->type);
    return $self->_post_entry($post_uri, $atom_body);
}

sub _guess_mime_type {
    my($self, $media) = @_;
    # MIME::Types doesn't support 3gpp
    if ($media =~ /\.3gpp?$/) {
	# XXX what about audio/3gpp?
	return "video/3gpp";
    } else {
	my $mime = MIME::Types->new->mimeTypeOf($media);
	return $mime ? $mime->type : "application/octet-stream";
    }
}

sub _create_media {
    my($self, $media) = @_;

    my $entry = XML::Atom::Entry->new();
    $entry->title($media->title);
    $entry->content($media->content);
    $entry->content->type($media->type);

    # add <standalone>1</standalone>
    my $tp = XML::Atom::Namespace->new(standalone => "http://sixapart.com/atom/typepad#");
    $entry->set($tp => "standalone" => 1);
    return $entry;
}

sub _create_body {
    my($self, $title, $body, $id, $mime_type) = @_;
    my $entry = XML::Atom::Entry->new();
    $entry->title($title);
    $entry->content($body);

    # add link rel="related" for the uploaded image
    my $link = XML::Atom::Link->new();
    $link->type($mime_type);
    $link->rel('related');
    $link->href($id);
    $entry->add_link($link);
    return $entry;
}

# XXX XML::Atom::Client's createEntry doesn't return response body
sub _post_entry {
    my $client = shift;
    my($uri, $entry) = @_;
    return $client->error("Must pass a PostURI before posting")
	unless $uri;

    my $req = HTTP::Request->new(POST => $uri);
    $req->content_type('application/x.atom+xml');

    my $xml = $entry->as_xml;
    Encode::_utf8_off($xml);
    $req->content_length(length $xml);
    $req->content($xml);

    my $res = $client->make_request($req);
    return $client->error("Error on POST $uri: " . $res->status_line)
	unless $res->code == 201;
    return XML::Atom::Entry->new(Stream => \$res->content);
}

1;
__END__

=head1 NAME

XML::Atom::Lifeblog - Post lifeblog items using AtomAPI

=head1 SYNOPSIS

  use XML::Atom::Lifeblog;

  my $client = XML::Atom::Lifeblog->new();
  $client->username("Melody");
  $client->password("Nelson");

  my $entry = $client->postLifeblog($PostURI, $title, $body, "foobar.jpg");

  my $media = XML::Atom::Lifeblog::Media->new(content => $data);
  my $entry = $client->postLifeblog($PostURI, $title, $body, $media);

=head1 DESCRIPTION

XML::Atom::Lifeblog is a wrapper for XML::Atom::Client that handles
Nokia Lifeblog API to post images associated with text messages.

=head1 METHODS

XML::Atom::Lifeblog is a subclass of XML::Atom::Client.

=over 4

=item postLifeblog

  my $entry = $client->postLifeblog($PostURI, $title, $body, $media);

Creates a new Lifeblog entry and post it to a Lifeblog aware server
using C<< <standalone> >> element. C<$media> is either a
XML::Atom::Lifeblog::Media object, or a filepath of media file to be
posted.

Returns XML::Atom::Entry object for the posted entry.

There're several ways to create Media object. At least you should specify how to fetch media data. C<filename>, C<filehandle> or C<content>.

  # create Media object
  # Content-Type is auto-guessed and media title is auto-determined
  my $media = XML::Atom::Lifeblog::Media->new(filename => "foo.jpg");
  my $media = XML::Atom::Lifeblog::Media->new(filehandle => $fh);
  my $media = XML::Atom::Lifeblog::Media->new(content  => $data);

If you omit other parameters like C<type> and C<title>, they're automatically guessed and generated using MIME type and file magic. If you want to specify them explicitly, you can do this like:

  my $media = XML::Atom::Lifeblog::Media->new(
      filehandle => $fh, type => "video/3gpp", title => "My dog.3gp",
  );

  # Then post it with $title & $body to $PostURI
  my $entry = $client->postLifeblog($PostURI, $title, $body, $media);

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom::Client>
http://cognections.typepad.com/lifeblog/2004/12/lifeblog_postin.html

=cut
