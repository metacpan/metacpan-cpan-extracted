#/usr/bin/perl
use Test::More;
use Test::Warn;
use Test::Fatal;
use Data::Dumper;
use Test::Exception;
use Test::NoWarnings;
use WebService::Google::Client;
use Test::File::ShareDir::Dist   { 'WebService-Google-Client'   => 'share/' };
use Test::File::ShareDir::Module { 'WebService::Google::Client' => 'share/' };

#use lib '/Users/stevedondley/perl/modules/Log-Log4perl-Shortcuts/lib';
use Log::Log4perl::Shortcuts qw(:all);
diag("Running client tests");

my $tests = 4;    # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;
set_log_config( 'wgc.cfg', 'WebService::Google::Client' );

my $client;

lives_ok { $client = WebService::Google::Client->new(); }
'can create new client obj';

lives_ok { $client = WebService::Google::Client->new( log_level => 'debug' ); }
'can pass log_level to constructor';

ok $client->log_level eq 'debug', 'can set log level';

#$client->books;
#lives_ok { $client->books; } 'can AUTOLOAD';
