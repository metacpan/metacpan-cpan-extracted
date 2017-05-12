use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More;

use Test::WWW::Selenium;
use WWW::Selenium::Util 'server_is_running';

use lib 't/lib';
use server;

{
    my ($host, $port) = server_is_running;

    if ( $host and $port ) {
        plan tests => 8;
    }
    else {
        plan skip_all => "No Selenium server found.";
        exit 0;
    };
}

use_ok 'Test::WWW::Jasmine';

my $source = <<'EEE';
/*
@css /css/css1.css
@css /css/css2.css
@css /css/css3.css

@script script1.js
@script script2.js
@script script3.js
*/

describe('Test::WWW::Jasmine passing', function() {
    it('should run tests', function() {
        expect(true).toBeTruthy();
        expect(false).toBeFalsy();
        expect(undefined).toBeUndefined();
        expect(null).toBeDefined()
    });
});
EEE

my $source2 = <<'EEE';
describe('Test::WWW::Jasmine single expectation', function() {
    it('should display single expectation as one test', function() {
        expect(true).toBeTruthy();
    });
});
EEE

my $source3 = <<'EEE';
describe('Test::WWW::Jasmine failing', function() {
    it('should fail some tests, too (mixed)', function() {
        expect(false).toBeTruthy();
        expect(false).toBeFalsy()
        expect(true).toBeFalsy();
        expect(false).toBeFalsy();
        expect(null).toBeUndefined();
        expect(undefined).toBeDefined();
    });
});
EEE

my $server = server->new(static_dir => 't/htdocs');
my $port   = $server->port;

my $pid;

if ( $pid = fork ) {
    local $SIG{CHLD} = sub { waitpid $pid, 0 };

    sleep 1;
}
elsif ( defined $pid && $pid == 0 ) {
    $server->run();
    exit 0;
}
else {
    die "Can't fork: $!";
};

my $filename = 't/htdocs/js_test_source.js';

{
    open my $fh, '>', $filename or die "Can't open $filename: $!\n";
    print $fh $source;
    close $fh;
}

my $jasmine_script = '/jasmine.js';

my $jasmine = Test::WWW::Jasmine->new(
        spec_file   => $filename,
        jasmine_url => $jasmine_script,
        html_dir    => 't/htdocs',
        browser_url => "http://127.0.0.1:$port/",
);

ok     $jasmine, 'Got object';
isa_ok $jasmine, 'Test::WWW::Jasmine', 'Right object';

my @css     = $jasmine->css;
my @scripts = $jasmine->scripts;

my $expected_css     = [qw(/css/css1.css /css/css2.css /css/css3.css)];
my $expected_scripts = [
    $jasmine_script,
    qw(script1.js script2.js script3.js)
];

is_deeply \@css,     $expected_css,     'Parsed all css scripts';
is_deeply \@scripts, $expected_scripts, 'Parsed all js scripts';

my $passed = subtest 'jasmine multiple test' => sub { $jasmine->run() };

{
    open my $fh, '>', $filename or die "Can't open $filename: $!\n";
    print $fh $source2;
    close $fh;
}

$jasmine = Test::WWW::Jasmine->new(
        spec_file   => $filename,
        jasmine_url => $jasmine_script,
        html_dir    => 't/htdocs',
        browser_url => "http://127.0.0.1:$port/",
);

$passed = subtest 'jasmine single test' => sub { $jasmine->run() };

{
    open my $fh, '>', $filename or die "Can't open $filename: $!\n";
    print $fh $source3;
    close $fh;
}

$jasmine = Test::WWW::Jasmine->new(
        spec_file   => $filename,
        jasmine_url => $jasmine_script,
        html_dir    => 't/htdocs',
        browser_url => "http://127.0.0.1:$port/",
);

my $failed;
TODO: {
    local $TODO = 'This test should always fail';

    $failed = subtest 'jasmine failing test' => sub { $jasmine->run() };
}

unlink $filename;

kill 9, $pid;


