package t::ua;

# cpan
use parent qw(Test::Class);
use Test::More;

# lib
my $Class = 'WWW::RobotRules::Parser::MultiValue';

sub _require : Test(startup => 1) {
    use_ok $Class;
}

sub match_ua : Tests {
    subtest 'Simple' => sub {
        my $robots = $Class->new(agent => 'TestBot');
        is $robots->match_ua('*'), $Class->WILDCARD;
        is $robots->match_ua('TestBot'), $Class->ME;
        ok !$robots->match_ua('TestBot/1.1');
        ok !$robots->match_ua('GuestBot');
    };

    subtest 'Version' => sub {
        my $robots = $Class->new(agent => 'TestBot/2.0');
        is $robots->match_ua('*'), $Class->WILDCARD;
        is $robots->match_ua('TestBot'), $Class->ME;
        ok !$robots->match_ua('TestBot/1.1');
        ok !$robots->match_ua('GuestBot');
    };

    subtest 'Comments' => sub {
        my $robots = $Class->new(agent => 'TestBot/2.0 (some; comment)');
        is $robots->match_ua('*'), $Class->WILDCARD;
        is $robots->match_ua('TestBot'), $Class->ME;
        ok !$robots->match_ua('TestBot/1.1');
        ok !$robots->match_ua('GuestBot');
    };
}

__PACKAGE__->runtests;
