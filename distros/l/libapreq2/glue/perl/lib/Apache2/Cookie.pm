package Apache2::Cookie;
use APR::Table;
use APR::Pool;
use APR::Request::Cookie;
use APR::Request::Apache2;
use APR::Request qw/encode decode/;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use overload '""' => sub { shift->as_string() }, fallback => 1;

push our @ISA, "APR::Request::Cookie";
our $VERSION = "2.15";

sub new {
    my ($class, $r, %attrs) = @_;
    my ($name)  = grep {defined} delete $attrs{name} , delete $attrs{-name};
    my ($value) = grep {defined} delete $attrs{value}, delete $attrs{-value};
    return unless defined $name and defined $value;

    my $cookie = $class->make($r->pool, $name, $class->freeze($value));
    while(my ($k, $v) = each %attrs) {
        $k =~ s/^-//;
        $cookie->$k($v);
    }
    return $cookie;
}

sub fetch {
    my $class = shift;
    my $req = shift;
    unless (defined $req) {
        my $usage = 'Usage: Apache2::Cookie->fetch($r): missing argument $r';
        $req = eval {Apache2::RequestUtil->request} or die <<EOD;
$usage: attempt to fetch global Apache2::RequestUtil->request failed: $@.
EOD
    }
    $req = APR::Request::Apache2->handle($req)
        unless $req->isa("APR::Request");

    my $jar = $req->jar or return;
    $jar->cookie_class(__PACKAGE__);
    return $jar->get(shift) if @_;
    return wantarray ? %$jar : $jar;
}

sub set_attr {
    my ($cookie, %attrs) = @_;
    while (my ($k, $v) = each %attrs) {
        $k =~ s/^-//;
        $cookie->$k($v);
    }
}

sub freeze {
    my ($class, $value) = @_;
    die 'Usage: Apache2::Cookie->freeze($value)' unless @_ == 2;

    if (not ref $value) {
        return encode($value);
    }
    elsif (UNIVERSAL::isa($value, "ARRAY")) {
        return join '&', map encode($_), @$value;
    }
    elsif (UNIVERSAL::isa($value, "HASH")) {
        return join '&', map encode($_), %$value;
    }

    die "Can't freeze reference: $value";
}

sub thaw {
    my $c = shift;
    my @rv = split /&/, @_ ? shift : $c->SUPER::value;
    return wantarray ? map decode($_), @rv : decode($rv[0]);
}

sub value {
    return shift->thaw;
}

sub bake {
    my ($c, $r) = @_;
    $r->err_headers_out->add("Set-Cookie", $c->as_string);
}

sub bake2 {
    my ($c, $r) = @_;
    die "Can't bake2 a Netscape cookie: $c" unless $c->version > 0;
    $r->err_headers_out->add("Set-Cookie2", $c->as_string);
}


package Apache2::Cookie::Jar;
use APR::Request::Apache2;
push our @ISA, qw/APR::Request::Apache2/;
sub cookies {
    return Apache2::Cookie->fetch(@_) if @_ == 2;
    my $cookies = Apache2::Cookie->fetch(@_);
    return wantarray ? keys %$cookies : $cookies;
}
*Apache2::Cookie::Jar::status = *APR::Request::jar_status;

sub new {
    my $class = shift;
    my $jar = $class->APR::Request::Apache2::handle(shift);
    my %attrs = @_;
    while (my ($k, $v) = each %attrs) {
        $k =~ s/^-//;
        my $method = lc $k;
        $jar->$method($v);
    }
    return $jar;
}

1;

__END__

=head1 NAME

Apache2::Cookie, Apache2::Cookie::Jar - HTTP Cookies Class

=for testing
    use Apache2::Cookie;
    use APR::Pool;
    # use $r instead of $p here, so doc examples reflect mp2 env, not CGI/test env
    $r = APR::Pool->new;
    $j = Apache2::Cookie::Jar->new($r);
    $j->cookies->{foo} = Apache2::Cookie->new($r, name => "foo", value => "1");
    $j->cookies->add( Apache2::Cookie->new($r, name => "bar", value => "2") );




=head1 SYNOPSIS


    use Apache2::Cookie;

    $j = Apache2::Cookie::Jar->new($r);
    $c_in = $j->cookies("foo");         # get cookie from request headers

    $c_out = Apache2::Cookie->new($r,
                                  -name  => "mycookie",
                                  -value => $c_in->name );

    $c_out->path("/bar");               # set path to "/bar"
    $c_out->bake($r);                   # send cookie in response headers




