package WWW::DirectAdmin::API;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
use Data::Dumper qw( Dumper );
use HTML::Entities;
use HTTP::Request;
use LWP::UserAgent ();
use Params::Validate;
use URI;

sub new {
    my ( $class, %params ) = @_;
    my $self = bless {}, $class;

    $self->{host} = delete $params{host}
      || croak "Missing required 'host' parameter";
      
    $self->{port}     = delete $params{port};

    $self->{username} = delete $params{username}
      || croak "Missing required 'username' parameter";

    $self->{password} = delete $params{password}
      || croak "Missing required 'password' parameter";

    $self->{ua} = delete $params{ua}
      || LWP::UserAgent->new(
        agent      => __PACKAGE__ . "/$VERSION",
        cookie_jar => {}
      );

    $self->{scheme}      = $params{https} ? 'https' : 'http';
    $self->{domain}      = delete $params{domain};
    $self->{debug_level} = delete $params{debug} || 0;
    $self->{error}       = {};

    return $self;
}

sub uri {
    my $self = shift;

    if ( !$self->{uri} ) {
        my $str = sprintf "%s://%s",
          $self->{scheme},
          $self->{host} . ( $self->{port} ? ":$self->{port}" : '' );

        my $uri = URI->new($str);

        $self->{uri} = $uri;
    }

    return $self->{uri};
}

sub debug_level {
    my $self = shift;

    $self->{debug_level} = shift if @_;

    return $self->{debug_level};
}

sub error {
    my $self = shift;

    $self->{error}  = shift if @_;

    return $self->{error};
}

# NOTE: parameters for Reseller or User packages are different than Admin levels
sub _send_request {
    my $self = shift;
    my %p    = validate @_,
      {
        command => 1,
        method  => { default => 'GET' },
        domain  => { default => $self->{domain} },
        params  => { default => {} }
      };

    my $method = delete $p{method};    # POST or GET
    my $params = delete $p{params};
    my $uri    = $self->uri;

    $uri->path_query( delete $p{command} );
    $uri->query_form( %p, %{$params} );

    my $req = HTTP::Request->new( $method => $uri );

    $self->debug( "Sending request: " . $req->as_string . "\n" );

    $req->authorization_basic( $self->{username}, $self->{password} );

    return $self->_parse_response( $self->{ua}->request($req) );
}

