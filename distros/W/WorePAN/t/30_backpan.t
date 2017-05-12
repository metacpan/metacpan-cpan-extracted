use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $path = 'I/IS/ISHIGAKI/Acme-CPANAuthors-0.01.tar.gz';

my $worepan = WorePAN->new(files => [$path], no_network => 0, cleanup => 1, use_backpan => 1);

my $dest = $worepan->file($path);

ok $dest->exists, "downloaded successfully";

my $ver = $worepan->look_for("Acme::CPANAuthors");

is $ver => '0.01', "correct version";

done_testing;
