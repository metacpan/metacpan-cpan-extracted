# CGI.pm
# by Bill Weinman -- Simple OO CGI
# Copyright (c) 1995-2008 The BearHeart Group, LLC
#
# See POD for History
#
package BW::CGI;
use strict;
use warnings;

use BW::Constants;
use IO::File;
use base qw( BW::Base );

our $VERSION = "0.1.7";

sub _init
{
    my $self = shift;
    return FAILURE unless $ENV{GATEWAY_INTERFACE};
    $self->SUPER::_init(@_);

    # set defaults
    $self->max_content_length( 1024 * 1024 ) unless $self->max_content_length;
    $self->content_type('text/html')         unless $self->content_type;
    $self->host( $ENV{HTTP_HOST} )           unless $self->host;

    $self->_set_query_string;

    return SUCCESS;
}

# _setter_getter entry points (see BW::Base)
sub content_type       { BW::Base::_setter_getter(@_); }
sub host               { BW::Base::_setter_getter(@_); }
sub query_string       { BW::Base::_setter_getter(@_); }
sub max_content_length { BW::Base::_setter_getter(@_); }

sub vars
{
    my $self = shift;
    return $self->{vars};
}

sub q_names { qnames(@_) }
sub qnames
{
    my $self = shift;
    return $self->{q_names};
}

# smart value getter
sub qv
{
    my ( $self, $name, $index ) = @_;
    return VOID unless $name and $self->{vars}{$name};

    if ( ref( $self->{vars}{$name} ) ) {
        if ( defined $index ) {
            $self->{q_index}{$name} = $index;
        } else {
            $self->{q_index}{$name} = 0 unless defined $self->{q_index}{$name};
            return $self->{vars}{$name}[ $self->{q_index}{$name}++ ];
        }
    } else {
        return $self->{vars}{$name};
    }
}

# provide a link back for use in form action attribute
sub linkback {
    my $l = $ENV{REQUEST_URI} || $ENV{SCRIPT_NAME} || FALSE;
    $l =~ s/\?.*// if $l;  # lose any query part
    return $l
}

sub status { set_status(@_) } # obsolescent alias
sub set_status
{
    my ( $self, $status, $message ) = @_;
    $self->{status} = "$status $message";
}

sub set_header
{
    my ( $self, $k, $v ) = @_;
    push( @{ $self->{headers} }, { k => $k, v => $v } );
}

sub set_cookie
{
    my $sn = 'set_cookie';
    my ( $self, $params, @list ) = @_;

    if ( !ref($params) ) {    # make hashref from list
        unshift( @list, $params );
        $params = {@list};
    }

    my $k = $params->{name} or return $self->_error("$sn: no name");
    my $v = $params->{value} || '';
    my $cs = "$k=$v";

    $cs .= "; expires=" . $self->header_date( $params->{expires} ) if defined $params->{expires};
    $cs .= "; path=" . $params->{path}                             if $params->{path};
    $cs .= "; domain=" . $params->{domain}                         if $params->{domain};
    $cs .= "; secure"                                              if defined $params->{secure};
    $cs .= "; httponly"                                            if defined $params->{httponly};

    $self->set_header( 'Set-Cookie', $cs );
    return SUCCESS;
}

sub get_cookie
{
    my ( $self, $cookie_name ) = @_;
    $self->_get_cookies or return VOID;
    return $self->{cookies}{$cookie_name};
}

sub _get_cookies
{
    my $self = shift;

    unless ( $self->{get_cookies_flag} ) {
        if ( $ENV{HTTP_COOKIE} ) {
            my @cookies = split( /;\s*/, $ENV{HTTP_COOKIE} );
            foreach my $c (@cookies) {
                my ( $n, $v ) = split( /=/, $c );
                $self->{cookies}{$n} = $v;
            }
        }
        $self->{get_cookies_flag} = TRUE;
    }
    return $self->{cookies} || VOID;
}

sub clear_cookie
{
    my ( $self, $params, @list ) = @_;

    if ( !ref($params) ) {    # make hashref from list
        unshift( @list, $params );
        $params = {@list};
    }

    $params->{expires} = 1;    # a date in the past: 1970-01-01 00:00:01
    return $self->set_cookie($params);
}

# print is a necessary alias so that this can be called from Template::process
sub print { p(@_) }
sub p
{
    my ( $self, $string ) = @_;
    $self->p_headers;
    print $string || '';
}

sub redirect
{
    my ( $self, $dest ) = @_;

    $self->set_status( 302, 'Yonder' );
    $self->set_header( 'Cache-control', 'no-cache' );
    $self->set_header( 'Location',      $dest );
    $self->p_headers;
}

sub p_headers
{
    my $self = shift;
    return if $self->{header_flag};

    STDOUT->autoflush(1);
    if ( $self->{headers} ) {
        foreach my $h ( @{ $self->{headers} } ) {
            print $h->{k} . ': ' . $h->{v} . CRLF;
        }
    }
    print "Status: " . $self->{status} . CRLF if $self->{status};
    print "Content-Type: " . $self->content_type . CRLF;
    print CRLF;
    $self->{header_flag} = TRUE;
}

# make a header-ish date from a time value
sub header_date
{
    my ( $self, $t ) = @_;
    $t = time unless defined $t;

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime($t);
    my @day   = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $tstr  = sprintf( "%s %02d-%s-%04d %02d:%02d:%02d GMT", $day[$wday], $mday, $month[$mon], $year + 1900, $hour, $min, $sec );
    return $tstr;
}

