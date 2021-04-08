use strict;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;
use URI::XS qw/uri :const/;

catch_run('[scheme-custom]');

package MyScheme;
use parent 'URI::XS';
use strict;

sub hello { return $_[0]->scheme . '-' . $_[0]->host }

package main;

URI::XS::register_scheme("myscheme", "MyScheme");

my $uri = uri('myscheme://mysite.com/a/b/c');
is(ref($uri), 'MyScheme');
is($uri, 'myscheme://mysite.com/a/b/c');

done_testing();
