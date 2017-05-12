package Yahoo::Music::Ratings;

use LWP::UserAgent;
use XML::Simple;
use strict;
use warnings;

our $VERSION = '2.00';


# Preloaded methods go here.

sub new {
    my $class = shift;
    my $this = bless {}, $class;
    
    # Set sessions options
    $this->{options} = shift;
    
    print '-' x 80,
          "\nYahoo::Music::Ratings Progress Output Enabled\n",
          '-' x 80,
          "\n" if $this->{options}->{progress};
    
    return $this;
}

sub findMemberId {
    my $this = shift;
    
    unless ( $this->{memberid} ){
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->env_proxy;
        
        $ua->max_redirect(0);
        
        my $url = 'http://music.yahoo.com/launchcast/membersearch.asp?memberName='.$this->{options}->{memberName};
        print "Fetching web page\n" if $this->{options}->{progress};
        my $response = $ua->get( $url );
        
        if ($response->is_success) {
            #print $response->status_line;
            $this->{errorMessage} = "\nLooks like either Yahoo is down, the membername provided is down or they've changed their site which means this module no longer works. Sorry :(";
            print "$this->{errorMessage}\n" if $this->{options}->{progress};
            return( 0 );
        }
        else {
            ($this->{memberid}) = $response->header('Location') =~ m/station\.asp\?u=(\d+)/g;
            print "Found $this->{options}->{memberName}'s memberId: $this->{memberid}\n" if $this->{options}->{progress};
            return( $this->{memberid} );    
        }
    }
}

# Backward Compatibility with version 1.00
sub getRatings {
    my $this = shift;
    return $this->getSongs();
}

# Display a list of Song Rankings
sub getSongs {
    my $this = shift;
    
    # Check if we have a member id, if not, return 0
    return 0 unless $this->_checkIfMemberId() ;
    
    # Reset the data hash as to not colide with old data
    undef($this->{data});
    
    print "Loading Ratings Pages\n" if $this->{options}->{progress};
    if ( $this->_parseRatings( 0, 1 ) ){
        for(my $i=1; $i < $this->{totalPages}; $i++){
            $this->_parseRatings( $i, 1 );
        }
        
        return( $this->{data} );
    }
    else {
        return( 0 );
    }
     
}

# Display a list of Album Rankings
sub getAlbums {
    my $this = shift;
    
    # Check if we have a member id, if not, return 0
    return 0 unless $this->_checkIfMemberId() ;
    
    # Reset the data hash as to not colide with old data
    undef($this->{data});
    
    print "Loading Ratings Pages\n" if $this->{options}->{progress};
    if ( $this->_parseRatings( 0, 2 ) ){
        for(my $i=1; $i < $this->{totalPages}; $i++){
            $this->_parseRatings( $i, 2 );
        }
        
        return( $this->{data} );
    }
    else {
        return( 0 );
    }
     
}

# Display a list of Artist Rankings
sub getArtists {
    my $this = shift;
    
    # Check if we have a member id, if not, return 0
    return 0 unless $this->_checkIfMemberId() ;
    
    # Reset the data hash as to not colide with old data
    undef($this->{data});
    
    print "Loading Ratings Pages\n" if $this->{options}->{progress};
    if ( $this->_parseRatings( 0, 3 ) ){
        for(my $i=1; $i < $this->{totalPages}; $i++){
            $this->_parseRatings( $i, 3 );
        }
        
        return( $this->{data} );
    }
    else {
        return( 0 );
    }
     
}

# Display a list of Song Rankings
sub getGenres {
    my $this = shift;
    
    # Check if we have a member id, if not, return 0
    return 0 unless $this->_checkIfMemberId() ;
    
    $this->{errorMessage} = "Genre Listing Is not Yet Enabled. This is partly becuase Yahoo has yet to provide much of usfulness.";
    print "$this->{errorMessage}\n" if $this->{options}->{progress};
            
    return( 0 );
     
}

# Internal Function to check if we have a member ID yet.
sub _checkIfMemberId {
    my $this = shift;
    
    # check to see if we have a memberId for this user,
    # if not fetch one
    unless ( $this->{memberid} ){
        unless ( $this->findMemberId() ){
            # if we were unable to fetch a memberId then return negativly
            # User should check $foo->error_message() for errors
            return( 0 );
        }
    }
}

