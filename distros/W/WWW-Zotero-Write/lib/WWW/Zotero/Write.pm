package WWW::Zotero::Write;

use 5.6.0;
use strict;
use warnings;
use Moo;
extends 'WWW::Zotero';

use Carp;
use JSON;

#use Data::Dumper;
use URI::Escape;

=head1 NAME

WWW::Zotero::Write - Perl interface to the Zotero Write API

=cut

our $VERSION = '0.04';

=head1 VERSION

Version 0.04

=cut

=head1 DESCRIPTION

This module use L<Zotero Write API|https://www.zotero.org/support/dev/web_api/v3/write_requests> to add, update, delete items, collections, tags or searches.

=cut

=head1 SYNOPSIS

      use Data::Dumper;
      use WWW::Zotero::Write;
      #key is the zotero key for the library
      my $client = WWW::Zotero::Write->new(key => 'Inlfxd ... ');

       #@collections is an array of hash ref {name => $collection_name, 
       #                                      parentCollection => $parent_collection_key}

        my ( $ok, $same, $failed ) =
            $client->addCollections( \@collections, group => $groupid );

        unless ($ok) {
           print Dumper ($same), "\n", Dumper($failed), "\n";
           die "Collection not added";
         }
        my @keys;
        for my $c ( sort { $a <=> $b } keys %$ok ) {
            push @keys, $ok->{$c};
         }

         # $keys[ $pos ] contains the key of $items[ $pos ]

       # %data is a hash of fields => values pairs.
       # fields are  key (mandatory), name, parentCollection, relations

        my ( $ok, $same, $failed ) =
        $client->updateCollection( \%data, group => $groupid );

      # @keys is an array of collections zotero keys

        $client->deleteCollections( \@keys, group => $groupid )
            or die("Can't delete collections");


       # @modif is an array of hash ref
       #     { key  => $item_key,
       #        collections => $coll_ref,
       #        version     => $item_version
       #     }
       # $coll_ref is an array ref of collections keys the item belongs to

       my ( $ok, $same, $failed ) =
            $client->updateItems( \@modif, group => $groupid );
        unless ($ok) {
            print Dumper ($same), "\n", Dumper($failed), "\n";
            die "Items collections not modidified in Zotero";
        }

        # @itemkeys is an array of item zotero keys

        $client->deleteItems( \@itemkeys, group => $groupid ) or die("Can't delete items");

        my $template = $client->itemTemplate("book");
        $template->{titre} = "Hello World";
        $template->{date} = "2017";
        # ...

        push @items, $template;
        # @items is an array of hash ref of new data (templates completed with real values)

        my ( $ok, $same, $failed ) =
                $client->addItems( \@items, group => $groupid );
         unless ($ok) {
                print Dumper ($same), "\n", Dumper($failed), "\n";
                die "Items not added to Zotero";
        }
        my @keys;
        for my $c ( sort { $a <=> $b } keys %$ok ) {
            print $c, " ", $ok->{$c}, "\n";
            push @keys, $ok->{$c};
         }
         # $keys[ $pos ] contains the key of $items[ $pos ]

        #@v is an array of tags values
        $client->deleteTags(\@v, group=>$groupid) or die "Can't delete tags";

=cut

has last_modif_ver => ( is => 'rw' );

=head2 addCollections($coll_array_ref, user => $userid | group => $groupid)

Add an array of collection.

Param: the array ref of hash ref with collection name and parent key 
[{"name"=>"coll name", "parentCollection"=> "parent key"}, {}]

Param: the group or the user id

Returns undef if the ResponseCode is not 200 (409: Conflit, 412: Precondition failed)

Returns an array with three hash ref (or undef if the hash are empty): changed, unchanged, failed. 
The keys are the index of the hash received in argument. The values are the keys given by zotero

=cut

