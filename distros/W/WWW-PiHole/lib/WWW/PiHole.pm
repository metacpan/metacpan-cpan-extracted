# ABSTRACT: Perl interface to Pi-hole

use v5.37.9;
use experimental qw( class );

package WWW::PiHole;

class WWW::PiHole {

  use URI;
  use HTTP::Tiny;
  use JSON::PP;
  use Syntax::Operator::In;
  use Term::ANSIColor;

  # @formatter:off

  field $auth :param = undef;

  # @formatter:on

  my $uri = URI -> new( 'http://pi.hole/admin/api.php' );
  my $http = HTTP::Tiny -> new;
  my $json = JSON::PP -> new;

  method _content ( ) {
    $http -> get( $uri ) -> {content};
  }

  method _content_json ( ) {
    $json -> decode( $http -> get( $uri ) -> {content} ); # 'content' is HTTP response body
  }

  method _status ( $uri ) {
    $self -> _content_json -> {status};
  }

  method _list ( $uri ) {
    my $json_body = $self -> _content_json;
    if ( $json_body -> {success} ) { # JSON::PP::Boolean
      $json_body -> {message};       # {"success":true,"message":null}
    }
  }

  method version ( $mode = 'current' ) {
    # Modes: 'update', 'current', 'latest', 'branch'

    #@formatter:off

    die colored ['bright_red', 'bold'], 'Bad mode'
      unless $mode in : eq ( 'update' , 'current' , 'latest' , 'branch' );

    #@formatter :on

    $uri -> query_param( versions => undef );

    my $hash = $json -> decode( $http -> get( $uri ) -> {content} );

    sprintf "Core: %s, Web: %s, FTL: %s\n" ,
      $hash -> {join '_' , 'core' , $mode} ,
      $hash -> {join '_' , 'core' , $mode} ,
      $hash -> {join '_' , 'core' , $mode} ,
  }


  method enable ( ) {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( enable => undef );
    $self -> _status( $uri );
  }


  method disable ( ) {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( disable => undef );
    $self -> _status( $uri );
  }


  method status ( ) {
    $uri -> query_param( status => undef );
    $self -> _status( $uri );
  }


  method add ( $domain , $list = 'black' ) {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( list => $list );
    $uri -> query_param( add => $domain );
    $self -> _list( $uri );
  }


  method remove ( $domain , $list = 'black' ) {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( list => $list );
    $uri -> query_param( sub => $domain );
    $self -> _list( $uri );
  }


  method recent ( ) {
    $uri -> query_param( recentBlocked => undef );
    $self -> content; # domain name
  }


  method add_dns ( $domain , $ip ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customdns => undef );
    $uri -> query_param( action => 'add' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( ip => $ip );

    $self -> _content; # domain name

  }


  method remove_dns ( $domain , $ip ) {

    # Command: pihole -a removecustomdns

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customdns => undef );
    $uri -> query_param( action => 'delete' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( ip => $ip );

    $self -> _content; # domain name

  }


  
  method get_dns ()
  {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( customdns => undef );
    $uri -> query_param( action => 'get' );

    $self -> _content_json -> {data};
  }



  method add_cname ( $domain , $target ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customcname => undef );
    $uri -> query_param( action => 'add' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( target => $target );

    $self -> _content; # domain name

  }


  method remove_cname ( $domain , $target ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customcname => undef );
    $uri -> query_param( action => 'delete' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( target => $target );

    $self -> _content; # domain name

  }



  method get_cname ()
  {
    $uri -> query_param( auth => $auth );
    $uri -> query_param( customcname => undef );
    $uri -> query_param( action => 'get' );

    $self -> _content_json -> {data};
  }



}

# https://github.com/pi-hole/AdminLTE/blob/master/api.php
# https://github.com/pi-hole/AdminLTE/blob/master/scripts/pi-hole/php/func.php

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PiHole - Perl interface to Pi-hole

=head1 VERSION

version 0.230680

=head1 METHODS

=head2 version([$mode])

Get the version string for Pi-hole components

=head2 enable()

Enable Pi-Hole

Returns the status ('enabled')

=head2 disable()

Disable Pi-Hole

Returns the status ('disabled')

=head2 status()

Get Pi-Hole status

Returns 'enabled' or 'disabled'    

=head2 add($domain [, $list])

Add a domain to the blacklist (by default)

C<$list> can be one of: C<black>, C<regex_black>, C<white>, C<regex_white>

URL: http://pi.hole/admin/groups-domains.php

=head2 remove($domain [, $list])

Remove a domain from the blacklist (by default)

C<$list> can be one of: C<black>, C<regex_black>, C<white>, C<regex_white>

AdminLTE API Function: C<sub>

URL: http://pi.hole/admin/groups-domains.php

=head2 recent()

Get the most recently blocked domain name

AdminLTE API: C<recentBlocked>

=head2 add_dns($domain, $ip)

Add DNS A record mapping domain name to an IP address

AdminLTE API: C<customdns>
AdminLTE Function: C<addCustomDNSEntry>

=head2 remove_dns($domain, $ip)

Remove a custom DNS A record

ie. IP to domain name association

AdminLTE API: C<customdns>
AdminLTE Function: C<deleteCustomDNSEntry>

=head2 get_dns()

Get DNS records as an array of two-element arrays (IP and domain)

AdminLTE API: C<customdns>
AdminLTE Function: C<echoCustomDNSEntries>

=head2 add_cname($domain, $target)

Add DNS CNAME record effectively redirecting one domain to another

AdminLTE API: C<customcname>

AdminLTE Function: C<addCustomCNAMEEntry>

See the L<func.php|https://github.com/pi-hole/AdminLTE/blob/master/scripts/pi-hole/php/func.php> script

URL: http://localhost/admin/cname_records.php

=head2 remove_cname($domain, $target)

Remove DNS CNAME record

=head2 get_cname()

Get CNAME records as an array of two-element arrays (domain and target)

AdminLTE API: C<customcname>
AdminLTE Function: C<echoCustomDNSEntries>

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
