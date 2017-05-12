use Test::More tests=>2;
BEGIN {
  use_ok(qw(Test::WWW::Simple));
}

like mech->agent(), qr/Windows/, "default agent";

