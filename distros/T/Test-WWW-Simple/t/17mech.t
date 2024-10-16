use Test::More tests=>2;
BEGIN {
  use_ok(qw(Test::WWW::Simple));
}

my $mech = mech();
isa_ok $mech,"WWW::Mechanize::Pluggable";