# Parse Yahoo XML feed
# Arguments:
#	int, pageNumber
#	int, search type - 1 = song
#                      2 = album
#                      3 = artist
#                      4 = genre
sub _parseRatings {
    my $this = shift;
    my $page = shift;
    my $type = shift;
    
    my $xs = new XML::Simple();
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    
    my $url = 'http://yme.us.music.yahoo.com/profile/rating_xml.asp?type='. $type .'&uid='. $this->{memberid} .'&p='. $page .'&g=undefined&gt=1';
    print "Fetching web page " if $this->{options}->{progress};
    
    my $response = $ua->get( $url );
    
    if ($response->is_success) {
        my $ref = $xs->XMLin( $response->content );

        # Search for type 1, songs
        if ($type == 1){
            $this->{totalPages} = $ref->{SONG_RATINGS}->{SONG_RATING_LIST}->{POSITION}->{PAGES}->{TOTAL};
            $this->{currentPage} = $ref->{SONG_RATINGS}->{SONG_RATING_LIST}->{POSITION}->{PAGES}->{CURRENT};
            print "$this->{currentPage} of $this->{totalPages}\n" if $this->{options}->{progress};
        
            foreach my $elem (@{$ref->{SONG_RATINGS}->{SONG_RATING_LIST}->{LIST}->{LIST_ROW}}) {
                #  {
                #	'VIEWER_RATING' => {
                #					   'VALUE' => '-1'
                #					 },
                #	'SONG' => {
                #			  'ID' => '319952',
                #			  'ALBUM' => {
                #						 'ID' => '115213',
                #						 'NAME' => 'The Slim Shady LP (Edited)'
                #					   },
                #			  'NAME' => 'My Name Is',
                #			  'HAS_SAMPLE' => {},
                #			  'ARTIST' => {
                #						  'ID' => '289114',
                #						  'NAME' => 'Eminem'
                #						},
                #			  'HAS_TETHDOWNLOAD' => {},
                #			  'HAS_ODSTREAM' => {},
                #			  'HAS_PERMDOWNLOAD' => {}
                #			},
                #	'USER_RATING' => {
                #					 'VALUE' => '100'
                #				   }
                #  },
                
                push(@{$this->{data}}, [
                             $elem->{SONG}->{ARTIST}->{NAME},
                             $elem->{SONG}->{NAME},
                             $elem->{SONG}->{ALBUM}->{NAME},
                             $elem->{USER_RATING}->{VALUE},
                             ]);
            }
        
            return( 1 );
        }
        # Search for type 2, albums
        elsif ( $type == 2 ){
            $this->{totalPages} = $ref->{ALBUM_RATINGS}->{ALBUM_RATING_LIST}->{POSITION}->{PAGES}->{TOTAL};
            $this->{currentPage} = $ref->{ALBUM_RATINGS}->{ALBUM_RATING_LIST}->{POSITION}->{PAGES}->{CURRENT};
            print "$this->{currentPage} of $this->{totalPages}\n" if $this->{options}->{progress};
        
            foreach my $elem (@{$ref->{ALBUM_RATINGS}->{ALBUM_RATING_LIST}->{LIST}->{LIST_ROW}}) {
                #{
                #  'ALBUM' => {
                #               'ID' => '48792',
                #               'NAME' => 'New Adventures In Hi-Fi',
                #               'ARTIST' => {
                #                             'ID' => '261307',
                #                             'NAME' => 'R.E.M.'
                #                           }
                #             },
                #  'VIEWER_RATING' => {
                #                       'VALUE' => '-1'
                #                     },
                #  'USER_RATING' => {
                #                     'VALUE' => '90'
                #                   }
                #},
                
                push(@{$this->{data}}, [
                             $elem->{ALBUM}->{ARTIST}->{NAME},
                             $elem->{ALBUM}->{NAME},
                             $elem->{USER_RATING}->{VALUE},
                             ]);
            }
        
            return( 1 );
        }
        # Search for type 3, artist
        elsif ( $type == 3 ){
            $this->{totalPages} = $ref->{ARTIST_RATINGS}->{ARTIST_RATING_LIST}->{POSITION}->{PAGES}->{TOTAL};
            $this->{currentPage} = $ref->{ARTIST_RATINGS}->{ARTIST_RATING_LIST}->{POSITION}->{PAGES}->{CURRENT};
            print "$this->{currentPage} of $this->{totalPages}\n" if $this->{options}->{progress};
        
            foreach my $elem (@{$ref->{ARTIST_RATINGS}->{ARTIST_RATING_LIST}->{LIST}->{LIST_ROW}}) {
                #{
                #  'VIEWER_RATING' => {
                #                       'VALUE' => '-1'
                #                     },
                #  'ARTIST' => {
                #                'ID' => '314672',
                #                'NAME' => 'Bill Engvall'
                #              },
                #  'USER_RATING' => {
                #                     'VALUE' => '60'
                #                   }
                #},
                
                push(@{$this->{data}}, [
                             $elem->{ARTIST}->{NAME},
                             $elem->{USER_RATING}->{VALUE},
                             ]);
            }
        
            return( 1 );
        }
        # Search for type 4, genre
        elsif ( $type == 4 ){
            return( 0 );
        }
    }
    else {
        $this->{errorMessage} = "\nLooks like either Yahoo is down or they've changed their site which means this module no longer works. Sorry :(";
        print "$this->{errorMessage}\n" if $this->{options}->{progress};
        return( 0 );
    }
}

