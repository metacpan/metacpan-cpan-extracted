use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $worepan = WorePAN->new(cleanup => 1, no_network => 0, use_backpan => 1);

$worepan->add_files(qw{
  JESSE/HTTP-Server-Simple-0.44.tar.gz
});

ok $worepan->update_indices;

is $worepan->look_for('HTTP::Server::Simple::CGI') => 'undef', "got a correct (undef) version";

done_testing;
