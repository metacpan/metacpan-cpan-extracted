use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $worepan = WorePAN->new(cleanup => 1, no_network => 0, use_backpan => 1);

$worepan->add_files(qw{
  MOB/Forks-Super-0.51.tar.gz
  MOB/Forks-Super-0.48.tar.gz
});

ok $worepan->update_indices;

is $worepan->look_for('Forks::Super') => '0.51', "got a correct version";

done_testing;
