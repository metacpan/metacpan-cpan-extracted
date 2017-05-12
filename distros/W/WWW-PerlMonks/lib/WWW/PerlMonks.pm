package WWW::PerlMonks        ;

use 5.006                     ;
use strict                    ;
use warnings FATAL => 'all'   ;

use Carp                      ;

use HTTP::Request             ;
use LWP::UserAgent            ;

use XML::Smart                ;


=head1 NAME

WWW::PerlMonks - [Alpha Release] This module provides access to PerlMonks.

=head1 VERSION

Version 0.01 ** Alpha Release **

=cut

our $VERSION = '0.01'; # ** Alpha Release **

=head1 SYNOPSIS

This module provides access to PerlMonks. 

This is an Alpha release, there are features such as posting posts and replies that are not implemented ( See TODO section ).

Details on the Original API can be found at L<http://www.perlmonks.org/?node_id=72241>

Each function returns a hash that consists of the original XML parsed through XML::Smart - The original XML 
can be accessed through $result->{ RAW_XML }

Example: 

    use WWW::PerlMonks;

    my $ob = new WWW::PerlMonks( 
	USERNAME   =>   'username'      , # Optional - Required for functions that require authentication. 
	PASSWORD   =>   'password'      , # Optional - Required for functions that require authentication. 
	USER_AGENT =>   'WWW_PerlMonks' , # Optional - default 'WWW_PerlMonks' . $VERSION 
	DEBUG      =>   0               , # Optional - default - 0
	);

    # my $hash = $ob->get_chatterbox()                             ;
    # my $hash = $ob->get_private_messages()                       ;
    # my $hash = $ob->send_chatter()                               ;     # Unimplemented
    # my $hash = $ob->get_user_nodes_info()                        ;
    # my $hash = $ob->get_user_nodes_reputation()                  ;
    # my $hash = $ob->get_user_XP()                                ;
    # my $hash = $ob->get_online_users()                           ;
    # my $hash = $ob->get_newest_nodes()                           ;
    # my $hash = $ob->get_node_details( [ '72241', '507312' ] )    ;
    # my $hash = $ob->get_node_thread( '1015083' )                 ;
    # my $hash = $ob->get_scratch_pad()                            ;     # Unimplemented
    # my $hash = $ob->get_best_nodes()                             ;
    # my $hash = $ob->get_worst_nodes()                            ;
    # my $hash = $ob->get_selected_best_nodes()                    ;
    # my $hash = $ob->get_nav_info_for_node('72241')               ;


=head1 EXPORT

The is an Object Oriented Modules and does not export anything.

=head1 SUBROUTINES/METHODS

=head2 new

Usage:

    my $ob = new WWW::PerlMonks( 
	USERNAME   =>   'username'      , # Optional - Required for functions that require authentication. 
	PASSWORD   =>   'password'      , # Optional - Required for functions that require authentication. 
	USER_AGENT =>   'WWW_PerlMonks' , # Optional - default 'WWW_PerlMonks' . $VERSION 
	DEBUG      =>   0               , # Optional - default - 0
	);

=cut

sub new {
    
    my $class           = shift  ;
    my %parameter_hash  = @_     ;

    my $useage_howto = "
Usage:

    my \$ob = new WWW::PerlMonks( 
	USERNAME   =>   'username'      , # Optional - Required for functions that require authentication. 
	PASSWORD   =>   'password'      , # Optional - Required for functions that require authentication. 
	USER_AGENT =>   'WWW_PerlMonks' , # Optional - default 'WWW_PerlMonks' . $VERSION 
	DEBUG      =>   0               , # Optional - default - 0
	);

";


    my %function_to_url = %{ _get_function_to_url_hash() } ;

    my $authenticated = ( $parameter_hash{ USERNAME } and $parameter_hash{ PASSWORD } )  ? 1 : 0 ;

    $parameter_hash{ USER_AGENT   } = 'WWW_PerlMonks' . $VERSION  unless( $parameter_hash{ USER_AGENT   } ) ;
    
    $parameter_hash{ DEBUG        } = 0                           unless( $parameter_hash{ DEBUG        } ) ;

    my $self = {

	USERNAME                     =>   $parameter_hash{ USERNAME     }        ,
	PASSWORD                     =>   $parameter_hash{ PASSWORD     }        ,
	USER_AGENT                   =>   $parameter_hash{ USER_AGENT   }        ,


	AUTHENTICATED                =>   $authenticated                         ,
	FUNC_TO_URL_HASH             =>   \%function_to_url                      ,

	DEBUG                        =>   $parameter_hash{ DEBUG        }        ,

    };


    ## Private and class data here. 

    ## NONE


    bless( $self, $class );

    if( $self->{ DEBUG } == 1 ) { 
	
    }

    return $self;

}

