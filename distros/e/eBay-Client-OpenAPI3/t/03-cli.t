use strict;
use warnings;

use Test::More;
use JSON::XS qw(decode_json);
use Util::H2O::More qw(d2o);
use lib 'lib';

my $loaded = do './bin/ebayapi3';
die $@ if $@;
die $! if not defined $loaded;

{
    package Local::CLIClient;
    our $ITEM_ERROR;
    our $RATE_ERROR;
    our $BROWSE_ERROR;
    our @BROWSE_RESPONSES;
    our @BROWSE_CALLS;

    sub new {
        return bless {
            next  => undef,
            token => Util::H2O::More::d2o({ access_token => 'CLI-TOKEN' }),
        }, shift;
    }
    sub oauth2 { return $_[0] }
    sub token { return $_[0]->{token} }
    sub next { return $_[0]->{next} }

    sub rate_limit {
        die $RATE_ERROR if defined $RATE_ERROR;
        return Util::H2O::More::d2o({
            rateLimits => [ {
                resources => [ {
                    name  => 'browse',
                    rates => [ {
                        limit      => 5000,
                        count      => 12,
                        remaining  => 4988,
                        reset      => '2026-09-11T00:00:00Z',
                        timeWindow => 86400,
                    } ],
                } ],
            } ],
        });
    }

    sub getItem {
        my ($self, %args) = @_;
        die $ITEM_ERROR if defined $ITEM_ERROR;
        return Util::H2O::More::d2o({
            itemId   => 'v1|' . ($args{itemid} // q{}) . '|0',
            title    => 'Example Item',
            bidCount => 7,
            price    => { value => '12.34', currency => 'USD' },
        });
    }

    sub browse {
        my ($self, %args) = @_;
        die $BROWSE_ERROR if defined $BROWSE_ERROR;
        push @BROWSE_CALLS, { %args };
        die "no fake browse response queued\n" if not @BROWSE_RESPONSES;
        my $data = shift @BROWSE_RESPONSES;
        $self->{next} = $data->{next};
        return Util::H2O::More::d2o($data);
    }
}

my $FAKE_CLIENT;
my $LAST_CONFIG;

sub reset_fake {
    $FAKE_CLIENT = Local::CLIClient->new;
    $LAST_CONFIG = undef;
    $Local::CLIClient::ITEM_ERROR = undef;
    $Local::CLIClient::RATE_ERROR = undef;
    $Local::CLIClient::BROWSE_ERROR = undef;
    @Local::CLIClient::BROWSE_RESPONSES = ();
    @Local::CLIClient::BROWSE_CALLS = ();
}

sub run_with_fake {
    my ($argv) = @_;
    no warnings qw(redefine once);
    local *eBay::Client::OpenAPI3::new = sub {
        my ($class, %args) = @_;
        $LAST_CONFIG = $args{config};
        return $FAKE_CLIENT;
    };
    return bin::ebayapi3::run($argv);
}

sub capture {
    my ($code) = @_;
    my ($out, $err) = (q{}, q{});
    my $ret;
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, '>', \$out or die "open scalar STDOUT: $!";
        open STDERR, '>', \$err or die "open scalar STDERR: $!";
        $ret = $code->();
    }
    return ($ret, $out, $err);
}

