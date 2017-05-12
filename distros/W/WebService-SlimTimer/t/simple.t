use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WebService::SlimTimer'); }

my $st = WebService::SlimTimer->new($ENV{'SLIMTIMER_API_KEY'} || 'bogus');
isa_ok($st, 'WebService::SlimTimer');

can_ok($st, qw(login list_tasks));

done_testing();
