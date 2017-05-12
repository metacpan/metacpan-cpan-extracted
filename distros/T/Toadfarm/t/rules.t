use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Toadfarm -init;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

my @rules;

{
  no warnings 'redefine';
  my $skip_if = \&Toadfarm::_skip_if;
  *Toadfarm::_skip_if = sub {
    my @r = $skip_if->(@_);
    push @rules, @r;
    return @r;
  };
}

mount 't::lib::Test' => {
  'config'         => {bar => 123},
  'mount_point'    => '/foo',
  'remote_address' => '10.10.10.10',
  'remote_port'    => qr{8000},
  'Host'           => 'te.st',
  'X-Request-Base' => 'http:/domain.com/foo',
};
start;

my @match = (
  qr{return 0 unless \+\(\$h->header\('Host'\) \|\| ''\) eq 'te\.st';},
  qr{return 0 unless \+\(\$_\[1\]->tx->remote_port \|\| ''\) \=\~ \/\D*8000\D*\/;},
  qr{return 0 unless \+\(\$_\[1\]->tx->remote_address \|\| ''\) eq '10\.10\.10\.10';},
  qr{return 0 unless \+\(\$h->header\('X-Request-Base'\) \|\| ''\) eq 'http:\/domain\.com\/foo';},
);

RULE:
for my $r (@rules) {
  for my $i (0 .. @match - 1) {
    next unless $r =~ $match[$i];
    ok 1, $r;
    splice @match, $i, 1, ();
    next RULE;
  }
  ok 0, $r;
}

is int(@match), 0, 'all rules matched';
ok 0, "not matched $_" for @match;

done_testing;
