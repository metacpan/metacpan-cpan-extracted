use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script;
use File::Temp qw( tempdir );

# the first subtest replaces t/04_runs_good.t

subtest 'good' => sub {

  my $rv;
  
  is(
    intercept { $rv = script_runs 't/bin/good.pl' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'Script t/bin/good.pl runs';
      };
      end;
    },
    'script_runs t/bin/good.pl',
  );
  
  is $rv, T(), 'script_compiles_ok returns true as convenience';

  is(
    intercept { $rv = script_runs 't/bin/good.pl', 'It worked' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'It worked';
      };
      end;
    },
    'script_runs t/bin/good.pl It worked',
  );
  
  is $rv, T(), 'script_compiles_ok returns true as convenience';
  
  
};

subtest 'good' => sub {

  my $rv;
  
  is(
    intercept { $rv = script_runs 't/bin/four.pl' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'Script t/bin/four.pl runs';
      };
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {
        call message => match qr{4 - (?:Using.*\n# )?Standard Error\n};
      };
      end;
    },
    'script_runs t/bin/good.pl',
  );
  
  is $rv, F(), 'script_compiles_ok returns false as convenience';

  is(
    intercept { $rv = script_runs 't/bin/four.pl', 'It worked' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'It worked';
      };
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {
        call message => match qr{4 - (?:Using.*\n# )?Standard Error\n};
      };
      end;
    },
    'script_runs t/bin/good.pl It worked',
  );
  
  is $rv, F(), 'script_compiles_ok returns false as convenience';
  
  
};

subtest 'unreasonable number of libs' => sub {

  skip_all 'developer only test' unless $ENV{TEST_SCRIPT_DEV_TEST};

  local @INC = @INC;
  my $dir = tempdir( CLEANUP => 1 );
  for(map { File::Spec->catfile($dir, $_) } 1..1000000)
  {
    #mkdir;
    push @INC, $_;
  }
  
  script_runs 't/bin/good.pl';

};

done_testing;
