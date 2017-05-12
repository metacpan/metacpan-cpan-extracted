package WWW::Resource;

use 5.008006;
use strict;
use vars qw( $VERSION );
use warnings;

$VERSION = '0.01';

use Data::Dumper;

use FCGI;
use IO::Handle;
use CGI qw(:standard); # convenience functions
use HTTP::Status;

use XML::Dumper;
XML::Dumper::dtd;

use JSON;

my %formats = (
  xml  => \&pl2xml,
  json => sub { objToJson( $_[0], {pretty => 1, indent => 4} ) },
  browser => \&browserprint,
);

our $TTL = 60 * 60;    # time-to-live is 1 hr by default

sub run {
  my $package = bless {}, shift;
  my $STARTTIME = time;

  # install the pretty printer from the subclass, if it exists
  if( my $printer = $package->can("browserprint") ){
    $formats{browser} = $printer;
  }

  # how much time could a ttl live if a ttl could live time?
  $TTL = $package->ttl if $package->can("ttl");
 
  my $request = FCGI::Request;
  while ( $request->Accept >= 0 ) {

    my $method = $ENV{REQUEST_METHOD};

    if ( my $handler = $package->can($method) ) {

      my %query = map { split /=/ } split /;/, lc $ENV{QUERY_STRING};
      my( $status, $obj ) = $handler->(\%query);
      return_result(  $status, $obj );

    }
    else {
      return_result( RC_NOT_IMPLEMENTED );
    }

    # Time to leave?
    exit if ( time - $STARTTIME ) > $TTL;
  }
}

sub return_result {
  my ( $status, $obj ) = @_;
  my $status_msg = join " ", $status, status_message($status);

  if ( is_error($status) or !defined $obj ) {
    print header( -status => $status_msg );
    return;
  }

  my %query = map { split /=/ } split /;/, lc $ENV{QUERY_STRING};
  my $formatter = $formats{json};
  $formatter = $formats{ $query{format} }
        if (exists $query{format}
        and exists $formats{ $query{format} });

  print header( -status => $status_msg );
  
  print ref $obj ? $formatter->($obj) : $obj;
  return;
}


# Format the data structure for browser viewing. This is an incredibly
# stupid prettyprint. It simply places an html break at all newlines.
sub browserprint {
  my $obj = shift;
  my $dumped = Dumper $obj;
  substr($dumped, 0, 7) = '';
  $dumped =~ s/\n/<br>\n/g;
  return start_html("Pretty-printed Data Structure") . $dumped . end_html;
}


1;


__END__

=head1 NAME

WWW::Resource - Quickly create a REST style web service.

=head1 SYNOPSIS

  package ResourceName;

  use HTTP::Status
  use WWW::Resource;
  @ISA = qw( WWW::Resource );

  sub GET {
    return RC_OK, "Congratulations you have accessed this resource.";
  }

  ResourceName->run;

  =EOF

  In a browser:
  http[s]://localhost/resourcename
  
  Congratulations you have accessed this resource.


=head1 DESCRIPTION

This module ties together a small set of serializers and a FastCGI interface to a load balancer, in a convenient package allowing you to quickly deploy resources to the network with a bare minimum of coding. If you have installed a web server and configured it to use FastCGI - which takes about fifteen minutes if you use lighttpd - in about two more minutes you can expose a REST-style web service.

Userspace? No problem. SSL? No problem. Load balancing? Got it covered.

Please see "INSTALL.REST-FRAMEWORK" in the build directory for more info about the full system installation.

There are two ways to return your response to the caller (a browser or other program). You can simply return any Perl data structure, which will be serialized into the requested format (XML or JSON or "browser prettyprint" format), or you can actually construct a page yourself, perhaps even using CGI.pm to help, and return a single string. Any single string will be transmitted verbatim (after the headers) to the caller.

To access the resource via a browser or other program, decide which serialization format you want and add "format=xml" or "format=json" or "format=browser" to the query string part of the URI. For example, http://localhost/resourcename?format=browser.

Whenever you define a GET, PUT, POST, or DELETE function, those will be installed automatically as handlers. In fact you can override any HTTP method whatsoever, but in practice no one should need more than these for a REST style service. These functions will recieve as their only argument a hash reference to the parsed query string. For instance, the "format=browser" arg will be there, as well as any others. This is only for convenience, since these items are available through $ENV{QUERY_STRING}.

=head1 OVERLOADABLE METHODS

All HTTP methods are overloadable. In practice you will not need more than GET, POST, PUT, and DELETE.

In addition, B<ttl()> and B<browserprint> can be defined. B<ttl()> should return a time-to-live value in seconds. Each of your processes will then exit after recieving a request after ttl has been exceeded, and the FastCGI process manager will start a new instance. Define B<browserprint()> if you want to do your own pretty printing to the browser, ie when your service is called with B<format=browser>. The default one is incredibly stupid.


=head1 EXAMPLE

Here is a fully functioning REST style web service, implementing all four CRUD operations (create retrieve update delete) via the analogous POST GET PUT DELETE http methods. This resource consists of all the PATH_INFO / QUERY_STRING pairs it has seen via previous requests, in the form of a hash.

  package ResourceName;

  use HTTP::Status
  use WWW::Resource;
  @ISA = qw( WWW::Resource );

  my %resource = (); # no resources yet

  # Time-to-live - default 1 hr - optional. You can 
  # also set this in the load balancer config file, but here
  # is finer-grained control if you need it.
  sub ttl { 60*60 };

  # start the event loop
  ResourceName->run;

  # The above will run as-is, but won't do much.
  # Create the following CRUD-analogous methods for different responses.
  
  # "Retrieve"
  sub GET {

    # Return the specified value, if it exists
    if(exists $resource{$ENV{PATH_INFO}}){
      return RC_OK, $resource{$ENV{PATH_INFO}};
    }

    # No named resource specified? Return them all.
    elsif($ENV{PATH_INFO}){ 
      return RC_OK, \%resource;
    }

    # A named resource that's not there is an error
    return RC_NOT_FOUND;
  }


  # "Update"
  sub PUT {
    my ($rkey, $rval) = ($ENV{PATH_INFO}, $ENV{QUERY_STRING});
    if(exists $resource{$rkey}){
      $resource{$rkey} = $rval;
      return RC_UPDATED;
    }
    $resource{$rkey} = $rval;
    return RC_CREATED;
  }

  # "Create"
  sub POST {
    my ($rkey, $rval) = ($ENV{PATH_INFO}, $ENV{QUERY_STRING});
    $resource{$rkey} = $rval;
    return RC_CREATED;
  }

  # "Delete"
  sub DELETE {
    my ($rkey, $rval) = ($ENV{PATH_INFO}, $ENV{QUERY_STRING});
    if(exists $resource{$rkey}){
      delete $resource{$rkey};
      return RC_DELETED;
    }
    return RC_NOT_FOUND;
  }


=head2 REQUIRES

A web server with FastCGI support, lighttpd is recommended.
FCGI
LWP
JSON
XML::Dumper



=head1 AUTHOR

Ira Woodhead, E<lt>ira at sweetpota dot toE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ira Woodhead

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
