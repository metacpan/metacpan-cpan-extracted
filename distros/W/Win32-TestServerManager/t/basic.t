use strict;
use warnings;
use Test::More;
use Win32::TestServerManager;

my $plan = 0;
my @tests;

my $manager = Win32::TestServerManager->new;

my $sleep_server_source = <<'SERVER';
#!perl
use strict;
sleep 100;
SERVER

# spawn ready-made perl script
test( test => 't/script/sleep.pl' );

# you can put args into an optional hash
test( test => { args => 't/script/sleep.pl' } );

# on the fly perl script
test_on_the_fly( test_on_the_fly => '',
  { create_server_with => $sleep_server_source }
);

# you can omit blank args
test_on_the_fly( test_on_the_fly =>
  { create_server_with => $sleep_server_source }
);

# you can pass coderef, which would be parsed by B::Deparse
test_on_the_fly( test_on_the_fly =>
  { create_server_with => \&sleep_server_func }
);

# and you can pass an anonymous subroutine.
test_on_the_fly( test_on_the_fly =>
  { create_server_with => sub {
    use strict;
    sleep 100;
  }}
);

plan tests => $plan;
foreach my $test (@tests) { $test->() }

sub test {
  my ($id, @args) = @_;

  $plan += 6;

  push @tests, sub {
    ok !defined $manager->instance($id), "there should be no $id instance";
    ok !defined $manager->process($id), "and there should be no $id process";
    ok scalar $manager->instances == 0, 'they should not be autovivified';

    eval { $manager->spawn( $id => @args ); };
    ok !$@, "$id server is launched successfully";

    ok $manager->pid($id) > 0, 'and the pid is positive';

    $manager->kill($id);

    ok scalar $manager->instances == 0, 'and there is no instances';
  };
}

sub test_on_the_fly {
  my ($id, @args) = @_;

  $plan += 8;

  push @tests, sub {
    ok !defined $manager->instance($id), "there should be no $id instance";
    ok !defined $manager->process($id), "and there should be no $id process";
    ok scalar $manager->instances == 0, 'they should not be autovivified';

    eval { $manager->spawn( $id => @args ); };
    ok !$@, "$id server is launched successfully";

    ok $manager->pid($id) > 0, 'and the pid is positive';

    my $instance = $manager->instance($id);

    ok -f $instance->{tmpfile}, 'temporary file exists';

    $manager->kill($id);

    ok !-f $instance->{tmpfile}, 'temporary file is deleted';

    ok scalar $manager->instances == 0, 'and there is no instances';
  };
}

sub sleep_server_func {
  use strict;
  sleep 100;
}
