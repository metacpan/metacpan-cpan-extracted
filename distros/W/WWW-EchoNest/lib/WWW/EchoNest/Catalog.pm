
package WWW::EchoNest::Catalog;

BEGIN {
    our @EXPORT        = qw(  );
    our @EXPORT_OK     = qw( list_catalogs _types );
}
use parent qw[ WWW::EchoNest::CatalogProxy Exporter ];

use 5.010;
use strict;
use warnings;
use Carp;
use JSON;

use WWW::EchoNest::Logger qw( get_logger );
use WWW::EchoNest::Result::List;
use WWW::EchoNest::Functional qw(
                                    update
                                    make_stupid_accessor
                               );

use WWW::EchoNest::Util qw(
                              call_api
                              fix_keys
                         );

use overload
    '""' => '_stringify',
    ;



make_stupid_accessor( qw[ type ] );



# # # # METHODS # # # #

sub _stringify {
    return q[<Catalog - '] . $_[0]->get_name . q['>];
}

sub _types { WWW::EchoNest::CatalogProxy::_types }

sub _pretty_json { to_json( $_[0], { utf8 => 1, pretty => 1 } ) }

my @acceptable_actions = qw( delete update play skip );
sub _update {
    # $items is ARRAY ref
    my($self, $items_aref) = @_;
    my $id = $self->get_id;

    my $logger = get_logger;

    for my $item (@$items_aref) {
        $item->{action}  //= 'update';
        my $action         = $item->{action};
    
        croak "Unrecognized action: $action"
            if ! grep { $_ eq $action } @acceptable_actions;

        my $item_id = $item->{item}{item_id};
        
        croak 'No item_id' if ! $item_id;
        croak "Malformed item_id: $item_id"
            if $item_id !~ /[[:alpha:][:digit:][:punct:]]+/;
    }

    my $data = _pretty_json( $items_aref );

    $logger->debug('items: ' . $data);
    
    my $result = $self->post_attribute( {method => 'update', data => $data} );

    return $result->{ticket};
}

sub add_song {
    use Digest::MD5 qw( md5_hex );
    
    my($self, @songs) = @_;
    my $type          = $self->{type};

    croak "Cannot add song to $type catalog" if ($type ne 'song');

    my $items = [];
    SONG : for my $song (@songs) {
        my $item = { action => 'update', item => {} };
        $item->{item}{item_id} = md5_hex( $song->get_title );

        my $title     = $song->get_title;
        my $artist    = $song->get_artist_name;

        $item->{item}{song_name}      = $title  if $title;
        $item->{item}{artist_name}    = $artist if $artist;

        push @$items, $item;
    }
    my $ticket = $self->_update( $items );
    return $ticket;
}

sub add_artist {
    use Digest::MD5 qw( md5_hex );
    
    my($self, @artists) = @_;
    my $type            = $self->get_type;

    croak "Cannot add artist to $type catalog" if ($type ne 'artist');
    
    my $items = [];
    ARTIST : for my $artist (@artists) {
        my $item = { action => 'update', item => {} };
        my $name = $artist->get_name;

        $item->{item}{item_id}     = md5_hex( $name );
        $item->{item}{artist_name} = $name if $name;

        push @$items, $item;
    }
    my $ticket = $self->_update( $items );
    return $ticket;
}

sub status {
    my($self, $ticket) = @_;
    return $self->get_attribute_simple(
                                       {
                                        method => 'status',
                                        ticket => $ticket,
                                       },
                                      );
}

sub get_profile {
    return $_[0]->get_attribute( { method => 'profile' } )->{catalog};
}

sub read_items {
    my($self, $args_ref) = @_;
    my $request_ref      = {};
    
    $request_ref->{bucket}       = $args_ref->{buckets}   || [];
    $request_ref->{results}      = $args_ref->{results}   // 15;
    $request_ref->{start}        = $args_ref->{start}     // 0;
    $request_ref->{method}       = 'read';
    
    my $response = $self->get_attribute( $request_ref );
    my $return_list = WWW::EchoNest::Result::List->new
        (
         [],
         start   => $response->{catalog}{start},
         total   => $response->{catalog}{total},
        );
    
    ITEM : for my $item (@{ $response->{catalog}{items} }) {
        my $new_item;
        if (exists $item->{song_id}) {
            $item->{id}    = delete $item->{song_id  };
            $item->{title} = delete $item->{song_name};
            $new_item = WWW::EchoNest::Song->new(fix_keys( $item ));
        }
        elsif (exists $item->{artist_id}) {
            $item->{id}   = delete $item->{artist_id  };
            $item->{name} = delete $item->{artist_name};
            $new_item = WWW::EchoNest::Artist->new(fix_keys( $item ));
        }
        else {
            $new_item = $item;
        }
        $return_list->push( $new_item );
    }
    return $return_list;
}