sub tab_output {
    my $this = shift;
    
    my @tabbed;
    
    foreach my $row (sort {uc($a->[0]) cmp uc($b->[0])} @{$this->{data}}){
        push(@tabbed, join("\t", @{$row} ) );
    }
    
    my $tabbed = join("\n", @tabbed);
    undef(@tabbed);
    return( $tabbed );
}

sub error_message {
    my $this = shift;
    return( $this->{errorMessage} );
}


1;
__END__

=head1 NAME

Yahoo::Music::Ratings - A method for retrieving a Yahoo! Music
members song ratings.

=head1 SYNOPSIS

    use Yahoo::Music::Ratings;
    
    my $ratings = new Yahoo::Music::Ratings( { 
				memberName => 'yahooMusicMemberName',
		} );
    
    # Fetch an arrayRef of all yahooMusicMemberName song ratings
    # this may take a couple minutes...
    my $arrayRef = $ratings->getRatings();
    
    # Print out a nice tab seperated version so that we can easily
    # read the list in a spreadsheet program (and then filter by
    # artists etc). tab_output() will output in artists alphabetical
    # order.
    print $ratings->tab_output();

=head1 DESCRIPTION

This module provides a way to retrieve a user's list of song ratings 
from Yahoo!'s Music service, including the LaunchCast and 
Unliminted services.

As Yahoo! do not provide an offical feed for a member to download
their ratings, the methods used within this module are subject to
change and simply may not work tomorrow. However at the time of 
writing this README i would suspect the methods used should be
stable for atleast a few days :)

=head1 METHODS

=head2 new( $hashref )
	
new() expects to find a hashref with a key and value of 
C<memberName> (Yahoo Music! Member Name).

    my $ratings = new Yahoo::Music::Ratings( { 
        memberName => 'smolarek', 
        progress => 0 
       } );

Providing a true value to the optional C<progress> argument will give you
a simple progress report printed to STDOUT.

returns an object reference

=head2 getRatings

Depreciated, please see getSongs

=head2 getSongs

No arguments are required.

Fetches a members song listing. This function will need to make
several calls to the Yahoo! Music site and therefore may take upto
a few minutes on a slow connection.

    my $arrayRef = $ratings->getSongs();

getRatings() will retun 0 if a problem was encountered or an arreyRef
if everything worked as planned. The arrayRef contains a 3d array of
ratings.

Example output:
    
    [
        'Red Hot Chili Peppers',    # Artist
        'Under The Bridge',         # Song
        'Blood Sugar Sex Magik',    # Album
        '100'                       # Member Song Rating 
    ],
    
=head2 getArtists

No arguments are required.

Fetches a members artist ratings. This function will need to make
several calls to the Yahoo! Music site and therefore may take upto
a few minutes on a slow connection.

    my $arrayRef = $ratings->getArtists();

getRatings() will retun 0 if a problem was encountered or an arreyRef
if everything worked as planned. The arrayRef contains a 3d array of
ratings.

Example output:
    
    [
      'The White Stripes',  # Artist
      '90'                  # Rating
    ],
    
=head2 getAlbums

No arguments are required.

Fetches a members song listing. This function will need to make
several calls to the Yahoo! Music site and therefore may take upto
a few minutes on a slow connection.

    my $arrayRef = $ratings->getAlbums();

getRatings() will retun 0 if a problem was encountered or an arreyRef
if everything worked as planned. The arrayRef contains a 3d array of
ratings.

Example output:
    
    [
      'Radiohead',   # Artist    
      'OK Computer', # Album
      '90'           # Rating
    ],
    

=head2 tab_output [optional]

No arguments required.

You I<must> call either C<getSongs()>, C<getArtists()>  or C<getAlbums()>
prior to using this function.

Will return a large string containing a tab seperated value of
ratings requested previously in artist alphabetical order. Simply 
pipe this string to a file and open in a spreadsheet application for
easy filtering and readability. If an error has been detected, 
will return 0.

Example

    The Police	Every Breath You Take	Synchronicity	90
    Van Morrison	Brown Eyed Girl	Blowin' Your Mind!	90


=head2 error_message [optional]

If any previous function returns 0 you can call C<error_message()>
to get a descriptive error message.

Returns a string with the error.

=head2 findMemberId [optional]

To get a member's player ratings we need to convert the memberName
into a memberId (bigint). This ID servers little other purpose,
however should you wish to retain this ID or to seak for several
different member ID's without further need to query the ratings
then simply exectute this function without arguments.

returns an int

=head1 EXPORT

None by default.


=head1 SEE ALSO

B<Yahoo::Music::Ratings> requires L<XML::Simple> or L<LWP::UserAgent>.

=head1 AUTHOR

Pierre Smolarek - smolarek a-t cpan d-o-t org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Pierre Smolarek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
