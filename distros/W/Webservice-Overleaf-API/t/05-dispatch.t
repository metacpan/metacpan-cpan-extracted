use strict;
use warnings;
use Test::More;

use Webservice::Overleaf::API;

my $ol = Webservice::Overleaf::API->new;

is $ol->call('git_url', 'abc123'), 'https://git.overleaf.com/abc123', 'call dispatches git_url';
like $ol->call('open_uri', uri => 'https://example.org/main.tex'), qr{snip_uri=}, 'call dispatches open_uri';

my $ok = eval { $ol->call('does_not_exist'); 1 };
ok !$ok, 'unsupported dispatch throws';
like $@, qr/unsupported Overleaf operation 'does_not_exist'/, 'unsupported dispatch diagnostic';

done_testing;