sub get_feed {
    my($self, $args_ref) = @_;
    my $request_ref = {};
    $request_ref->{method}   = 'feed';
    $request_ref->{start}    = $args_ref->{start}    // 0;
    $request_ref->{results}  = $args_ref->{results}  // 15;
    $request_ref->{bucket}   = $args_ref->{buckets}  || [];
    $request_ref->{since}    = $args_ref->{since} if exists $args_ref->{since};
    my $response = $self->get_attribute( $request_ref );
    return WWW::EchoNest::Result::List->new( $response->{feed} );
}

sub delete {
    my $result = $_[0]->post_attribute( { method => 'delete' } );
    delete $result->{status};
    return $result;
}



# # # # FUNCTIONS # # # #

sub list_catalogs {
    my($args_ref) = @_;
    my $result = call_api(
                          {
                           method  => 'catalog/list',
                           params  =>
                           {
                            start     => $args_ref->{start}      // 0,
                            results   => $args_ref->{results}    // 30,
                           },
                          },
                         );
    my @catalogs = map {   WWW::EchoNest::Catalog->new(fix_keys($_))   }
        @{ $result->{response}{catalogs} };
    return wantarray ? @catalogs : \@catalogs;
}

1;

__END__

=head1 NAME

WWW::EchoNest::Catalog

=head1 SYNOPSIS

  Create catalogs of artists and songs for a given API Key. For example, Catalog names can be provided as arguments to some of the Playlist methods, to return only songs that are by artists in a given catalog.
  Please go to <http://developer.echonest.com/docs/v4/catalog.html> for more information about the way the Echo Nest Catalog API works.

=head1 METHODS

=head2 new

  Returns a new WWW::EchoNest::Catalog instance.
  
  NOTE:
    WWW::EchoNest also provides the get_catalog() convenience function
    to create new instances of WWW::EchoNest::Catalog.
  
  ARGUMENTS:
    id        => a catalog id
    name      => a catalog name
    type      => 'song' or 'artist' -- specifies the catalog type
  
  RETURNS:
    A new instance of WWW::EchoNest::Catalog.

  EXAMPLE:
    use WWW::EchoNest::Catalog;
    $catalog = WWW::EchoNest::Catalog->new({ name => 'my_songs', type => 'songs' });
    print 'id : ', $catalog->get_id, "\n";
    
    ######## Results will differ ########
    #
    # id : CAPSBIZ131500C102A

    # or...

    use WWW::EchoNest qw( :all );
    # Note:
    # - <type> defaults to song, so all we need is a name
    # - this method also could have been called with the HASH ref above
    $catalog = get_catalog('my_songs');
    print 'id : ', $catalog->get_id, "\n";
    
    ######## Results may differ ########
    #
    # id : CAPSBIZ131500C102A



=head2 add_song

  Add some Song objects to add to the catalog.

  ARGUMENTS:
    Some WWW::EchoNest::Song objects.
  
  RETURNS:
    A reference to an array of tickets to be used with the 'status' method.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    my $imagine_song      = get_song('SOFNJLR1312FDFABE5');
    my $satisfaction_song = get_song('SOMEEYZ12A8C1430B5');
    my @song_list = ( $imagine_song, $satisfaction_song );
    my $catalog = get_catalog('classic_songs');
    my $tickets_ref = $catalog->add_song( @song_list );
    my %status_for = map { $_ => $catalog->status($_) } @$tickets_ref;

    use Data::Dumper;
    for (keys %status_for) {
        print "ticket: $_\n";
        print 'status: ' . $status_for{$_}{'ticket_status'};
    };
    
    ######## Results may differ ########
    #
    # ticket : <insert_ticket_number_here>
    # status : complete



