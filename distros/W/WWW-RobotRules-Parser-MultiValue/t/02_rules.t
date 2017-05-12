package t::rules;

# cpan
use parent qw(Test::Class);
use Data::Section::Simple qw(get_data_section);
use Test::More;
use Test::Fatal qw(lives_ok);

# lib
my $Class = 'WWW::RobotRules::Parser::MultiValue';

sub _fixture { get_data_section(@_) }

sub _require : Test(startup => 1) {
    use_ok $Class;
}

sub allows : Tests {
    subtest 'Single agent rule' => sub {
        subtest 'http' => sub {
            my $robots = $Class->new(agent => 'TestBot/1.0');
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('single_agent'),
                );
            };
            ok $robots->allows('http://example.com/');
            ok $robots->allows('http://example.com/some/allowed/path');
            ok !$robots->allows('http://example.com/some/disallowed/path');
            ok !$robots->allows('http://example.com/some/thing');
            ok $robots->allows('http://example.com/some/other/path');
            ok $robots->allows('http://example.com/yet/another/path');

            ok $robots->allows('http://other.example.com/some/disallowed/path'),
                'Domain name must match to apply rules';
            ok $robots->allows('https://example.com/ssl/path'),
                'Port number must match to apply rules';
        };

        subtest 'https' => sub {
            my $robots = $Class->new(agent => 'TestBot/1.0');
            lives_ok {
                $robots->parse(
                    'https://example.com/robots.txt',
                    _fixture('single_agent'),
                );
            };
            ok $robots->allows('https://example.com/');
            ok $robots->allows('https://example.com/some/allowed/path');
            ok !$robots->allows('https://example.com/some/disallowed/path');
            ok !$robots->allows('https://example.com/some/thing');
            ok $robots->allows('https://example.com/some/other/path');
            ok $robots->allows('https://example.com/yet/another/path');

            ok $robots->allows('https://other.example.com/some/disallowed/path'),
                'Domain name must match to apply rules';
            ok $robots->allows('http://example.com/ssl/path'),
                'Port number must match to apply rules';
        };
    };

    subtest 'Multiple agent rule' => sub {
        subtest 'http' => sub {
            my $robots = $Class->new(agent => 'TestBot/1.0');
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('multiple_agent'),
                );
            };
            ok !$robots->allows('http://example.com/');
            ok $robots->allows('http://example.com/some/allowed/path');
            ok !$robots->allows('http://example.com/some/disallowed/path');
            ok !$robots->allows('http://example.com/some/thing');
            ok $robots->allows('http://example.com/some/other/path');
            ok !$robots->allows('http://example.com/yet/another/path');

            ok $robots->allows('http://other.example.com/some/disallowed/path'),
                'Domain name must match to apply rules';
            ok $robots->allows('https://example.com/ssl/path'),
                'Port number must match to apply rules';
        };

        subtest 'https' => sub {
            my $robots = $Class->new(agent => 'TestBot/1.0');
            lives_ok {
                $robots->parse(
                    'https://example.com/robots.txt',
                    _fixture('multiple_agent'),
                );
            };
            ok !$robots->allows('https://example.com/');
            ok $robots->allows('https://example.com/some/allowed/path');
            ok !$robots->allows('https://example.com/some/disallowed/path');
            ok !$robots->allows('https://example.com/some/thing');
            ok $robots->allows('https://example.com/some/other/path');
            ok !$robots->allows('https://example.com/yet/another/path');

            ok $robots->allows('https://other.example.com/some/disallowed/path'),
                'Domain name must match to apply rules';
            ok $robots->allows('http://example.com/ssl/path'),
                'Port number must match to apply rules';
        };
    };

    subtest 'Extended rule' => sub {
        my $robots = $Class->new(agent => $_);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('extended'),
            );
        };
        ok !$robots->allows('http://example.com/');
        ok $robots->allows('http://example.com/some/allowed/path');
        ok $robots->allows('http://example.com/some/disallowed/path');
        ok !$robots->allows('http://example.com/some/thing');
        ok !$robots->allows('http://example.com/some/other/path');
        ok !$robots->allows('http://example.com/yet/another/path');

        ok $robots->allows('http://other.example.com/any/path'),
            'Domain name must match to apply rules';
        ok $robots->allows('https://example.com/ssl/path'),
            'Port number must match to apply rules';
    };

    subtest 'Omitted wildcard agent rule' => sub {
        for (qw(TestBot/1.0 GuestBot)) {
            my $robots = $Class->new(agent => $_);
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('no_agent'),
                );
            };
            ok $robots->allows('http://example.com/');
            ok $robots->allows('http://example.com/some/allowed/path');
            ok !$robots->allows('http://example.com/some/disallowed/path');
            ok !$robots->allows('http://example.com/some/thing');
            ok $robots->allows('http://example.com/some/other/path');
            ok $robots->allows('http://example.com/yet/another/path');

            ok $robots->allows('http://other.example.com/some/disallowed/path'),
                'Domain name must match to apply rules';
            ok $robots->allows('https://example.com/ssl/path'),
                'Port number must match to apply rules';
        };
    };
}

