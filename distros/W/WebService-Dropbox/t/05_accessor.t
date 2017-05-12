use strict;
use Test::More;

use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new();

is $dropbox->{env_proxy}, 0;

$dropbox->env_proxy;

is $dropbox->{env_proxy}, 1;

$dropbox->env_proxy(0);

is $dropbox->{env_proxy}, 0;

$dropbox = WebService::Dropbox->new({ env_proxy => 1 });

is $dropbox->{env_proxy}, 1;

done_testing();
