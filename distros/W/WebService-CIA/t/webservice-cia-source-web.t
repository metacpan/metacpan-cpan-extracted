use strict;
use Test::More tests => 30;
use lib  qw( t/lib );
use WCUA;
use Module::Build;

my $build = Module::Build->current();


BEGIN { use_ok('WebService::CIA::Source::Web'); }

my $source;

eval {
    $source = WebService::CIA::Source::Web->new( 'foo' );
};
ok( $@ );
ok( $@ =~ /^\QArguments to new() must be a hashref\E/ );

$source = WebService::CIA::Source::Web->new;

ok( defined $source, 'new() - returns something' );

ok( $source->isa('WebService::CIA::Source::Web'), 'new() - returns a WebService::CIA::Source::Web object' );

ok( ref $source->ua eq 'LWP::UserAgent', 'ua() - returns LWP::UserAgent object' );

is( ref $source->ua( WCUA->new ), 'WCUA', 'ua() returns set object' ); 
is( ref $source->ua(), 'WCUA', 'ua() stores object correctly' ); 
$source = WebService::CIA::Source::Web->new( { user_agent => WCUA->new } );
is( ref $source->ua(), 'WCUA', 'new() takes user_agent arg correctly' ); 

ok( ref $source->parser eq 'WebService::CIA::Parser', 'parser() - returns WebService::CIA::Parser object' );

ok( $source->cached eq '', 'cached() - returns empty string after new()' );

ok( scalar keys %{$source->cache} == 0, 'cache() returns empty hashref after new()' );

$source->cached('testcountry');
ok( $source->cached eq 'testcountry', 'cached() - set data' );

$source->cache({'Test' => 'Wombat'});
ok( exists $source->cache->{'Test'} &&
    $source->cache->{'Test'} eq 'Wombat', 'cache() - set data' );

ok( $source->value('testcountry','Test') eq 'Wombat', 'value() (manually set data) - valid args - return test string' );

ok( ! defined $source->value('testcountry','Blah'), 'value() (manually set data) - invalid args - return undef' );

ok( scalar keys %{$source->all('testcountry')} == 1 &&
    exists $source->all('testcountry')->{'Test'} &&
    $source->all('testcountry')->{'Test'} eq 'Wombat', 'all() (manually set data) - return expected values' );

ok( $source->get('testcountry') == 0, 'get() on bad country - returns 0' );
my $resp = $source->last_response;
ok( $resp, "Stores last response" );
is( ref $resp, "HTTP::Response", "Right object" );
is( $resp->code, 404, "Right response" );

ok( $source->get('uk') == 1, 'get() - returns 1' );
$resp = $source->last_response;
is( $resp->code, 200, "Right response" );


ok( $source->cached eq 'uk', 'cached() - cached country set correctly after get()' );

ok( scalar keys %{$source->cache} > 0 &&
    exists $source->cache->{'Background'} &&
    $source->cache->{'Background'}, 'cache() - cache contains values' );

ok( $source->value('uk','Background'), 'value() - valid args - returns a value' );

ok( ! defined $source->value('uk','Test'), 'value() (cached info) - invalid args - returns undef' );

ok( ! defined $source->value('testcountry', 'Test'), 'value() (non-cached info) - invalid args - returns undef' );

ok( scalar keys %{$source->all('uk')} > 0 &&
    exists $source->all('uk')->{'Background'} &&
    $source->all('uk')->{'Background'}, 'all() - valid args - returns hashref' );

ok( scalar keys %{$source->all('testcountry')} == 0, 'all() - invalid args - returns empty hashref' );