=head2 get_chatterbox

This function retrieves the recents comments on the PerlMonks Chatterbox. 

Authentication: Not required. 

Parameters    : None        .

=cut

sub get_chatterbox { 

    my $self  = shift ;
    my $param = shift ;

    if( $param ) { 
	warn( "'get_chatterbox' does not take parameters but you seem to have passed something!\n" ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_chatterbox' } ;
    my $xml        = $self->_get_from_url( $url_to_get )             ;
    my $xml_hash   = new XML::Smart( $xml )->tree()                  ;

    $xml_hash->{ RAW_XML } = $xml ;

    return $xml_hash ;

}

=head2 get_private_messages

This function retrieves private messages in the inbox of the authenticated user.

Authentication: Required . 

Parameters    : None     .

=cut 

sub get_private_messages { 

    my $self  = shift ;
    my $param = shift ;

    croak( "'get_private_messages' requires authentication \n" ) unless( $self->{ AUTHENTICATED } ) ;

    if( $param ) { 
	warn( "'get_private_messages' does not take parameters but you seem to have passed something!\n" ) ;
    }

    my $url_to_get = 
	$self->{ FUNC_TO_URL_HASH }{ 'get_private_messages' } . 
	'&op=login;user=' . $self->{ USERNAME } . 
	';passwd=' . $self->{ PASSWORD } . ';'                       ;

    my $xml        = $self->_get_from_url( $url_to_get )             ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                  ;
    $xml_hash->{ RAW_XML } = $xml                                    ;

    return $xml_hash ;

}


=head2 send_chatter   [ Unimplemented ]

B<Unimplemented> - Original API seems to have a problem. 

This function sends chatter to the PerlMonks chatterbox on behalf of the authenticated user.

Authentication: Required . 

Parameters    : Chatter  .

=cut

sub send_chatter { 

    my $self    = shift ;
    my $message = shift ;

    croak( 'Unimplemented' ) ;

    return 0                 ;

    croak( "'send_chatter' requires authentication \n" ) unless( $self->{ AUTHENTICATED } ) ;
    croak( "Need a message to send\n!"                 ) unless( $message                 ) ;

}


=head2 get_user_nodes_info

This function returns details of a user. If authenticated the user param is optional and it will default to the authenticated user. 
Also reputation is available only when authenticated. 

Authentication: Required for 'reputation' . 

Parameters    : user if not authenticated, default is authenticated user.  

=cut

sub get_user_nodes_info { 

    my $self = shift ;
    my $user = shift ;

    $user    = $self->_find_user_to_use( $user ) ;

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_user_nodes_info' } . '&foruser=' . $user ;
    if( $self->{ AUTHENTICATED } ) { 
	$url_to_get .= 	
	    '&op=login;user=' . $self->{ USERNAME } . 
	    ';passwd=' . $self->{ PASSWORD } . ';'     ;
    }
    
    my $xml = $self->_get_from_url( $url_to_get ) ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                  ;
    $xml_hash->{ RAW_XML } = $xml                                    ;

    return $xml_hash ;

}


=head2 get_user_nodes_reputation

Returns reputation information about recently voted on nodes owned by the logged in user. Returns those nodes voted on since 
the last fetch or the past 24 hours whichever is shorter. Will return an error code if called sooner than 
10 minutes after the last fetch.

B<WARNING:> Required min time between hits is 10 min.

Authentication: Required . 

Parameters    : None     .

=cut

sub get_user_nodes_reputation { 

    my $self = shift ;
    
    croak( "'get_private_messages' requires authentication \n" ) unless( $self->{ AUTHENTICATED } ) ;

    my $url_to_get = 
	$self->{ FUNC_TO_URL_HASH }{ 'get_user_nodes_reputation' } . 
	'&op=login;user=' . $self->{ USERNAME } . 
	';passwd=' . $self->{ PASSWORD } . ';'                       ;

    
    my $xml = $self->_get_from_url( $url_to_get ) ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                  ;
    $xml_hash->{ RAW_XML } = $xml                                    ;

    return $xml_hash ;

}    

=head2 get_user_XP

This function returns the XP and other basic details of a user. If authenticated the user param is optional and it will default to the 
authenticated user. Also 'votesleft' is available only when authenticated. 

Authentication: Required for 'votesleft' . 

Parameters    : user if not authenticated, default is authenticated user.  

=cut 

sub get_user_XP { 

    my $self = shift ;
    my $user = shift ;

    $user    = $self->_find_user_to_use( $user ) ;

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_user_XP' } . '&for_user=' . $user ;
    if( $self->{ AUTHENTICATED } ) { 
	$url_to_get .= 	
	    '&op=login;user=' . $self->{ USERNAME } . 
	    ';passwd=' . $self->{ PASSWORD } . ';'     ;
    }
    
    
    my $xml = $self->_get_from_url( $url_to_get ) ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                  ;
    $xml_hash->{ RAW_XML } = $xml                                    ;

    return $xml_hash ;

}

=head2 get_online_users

This function returns a list of currently online users.

Authentication: Not Required.

Parameters    : None.

=cut 

sub get_online_users { 

    my $self  = shift ;
    my $param = shift ;

    if( $param ) { 
	warn( "'get_online_users' does not take parameters but you seem to have passed something!\n" ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_online_users' } ;
    
    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;
    
}

=head2 get_newest_nodes

This function returns a list of new nodes. 

Authentication: Not Required.

Parameters    : Optional - 'unix timestamp' of earliest message ( cannot be more than 8 days - 691200 sec - ago )

=cut

sub get_newest_nodes { 

    my $self          = shift ;
    my $since_seconds = shift ;

    if( defined( $since_seconds ) and $since_seconds > 691200 ) { # Magic number comes from restriction in API.
	warn( 'Requested earliest time is way too far out in the past, limiting to 8 days ( 691200 sec )' ) ;
	$since_seconds = 691200 ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_newest_nodes' } ;
    if( $since_seconds ) { 
	$url_to_get .= '&sinceunixtime=' . $since_seconds ;
    }
    
    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;
    

}

=head2 get_node_details

This function returns information about specific nodes.

Authentication: Not Required.

Parameters    : Required: reference to array containing node ids. 

=cut

sub get_node_details { 
    
    my $self  = shift ;
    my $nodes = shift ;

    my @nodes = @{ $nodes } ;

    eval { 
	@nodes = map( int, @nodes ) ;
    } ; if( $@ ) { 
	croak( 'Something wrong with the format in which you gave me nodes!' ) ;
    }

    my $number_of_nodes = @nodes ;

    unless( $number_of_nodes ) { 
	croak( 'Give me at least one node to get information for' ) unless ( $nodes ) ;
    }

    my $node_string = join( ',', @nodes ) ;
 

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_node_details' } . '&nodes=' . $node_string ;

    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;

}


=head2 get_node_thread

This function returns the node IDs of a thread, properly nested. 

Authentication: Not Required.

Parameters    : Required: nodeID of node to get thread of.

=cut

sub get_node_thread { 

    my $self = shift ;
    my $node = shift ;

    unless( $node ) { 
	croak( 'NodeID to get thread for missing!' ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_node_thread' } . '&id=' . $node ;
    

    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;

}    

=head2 get_scratch_pad  [ Unimplemented ]

B<Unimplemented>! There seems to be a problem with the original API.

=cut

sub get_scratch_pad { 

    my $self = shift ;

    croak( 'Unimplemented - API seems to have problems.' ) ;

    return 0 ;

}

=head2 get_best_nodes

This function returns a list of the best nodes. 

Authentication: Not Required.

Parameters    : None        .

=cut

sub get_best_nodes { 

    my $self  = shift ;
    my $param = shift ;

    if( $param ) { 
	warn( "'get_best_nodes' does not take parameters but you seem to have passed something!\n" ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_best_nodes' }   ;
    

    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;

}
    

=head2 get_worst_nodes

This function returns a list of the worst nodes. 

Authentication: Required.

Parameters    : None    .  

=cut

sub get_worst_nodes { 

    my $self  = shift ;
    my $param = shift ;

    if( $param ) { 
	warn( "'get_worst_nodes' does not take parameters but you seem to have passed something!\n" ) ;
    }

    unless( $self->{ AUTHENTICATED } ) { 
	croak( "'get_worst_nodes' requires authentication." ) ;
    }
    
    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_worst_nodes' }  ;
    $url_to_get .= 	
	'&op=login;user=' . $self->{ USERNAME } . 
	';passwd=' . $self->{ PASSWORD } . ';'                         ;

    my $xml = $self->_get_from_url( $url_to_get )                      ;

    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;

}
    

=head2 get_selected_best_nodes

This function returns a list of the all time best nodes. 

Authentication: Not Required .

Parameters    : None         .  

=cut

sub get_selected_best_nodes { 

    my $self  = shift ;
    my $param = shift ;

    if( $param ) { 
	warn( "'get_selected_best_nodes' does not take parameters but you seem to have passed something!\n" ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_selected_best_nodes' }   ;
    

    my $xml = $self->_get_from_url( $url_to_get )                               ;
    my $xml_hash   = new XML::Smart( $xml )->tree()                             ;
    $xml_hash->{ RAW_XML } = $xml                                               ;

    return $xml_hash ;

}

=head2 get_nav_info_for_node

This function provides an interface to the Navigational Nodelet - Description from Original API Follows:

PerlMonks automation clients can use this to spider the site in various ways. Its concept of operation is just like that of the 
Node Navigator nodelet: given a node (by ID), it reports the previous and next node, the previous and next of the same node 
type (e.g. Meditation), and the previous and next by the same author. Optionally, it lets you request the previous/next node, 
relative to the given node, of a different type or by a different author. 

Information on the search, including the search parameters and any error conditions, is reported in the <info> "header" 
element of the result.

Authentication: Not Required .

Parameters    : 

           nodeID   - of the reference node ( Required )
           nodetype - id of the desired node type (optional)
           author   - id of the desired author (that is, their homenode id) (optional)

=cut

sub get_nav_info_for_node { 

    my $self     = shift ;
    my $node     = shift ;
    my $nodetype = shift ;
    my $author   = shift ;

    unless( $node ) { 
	croak( 'NodeID to get nav info for missing!' ) ;
    }

    my $url_to_get = $self->{ FUNC_TO_URL_HASH }{ 'get_nav_info_for_node' } . '&id=' . $node ;
    if( $nodetype ) { 
	$url_to_get .= '&nodetype=' . $nodetype ;
    }
    if( $author   ) { 
	$url_to_get .= '&author='   . $author   ;
    }

    my $xml = $self->_get_from_url( $url_to_get )                      ;
    my $xml_hash   = new XML::Smart( $xml )->tree()                    ;
    $xml_hash->{ RAW_XML } = $xml                                      ;

    return $xml_hash ;

}    
    

=head1 INTERNAL SUBROUTINES/METHODS

These functions are used by the module. They are not meant to be called directly using the Net::XMPP::Client::GTalk object although 
there is nothing stoping you from doing that. 

=head2 _get_from_url

This function retrieves the contents of a web url. 

=cut 

sub _get_from_url { 

    my $self       = shift ;
    my $url        = shift ;

    my $user_agent = $self->{ USER_AGENT } ;

    croak( "User Agent undefined!\n" ) unless( $user_agent ) ;

    my $contents               ;
    my $response               ;
    my $attempts           = 0 ;
    my $successful_url_get = 0 ;
    while( ( $attempts < 1 ) and ( !($successful_url_get ) ) ) { 
	my $request = HTTP::Request->new(
	    GET => $url ,
	    );

	my $ua = LWP::UserAgent->new          ;
	$ua->timeout(60)                      ;
	$ua->env_proxy                        ;
	$ua->agent( $user_agent )             ;
	
	$response = $ua->request( $request )  ;
	if ($response->is_success) {
	    $contents = $response->content or $response->decoded_content ; 
	    $successful_url_get = 1                                      ;
	}  else {
	    $attempts++                                                  ;
	    sleep( ( $attempts * 2 ) )                                   ;
	}

    }

    unless( $successful_url_get ) { 
	croak(  "Failed access to $url : ".$response->status_line."\n"  ) ;
    }

    $contents =~ s/\s+$//g ;
    
    if( $contents eq '' and $self->{ AUTHENTICATED } ) { 
	warn( 'WARNING: Did not get data - possible authentication failure!' . "\n" ) ;
    }
    

    return $contents   ;

}

=head2 _get_function_to_url_hash

This function provides the mapping from functions used within this module and the PerlMonks API.

=cut

sub _get_function_to_url_hash { 

    my %relations = ( 

	'get_chatterbox'                 =>    'http://www.perlmonks.org/?node_id=207304'                   ,
	'get_private_messages'           =>    'http://www.perlmonks.org/?node_id=15848'                    ,
	'send_chatter'                   =>    'http://www.perlmonks.org/?node_id=227820'                   ,

	'get_user_nodes_info'            =>    'http://www.perlmonks.org/?node_id=32704'                    ,
	'get_user_nodes_reputation'      =>    'http://www.perlmonks.org/?node_id=507310'                   ,

	'get_user_XP'                    =>    'http://www.perlmonks.org/?node_id=16046&showall=1'          ,
	'get_online_users'               =>    'http://www.perlmonks.org/?node_id=15851'                    ,
	'get_newest_nodes'               =>    'http://www.perlmonks.org/?node_id=30175'                    ,
	'get_node_details'               =>    'http://www.perlmonks.org/?node_id=37150'                    ,
	'get_node_thread'                =>    'http://www.perlmonks.org/?node_id=180684'                   ,

	'get_scratch_pad'                =>    ''                                                           ,
	'get_best_nodes'                 =>    'http://www.perlmonks.org/?node_id=9066&displaytype=xml'     ,
	'get_worst_nodes'                =>    'http://www.perlmonks.org/?node_id=9488&displaytype=xml'     ,
	'get_selected_best_nodes'        =>    'http://www.perlmonks.org/?node_id=328478&displaytype=xml'   ,

	'get_nav_info_for_node'          =>    'http://www.perlmonks.org/?node_id=693598'                   ,

	) ;

    return \%relations ;

}

=head2 _find_user_to_use

This function picks the user to use based on context, user passed and ( if exists ) authenticated user.

=cut

sub _find_user_to_use { 

    my $self = shift ;
    my $user = shift ;


    unless( $user ) { 
	if( $self->{ AUTHENTICATED } ) { 
	    $user = $self->{ USERNAME } ;
	} else { 
	    croak( "Who do you want to get info for?\n" ) ;
	}  
    }

    return $user ;

}

=head1 AUTHOR

Harish Madabushi, C<< <harish.tmh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-perlmonks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PerlMonks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PerlMonks

You can also look for information at:

=over 5

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PerlMonks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PerlMonks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PerlMonks>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PerlMonks/>

=item * GitHub

L<https://github.com/harishmadabushi/WWW-PerlMonks>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Harish Madabushi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::PerlMonks