reset_fake();
{
    my ($ret, $out, $err) = capture(sub { bin::ebayapi3::run(['help']) });
    is($ret, 1, 'explicit help retains historical status 1');
    is($out, q{}, 'help writes no STDOUT');
    like($err, qr/Each subcommand has it's own options/, 'existing help text is retained');
}

reset_fake();
{
    my ($ret, $out, $err) = capture(sub { run_with_fake([]) });
    is($ret, 0, 'no subcommand still defaults to oauth2');
    is($out, 'CLI-TOKEN', 'oauth2 default output remains bare token without newline');
    is($err, q{}, 'oauth2 success is quiet on STDERR');
}

reset_fake();
{
    my ($ret, $out, $err) = capture(sub {
        run_with_fake(['oauth2', '--config', '/tmp/custom.ini', '--as', 'json']);
    });
    is($ret, 0, 'oauth2 --as json succeeds');
    is($LAST_CONFIG, '/tmp/custom.ini', 'documented --config now reaches constructor');
    like($out, qr/^\{"access_token":"CLI-TOKEN"\}CLI-TOKEN$/, 'oauth2 JSON+token output is intentionally preserved');
}

reset_fake();
{
    my ($ret, $out, $err) = capture(sub {
        run_with_fake(['item', '--itemid', '42', '--as', 'summary']);
    });
    is($ret, 0, 'item summary succeeds');
    like($out, qr/^42 Title: Example Item/m, 'item summary strips REST item wrapper as before');
    like($out, qr/Bids: 7/, 'item summary includes bids');
    like($out, qr/Price: 12\.34 \(USD\)/, 'item summary includes price');
}

reset_fake();
{
    $Local::CLIClient::ITEM_ERROR = "item failed\n";
    my ($ret, $out, $err) = capture(sub { run_with_fake(['item', '--itemid', '42']) });
    is($ret, 1, 'item handled API error still yields status 1');
    like($err, qr/FATAL: eBay 'getItem'.*item failed/s, 'item API error text retains existing prefix');
}

reset_fake();
{
    my ($ret, $out, $err) = capture(sub { run_with_fake(['rate', '--as', 'summary']) });
    is($ret, 0, 'rate summary succeeds');
    like($out, qr/browse API Call Rates/, 'rate summary names resource');
    like($out, qr/Limit:\s+5000/, 'rate summary includes limit');
    like($out, qr/Left\s+:\s+4988/, 'rate summary includes remaining calls');
}

reset_fake();
{
    $Local::CLIClient::RATE_ERROR = "rate failed\n";
    my ($ret, $out, $err) = capture(sub { run_with_fake(['rate']) });
    is($ret, 1, 'rate handled API error still yields status 1');
    like($err, qr/FATAL: eBay 'rate_limit'.*rate failed/s, 'rate error prefix retained');
}

reset_fake();
{
    @Local::CLIClient::BROWSE_RESPONSES = ({
        total => 1,
        next => undef,
        warnings => [ { message => 'test warning' } ],
        itemSummaries => [ { itemId => 'v1|1|0', title => 'One' } ],
    });
    my ($ret, $out, $err) = capture(sub {
        run_with_fake([
            'browse', '--config', '/tmp/bspi.ini', '--category_ids', '123',
            '--brand', 'Acme', '--filter', 'price:[1..10]', '--q', 'widget',
            '--stats',
        ]);
    });
    is($ret, 0, 'single-page browse succeeds');
    my $json = decode_json($out);
    is($json->{itemSummaries}[0]{title}, 'One', 'browse default output remains JSON');
    is($LAST_CONFIG, '/tmp/bspi.ini', '--config is additive to browse');
    like($err, qr/API WARNING: test warning/, 'API warning format retained');
    like($err, qr/01\/01 requests, 00001\/01 items gotten/, 'stats formatting retained');
    my $call = $Local::CLIClient::BROWSE_CALLS[0];
    is($call->{q}, 'widget', 'q is passed through');
    like($call->{filter}, qr/brand:\{"Acme"\}/, 'brand filter retained');
    like($call->{filter}, qr/buyingOptions:\{AUCTION\}/, 'default AUCTION filter retained');
    like($call->{filter}, qr/price:\[1\.\.10\]/, 'raw filter remains appended');
}

reset_fake();
{
    my $next = 'https://api.ebay.com/buy/browse/v1/item_summary/search?offset=2&limit=2&sort=endingSoonest&category_ids=123';
    @Local::CLIClient::BROWSE_RESPONSES = (
        {
            total => 4,
            next => $next,
            warnings => [],
            itemSummaries => [
                { itemId => 'v1|1|0', title => 'One' },
                { itemId => 'v1|2|0', title => 'Two' },
            ],
        },
        {
            total => 4,
            next => undef,
            warnings => [],
            itemSummaries => [
                { itemId => 'v1|3|0', title => 'Three' },
                { itemId => 'v1|4|0', title => 'Four' },
            ],
        },
    );
    my ($ret, $out, $err) = capture(sub {
        run_with_fake([
            'browse', '--category_ids', '123', '--limit', '2', '--max', '4',
            '--continue', '--as', 'compactjson', '--nextcmd',
        ]);
    });
    is($ret, 0, 'continued browse succeeds');
    is(scalar @Local::CLIClient::BROWSE_CALLS, 2, 'continued browse follows next page');
    like($out, qr/\}\{/, 'continued compact JSON remains consecutive JSON documents, not a new array');
    unlike($out, qr/^\[/, 'continued JSON is not silently reframed');
    like(
        $err,
        qr{\./bin/ebayapi3 browse --offset '2' --limit '2' --sort 'endingSoonest' --category_ids '123' --as yaml --continue},
        '--nextcmd retains historical YAML continuation format',
    );
}

reset_fake();
{
    my $next = 'https://api.ebay.com/buy/browse/v1/item_summary/search?offset=2&limit=2&sort=endingSoonest&category_ids=123';
    @Local::CLIClient::BROWSE_RESPONSES = (
        {
            total => 10,
            next => $next,
            warnings => [],
            itemSummaries => [
                { itemId => 'v1|1|0', title => 'One' },
                { itemId => 'v1|2|0', title => 'Two' },
            ],
        },
        {
            total => 10,
            next => undef,
            warnings => [],
            itemSummaries => [
                { itemId => 'v1|3|0', title => 'Three' },
                { itemId => 'v1|4|0', title => 'Four' },
            ],
        },
    );
    my ($ret, $out, $err) = capture(sub {
        run_with_fake([
            'browse', '--category_ids', '123', '--limit', '2', '--max', '3',
            '--continue', '--as', 'compactjson',
        ]);
    });
    is($ret, 0, 'historical --max cutoff exits successfully');
    is(scalar @Local::CLIClient::BROWSE_CALLS, 2, 'historical --max behavior fetches next page before cutoff');
    like($err, qr/fetch shutting down, number got exceeded max set with, "--max 3"/, '--max cutoff message retained');
    my $count = () = $out =~ /itemSummaries/g;
    is($count, 1, 'page that trips historical max guard is not emitted');
}

reset_fake();
{
    @Local::CLIClient::BROWSE_RESPONSES = ({
        total => 1,
        next => undef,
        warnings => [],
        itemSummaries => [ { itemId => 'v1|1|0', title => 'One' } ],
    });
    my ($ret, $out, $err) = capture(sub { run_with_fake(['browse', '--as', 'yaml']) });
    is($ret, 0, 'YAML browse output succeeds');
    like($out, qr/^---/m, 'YAML output remains document-oriented');
}

reset_fake();
{
    $Local::CLIClient::BROWSE_ERROR = "browse failed\n";
    my ($ret, $out, $err) = capture(sub { run_with_fake(['browse']) });
    is($ret, 1, 'browse handled API error still yields status 1');
    like($err, qr/FATAL: eBay 'browse'.*browse failed/s, 'browse API error prefix retained');
}

is(bin::ebayapi3::shell_quote(undef), q{''}, 'shell_quote handles undef');
is(bin::ebayapi3::shell_quote(q{}), q{''}, 'shell_quote handles empty string');
is(bin::ebayapi3::shell_quote('simple'), q{'simple'}, 'shell_quote wraps simple value');
is(bin::ebayapi3::shell_quote("a'b"), q{'a'''b'}, 'shell_quote retains historical single-quote behavior');

done_testing;
