use Test::More tests=>6;

use WebService::PutIo;
use WebService::PutIo::Result;
my $put_io=WebService::PutIo->new;
my $res=WebService::PutIo::Result->new();
isa_ok($put_io,'WebService::PutIo');
can_ok($put_io,'api_key','api_secret','request');
isa_ok($res,'WebService::PutIo::Result');
can_ok($res,qw/response json data count results/);
isa_ok($put_io->ua,'Mojo::UserAgent');
isa_ok($put_io->json,'Mojo::JSON');