sub delay_for : Tests {
    subtest 'Precedence' => sub {
        do {
            my $robots = $Class->new(agent => 'TestBot/1.0');
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('multiple_agent'),
                );
            };
            is $robots->delay_for('http://example.com/some/path'), 10;
            is $robots->delay_for('http://example.com/some/path', 1000), 10000;
        };

        do {
            my $robots = $Class->new(agent => 'GuestBot');
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('multiple_agent'),
                );
            };
            is $robots->delay_for('http://example.com/other/some/path'), 0.5;
            is $robots->delay_for('http://example.com/some/path', 1000), 500;
        };

        do {
            my $robots = $Class->new(agent => 'Unknown');
            lives_ok {
                $robots->parse(
                    'http://example.com/robots.txt',
                    _fixture('multiple_agent'),
                );
            };
            is $robots->delay_for('http://example.com/'), 5;
            is $robots->delay_for('http://example.com/', 1000), 5000;
        };
    };

    subtest 'Format' => sub {
        my $cases = {
            delay_milliseconds => 200,
            delay_zero => 0,
            delay_floating_zero => 0,
            delay_invalid => undef,
            rate_floating => 3000,
            rate_zero => 0,
            rate_floating_zero => 0,
            rate_zero_division => undef,
            rate_floating_zero_division => undef,
            rate_invalid => undef,
        };
        for my $name (keys %$cases) {
            subtest $name => sub {
                my $robots = $Class->new(agent => 'TestBot');
                lives_ok {
                    $robots->parse(
                        'http://example.com/robots.txt',
                        _fixture($name),
                    );
                };
                is $robots->delay_for('http://example.com/', 1000), $cases->{$name};
            };
        }
    };
}

__PACKAGE__->runtests;

__DATA__
@@ single_agent

User-agent: TestBot

Allow: /some/allowed/path
Disallow: /some/disallowed/path
Disallow: /some
Allow: /some/other/path
Allow: http://example.com/absolute/path
Disallow: https://example.com/ssl/path

@@ multiple_agent

User-agent: *

Disallow: /
Request-rate: 1/5

User-agent: GuestBot

Disallow: /some/other/path
Request-rate: 2/1

User-agent: TestBot

Allow: /some/allowed/path
Disallow: /some/disallowed/path
Disallow: /some
Allow: /some/other/path
Allow: http://example.com/absolute/path
Disallow: https://example.com/ssl/path
Crawl-delay: 10

@@ no_agent

Allow: /some/allowed/path
Disallow: /some/disallowed/path
Disallow: /some
Allow: /some/other/path
Allow: http://example.com/absolute/path
Disallow: https://example.com/ssl/path

@@ extended

Allow: /*allowed*
Disallow: /

@@ delay_milliseconds
Crawl-delay: 0.2

@@ delay_zero
Crawl-delay: 0

@@ delay_floating_zero
Crawl-delay: 0.0

@@ delay_invalid
Crawl-delay: a

@@ rate_floating
Request-rate: 0.5/1.5

@@ rate_zero
Request-rate: 2/0

@@ rate_floating_zero
Request-rate: 2/0.0

@@ rate_zero_division
Request-rate: 0/2

@@ rate_floating_zero_division
Request-rate: 0.0/2

@@ rate_invalid
Request-rate: x/3
