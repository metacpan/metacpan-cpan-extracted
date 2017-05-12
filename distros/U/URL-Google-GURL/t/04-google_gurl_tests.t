use strict;
use warnings;
use utf8;
use Carp;

use Test::More tests => 244;

use_ok('URL::Google::GURL');

note('ALL of the tests in this file were adapted from the GURL unit tests that are part \
of the core google url library source distribution');

note(q(URLs with unknown schemes should be treated as path URLs, even when they have things like '://'));
check_possibly_invalid_spec(url => 'something:///HOSTNAME.com/', expected => 'something:///HOSTNAME.com/');
             
note('In the reverse, known schemes should always trigger standard URL handling');
check_possibly_invalid_spec(url => 'http:HOSTNAME.com', expected => 'http://hostname.com/');
check_possibly_invalid_spec(url => 'http:/HOSTNAME.com', expected => 'http://hostname.com/');
check_possibly_invalid_spec(url => 'http://HOSTNAME.com', expected => 'http://hostname.com/');
check_possibly_invalid_spec(url => 'http:///HOSTNAME.com', expected => 'http://hostname.com/');

note('Test the basic creation and querying of components in a GURL. We assume \
the parser is already tested and works, so we are mostly interested if the \
object does the right thing with the results.');
my $u1 = new_ok( 'URL::Google::GURL' => ['http://user:pass@google.com:99/foo;bar?q=a#ref'] );
ok($u1->is_valid());
ok($u1->scheme_is('http'));
ok(! $u1->scheme_is_file());
is($u1->scheme(), 'http');
is($u1->username(), 'user');
is($u1->password(), 'pass');
is($u1->host(), 'google.com');
is($u1->port(), '99');
ok($u1->int_port() == 99);
is($u1->path(), '/foo;bar');
is($u1->query(), 'q=a');
is($u1->ref(), 'ref');

note('Test empty gurl object creation');
my $empty = URL::Google::GURL::EmptyGURL();
ok(! $empty->is_valid());
is($empty->spec(), '');
is($empty->scheme(), '');
is($empty->username(), '');
is($empty->password(), '');
is($empty->host(), '');
is($empty->port(), '');
ok($empty->int_port() == URL::Google::GURL::PORT_UNSPECIFIED());
is($empty->path(), '');
is($empty->query(), '');
is($empty->ref(), '');

note('Test cloning (copy constructor)');
my $u2 = URL::Google::GURL->clone($u1);
ok($u2->is_valid());
ok($u2->scheme_is('http'));
ok(! $u2->scheme_is_file());
is($u2->scheme(), 'http');
is($u2->username(), 'user');
is($u2->password(), 'pass');
is($u2->host(), 'google.com');
is($u2->port(), '99');
ok($u2->int_port() == 99);
is($u2->path(), '/foo;bar');
is($u2->query(), 'q=a');
is($u2->ref(), 'ref');

note('Cloning of an invalid URL should be invalid');
my $invalid = new_ok( 'URL::Google::GURL' => [''] );
my $invalid2 = URL::Google::GURL->clone($invalid);
ok(! $invalid2->is_valid());
is($invalid2->spec(), '');
is($invalid2->scheme(), '');
is($invalid2->username(), '');
is($invalid2->password(), '');
is($invalid2->host(), '');
is($invalid2->port(), '');
ok($invalid2->int_port() == URL::Google::GURL::PORT_UNSPECIFIED());
is($invalid2->path(), '');
is($invalid2->query(), '');
is($invalid2->ref(), '');

note('Given an invalid URL, we should still get most of the components.');
my $u3 = new_ok( 'URL::Google::GURL' => ['http:google.com:foo'] );
ok(! $u3->is_valid());
is($u3->possibly_invalid_spec(), 'http://google.com:foo/');
is($u3->scheme(), 'http');
is($u3->username(), '');
is($u3->password(), '');
is($u3->host(), 'google.com');
is($u3->port(), 'foo');
ok($u3->int_port() == URL::Google::GURL::PORT_INVALID());
is($u3->path(), '/');
is($u3->query(), '');
is($u3->ref(), '');

note('The tricky cases for relative URL resolving are tested in the \
canonicalizer unit test. Here, we just test that the GURL integration \
works properly.');
ok( check_spec(
      url => 'http://www.google.com/',
      method => 'resolve',
      method_args => ['foo.html'],
      expected => 'http://www.google.com/foo.html')->is_valid() == 1);
ok( check_spec(
      url => 'http://www.google.com/',
      method => 'resolve',
      method_args => ['http://images.google.com/foo.html'],
      expected => 'http://images.google.com/foo.html')->is_valid() == 1);
ok( check_spec(
      url => 'http://www.google.com/blah/bloo?c#d',
      method => 'resolve',
      method_args => ['../../../hello/./world.html?a#b'],
      expected => 'http://www.google.com/hello/world.html?a#b')->is_valid() == 1);
