use strict;
use warnings;
use Test::More;
use WebDyne::CGI::Simple;

#  Simulate ambient CGI values belonging to a different request.
#
local $ENV{'WEBDYNE_CONF'}='.';
local $ENV{'HTTP_COOKIE'}='visitor=ambient; ambient_only=1';
local $ENV{'COOKIE'}='fallback_only=1';
my $header='visitor=Alice%20Smith; zero=0; choices=red&white';
my $request_or=CookieRequest->new($header);
my $cgi_or=WebDyne::CGI::Simple->new($request_or);

is(scalar($cgi_or->cookie('visitor')), 'Alice Smith', 'cookie comes from request header');
is(scalar($cgi_or->cookie('zero')), '0', 'zero cookie value survives');
is_deeply([$cgi_or->cookie('choices')], [qw(red white)], 'list context is preserved');
is_deeply([sort $cgi_or->cookie()], [qw(choices visitor zero)], 'cookie names come from the request');
is($cgi_or->raw_cookie(), $header, 'raw_cookie returns original request header');
is($cgi_or->raw_cookie('visitor'), 'Alice%20Smith', 'named raw cookie remains encoded');
is($ENV{'HTTP_COOKIE'}, 'visitor=ambient; ambient_only=1', 'HTTP_COOKIE is restored');
is($ENV{'COOKIE'}, 'fallback_only=1', 'COOKIE fallback is restored');

my $other_or=WebDyne::CGI::Simple->new(CookieRequest->new('visitor=Bob'));
is(scalar($other_or->cookie('visitor')), 'Bob', 'second request has its own cookie');
is(scalar($cgi_or->cookie('visitor')), 'Alice Smith', 'first request retains its cookie');

my $empty_or=WebDyne::CGI::Simple->new(CookieRequest->new(undef));
is_deeply([$empty_or->cookie()], [], 'missing header does not inherit ambient cookies');
is($empty_or->raw_cookie(), '', 'missing raw header does not inherit environment');

my $cookie_or=$empty_or->cookie(-name => 'new', -value => 'value', -secure => 1, -httponly => 1);
like("$cookie_or", qr/^new=value/, 'outbound cookie creation is unchanged');
like("$cookie_or", qr/;\s*secure\b/i, 'Secure flag is unchanged');
like("$cookie_or", qr/;\s*httponly\b/i, 'HttpOnly flag is unchanged');

done_testing();

package CookieRequest;

sub new {
    my ($class, $header)=@_;
    return bless({header => $header}, $class);
}

sub headers_in {
    my ($self, $name)=@_;
    return lc($name) eq 'cookie' ? $self->{'header'} : undef;
}

sub args { return ''; }
sub method { return 'GET'; }
sub content_length { return 0; }
