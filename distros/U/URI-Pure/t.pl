$| = 1;
use strict;
use warnings;

use Test::More "no_plan";

use URI::Pure;


sub show_URI_for_test {
	my ($s) = @_;
	print "$s\n";
	my $u = URI::Pure->new($s);
	print $u->as_string, "\n";
	foreach (qw(scheme user password host port path query fragment)) {
		printf "\t%s:\t%s\n", (sprintf "%-10s", $_), $u->{$_} if defined $u->{$_};
	}
	print "\n";
}

show_URI_for_test("http://www.foo.com:80/baz/foo.html?a=b&c=d");


{
my $url = URI::Pure->new("http://www.foo.com:80/baz/foo.html?a=b&c=d");

is($url->scheme,    "http",           "scheme");
is($url->user,      undef,            "user");
is($url->password,  undef,            "password");
is($url->host,      "www.foo.com",    "host");
is($url->port,      "80",             "port");
is($url->path,      "/baz/foo.html",  "path");
is($url->query,     "a=b&c=d",        "query");
is($url->fragment,  undef,            "fragment");
is($url->as_string, "http://www.foo.com/baz/foo.html?a=b&c=d", "as_string");
}

{
my $url = URI::Pure->new('http://u:p@www.foo.com/baz/bar.html?a=b#too');
is($url->scheme,    "http",            "scheme");
is($url->user,      "u",               "user");
is($url->password,  "p",               "password");
is($url->host,      "www.foo.com",     "host");
is($url->port,      undef,             "port");
is($url->path,      "/baz/bar.html",   "path");
is($url->query,     "a=b",             "query");
is($url->fragment,  "too",             "fragment");
is($url->as_string, 'http://u:p@www.foo.com/baz/bar.html?a=b#too', "as_string");
}


{
my $url = URI::Pure->new("urn:a:b:c:d");
is($url->scheme,    "urn",             "scheme");
is($url->user,      undef,             "user");
is($url->password,  undef,             "password");
is($url->host,      undef,             "host");
is($url->port,      undef,             "port");
is($url->path,      "a:b:c:d",         "path");
is($url->query,     undef,             "query");
is($url->fragment,  undef,             "fragment");
is($url->as_string, "urn:a:b:c:d", "as_string");
}


{
my $base = "http://a/b/c/d;p?q";
my @t = (
	["http://www.baz.com/baz.html", "http://www.foo.com/baz/bar.html", "http://www.baz.com/baz.html"],
	["foo.html?a=b&c=d",            "http://www.foo.com/baz/bar.html", "http://www.foo.com/baz/foo.html?a=b&c=d"],
	["foo.html?a=b&c=d",            "http://www.foo.com/",             "http://www.foo.com/foo.html?a=b&c=d"],
	["foo.html?a=b&c=d",            "http://www.foo.com",              "http://www.foo.com/foo.html?a=b&c=d"],
	["//g",                          $base, "http://g"],
	["g:h",                          $base, "g:h"],
	["g",                            $base, "http://a/b/c/g"],
	["./g",                          $base, "http://a/b/c/g"],
	["g/",                           $base, "http://a/b/c/g/"],
	["/g",                           $base, "http://a/g"],
	["//g",                          $base, "http://g"],
	["?y",                           $base, "http://a/b/c/d;p?y"],
	["g?y",                          $base, "http://a/b/c/g?y"],
	["#s",                           $base, "http://a/b/c/d;p?q#s"],
	["g#s",                          $base, "http://a/b/c/g#s"],
	["g?y#s",                        $base, "http://a/b/c/g?y#s"],
	[";x",                           $base, "http://a/b/c/;x"],
	["g;x",                          $base, "http://a/b/c/g;x"],
	["g;x?y#s",                      $base, "http://a/b/c/g;x?y#s"],
	["",                             $base, "http://a/b/c/d;p?q"],
	[".",                            $base, "http://a/b/c/"],
	["./",                           $base, "http://a/b/c/"],
	["..",                           $base, "http://a/b/"],
	["../",                          $base, "http://a/b/"],
	["../g",                         $base, "http://a/b/g"],
	["../..",                        $base, "http://a/"],
	["../../",                       $base, "http://a/"],
	["../../g",                      $base, "http://a/g"],
);

print "\nTests for abs:\n";
my $i = 0;
foreach (@t) {
	my ($url, $base, $expected) = @$_;
	my $u = URI::Pure->new($url);
	my $b = URI::Pure->new($base);
	my $got = $u->abs($b)->as_string;
	$i++;
	is($got, $expected, "abs $i");
}
}


print "\nTests for normalization:\n";
{
my @t = (
	["/", "/"],
	[".", "."],
	["//", ""],  # Тут - host, а не path
	["//a", ""], # Тут a - это host, а не path
	["/a/", "/a/"],
	["/a/b/.", "/a/b/"],
	["/a//b/./c/d", "/a/b/c/d"],
	["a//b/./c/d", "a/b/c/d"],
	["/a/b/../d", "/a/d"],
	["/a/../c/d", "/c/d"],
	["/a/b/../../c", "/c"],
	["/a/../../b", "/b"],
	["a/../../b", "../b"],
	["a/../../../b", "../../b"],
	["/b/c/..", "/b/"],
	["a1/a2/a3/a4/a5/../../b", "a1/a2/a3/b"],
	["a1/a2/a3/a4/a5/../../../b", "a1/a2/b"],
	["a1/a2/a3/a4/a5/../../../../b", "a1/b"],
	["a1/a2/a3/a4/a5/../../../../../b", "b"],
	["a1/a2/a3/a4/a5/../../../../../../b", "../b"],
);

my $i = 0;
foreach (@t) {
	my ($u, $e) = @$_;
	$i++;
	is (URI::Pure->new($u)->path, $e, "normalize $i");
}

}


print "\nInternationalized Resource Identifier\n";
{
my $u = URI::Pure->new("http://Інтернаціоналізовані.Доменні.Імена/Головна/сторінка?a=Вітаю&b=До побачення");
my $e = "http://xn--80aaahmo1ambbffeu2a2e1ohef.xn--d1acufac6o.xn--80ajuf6j/%D0%93%D0%BE%D0%BB%D0%BE%D0%B2%D0%BD%D0%B0/%D1%81%D1%82%D0%BE%D1%80%D1%96%D0%BD%D0%BA%D0%B0?a=%D0%92%D1%96%D1%82%D0%B0%D1%8E&b=%D0%94%D0%BE%20%D0%BF%D0%BE%D0%B1%D0%B0%D1%87%D0%B5%D0%BD%D0%BD%D1%8F";
is ($u->as_string, $e, "IDN");
is ($u->as_iri, "http://інтернаціоналізовані.доменні.імена/Головна/сторінка?a=Вітаю&b=До побачення", "IRI");
}