ok( check_spec(
      url => 'http://www.google.com/foo#bar',
      method => 'resolve',
      method_args => ['#com'],
      expected => 'http://www.google.com/foo#com')->is_valid() == 1);
ok( check_spec(
      url => 'http://www.google.com/',
      method => 'resolve',
      method_args => ['Https:images.google.com'],
      expected => 'https://images.google.com/')->is_valid() == 1);
note('Unknown schemes are not standard.');
ok( check_spec(
      url => 'data:blahblah',
      method => 'resolve',
      method_args => ['http://google.com/'],
      expected => 'http://google.com/')->is_valid() == 1);
ok( check_spec(
      url => 'data:blahblah',
      method => 'resolve',
      method_args => ['http:google.com'],
      expected => 'http://google.com/')->is_valid() == 1);
ok( check_spec(
      url => 'filesystem:http://www.google.com/type/',
      method => 'resolve',
      method_args => ['foo.html'],
      expected => 'filesystem:http://www.google.com/type/foo.html')->is_valid() == 1);
ok( check_spec(
      url => 'filesystem:http://www.google.com/type/',
      method => 'resolve',
      method_args => ['../foo.html'],
      expected => 'filesystem:http://www.google.com/type/foo.html')->is_valid() == 1);

note('get_origin validation...');
check_spec(url => 'http://www.google.com', expected => 'http://www.google.com/', method => 'get_origin');
check_spec(url => 'javascript:window.alert("hello,world");', expected => '', method => 'get_origin');
check_spec(url => 'http://user:pass@www.google.com:21/blah#baz', expected => 'http://www.google.com:21/', method => 'get_origin');
check_spec(url => 'http://user@www.google.com', expected => 'http://www.google.com/', method => 'get_origin');
check_spec(url => 'http://:pass@www.google.com', expected => 'http://www.google.com/', method => 'get_origin');
check_spec(url => 'http://:@www.google.com', expected => 'http://www.google.com/', method => 'get_origin');

note('get_with_empty_path validation...');
check_spec(url => "http://www.google.com", expected => "http://www.google.com/", method => 'get_with_empty_path');
check_spec(url => "javascript:window.alert(\"hello, world\");", expected => "", method => 'get_with_empty_path');
check_spec(url => "http://www.google.com/foo/bar.html?baz=22", expected => "http://www.google.com/", method => 'get_with_empty_path');

note('path_for_request validation...');
check_value(url => "http://www.google.com", expected => "/", method => 'path_for_request');
check_value(url => "http://www.google.com/", expected => "/", method => 'path_for_request');
check_value(url => "http://www.google.com/foo/bar.html?baz=22", expected => "/foo/bar.html?baz=22", method => 'path_for_request');
check_value(url => "http://www.google.com/foo/bar.html#ref", expected => "/foo/bar.html", method => 'path_for_request');
check_value(url => "http://www.google.com/foo/bar.html?query#ref", expected => "/foo/bar.html?query", method => 'path_for_request');

note('effective_int_port validation...');
check_value(url =>"http://www.google.com/", expected => 80, method => 'effective_int_port');
check_value(url => "http://www.google.com:80/", expected => 80, method => 'effective_int_port');
check_value(url => "http://www.google.com:443/", expected => 443, method => 'effective_int_port');
check_value(url => "https://www.google.com/", expected => 443, method => 'effective_int_port');
check_value(url => "https://www.google.com:443/", expected => 443, method => 'effective_int_port');
check_value(url => "https://www.google.com:80/", expected => 80, method => 'effective_int_port');
check_value(url => "ftp://www.google.com/", expected => 21, method => 'effective_int_port');
check_value(url => "ftp://www.google.com:21/", expected => 21, method => 'effective_int_port');
check_value(url => "ftp://www.google.com:80/", expected => 80, method => 'effective_int_port');
check_value(url => "gopher://www.google.com/", expected => 70, method => 'effective_int_port');
check_value(url => "gopher://www.google.com:70/", expected => 70, method => 'effective_int_port');
check_value(url => "gopher://www.google.com:80/", expected => 80, method => 'effective_int_port');
check_value(url => "file://www.google.com/", expected => URL::Google::GURL::PORT_UNSPECIFIED(), method => 'effective_int_port');
check_value(url => "file://www.google.com:443/", expected => URL::Google::GURL::PORT_UNSPECIFIED(), method => 'effective_int_port');
check_value(url => "data:www.google.com:90", expected => URL::Google::GURL::PORT_UNSPECIFIED(), method => 'effective_int_port');
check_value(url => "data:www.google.com", expected => URL::Google::GURL::PORT_UNSPECIFIED(), method => 'effective_int_port');

