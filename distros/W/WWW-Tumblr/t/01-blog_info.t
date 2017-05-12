use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();
my $info = $blog->info();

ok ref $info eq 'HASH',         'response is a hash reference';
ok defined $info->{blog},       'response has a blog response';
is ref $info->{blog}, 'HASH',   'blog response also a hash';

ok scalar keys %{ $info->{blog} }, 'blog response not empty';

done_testing();