=head2 add_artist

  Add some Artist objects to add to the catalog.

  ARGUMENTS:
    Some WWW::EchoNest::Artist objects.
  
  RETURNS:
    A reference to an array of tickets to be used with the 'status' method.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    my $beatles = get_artist('The Beatles');
    my $stones  = get_artist('The Rolling Stones');
    my $catalog = get_catalog( { name => 'classic_artists', type => 'artist' } );
    my $tickets_ref = $catalog->add_artist( $beatles, $stones );
    my %status_for = map { $_ => $catalog->status($_) } @$tickets_ref;

    use Data::Dumper;
    for (keys %status_for) {
        print "ticket: $_\n";
        print 'status: ' . $status_for{$_}{'ticket_status'};
    };
    
    ######## Results may differ ########
    #
    # ticket : <insert_ticket_number_here>
    # status : complete



=head2 status

  Check the status of a catalog update.
  
  ARGUMENTS:
    ticket => A string representing a ticket ID.
  
  RETURNS:
    A hash ref that contains info about a ticket's status.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    my $catalog = catalog( { name => 'my_songs', type => 'songs' } );
    # Make an update, and store the ticket id as $ticket_id
    use Data::Dumper;
    print 'status : ', pretty_json( $catalog->status($ticket_id) ), "\n";
    
    ######## Results may differ ########
    #
    # status: {
    #     ticket_status => 'complete',
    #     update_info => [
    #     ]
    # };



=head2 get_profile

  Get basic information about a catalog.
  
  ARGUMENTS:
    none
  
  RETURNS:
    A hash ref to a description of a catalog.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    # Create a catalog and store it as $catalog...
    # Do some stuff with the catalog, like making updates...
    print 'profile: ', pretty_json( $catalog->get_profile ), "\n";
    
    ######## Results may differ ########
    #
    # profile: {
    #     'id'                => 'CAMSSDQ1303D86C20D',
    #     'name'              => 'catalog_foo_by_song',
    #     'pending_tickets'   => [],
    #     'resolved'          => 2,
    #     'total'             => 2,
    #     'type'              => 'song'
    # };



=head2 read_items

  Returns data from the catalog. Expands the requested buckets.
  
  ARGUMENTS:
    buckets   => A list of strings specifying which buckets to retrieve
    results   => An integer number of results to return (defaults to 15)
    start     => An integer starting value for the result set
    
    See <http://developer.echonest.com/docs/v4/catalog.html#read> for more info about possible values for 'buckets'.

  
  RETURNS:
    An array ref of objects in the catalog.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    # Create a catalog and store it as $catalog...
    # Do some stuff with the catalog, like making updates...
    my $items = $catalog->read_items( { results => 1 } );
    print 'items: ', pretty_json( $items ), "\n";
    
    ######## Results may differ ########
    #
    # items: {
    # }

=head2 get_feed

  Returns feed (news, blogs, reviews, audio, video) for the catalog artists;
  response depends on requested buckets
  
  ARGUMENTS:
    buckets   => A list of strings specifying which buckets to retrieve
    results   => An integer number of results to return (defaults to 15)
    start     => An integer starting value for the result set

    See <http://developer.echonest.com/docs/v4/catalog.html#read> for more info about possible values for 'buckets'.

  
  RETURNS:
    A reference to an array of news, blogs, reviews, audio or video document hash refs.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    # Create a catalog and store it as $catalog...
    # Do some stuff with the catalog, like making updates...
    my $feeds = $catalog->get_feed( { results => 1 } );
    print 'feeds: ', pretty_json( $feed ), "\n";

    ######## Results will differ ########
    #
    # Insert printout here!
    #
    #


=head2 delete

  Deletes the entire catalog.
  
  ARGUMENTS:
    none
  
  RETURNS:
    The deleted catalog's id.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    # Create a catalog and store it as $catalog...
    my $deleted_id = $catalog->delete();
    print "Deleted catalog $catalog_id\n";

    ######## Results will differ ########
    #
    # Deleted catalog CAMSSDQ1303D86C20D
    #



=head1 FUNCTIONS

=head2 list_catalogs

  Returns a list of all catalogs for a given API key.

  ARGUMENTS:
    results => An integer number of results to return (defaults to 30)
    start   => An integer starting value for the result set

  RETURNS:
    A reference to an array of references to Catalog objects.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    # Create some catalogs...
    my $catalog_list = list_catalogs( { results => 1 } );
    print 'Catalogs: ', pretty_json( $catalog_list ), "\n";

    ######## Results will differ ########
    #
    # Catalogs: {
    # }
    #



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
