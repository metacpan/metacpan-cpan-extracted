use Test::Simple tests => 2;

require WWW::Facebook::FQL;
ok(1, 'loaded');
my $x = eval {
    new WWW::Facebook::FQL email => 'example@example.edu', pass => 'foo',
        key => 'deadbeef', secret => 'decafbad';
};

ok(!defined $x, 'bogus info => failure');