=head1 DESCRIPTION


The Apache2::Cookie module is based on the original 1.X versions, which mimic
the CGI::Cookie API.  The current version of this module includes several packages
and methods which are patterned after Apache2::Request, yet remain largely
backwards-compatible with the original 1.X API (see the L<PORTING from 1.X> section
below for known issues).

This manpage documents the Apache2::Cookie and Apache2::Cookie::Jar packages.




=head1 Apache2::Cookie::Jar

This class collects Apache2::Cookie objects into a lookup table.  It plays
the same role for accessing the incoming cookies as Apache2::Request does for
accessing the incoming params and file uploads.




=head2 new

    Apache2::Cookie::Jar->new($env)

Class method that retrieves the parsed cookie jar from the current
environment.

=head2 cookies

    $jar->cookies()
    $jar->cookies($key)

Retrieve cookies named $key with from the jar object.  In scalar
context the first such cookie is returned, and in list context the
full list of such cookies are returned.

If the $key argument is omitted, C<< scalar $jar->cookies() >> will
return an APR::Request::Cookie::Table object containing all the cookies in
the jar.  Modifications to the this object will affect the jar's
internal I<cookies> table in C<apreq_jar_t>, so their impact will
be noticed by all libapreq2 applications during this request.

In list context C<< $jar->cookies() >> returns the list of names
for all the cookies in the jar.  The order corresponds to the
order in which the cookies appeared in the incoming "Cookie" header.

This method will throw an C<< APR::Request::Error >> object into $@ if
the returned value(s) could be unreliable.  In particular, note that
C<< scalar $jar->cookies("foo") >> will not croak if it can locate
the a "foo" cookie within the jar's parsed cookie table, even if the
cookie parser has failed (the cookies are parsed in the same order
as they appeared in the "Cookie" header). In all other circumstances
C<cookies> will croak if the parser failed to successfully parse the
"Cookie" header.

    $c = Apache2::Cookie->new($r, name => "foo", value => 3);
    $j->cookies->add($c);

    $cookie = $j->cookies("foo");  # first foo cookie
    @cookies = $j->cookies("foo"); # all foo cookies
    @names = $j->cookies();        # all cookie names




=head2 status

    $jar->status()

Get the I<APR> status code of the cookie parser:
APR_SUCCESS on success, error otherwise.




=head1 Apache2::Cookie




=head2 new

    Apache2::Cookie->new($env, %args)

Just like CGI::Cookie::new, but requires an additional environment argument:

    $cookie = Apache2::Cookie->new($r,
                             -name    =>  'foo',
                             -value   =>  'bar',
                             -expires =>  '+3M',
                             -domain  =>  '.capricorn.com',
                             -path    =>  '/cgi-bin/database',
                             -secure  =>  1
                            );

The C<-value> argument may be either an arrayref, a hashref, or
a string.  C<Apache2::Cookie::freeze> encodes this argument into the
cookie's raw value.




=head2 freeze

    Apache2::Cookie->freeze($value)

Helper function (for C<new>) that serializes a new cookie's value in a
manner compatible with CGI::Cookie (and Apache2::Cookie 1.X).  This class
method accepts an arrayref, hashref, or normal perl string in $value.

    $value = Apache2::Cookie->freeze(["2+2", "=4"]);




=head2 thaw

    Apache2::Cookie->thaw($value)
    $cookie->thaw()


This is the helper method (for C<value>) responsible for decoding the
raw value of a cookie.  An optional argument $value may be used in
place of the cookie's raw value.  This method can also decode cookie
values created using CGI::Cookie or Apache2::Cookie 1.X.

    print $cookie->thaw;                    # prints "bar"
    @values = Apache2::Cookie->thaw($value); # ( "2+2", "=4" )




=head2 as_string

    $cookie->as_string()

Format the cookie object as a string.  The quote-operator for Apache2::Cookie
is overloaded to run this method whenever a cookie appears in quotes.

    ok "$cookie" eq $cookie->as_string;




=head2 name

    $cookie->name()

Get the name of the cookie.




=head2 value

    $cookie->value()

Get the (unswizzled) value of the cookie:

    my $value = $cookie->value;
    my @values = $cookie->value;

