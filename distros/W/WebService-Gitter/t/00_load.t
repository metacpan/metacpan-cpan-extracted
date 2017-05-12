use Test::More tests => 5;

require_ok('LWP::UserAgent');
use_ok('JSON::MaybeXS');
use_ok('Getopt::Long::Descriptive');
use_ok('Data::Dumper', qw(Dumper));
use_ok('WebService::Gitter');
done_testing();
