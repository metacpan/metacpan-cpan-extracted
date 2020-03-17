use strict;
use warnings;
use lib 't';
use UniClientSSL;
use SSL_conf;
use Talkers;

my $line = shift;

UniClient::connect(Talkers::make_writer($line), SSL_conf::client);
