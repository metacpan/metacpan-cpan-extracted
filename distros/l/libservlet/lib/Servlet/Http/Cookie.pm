# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::Cookie;

use fields qw(name value comment domain maxage path secure version);
use strict;
use warnings;

use Servlet::Util::Exception ();

my $Fieldpat = '(comment|discard|domain|expires|max\-age|path|secure|version)';

sub new {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    unless ($name) {
        my $msg = 'cookie name needed';
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    if ($name !~ /^[[:alpha:]]+$/ ||
        $name =~ /,;\s/ ||
        $name =~ /^\$/ ||
        $name =~ /$Fieldpat/i) {
        my $msg = "invalid cookie name [$name]";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self = fields::new($self) unless ref $self;

    $self->{name} = $name;
    $self->{value} = $value;
    $self->{comment} = undef;
    $self->{domain} = undef;
    $self->{maxage} = -1;
    $self->{path} = undef;
    $self->{secure} = undef;
    $self->{version} = 0;

    return $self;
}

sub getComment {
    my $self = shift;

    return $self->{comment};
}

sub getDomain {
    my $self = shift;

    return $self->{domain};
}

sub getMaxAge {
    my $self = shift;

    return $self->{maxage};
}

sub getName {
    my $self = shift;

    return $self->{name};
}

sub getPath {
    my $self = shift;

    return $self->{path};
}

sub getSecure {
    my $self = shift;

    return $self->{secure};
}

sub getValue {
    my $self = shift;

    return $self->{value};
}

sub getVersion {
    my $self = shift;

    return $self->{version};
}

sub setComment {
    my $self = shift;
    my $purpose = shift;

    $self->{comment} = $purpose;

    return 1;
}

sub setDomain {
    my $self = shift;
    my $pattern = shift;

    $self->{domain} = lc($pattern); # IE allegedly needs this

    return 1;
}

sub setMaxAge {
    my $self = shift;
    my $expiry = shift;

    $self->{maxage} = $expiry;

    return 1;
}

sub setPath {
    my $self = shift;
    my $uri = shift;

    $self->{path} = $uri;

    return 1;
}

sub setSecure {
    my $self = shift;
    my $flag = shift;

    $self->{secure} = $flag;

    return 1;
}

sub setValue {
    my $self = shift;
    my $newvalue = shift;

    $self->{value} = $newvalue;

    return 1;
}

sub setVersion {
    my $self = shift;
    my $v = shift;

    $self->{version} = $v;

    return 1;
}

1;
__END__

=pod

=head1 NAME

Servlet::Http::Cookie - HTTP cookie class

=head1 SYNOPSIS

  my $cookie = Servlet::Http::Cookie->new($name, $value);

  my $clone = $cookie->clone();

  my $comment = $cookie->getComment();
  $cookie->setComment($comment);

  my $domain = $cookie->getDomain();
  $cookie->setDomain($domain);

  my $seconds = $cookie->getMaxAge();
  $cookie->setMaxAge($seconds);

  my $name = $cookie->getName();

  my $path = $cookie->getPath();
  $cookie->setPath($path);

  my $bool = $cookie->getSecure();
  $cookie->setSecure($bool);

  my $value = $cookie->getValue();
  $cookie->setValue($value);

  my $version = $cookie->getVersion();
  $cookie->setVersion();

=head1 DESCRIPTION

This class represents a cookie, a small amount of information sent by
a servlet to a Web browser, saved by the browser, and later sent back
to the server. A cookie's value can uniquely identify a client, so
cookies are commonly used for session management.

A cookie has a name, a single value, and optional attributes such as a
comment, path and domain qualifiers, a maximum age, and a version
number. Some Web browsers have bugs in how they handle the optional
attributes, so use them sparingly to improve the interoperability of
your servlets.

The servlet sends cookies to the browser by using the C<addCookie()>
method, which adds fields to the HTTP response headers to send cookies
to the browser, one at a time. The browser is expected to support 20
cookies for each Web server, 300 cookies total, and may limit cookie
size to 4 KB each.

The browser returns cookies to the servlet by adding fields to HTTP
request headers. Cookies can be retrieved from a request by using the
C<getCookies()> method. Serveral cookies might have the same name but
different path attributes.

Cookies affect the caching of the Web pages that use them. HTTP 1.0
does not cache pages that use cookies created with this class. This
class does not support the cache control defined with HTTP 1.1.

This class supports both the Version 0 (by Netscape) and Version 1 (by
RFC 2109) cookie specifications. By default, cookies are created using
Version 0 to ensure the best interoperability.

=head1 CONSTRUCTOR

=over

=item new($name, $value)

Constructs an instance with the specified name and value.

The name must conform to RFC 2109. That means it can contain only
ASCII alphanumeric characters and cannot contain commas, semicolons,
or white space or begin with a $ character. The cookie's name cannot
be changed after creation.

The value can be anything the server chooses to send. Its value is
probably of interest only to the server. The cookie's value can be c
hanged after creation with C<setValue()>.

By deafult, cookies are created according to the Netscape cookie
specification. The version can be changed with C<setVersion()>.

B<Parameters:>

=over

=item I<$name>

the name of the cookie

=item I<$value>

the value of the cookie

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the cookie name contains illegal characters or is one of the tokens
reserved for use by the cookie specification

=back

=back

=head1 METHODS

=over

=item clone()

Returns a copy of the object.

=item getComment()

Returns the comment describing the purpose of the cookie, or I<undef>
if the cookie has no comment.

=item getDomain()

Returns the domain name for the cookie, in the form specified by RFC
2109.

=item getMaxAge()

Returns the maximum age of the cookie, specified in seconds. The
default value is -1, indicating that the cookie will persist until
client shutdown.

=item getName()

Returns the name of the cookie. The name cannot be changed after
creation.

=item getPath()

Returns the path on the server to which the browser returns the
cookie. The cookie is visible to all subpaths on the server.

=item getSecure()

Returns true if the cookie can only be sent over a secure channel., or
false if the cookie can be sent over any channel.

=item getValue()

Returns the value of the cookie.

=item getVersion()

Returns the version of the cookie specification complied with by the
cookie. Version 1 complies with RFC 2109, and version 0 complies with
the original cookie specification drafted by Netscape. Cookies
provided by a client use and identify the client's cookie version.

=item setComment($comment)

Specifies a comment that describes the cookie's purpose. Comments are
not supported by Version 0 cookies.

B<Parameters:>

=over

=item I<$comment>

the comment

=back

=item setDomain($domain)

Specifies the domain within which this cookie should be presented.

The form of the domain name is specified by RFC 2109. A domain name
begins with a dot (I<.foo.com>), which means that the cookie is
visible to servers in that domain only (I<www.foo.com>, but not
I<www.bar.com>). By default, cookies are only returned to the server
that sent them.

B<Parameters:>

=over

=item I<$domain>

the domain name within which the cookie is visible

=back

=item setMaxAge($expiry)

Sets the maximum age of the cookie in seconds.

A positive value indicates that the cookie will expire after that many
seconds have passed. Note that the value is the maximum age when the
cookie will expire, not the cookie's current age.

A negative value means that the cookie is not stored persistently and
will be deleted when the client exits. A zero value causes the cookie
to be deleted.

B<Parameters:>

=over

=item I<$expiry>

the maximum age of the cookie in seconds

=back

=item setPath($uri)

Specifies a server namespace for which the cookie is visible.

The cookie is visible to all the resources at or beneath the URI
namespace specified by the path. A cookie's path must include the
servlet that set the cookie in order to make the cookie visible to
that servlet.

B<Parameters:>

=over

=item I<$uri>

the uri path denoting the visible namespace for the cookie

=back

=item setSecure($flag)

Indicates to the if the cookie must be sent only over a secure channel
or if it can be sent over any channel. The default is false.

B<Parameters:>

=over

=item I<$flag>

a flag specifying the security requirement for cookie transmission

=back

=item setValue($value)

Assigns a new value to a cookie after the cookie is created. If a
binary value is used, Base64 encoding the value is suggested.

With version 0 cookies, values should not contain white space,
brackets, parentheses, equals signs, commas, double quotes, slashes,
question marks, at signs, colons and semicolons. The behavior of
clients in response to empty values is undefined.

B<Parameters:>

=over

=item I<$value>

the new value of the cookie

=back

=item setVersion($number)

Sets the version of the cookie specification with which the cookie
complies. Version 0 complies with the original Netscape cookie
specification, Version 1 complies with RFC 2109. The default is 0.

B<Parameters:>

=over

=item I<$number>

the version number of the supported cookie specification

=back

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
