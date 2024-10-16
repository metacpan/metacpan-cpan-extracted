use Test::More tests=>5;
BEGIN {
  use_ok(qw(Test::WWW::Simple));
}

page_like('http://perl.org', qr/Perl/, "valid");
my $test_data = last_test;
ok $test_data->{ok}, "test was indeed ok";
ok $test_data->{actual_ok}, "literally said ok";
is $test_data->{name}, "valid", "right name";



