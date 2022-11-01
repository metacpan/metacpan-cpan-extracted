use Test2::V0 -no_srand => 1;
use Test2::Tools::Rustfmt;

my $exit;

subtest rustfmt_ok => sub {

  subtest 'good' => sub {

    is
      intercept { $exit = rustfmt_ok 'corpus/rustgood.rs' },
      array {
        event Pass => sub {
          call name => 'rustfmt corpus/rustgood.rs';
        };
        end;
      };

    is
      $exit,
      T();

  };

  subtest 'bad' => sub {

    my $x;

    is
      $x = intercept { $exit = rustfmt_ok 'corpus/rustbad.rs' },
      array {
        event Fail => sub {
          call name => 'rustfmt corpus/rustbad.rs';
          call facet_data => hash {
            field info => array {
              item hash sub {
                field tag => 'DIAG';
                field details => match qr{rustfmt --check corpus/rustbad.rs};
                etc;
              };
              item hash sub {
                field tag => 'DIAG';
                field details => match qr{rustbad.rs};
                etc;
              };
              etc;
            };
            etc;
          };
        };
        end;
      };

    is
      $exit,
      F();

  };

  subtest 'list' => sub {

    is
      intercept { $exit = rustfmt_ok ['corpus/rustbad.rs','corpus/rustgood.rs'] },
      array {
        event Fail => sub {
          call name => 'rustfmt corpus/rustbad.rs corpus/rustgood.rs';
        };
        end;
      };

    is
      $exit,
      F();
  };

};

subtest cargo_fmt_ok => sub {

  subtest 'good' => sub {

    is
      intercept { $exit = cargo_fmt_ok 'corpus/cargogood' },
      array {
        event Pass => sub {
          call name => 'cargo fmt for corpus/cargogood';
        };
        end;
      };

    is
      $exit,
      T();

  };

  subtest 'bad' => sub {

    is
      intercept { $exit = cargo_fmt_ok 'corpus/cargobad' },
      array {
        event Fail => sub {
          call name => 'cargo fmt for corpus/cargobad';
          call facet_data => hash {
            field info => array {
              item hash sub {
                field tag => 'DIAG';
                field details => match qr{\+cd corpus/cargobad};
                etc;
              };
              item hash sub {
                field tag => 'DIAG';
                field details => match qr{cargo fmt};
                etc;
              };
              item hash sub {
                field tag => 'DIAG';
                field details => match qr{main.rs};
                etc;
              };
              etc;
            };
            etc;
          };
        };
        end;
      };

    is
      $exit,
      F();

  };

};

done_testing;


