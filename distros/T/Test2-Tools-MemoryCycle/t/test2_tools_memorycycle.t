use Test2::V0 -no_srand => 1;
use Test2::Tools::MemoryCycle;

my $foo = { bar => 1 };

is
  intercept { memory_cycle_ok $foo },
  array {
    event 'Pass' => sub {
      call name => 'no memory cycle';
    };
    end;
  },
  'uncycled memory passes';

is
  intercept { memory_cycle_ok $foo, 'different message' },
  array {
    event 'Pass' => sub {
      call name => 'different message';
    };
    end;
  },
  'uncycled memory passes with a different name';

$foo->{baz} = sub {
  print $foo->{bar}, "\n";
};

my $events;

is
  $events = intercept { memory_cycle_ok $foo },
  array {
    event 'Fail' => sub {
      call name => 'no memory cycle';
    };
    end;
  },
  'cycled memory fails';

note "pass: @{[ $events->[0]->name ]}";
note "diag: $_" for map { $_->details } @{ $events->[0]->info };

done_testing;
