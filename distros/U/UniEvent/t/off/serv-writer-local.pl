use strict;
use lib 't';
use Talkers;
use SingleClientServer;

my $line = shift;
my $path = shift;

# print STDERR '$line = '."$line\n";
# print STDERR '$path = '."$path\n";

SingleClientServer::run_local(Talkers::make_writer($line), $path);