# allows for more than one value for each key
sub _set_query
{
    my ( $self, $n, $v ) = @_;
    return unless $n;

    $n = $self->url_decode($n);
    $v = $self->url_decode($v);

    push( @{ $self->{q_names} }, $n );

    if ( defined( $self->{vars}{$n} ) and $v ) {
        if ( ref( $self->{vars}{$n} ) ) {
            push( @{ $self->{vars}{$n} }, $v );
        } else {
            my $qn = [ $self->{vars}{$n}, $v ];
            $self->{vars}{$n} = $qn;
        }
    } else {
        $self->{vars}{$n} = $v;
    }

}

sub _set_query_string
{
    my $sn   = '_set_query_string';
    my $self = shift;

    $self->{q_names} = [] unless $self->{q_names};

    if ( uc( $ENV{REQUEST_METHOD} ) eq 'GET' ) {
        $self->query_string( $ENV{QUERY_STRING} );
    } elsif ( uc( $ENV{REQUEST_METHOD} ) eq 'POST' ) {
        my $buf;
        my $content_length = $ENV{'CONTENT_LENGTH'} || 0;
        return FAILURE if $content_length > $self->max_content_length;
        STDIN->read( $buf, $content_length );
        $self->query_string($buf);
    }

    my $qs = $self->query_string or return SUCCESS;
    foreach my $qnv ( split( /[&;]/, $qs ) ) {
        $self->_set_query( split( /=/, $qnv ) );
    }

    return SUCCESS;
}

sub html_encode
{
    my ( $self, $s ) = @_;
    return $s unless $s;
    $s =~ s/([^a-z0-9_\-\.,?:;\(\)\@! ])/sprintf("&#%d;", ord($1))/segi;
    return $s;
}

sub url_encode
{
    my ( $self, $s ) = @_;
    return $s unless $s;
    $s =~ s/([^a-z0-9_ ])/sprintf("%%%02X", ord($1))/segi;
    $s =~ s/ /+/g;
    return $s;
}

sub url_decode
{
    my ( $self, $s ) = @_;
    return $s unless $s;
    $s =~ s/\+/ /g;  # + is space
    $s =~ s/\%([a-f0-9]{2})/pack('C', hex($1))/segi;
    return $s;
}

1;

=head1 NAME

BW::CGI - Simple OO CGI

=head1 SYNOPSIS

  use BW::CGI;
  my $o = BW::CGI->new;

=head1 METHODS

=over 4

=item B<new>( [ property => value, ... ] )

Constructs a new BW::CGI object. 

Returns a blessed BW::CGI object reference.
Returns undef (VOID) if the object cannot be created. 

Properties can be set by passing their values in a hash or hashref 
like this: 

  my $o = BW::CGI->new ( content_type => 'text/plain' );

Or by hashref, like this:

  my $properties = { content_type => 'text/plain' };
  my $o = BW::CGI->new ( $properties );

=item B<vars>

Returns the parsed results of the query string as a hashref, or undef. 

=item B<qnames>

Returns a list of query variable names. (B<q_names> is an alias for qnames.)

=item B<qv>( name [, index] )

Returns the value of the query variable I<name>. If there is more than one variable with the same name
a list will be returned, or if I<index> is provided, the value in the specified list position. I<index> is 
zero-based. 

=item B<linkback>

Returns a URI for use as a link back in the form action attribute. 

=item B<set_status>( code [, message] )

Sets the HTTP "Status" code and, optionally, the associated message. 

=item B<set_cookie>( params )

Sets a cookie. Must be called before headers are sent (see I<set_header>). I<params> is a hashref 
with the cookie parameters: I<name>, I<value>, I<expires>, I<path>, I<domain>, I<secure>, I<httponly>. 

=item B<get_cookie>( name )

Returns the value of the named cookie. 

=item B<clear_cookie>( params )

Clears the specified cookie from the browser by setting an empty cookie. The same parameter rules as in set_cookie apply. 

=item B<p>( string ) B<print>( string )

Prints I<string> to the client. Sends the headers first, if they haven't already been sent. 

=item B<redirect>( destination )

Sends an HTTP redirect (status code 302) to the client with Location set to I<destination>. 

=item B<set_header>( key, value )

Sets header I<key> to I<value>. Must be called before the first call to I<p> (I<print>) as the headers 
are sent to the client at that time. 

=item B<p_headers>

Sends the headers that have been set with set_header. 

=item B<header_date>( time )

Returns a header-ish date from a unix-epoch time value. 

=item B<html_encode>( string )

Returns an encoded copy of I<string> with all non-matching /[^a-z0-9_\-\.,?:;\(\)\@! ]/ characters 
replaced with numeric HTML entities. 

=item B<url_encode>( string )

Returns an encoded copy of I<string> with all non-matching /[^a-z0-9_]/ characters 
replaced with URL-encoded hexadecimal values (e.g., %20 for space). 

=item B<url_decode>( string )

Returns a URL-decoded copy of I<string>. 

=item B<error>

Returns and clears the object error message.

=back

=head1 PROPERTIES

Properties can be set or retrieved by using their name as a method, e.g.:

  $o->content_type( 'text/plain' );
  my $ct = $o->content_type;

The available properties for this method are:

=over 4

=item B<content_type>

The C<Content-type:> header that gets sent to the client. 

=item B<host>

Value of HTTP_HOST environment variable. Used for creating links back to self, 
e.g., in the "action" attribute of form. 

=item B<max_content_length>

The maximum content length allowed from POST method queries. Defaults to 1MB (1,0485,776). 

=back

=head1 AUTHOR

Written by Bill Weinman

=head1 COPYRIGHT

Copyright (c) 1995-2008 The BearHeart Group, LLC

=head1 HISTORY

  2009-11-04 bw     -- added linkback method
  2008-03-26 bw     -- updated and documented
  2007-10-20 bw     -- initial release.

=cut

