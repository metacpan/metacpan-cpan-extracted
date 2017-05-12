use strict;
use warnings;
use Test::Tester;
use Test::More tests => 4;
use Test::Script;

script_runs 't/bin/print.pl';

subtest 'stdout' => sub {
  plan tests => 8;

  subtest 'is' => sub {
    check_test( sub {
        script_stdout_is "Standard Out\nsecond line\n";
      }, {
        ok => 1,
        name => 'stdout matches',
      },
      'script_stdout_is',
    );
  };

  subtest 'isnt' => sub {
    check_test( sub {
        script_stdout_isnt "XXXX";
      }, {
        ok => 1,
        name => 'stdout does not match',
      },
      'script_stdout_isnt',
    );
  };

  subtest 'not is' => sub {
    my(undef, $r) = check_test( sub {
        script_stdout_is "XXX",
      }, {
        ok => 0,
        name => 'stdout matches',
      },
      'script_stdout_is',
    );
    note $r->{diag};    
  };

  subtest 'not isnt' => sub {
    my(undef, $r) = check_test( sub {
        script_stdout_isnt "Standard Out\nsecond line\n";;
      }, {
        ok => 0,
        name => 'stdout does not match',
      },
      'script_stdout_isnt',
    );
    note $r->{diag};    
  };

  subtest 'like' => sub {

    check_test( sub {
        script_stdout_like qr{tandard Ou};
      }, {
        ok => 1,
        name => 'stdout matches',
      },
      'script_stdout_like',
    );
    
  };

  subtest 'not like' => sub {

    my(undef, $r) = check_test( sub {
        script_stdout_like qr{XXXX};
      }, {
        ok => 0,
        name => 'stdout matches',
      },
      'script_stdout_like',
    );

    note $r->{diag};    
    
  };

  subtest 'unlike' => sub {

    check_test( sub {
        script_stdout_unlike qr{XXXX};
      }, {
        ok => 1,
        name => 'stdout does not match',
      },
      'script_stdout_unlike',
    );
    
  };

  subtest 'not unlike' => sub {

    my(undef, $r) = check_test( sub {
        script_stdout_unlike qr{tandard Ou};
      }, {
        ok => 0,
        name => 'stdout does not match',
      },
      'script_stdout_unlike',
    );
    
    note $r->{diag};    
  };

};

subtest 'stderr' => sub {
  plan tests => 8;

  subtest 'is' => sub {
    check_test( sub {
        script_stderr_is "Standard Error\nanother line\n";
      }, {
        ok => 1,
        name => 'stderr matches',
      },
      'script_stderr_is',
    );
  };

  subtest 'isnt' => sub {
    check_test( sub {
        script_stderr_isnt "XXXX";
      }, {
        ok => 1,
        name => 'stderr does not match',
      },
      'script_stderr_isnt',
    );
  };

  subtest 'not is' => sub {
    my(undef, $r) = check_test( sub {
        script_stderr_is "XXX",
      }, {
        ok => 0,
        name => 'stderr matches',
      },
      'script_stderr_is',
    );
    note $r->{diag};    
  };

  subtest 'not isnt' => sub {
    my(undef, $r) = check_test( sub {
        script_stderr_isnt "Standard Error\nanother line\n";;
      }, {
        ok => 0,
        name => 'stderr does not match',
      },
      'script_stderr_isnt',
    );
    note $r->{diag};    
  };

  subtest 'like' => sub {

    check_test( sub {
        script_stderr_like qr{tandard Er};
      }, {
        ok => 1,
        name => 'stderr matches',
      },
      'script_stderr_like',
    );
    
  };

  subtest 'not like' => sub {

    my(undef, $r) = check_test( sub {
        script_stderr_like qr{XXXX};
      }, {
        ok => 0,
        name => 'stderr matches',
      },
      'script_stderr_like',
    );

    note $r->{diag};    
    
  };

  subtest 'unlike' => sub {

    check_test( sub {
        script_stderr_unlike qr{XXXX};
      }, {
        ok => 1,
        name => 'stderr does not match',
      },
      'script_stderr_unlike',
    );
    
  };

  subtest 'not unlike' => sub {

    my(undef, $r) = check_test( sub {
        script_stderr_unlike qr{tandard Er};
      }, {
        ok => 0,
        name => 'stderr does not match',
      },
      'script_stderr_unlike',
    );
    
    note $r->{diag};    
  };

};

subtest 'code ref' => sub {

  my $stdout = '';
  my $stderr = '';

  script_runs 't/bin/print.pl', { stdout => \$stdout, stderr => \$stderr };

  is $stdout, "Standard Out\nsecond line\n";
  is $stderr, "Standard Error\nanother line\n";

};