sub _parse_response {
    my $self = shift;
    my $resp = shift;

    croak "Failed to receive response from server"
      unless $resp;

    $self->debug( "Received response: " . $resp->content );

    if ( $resp->content =~ /You cannot execute that command/ ) {
        croak "Current user doesn't have correct authority level";
    }

    if ( $resp->content =~ /error=1/ ) {
        my $str   = decode_entities( $resp->content );
        my %error; 

        foreach ( split '&', $str ) {
            my ( $k, $v ) = split /\=/;
            $error{$k} = $v;
        }

        $self->error( \%error );

        croak "Response returned an error";
    }

    # for now it looks like error=0 means good action
    # but may need to check all calls for cases where it may be part of
    # returned data.
    if ( $resp->content =~ /error=0/ ) {
        return 1;
    }

    # return data containing goofy list[] format gets turned into list
    # - this appears to be related to function type
    if ( $resp->content =~ /list\[\]\=/ ) {

        # or $resp->as_string
        return map { s/list\[\]\=//; $_; } split( '&', $resp->content );
    }

    croak "Unknown return format: " . $resp->content;
}

#
# Admin functions
#
sub get_users {
    my $self = shift;
    my %p    = validate @_,
      { reseller => 0, domain => { default => $self->{domain} } };
    my $uri = $self->uri;

    $uri->path_query('CMD_API_SHOW_USERS');
    $uri->query_form(%p);

    $self->debug( "Sending request: " . $uri->as_string );

    my $req = HTTP::Request->new( GET => $uri );
    $req->authorization_basic( $self->{username}, $self->{password} );
    return $self->_parse_response( $self->{ua}->request($req) );
}

#
# User API Functions
#

sub get_domains {
    my $self = shift;
    return $self->_send_request( command => 'CMD_API_SHOW_DOMAINS', @_ );
}

sub get_subdomains {
    my $self = shift;
    return $self->_send_request( command => 'CMD_API_SUBDOMAINS', @_ );
}

sub create_subdomain {
    my $self = shift;
    my %p = validate @_, { domain => 0, subdomain => 1 };

    return $self->_send_request(
        command => 'CMD_API_SUBDOMAINS',
        params  => { %p, action => 'create' }
    );
}

sub delete_subdomain {
    my $self = shift;
    my %p    = validate @_,
      { domain => 0, subdomain => 1, contents => { default => 'yes' } };

    # ugh.... maybe support subdomain as list ref too?
    $p{select0} = delete $p{subdomain};

    # remove directory for it too
    return $self->_send_request(
        command => 'CMD_API_SUBDOMAINS',
        params  => { %p, action => 'delete' }
    );
}

sub get_databases {
    my $self = shift;

    return $self->_send_request( command => 'CMD_API_DATABASES', @_ );
}

sub create_database {
    my $self = shift;
    my %p = validate @_, { name => 1, user => 1, passwd => 1, passwd2 => 1 };

    return $self->_send_request(
        command => 'CMD_API_DATABASES',
        params  => { %p, action => 'create' }
    );
}

sub delete_database {
    my $self = shift;
    my %p = validate @_, { name => 1 };

    $p{'select0'} = delete $p{name};

    return $self->_send_request(
        command => 'CMD_API_DATABASES',
        params  => { %p, action => 'delete' }
    );
}

sub debug {
    my $self = shift;
    my $func = ( caller(1) )[3];
    my $msg  = shift || 'here';

    return unless $self->debug_level;

    printf STDERR "[%s] %s: %s\n", scalar(localtime), $func, $msg;
}

=head1 NAME

WWW::DirectAdmin::API - Access the DirectAdmin API with Perl

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This will provide access to the DirectAdmin API. The DirectAdmin API has
three levels Admin, Reseller and User functions. 

At this time, this API only implements the User level functions. I am open
to adding others but at time of initial creation I didn't need those.

Please read L<http://www.directadmin.com/api.html> for details.

    use WWW::DirectAdmin::API;

    my $da = WWW::DirectAdmin::API->new(
        host   => 'example.com',
        user   => 'username',
        pass   => 'password',
        domain => 'example-example.com'
    );

    my @domains = $da->get_domains;

    print "You have: ", join( ',', @domains ), "\n";

    my @subdomains = $da->get_subdomains;

    print "You have: ", join( ',', @subdomains ), "\n";

=head1 METHODS

=head2 new

Creates new WWW::DirectAdmin::API object. Parameters are 
passed in as name value pairs. e.g. host => 'example.com'

=over 4 

=item * host 

=item * port (optional, default: 2222)

=item * username 

=item * password 

=item * domain - user's require this for most user actions (e.g. example.com) 

=item * ua - L<LWP::UserAgent> object (optional)

=item * https - set to true to use HTTPS (default: false)

=item * debug - Output debug logging (optional)

=back


=head2 error

Returns hash with error keys from API calls. This is not always populated 
since maybe calls don't return error messages.

Usage:

   if ( defined $da->error->{details} ) {  
     print "Error details: ", $da->error->{details}, "\n";
   }

These are possible keys:

=over 4

=item * text

=item * details

=back 


=head2 uri

Returns URI object 

=head2 debug_level( $boolean )

Set debug level after object construction. 

At this time debugging can be enabled with '1' or disabled with '0'.

=head1 USER LEVEL API 

User level API commands.

All create or delete commands return true on success and throw exception in case of error.

You can check C<error> method for hash of error details. 

=head2 get_domains 

Returns list of domains

  my @domains = $da->get_domains;

=head2 get_subdomains 

Returns list of subdomains 

  my @subdomains = $da->get_subdomains;

=head2 create_subdomain( subdomain => 'name' )

Creates new subdomain

  if ( create_subdomain( subdomain => 'perlrocks' ) {
    print "Created subdomain\n";
  }   
  else {
    print "Booo! failed to create subdomain\n";
    print "Error: ", $da->error->{details}, "\n";
  }

Returns true on success, false on error

=head2 delete_subdomain( subdomain => 'name', contents => 'yes|no' )

Deletes subdomain and if contents are set to 'yes' (default) then directory underneath.

=head2 get_databases

Returns list of databases

=head2 create_database( %params )

Create new database with user

Parameters

=over 4

=item * name - database name

=item * user - database username (according to API doc will append current username to it)

=item * passwd - password

=item * passwd2 - confirm password

=back

=head2 delete_database( name => 'database name' )

Deletes database

B<Note>: Database names have current username automatically prefixed when created by DirectAdmin. In delete call I<name> must include username prefix. e.g. 'username_dbname' 


=head1 ADMIN LEVEL API

Very little of this is implemented today. More to come in later releases.

=head2 get_users 

Retrieves list of users

=head1 AUTHOR

Lee Carmichael, C<< <lcarmich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-directadmin-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-DirectAdmin-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::DirectAdmin::API


You can also look for information at:

=over 4

=item * DirectAdmin API L<http://www.directadmin.com/api.html>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-DirectAdmin-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-DirectAdmin-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-DirectAdmin-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-DirectAdmin-API/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Lee Carmichael.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of WWW::DirectAdmin::API
