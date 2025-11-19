use utf8;
use Test2::V0 -no_srand => 1;
use Test2::Tools::PerlTidy qw( is_file_tidy run_tests );
use Path::Tiny qw( path );

subtest 'list files' => sub {

  is
    intercept { Test2::Tools::PerlTidy::list_files './corpus/not-there' },
    array {
      event Bail => sub {
        call reason => './corpus/not-there does not exist';
      };
      end;
    }
  ;

  is
    intercept { Test2::Tools::PerlTidy::list_files('./corpus/just-a-file') },
    array {
      event Bail => sub {
        call reason => './corpus/just-a-file is not a directory';
      };
      end;
    }
  ;

  is
    intercept { Test2::Tools::PerlTidy::list_files(exclude => 'string') },
    array {
      event Bail => sub {
        call reason => 'exclude must be an array';
      };
      end;
    }
  ;

  chdir 'corpus/list-files';

  is
    [Test2::Tools::PerlTidy::list_files('.')],
    [qw(
      Makefile.PL
      lib/Foo/Bar/Baz.pm
      t/foo_bar_baz.t
    )],
  ;

  is
    [Test2::Tools::PerlTidy::list_files(path => '.', exclude => [qr/\.pm$/])],
    [qw(
      Makefile.PL
      t/foo_bar_baz.t
    )],
  ;

  is
    [Test2::Tools::PerlTidy::list_files(path => '.', exclude => ['t/'])],
    [qw(
      Makefile.PL
      blib/no-match.pm
      lib/Foo/Bar/Baz.pm
    )],
  ;

  chdir '../..';

};

subtest 'load_file' => sub {

  is
    [Test2::Tools::PerlTidy::load_file],
    []
  ;

  is
    [Test2::Tools::PerlTidy::load_file 'corpus'],
    []
  ;

  is
    [Test2::Tools::PerlTidy::load_file 'corpus/not-there.txt'],
    []
  ;

  is
    [Test2::Tools::PerlTidy::load_file 'corpus/load-file'],
    ["this is a file (火雞)\n"]
  ;

};

subtest 'is_file_tidy' => sub {

  subtest 'bad file' => sub {
    my $ok;
    is
      intercept { $ok = is_file_tidy 'corpus/not-there.txt' },
      array {
        event Diag => sub {
          call message => "Unable to find or read 'corpus/not-there.txt'";
        };
        end;
      },
    ;
    is $ok, F();
  };

  subtest 'untidy file' => sub {
    my $ok;
    my $events;
    is
      $events = intercept { $ok = is_file_tidy 'corpus/messy_file.txt' },
      array {
        event Diag => sub {
          call message => "The file 'corpus/messy_file.txt' is not tidy";
        };
        event Diag => sub {
        };
        end;
      },
    ;
    is $ok, F();
    note "diagnostic as follows:";
    note $events->[0]->message;
    note $events->[1]->message;
  };

  subtest 'tidy file passes' => sub {
    my $ok;
    is
      intercept { $ok = is_file_tidy 'corpus/just-a-file' },
      [],
    ;
    is $ok, T();
  };

  subtest 'stderr' => sub {

    my $mock = mock 'Perl::Tidy' => (
      override => [
        perltidy => sub {
          my %args = @_;
          ${ $args{destination} } = ${ $args{source} };
          my $stderr = $args{stderr};
          print $stderr "Something wrong happened\n";
        },
      ],
    );

    my $ok;
    is
      intercept { $ok = is_file_tidy 'corpus/just-a-file' },
      array {
        event Diag => sub {
          call message => "perltidy reported the following errors:";
        };
        event Diag => sub {
          call message => "Something wrong happened\n";
        };
        end;
      },
    ;
    is $ok, F();

  };

};

subtest 'run_tests' => sub {

  is
    intercept { run_tests skip_all => 1 },
    array {
      event Plan => sub {
        call directive => 'SKIP';
        call reason => 'All tests skipped.';
      };
      end;
    }
  ;

  chdir 'corpus/list-files';

  is
    intercept { run_tests },
    array {
      event Plan => sub {
        call max => 3;
      };
      event Pass => sub {
        call name => "'$_'";
      } for qw( Makefile.PL lib/Foo/Bar/Baz.pm t/foo_bar_baz.t );
      end;
    }
  ;

  is
    intercept { run_tests no_plan => 1 },
    array {
      event Pass => sub {
        call name => "'$_'";
      } for qw( Makefile.PL lib/Foo/Bar/Baz.pm t/foo_bar_baz.t );
      end;
    }
  ;

  chdir '../fail';

  is
    intercept { run_tests },
    array {
      event Plan => sub {
        call max => 3;
      };
      event Pass => sub {
        call name => "'Makefile.PL'";
      };
      event Fail => sub {
        call name => "'lib/Foo/Bar/Baz.pm'";
        # TODO: check diagnostics
      };
      event Pass => sub {
        call name => "'t/foo_bar_baz.t'";
      };
      end;
    }
  ;

  chdir '../..'; 

};

done_testing
