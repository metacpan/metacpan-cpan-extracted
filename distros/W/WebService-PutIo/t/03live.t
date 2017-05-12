use Test::More;
plan skip_all => 'This test requires PUT_IO_API_KEY and PUT_IO_SECRET'
  unless $ENV{PUT_IO_API_KEY} && $ENV{PUT_IO_API_SECRET};
plan tests => 3;

use WebService::PutIo;

my $put_io=WebService::PutIo->new(api_key=>$ENV{PUT_IO_API_KEY}, api_secret => $ENV{PUT_IO_API_SECRET});
isa_ok($put_io,'WebService::PutIo');

# Basic Request
my $res=$put_io->request('messages','list');
isa_ok($res,'WebService::PutIo::Result');
is($res->count, @{$res->results},'Return the specified number of results');