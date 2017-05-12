package WebService::Hatena::Bookmark::Lite;

use strict;
use warnings;
our $VERSION = '0.03';

use Carp qw/croak/;
use XML::Atom::Link;
use XML::Atom::Entry;
use XML::Atom::Client;

use base qw/ Class::Accessor::Fast /;

__PACKAGE__->mk_accessors qw/
    client
/;

my $HatenaURI      = q{http://b.hatena.ne.jp/};
my $PostURI        = $HatenaURI.q{atom/post};
my $FeedURI        = $HatenaURI.q{atom/feed};

sub new{
    my( $class , %arg ) = @_;

    my $client = XML::Atom::Client->new;
    $client->username($arg{username});
    $client->password($arg{password});

    bless {
        client   => $client
    },$class;
}

sub add{
    my( $self , %arg ) = @_;

    my $url      = $arg{url};
    my $tag      = $arg{tag};
    my $comment  = $arg{comment};

    my $entry = XML::Atom::Entry->new;
    $entry->add_link( $self->_make_link_element($url) );

    $entry->summary( $self->_make_summary($tag,$comment) );

    return $self->client->createEntry($PostURI , $entry)
        or croak $self->client->errstr;
}

sub getEntry{
    my( $self , %arg ) = @_;

    my $EditURI = $self->_set_edit_uri( $arg{edit_ep} );

    return $self->client->getEntry( $EditURI )
        or croak $self->client->errstr;
}

sub edit{
    my( $self , %arg ) = @_;

    my $tag      = $arg{tag};
    my $comment  = $arg{comment};

    my $EditURI = $self->_set_edit_uri( $arg{edit_ep} );

    my $entry = XML::Atom::Entry->new;

    $entry->summary( $self->_make_summary($tag,$comment) );

    return $self->client->updateEntry($EditURI , $entry)
        or croak $self->client->errstr;
}

sub delete{
    my( $self , %arg ) = @_;

    my $EditURI = $self->_set_edit_uri( $arg{edit_ep} );

    return $self->client->deleteEntry($EditURI )
        or croak $self->client->errstr;
}

sub getFeed{
    my $self = shift;

    return $self->client->getFeed( $FeedURI )
        or croak $self->client->errstr;
}

sub entry2edit_ep{
    my( $self , $entry ) = @_;

    return if ! $entry;

    my $edit = '';
    for my $link ( $entry->link() ){
        if( $link->rel() eq 'service.edit'){
            $edit = $link->href();
            last;
        }
        else{
            next;
        }
    }
    my $edit_ep = substr($edit , length("$HatenaURI") );

    return $edit_ep;
}



sub _set_edit_uri{
    my( $self , $edit_ep ) = @_;

    return if ! $edit_ep;

    return sprintf("%s%s", $HatenaURI , $edit_ep);
}

sub _make_link_element{
    my( $self , $url ) = @_;

    my $link = XML::Atom::Link->new;

    $link->rel('related');
    $link->type('text/html');
    $link->href($url);

    return $link;
}

sub _make_tag{
    my( $self , $tag_list ) = @_;

    my $tag_str = '';
    for my $tag ( @{$tag_list} ){
        $tag_str .= sprintf("[%s]" , $tag);
    }

    return $tag_str;
}

sub _make_summary{
    my ( $self , $tag , $comment ) = @_;

    my $summary = $self->_make_tag($tag);
    $summary .= $comment || '';

    return $summary;
}


1;
__END__

=head1 NAME

WebService::Hatena::Bookmark::Lite - A Perl Interface for Hatena::Bookmark AtomPub API

=head1 SYNOPSIS

    use WebService::Hatena::Bookmark::Lite;

    my $bookmark = WebService::Hatena::Bookmark::Lite->new(
        username  => $username,
        password  => $password,
    );

    ### add
    my $edit_ep = $bookmark->add(
        url     => $url,
        tag     => \@tag_list,
        comment => $comment,
    );

    ### edit
    @tag = ( qw/ kaka tete /);
    $com = 'edit comment';

    $bookmark->edit(
        edit_ep => $edit_ep,
        tag     => \@tag ,
        comment => $com  ,
    );

    ### delete
    $bookmark->delete(
        edit_ep => $edit_ep ,
    );

    # Get Feed
    my $feed = $bookmark->getFeed();
    print $feed->as_xml;



=head1 DESCRIPTION

WebService::Hatena::Bookmark::Lite provides an interface to the Hatena::Bookmark AtomAPI.

If you use this module , It is necessary to prepare Hatena ID beforehand.

Hatena ID & password are necessary , when you install this module too.
please set ID & password using Conig::Pit , it looks like this.

  % perl -MConfig::Pit -e'Config::Pit::set("http://www.hatena.ne.jp", data=>{ username => "foobar", password => "barbaz" })'

=head1 METHODS

=head2 new

=over 4

  my $bookmark = WebService::Hatena::Bookmark::Lite->new(
      username  => $username,
      password  => $password,
  );

Creates and returns a WebService::Hatena::Bookmark::Lite Object.

=back

=head2 add

=over 4

  my $edit_ep = $bookmark->add(
      url     => $url,
      tag     => \@tag_list,
      comment => $comment,
  );

Add Entry of your Hatena::Bookmark.
Return EditURI End Point.

=back

=head2 edit

=over 4

  my $edit_ret = $bookmark->edit(
      edit_ep => $edit_ep,
      tag     => \@tag_list,
      comment => $comment,
  );

Edit exist entry of your Hatena::Bookmark.
Return true on success, false otherwise.

=back

=head2 delete

=over 4

  my $del_ret = $bookmark->delete(
      edit_ep  => $edit_ep ,
  );

Delete exist entry of your Hatena::Bookmark.

=back

=head2 entry2edit_ep

=over 4

  my $edit_ep = $bookmark->entry2edit_ep( $entry );

Need one parameter. what is XML::Atom::Entry Object.
Return EditURI End Point of correct entry.
EditURI End Point is unique number of each entry.

=back

=head2 getEntry

=over 4

  my $entry = $bookmark->getEntry(
      edit_ep  => $edit_ep ,
  );

Get exist entry of your Hatena::Bookmark.
Return XML::Atom::Entry Object.

=back

=head2 getFeed

=over 4

  my $feed = $bookmark->getFeed();

  print $feed->as_xml;

Get entries of your Hatena::Bookmark.
Return XML::Atom::Feed Object.

=back

=head1 REPOS

    http://github.com/masartz/p5-webservice-hatena-bookmark-lite/tree/master

=head1 AUTHOR

Masartz E<lt>masartz {at} gmail.comE<gt>

=head1 SEE ALSO

=over 4

=item * Hatena-Bookmark

http://b.hatena.ne.jp/

=item * Hatena-Bookmark API documentation

http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%D6%A5%C3%A5%AF%A5%DE%A1%BC%A5%AFAtomAPI

=item * L<XML::Atom>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
