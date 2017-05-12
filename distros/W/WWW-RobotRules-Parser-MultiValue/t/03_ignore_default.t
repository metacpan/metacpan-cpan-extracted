package t::ignore_default;

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
    subtest 'Allow /' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('allow_root'),
            );
        };
        ok $robots->allows('http://example.com/');
        ok $robots->allows('http://example.com/some/path');
    };

    subtest 'Allow /some/path' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('allow_subdir'),
            );
        };
        ok $robots->allows('http://example.com/some/path');
    };

    subtest 'Disallow /' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('disallow_root'),
            );
        };
        ok !$robots->allows('http://example.com/');
        ok !$robots->allows('http://example.com/some/path');
    };

    subtest 'Disallow /some/path' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('disallow_subdir'),
            );
        };
        ok $robots->allows('http://example.com/');
        ok !$robots->allows('http://example.com/some/path');
    };

    subtest 'Unspecified' => sub {
        my $robots = $Class->new(agent => 'Unknown/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('allow_root'),
            );
        };
        ok $robots->allows('http://example.com/');
        ok $robots->allows('http://example.com/some/path');

    };
}

sub delay_for : Tests {
    subtest 'Crawl-delay' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('crawl_delay'),
            );
        };
        is $robots->delay_for('http://example.com/some/path'), 2;
        is $robots->delay_for('http://example.com/some/path', 1000), 2000;
    };

    subtest 'Request-rate' => sub {
        my $robots = $Class->new(agent => 'TestBot/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('request_rate'),
            );
        };
        is $robots->delay_for('http://example.com/some/path'), 2;
        is $robots->delay_for('http://example.com/some/path', 1000), 2000;
    };

    subtest 'Unspecified' => sub {
        my $robots = $Class->new(agent => 'Unknown/1.0', ignore_default => 1);
        lives_ok {
            $robots->parse(
                'http://example.com/robots.txt',
                _fixture('crawl_delay'),
            );
        };
        is $robots->delay_for('http://example.com/some/path'), undef;
        is $robots->delay_for('http://example.com/some/path', 1000), undef;

    };
}

__PACKAGE__->runtests;

__DATA__
@@ allow_root

User-agent: *
Disallow: /

User-agent: TestBot
Allow: /

User-agent: OtherBot
Disallow: /

@@ allow_subdir

User-agent: *
Disallow: /

User-agent: TestBot
Allow: /some/path

User-agent: OtherBot
Disallow: /some/path

@@ disallow_root

User-agent: *
Allow: /

User-agent: TestBot
Disallow: /

User-agent: OtherBot
Allow: /

@@ disallow_subdir

User-agent: *
Allow: /

User-agent: TestBot
Disallow: /some/path

User-agent: OtherBot
Allow: /some/path

@@ crawl_delay

User-agent: *
Crawl-delay: 5
Request-rate: 1/5

User-agent: TestBot
Crawl-delay: 2

User-agent: OtherBot
Crawl-delay: 10

@@ request_rate

User-agent: *
Crawl-delay: 5
Request-rate: 1/5

User-agent: TestBot
Request-rate: 1/2

User-agent: OtherBot
Request-rate: 1/10
