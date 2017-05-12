use strict;
use warnings;
use Test::More;
use Types::URI qw( to_Uri );

my $uri = to_Uri('1ad21e80-63a0-4cde-aa36-1301761a4285');
isa_ok($uri, 'URI');
is("$uri", 'urn:uuid:1ad21e80-63a0-4cde-aa36-1301761a4285');
done_testing;
