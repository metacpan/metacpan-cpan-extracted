# ABSTRACT: Perl interface to Pi-hole

use v5.37.9;
use experimental qw( class builtin try );

package WWW::PiHole;

class WWW::PiHole {

  use URI;
  use HTTP::Tiny;
  use JSON::PP;

  # @formatter:off

  field $auth :param = undef;

  # @formatter:on

  my $uri = URI -> new( 'http://pi.hole/admin/api.php' );
  my $http = HTTP::Tiny -> new;
  my $json = JSON::PP -> new;

  method _status ( $uri ) {
    $json -> decode( $http -> get( $uri ) -> {content} ) -> {status};
  }

  method _list ( $uri ) {
    my $hash = $json -> decode( $http -> get( $uri ) -> {content} );
    if ( $hash -> {success} ) { # JSON::PP::Boolean
      $hash -> {message};       # {"success":true,"message":null}
    }
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
    $http -> get( $uri ) -> {content}; # domain name
  }



  method add_dns ( $domain , $ip ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customdns => undef );
    $uri -> query_param( action => 'add' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( ip => $ip );

    $http -> get( $uri ) -> {content}; # domain name

    # https://github.com/pi-hole/AdminLTE/blob/b29a423b9553654f113bcdc8a82296eb6e4613d7/scripts/pi-hole/php/func.php#L223

  }


  method remove_dns ( $domain , $ip ) {

    # Command: pihole -a removecustomdns

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customdns => undef );
    $uri -> query_param( action => 'delete' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( ip => $ip );

    $http -> get( $uri ) -> {content}; # domain name

  }

  method add_cname ( $domain , $target ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customcname => undef );
    $uri -> query_param( action => 'add' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( target => $target );

    $http -> get( $uri ) -> {content}; # domain name

  }



  method remove_cname ( $domain , $target ) {

    $uri -> query_param( auth => $auth );
    $uri -> query_param( customcname => undef );
    $uri -> query_param( action => 'delete' );
    $uri -> query_param( domain => $domain );
    $uri -> query_param( target => $target );

    $http -> get( $uri ) -> {content}; # domain name

  }

}

# https://github.com/pi-hole/AdminLTE/blob/master/api.php

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PiHole - Perl interface to Pi-hole

=head1 VERSION

version 0.230630

=head1 METHODS

=head2 enable()

Enable Pi-Hole

Returns the status ('enabled')

=head2 disable()

Disable Pi-Hole

Returns the status ('disabled')

=head2 status()

Get Pi-Hole status

Returns 'enabled' or 'disabled'    

=head2 add

Add domain to the blacklist (by default)

C<$list> can be one of: C<black>, C<regex_black>, C<white>, C<regex_white>

URL: http://pi.hole/admin/groups-domains.php

=head2 remove($domain [, $list])

Add domain to the blacklist (by default)

C<$list> can be one of: C<black>, C<regex_black>, C<white>, C<regex_white>

AdminLTE API Function: C<sub>

URL: http://pi.hole/admin/groups-domains.php

=head2 recent()

Get the most recently blocked domain name

AdminLTE API Function: C<recentBlocked>

=head2 add_dns($domain, $ip)

Add DNS A record mapping domain name to an IP address

=head2 add_cname($domain, $target)

Add DNS CNAME record effectively redirecting one domain to another

AdminLTE API Functions: C<customcname>, C<addCustomCNAMEEntry>

See the L<https://github.com/pi-hole/AdminLTE/blob/master/scripts/pi-hole/php/func.php|func.php> script

URL: http://localhost/admin/cname_records.php

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