Note: if the cookie's value was created using a  C<freeze> method,
one way to reconstitute the object is by subclassing
Apache2::Cookie with a package that provides the associated C<thaw> sub:

    {
        package My::COOKIE;
        @ISA = 'Apache2::Cookie';
        sub thaw { my $val = shift->raw_value; $val =~ tr/a-z/A-Z/; $val }
    }

    bless $cookie, "My::COOKIE";

    ok $cookie->value eq "BAR";




=head2 raw_value

    $cookie->raw_value()

Gets the raw (opaque) value string as it appears in the incoming
"Cookie" header.

    ok $cookie->raw_value eq "bar";




=head2 bake

    $cookie->bake($r)

Adds a I<Set-Cookie> header to the outgoing headers table.




=head2 bake2

    $cookie->bake2($r)

Adds a I<Set-Cookie2> header to the outgoing headers table.




=head2 domain

    $cookie->domain()
    $cookie->domain($set)

Get or set the domain for the cookie:

    $domain = $cookie->domain;
    $cookie->domain(".cp.net");




=head2 path

    $cookie->path()
    $cookie->path($set)

Get or set the path for the cookie:

    $path = $cookie->path;
    $cookie->path("/");




=head2 version

    $cookie->version()
    $cookie->version($set)

Get or set the cookie version for this cookie.
Netscape spec cookies have version = 0;
RFC-compliant cookies have version = 1.

    ok $cookie->version == 0;
    $cookie->version(1);
    ok $cookie->version == 1;




=head2 expires

    $cookie->expires()
    $cookie->expires($set)

Get or set the future expire time for the cookie.  When
assigning, the new value ($set) should match /^\+?(\d+)([YMDhms]?)$/
$2 qualifies the number in $1 as representing "Y"ears, "M"onths,
"D"ays, "h"ours, "m"inutes, or "s"econds (if the qualifier is
omitted, the number is interpreted as representing seconds).
As a special case, $set = "now" is equivalent to $set = "0".

    my $expires = $cookie->expires;
    $cookie->expires("+3h"); # cookie is set to expire in 3 hours




=head2 secure

    $cookie->secure()
    $cookie->secure($set)

Get or set the secure flag for the cookie:

    $cookie->secure(1);
    $is_secure = $cookie->secure;
    $cookie->secure(0);




=head2 httponly

    $cookie->httponly()
    $cookie->httponly($set)

Get or set the HttpOnly flag for the cookie:

    $cookie->httponly(1);
    $is_HttpOnly = $cookie->httponly;
    $cookie->httponly(0);




=head2 comment

    $cookie->comment()
    $cookie->comment($set)

Get or set the comment field of an RFC (Version > 0) cookie.

    $cookie->comment("Never eat yellow snow");
    print $cookie->comment;




=head2 commentURL

    $cookie->commentURL()
    $cookie->commentURL($set)

Get or set the commentURL field of an RFC (Version > 0) cookie.

    $cookie->commentURL("http://localhost/cookie.policy");
    print $cookie->commentURL;




=head2 fetch

    Apache2::Cookie->fetch($r)

Fetch and parse the incoming I<Cookie> header:

    my $cookies = Apache2::Cookie->fetch($r); # APR::Request::Cookie::Table ref

    It should be noted, that with perl 5.8+ Iterator magic, table is able
    to handle multiple cookies of the same name.

    my %cookies = Apache2::Cookie->fetch($r);





=head1 PORTING from 1.X

Changes to the 1.X API:

=over 5

=item * C<Apache2::Cookie::fetch> now expects an C<$r> object as (second)
        argument, although this isn't necessary in mod_perl 2 if
        C<Apache2::RequestUtil> is loaded and 'PerlOptions +GlobalRequest'
        is in effect.

=item * C<Apache2::Cookie::parse> is gone.

=item * C<Apache2::Cookie::new> no longer encodes the supplied cookie name.

=item * C<Apache2::Cookie::new()> returns undef if -value is not specified
        or -value => undef.

=item * C<name()> and C<value()> no longer accept a "set" argument. In other words,
        neither a cookie's name, nor its value, may be modified.  A new cookie
        should be made instead.

=back




=head1 SEE ALSO

L<Apache2::Request>, L<APR::Request::Cookie>,
L<APR::Request::Error>, CGI::Cookie(3)




=head1 COPYRIGHT

  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

