# Basic URI::Query tests

use Test::More;
use_ok(URI::Query);
use strict;

my $qq;

# Constructor - scalar version
ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), 
  "scalar constructor ok");
is($qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 
  sprintf("stringifies ok (%s)", $qq->stringify));

# Constructor - array version
ok($qq = URI::Query->new(foo => 1, foo => 2, bar => 3, bog => 'abc', bar => 7, fluffy => 3), 
  "array constructor ok");
is($qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 
  sprintf("stringifies ok (%s)", $qq->stringify));

# Constructor - hashref version
ok($qq = URI::Query->new({ foo => [ 1, 2 ], bar => [ 3, 7 ], bog => 'abc', fluffy => 3 }), 
  "hashref constructor ok");
is($qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 
  sprintf("stringifies ok (%s)", $qq->stringify));

# Constructor - CGI.pm-style hashref version, packed values
ok($qq = URI::Query->new({ foo => "1\0002", bar => "3\0007", bog => 'abc', fluffy => 3 }), 
  "cgi-style hashref constructor ok");
is($qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 
  sprintf("stringifies ok (%s)", $qq->stringify));

# Bad constructor args
{
  no warnings qw(once);
  for my $bad ((undef, '', \"foo", [ foo => 1 ], \*bad)) {
    my $b2 = $bad;
    $b2 = '[undef]' unless defined $bad;
    $qq = URI::Query->new($bad);
    ok(ref $qq eq 'URI::Query', "bad '$b2' constructor ok");
    is($qq->stringify, '', sprintf("stringifies ok (%s)", $qq->stringify));
  }
}

done_testing;