sub addCollections {
    my ( $self, $coll, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    $self->_add_this( $groupid, $userid, $coll, "collections" );

}

=head2 updateCollection ($data, group => $groupid | user => $userid)

Update an existing collection.

Param: hash ref of key value pairs. The zotero key of the collection must be present in the hash. 
        Others fields are  name, parentCollection, relations.

Param: the group id (hash key: group) or the user id (hash key: user).

Returns an array with three hash ref (or undef if the hash are empty): changed, unchanged, failed. 

=cut

sub updateCollection {
    my ( $self, $data, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    croak("Missing a collection key") unless ( $data->{key} );
    my $url =
        $self->_build_url( $groupid, $userid ) . "/collections/$data->{key}";
    my $token = encode_json($data);
    if ( !$data->{version} ) {
        $self->_header_last_modif_ver( $groupid, $userid );
    }
    my $response = $self->client->PATCH( $url, $token );
    return $self->_check_response( $response, "204" );
}

=head2 addItems($items, group => $groupid | user => $userid)

Add an array of items.

Param: the array ref of hash ref with completed item templates. 

Param: the group id (hash key: group) or the user id (hash key: user).

Returns undef if the ResponseCode is not 200 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

Returns an array with three hash ref (or undef if the hash are empty): changed, unchanged, failed. 

The keys are the index of the hash received in argument. The values are the keys given by zotero

=cut

sub addItems {
    my ( $self, $items, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    $self->_add_this( $groupid, $userid, $items, "items" );
}

=head2 updateItems($data, group => $groupid | user => $userid)

Update an array of items.

Param: the array ref of hash ref which must include the key of the item, the version of the item and the new value.

Param: the group id or the user id pass with the hash keys group or user.

Returns undef if the ResponseCode is not 200 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

Returns an array with three hash ref (or undef if the hashes are empty): changed, unchanged, failed. 

The keys are the index of the hash received in argument. The values are the keys given by zotero

=cut

sub updateItems {
    my ( $self, $data, %opt ) = @_;
    croak "updateItems: can't treat more then 50 elements"
        if ( scalar @$data > 50 );
    my ( $groupid, $userid ) = @opt{qw(group user)};
    my $url = $self->_build_url( $groupid, $userid ) . "/items";
    my $token = encode_json($data);
    $self->_header_last_modif_ver( $groupid, $userid );
    my $response = $self->client->POST( $url, $token );
    $self->last_modif_ver(
        $response->responseHeader('Last-Modified-Version') )
        if ( $response->responseCode eq "200" );
    return $self->_check_response( $response, "200" );
}

=head2 =head2 updateCollections($data, group => $groupid | user => $userid)

Update an array of collections.

Param: the array ref of hash ref which must include the key of the collection, and the new value.

Param: the group id or the user id pass with the hash keys group or user.

Returns undef if the ResponseCode is not 200 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

Returns an array with three hash ref (or undef if the hashes are empty): changed, unchanged, failed. 

The keys are the index of the hash received in argument. The values are the keys given by zotero

=cut

sub updateCollections {
    my ( $self, $data, %opt ) = @_;
    croak "updateCollections: can't treat more then 50 elements"
        if ( scalar @$data > 50 );
    my ( $groupid, $userid ) = @opt{qw(group user)};
    my $url = $self->_build_url( $groupid, $userid ) . "/collections";
    my $token = encode_json($data);
    $self->_header_last_modif_ver( $groupid, $userid );
    my $response = $self->client->POST( $url, $token );
    $self->last_modif_ver(
        $response->responseHeader('Last-Modified-Version') )
        if ( $response->responseCode eq "200" );
    return $self->_check_response( $response, "200" );
}

=head2 deleteItems($keys, group => $groupid | user => $userid)

Delete an array of items.

Param: the array ref of item keys to delete.

Param: the group or the user id, pass with the hash keys user or group.

Returns undef if the ResponseCode is not 204 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

=cut

sub deleteItems {
    my ( $self, $keys, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    $self->_delete_this( $groupid, $userid, $keys, "items?itemKey", "," );
}

=head2 deleteCollections($keys, group => $groupid | user => $userid)

Delete an array of collections.

Param: the array ref of collection keys to delete.

Param: the group or the user id, pass with the keys group or user.

Returns undef if the ResponseCode is not 204 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

=cut

sub deleteCollections {
    my ( $self, $keys, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    $self->_delete_this( $groupid, $userid, $keys,
        "collections?collectionKey", "," );

}

=head2 deleteSearches($keys, group => $groupid | user => $userid)

Delete an array of searches.

Param: the array ref of search key to delete.

Param: the group or the user id, pass with the keys group or user.

Returns undef if the ResponseCode is not 204 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

=cut

sub deleteSearches {
    my ( $self, $keys, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    $self->_delete_this( $groupid, $userid, $keys, "searches?searchKey",
        "," );

}

=head2 deleteTags($keys, group => $groupid | user => $userid)

Delete an array of tags.

Param: the array ref of tags to delete.

Param: the group or the user id, pass with the keys group or user.

Returns undef if the ResponseCode is not 204 (see https://www.zotero.org/support/dev/web_api/v3/write_requests).

=cut

sub deleteTags {
    my ( $self, $tags, %opt ) = @_;
    my ( $groupid, $userid ) = @opt{qw(group user)};
    my @encoded_tags = map ( uri_escape($_), @$tags );
    $self->_delete_this( $groupid, $userid, \@encoded_tags, "tags?tag",
        " || " );
}

sub _delete_this {
    my ( $self, $groupid, $userid, $data, $metadata, $sep ) = @_;
    confess "Can't delete more then 50 elements" if ( scalar @$data > 50 );
    my $url =
          $self->_build_url( $groupid, $userid )
        . "/$metadata="
        . join( $sep, @$data );

    $self->_header_last_modif_ver( $groupid, $userid );
    my $response = $self->client->DELETE($url);
    return $self->_check_response( $response, "204" );
}

sub _add_this {
    my ( $self, $groupid, $userid, $data, $metadata ) = @_;
    confess "Can't treat more then 50 elements"
        if ( scalar @$data > 50 );
    $self->_header_last_modif_ver( $groupid, $userid );
    my $url      = $self->_build_url( $groupid, $userid ) . "/$metadata";
    my $token    = encode_json($data);
    my $response = $self->client->POST( $url, $token );
    return $self->_check_response( $response, "200" );

}

sub _check_response {
    my ( $self, $response, $success_code ) = @_;
    my $code = $response->responseCode;
    my $res  = $response->responseContent;
    $self->log->debug( "> Code: ",    $code );
    $self->log->debug( "> Content: ", $res );

    return unless ( $code eq $success_code );
    if ( $success_code eq "200" ) {

        my $data = decode_json($res);
       
        my @results;
        for my $href ( $data->{success}, $data->{unchanged}, $data->{failed} )
        {
            push @results, ( scalar keys %$href > 0 ? $href : undef );
        }
        return @results;
    }
    else { return 1 }
    ;    #code 204

}

sub _get_last_modified_version {
    my ( $self, $groupid, $userid ) = @_;

    my $url = $self->_build_url( $groupid, $userid ) . "/collections/top";
    my $response = $self->client->GET($url);
    if ($response) {
        my $last_modif = $response->responseHeader('Last-Modified-Version');
        $self->log->debug("> Last-Modified-Version: $last_modif");
        $self->last_modif_ver($last_modif);
        return 1;
    }
    return 0;

}

sub _build_url {
    my ( $self, $groupid, $userid ) = @_;
    confess("userid or groupid missing") unless ( $groupid || $userid );
    confess("userid and groupid: choose one, can't use both")
        if ( $groupid && $userid );
    my $id   = defined $userid ? $userid : $groupid;
    my $type = defined $userid ? 'users' : 'groups';

    return $self->baseurl . "/$type/$id";

}

sub _header_last_modif_ver {
    my ( $self, $groupid, $userid ) = @_;

    #ensure to set the last-modified-version with querying
    #all the top collection
    confess("Can't get Last-Modified-Version")
        unless ( $self->_get_last_modified_version( $groupid, $userid ) );
    $self->client->addHeader( 'If-Unmodified-Since-Version',
        $self->last_modif_ver() );

}

1;

=head1 BUGS

See support below.

=head1 SUPPORT

Any questions or problems can be posted to me (rappazf) on my gmail account.

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/www-zotero-write/> 

=head1 AUTHOR

FranE<ccedil>ois Rappaz
CPAN ID: RAPPAZF

=head1 COPYRIGHT

FranE<ccedil>ois Rappaz 2017
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<WWW::Zotero>

=cut

