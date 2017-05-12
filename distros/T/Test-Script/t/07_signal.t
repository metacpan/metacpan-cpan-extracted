use strict;
use warnings;
use Test::Tester;
use Test::More tests => 2;
use Test::Script;

subtest 'compiles' => sub {

  my(undef, $r) = check_test( sub {
      script_compiles( 't/bin/signal.pl' );
    }, {
      ok => 0,
    },
  );

  note $r->{diag};

};

subtest 'runs' => sub {

  my(undef, $r) = check_test( sub {
      script_runs( 't/bin/signal.pl' );
    }, {
      ok => 0,
    },
  );
  
  note $r->{diag};

};