note('host_is_ip_address validation...');
check_value(url => "http://www.google.com/", expected => 0, method => 'host_is_ip_address');
check_value(url => "http://192.168.9.1/", expected => 1, method => 'host_is_ip_address');
check_value(url => "http://192.168.9.1.2/", expected => 0, method => 'host_is_ip_address');
check_value(url => "http://192.168.m.1/", expected => 0, method => 'host_is_ip_address');
check_value(url => "http://2001:db8::1/", expected => 0, method => 'host_is_ip_address');
check_value(url => "http://[2001:db8::1]/", expected => 1, method => 'host_is_ip_address');
check_value(url => "", expected => 0, method => 'host_is_ip_address');
check_value(url => "some random input!", expected => 0, method => 'host_is_ip_address');

note('host validation...');
check_value(url => "http://www.google.com", expected => "www.google.com", method => 'host');
check_value(url => "http://[2001:db8::1]/", expected => "[2001:db8::1]", method => 'host');
check_value(url => "http://[::]/", expected => "[::]", method => 'host');
note(q(....don't require a valid URL, but don't crash either.));
check_value(url => "http://[]/", expected => "[]", method => 'host');
check_value(url => "http://[x]/", expected => "[x]", method => 'host');
check_value(url => "http://[x/", expected => "[x", method => 'host');
check_value(url => "http://x]/", expected => "x]", method => 'host');
check_value(url => "http://[/", expected => "[", method => 'host');
check_value(url => "http://]/", expected => "]", method => 'host');
check_value(url => "", expected => "", method => 'host');

note('host_no_brackets validation...');
check_value(url => "http://www.google.com", expected => "www.google.com", method => 'host_no_brackets');
check_value(url => "http://[2001:db8::1]/", expected => "2001:db8::1", method => 'host_no_brackets');
check_value(url => "http://[::]/", expected => "::", method => 'host_no_brackets');
note(q(....don't require a valid URL, but don't crash either.));
check_value(url => "http://[]/", expected => "", method => 'host_no_brackets');
check_value(url => "http://[x]/", expected => "x", method => 'host_no_brackets');
check_value(url => "http://[x/", expected => "[x", method => 'host_no_brackets');
check_value(url => "http://x]/", expected => "x]", method => 'host_no_brackets');
check_value(url => "http://[/", expected => "[", method => 'host_no_brackets');
check_value(url => "http://]/", expected => "]", method => 'host_no_brackets');
check_value(url => "", expected => "", method => 'host_no_brackets');

note('domain_is validation...');
my $google_domain = "google.com";
check_value(url => "http://www.google.com:99/foo", expected => 1, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://google.com:99/foo", expected => 1, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://google.com./foo", expected => 1, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://google.com/foo", expected => 0, method => 'domain_is', method_args => [$google_domain . '.']);
check_value(url => "http://google.com./foo", expected => 1, method => 'domain_is', method_args => [$google_domain . '.']);
check_value(url => "http://www.google.com./foo", expected => 1, method => 'domain_is', method_args => [".com."]);
check_value(url => "http://www.balabala.com/foo", expected => 0, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://www.google.com.cn/foo", expected => 0, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://www.iamnotgoogle.com/foo", expected => 0, method => 'domain_is', method_args => [$google_domain]);
check_value(url => "http://www.iamnotgoogle.com../foo", expected => 0, method => 'domain_is', method_args => [".com"]);

note('Newlines should be stripped from inputs.');
check_spec(url =>" \t ht\ntp://\twww.goo\rgle.com/as\ndf \n ", expected => "http://www.google.com/asdf");
check_spec(
    url =>" \t ht\ntp://\twww.goo\rgle.com/as\ndf \n ",
    expected => "http://www.google.com/foo",
    method => 'resolve',
    method_args => [" \n /fo\to\r "]);
  
note('is_standard validation...');
check_value(url => "http:foo/bar", expected => 1, method => 'is_standard');
check_value(url => "foo:bar/baz", expected => 0, method => 'is_standard');
check_value(url => "foo://bar/baz", expected => 0, method => 'is_standard');

## -- HELPER functions -- ##

sub check_spec {return _check_core(@_, spec_method => 'spec')}
sub check_possibly_invalid_spec {return _check_core(@_, spec_method => 'possibly_invalid_spec')}
sub check_value {return _check_core(@_)}

sub _check_core
{
    my %args = @_;
    my $u = new_ok( 'URL::Google::GURL' => [$args{url}] );
    croak "check must be called with method or spec_method argument" unless ($args{spec_method} || $args{method});
    if ($args{method}) {
        my $method = $args{method};
        my @marg = $args{method_args} ? @{$args{method_args}} : ();
        $u = eval{$u->$method( @marg )};
    }
    my $spec_method = $args{spec_method};
    my $value_to_compare = $spec_method ? eval{$u->$spec_method()} : $u;
    
    my $note_extra = $args{method} ? "$args{method} of" : "";
    my $spec_name = $args{spec_method} || "value";
    note("$spec_name for $note_extra $args{url} is $value_to_compare");
    
    is($value_to_compare, $args{expected});
    return $u;
}
