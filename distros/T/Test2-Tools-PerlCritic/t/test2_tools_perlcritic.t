use Test2::V0 -no_srand => 1;
use Test2::Tools::PerlCritic;
use Perl::Critic ();
use experimental qw( signatures );

subtest 'BUILDARGS / BUILD' => sub {

  subtest 'files' => sub {

    is(
      Test2::Tools::PerlCritic->new( 'corpus/lib1/Foo.pm' ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'simple file',
    );

    is(
      Test2::Tools::PerlCritic->new( 'corpus/lib1' ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1';
      },
      'simple directory',
    );

    is(
      Test2::Tools::PerlCritic->new( ['corpus/lib1/Foo.pm', 'corpus/lib1/Bar.pm'] ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm corpus/lib1/Bar.pm';
      },
    );

    is(
      Test2::Tools::PerlCritic->new( ['corpus/lib1'] ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1';
      },
      'directory in array ref',
    );

    like(
      dies { Test2::Tools::PerlCritic->new() },
      qr/no files provided/,
      'no files provided',
    );

    like(
      dies { Test2::Tools::PerlCritic->new('corpus/lib1/Bogus.pm') },
      qr/not a file or directory: corpus\/lib1\/Bogus\.pm/,
      'bogus filename',
    );

  };

  subtest 'critic' => sub {

    my $critic = Perl::Critic->new;
    ref_is(
      Test2::Tools::PerlCritic->new('corpus/lib1', $critic)->critic,
      $critic,
      'pass through critic object',
    );

    ref_is_not(
      Test2::Tools::PerlCritic->new('corpus/lib1')->critic,
      $critic,
      'generate new critic',
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1'),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
      },
      'generate new critic correct class',
    );

  };

  subtest 'options' => sub {

    my %opts;
    my @opts;

    my $mock = mock 'Perl::Critic' => (
      around => [
        new => sub {
          my $orig = shift;
          my $class = shift;
          %opts = @_;
          @opts = @_;
          $class->$orig;
        },
      ],
    );

    Test2::Tools::PerlCritic->new('corpus/lib1', [ -foo => 1, -bar => 2 ]);
    is(\@opts, [ -foo =>1, -bar => 2 ], 'passing as array ref');

    Test2::Tools::PerlCritic->new('corpus/lib1', { -foo => 1, -bar => 2 });
    is(\%opts, { -foo =>1, -bar => 2 }, 'passing as hash ref');

    like(
      dies { Test2::Tools::PerlCritic->new('corpus/lib1', \"foo") },
      qr/options must be either an array or hash reference/,
      'do not accept non hash or array',
    );

  };

  subtest 'test name' => sub {

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm'),
      object {
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', 'override'),
      object {
        call test_name => 'override';
      },
      'override test name'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', Perl::Critic->new),
      object {
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name (positional)'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', Perl::Critic->new, 'override'),
      object {
        call test_name => 'override';
      },
      'override test name (positional)'
    );


  };

};

subtest 'perl_critic_ok' => sub {

  subtest 'pass' => sub {

    my $mock = mock 'Perl::Critic' => (
      override => [ critique => sub { () } ],
    );

    is(
      intercept { perl_critic_ok 'corpus/lib1/Foo.pm' },
      array {
        event Pass => sub {
          call name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
        };
        end;
      },
      'pass with default test name'
    );

    is(
      intercept { perl_critic_ok 'corpus/lib1/Foo.pm', 'override test name' },
      array {
        event Pass => sub {
          call name => 'override test name';
        };
        end;
      },
      'pass with override test name'
    );

  };

  subtest 'fail' => sub {

    my $critic = Perl::Critic->new(
      -only => 1,
    );
    $critic->add_policy( -policy => 'Perl::Critic::Policy::Foo::Bar' );

    is(
      intercept { perl_critic_ok 'corpus/lib1', $critic },
      array {
        event Fail => sub {
          call name => 'no Perl::Critic policy violations for corpus/lib1';
          call facet_data => hash {
            field info => [map {
              my %foo = ( debug => 1, tag => 'DIAG', details => $_ );
              \%foo;
            } (
              '',
              'Perl::Critic::Policy::Foo::Bar [sev 5]',
              'Foo Bar found',
              '    No diagnostics available',
              '',
              'found at corpus/lib1/Bar.pm line 1 column 1',
              'found at corpus/lib1/Baz.pm line 1 column 1',
              'found at corpus/lib1/Foo.pm line 1 column 1',
            )];
            etc;
          };
        };
      },
      'simple fail'
    );

  };

};

subtest 'hooks' => sub {

  subtest 'errors' => sub {

    is(
      dies { Test2::Tools::PerlCritic->new({ files => '.'})->add_hook("bogus" => sub {})},
      match qr/^unknown hook: bogus/,
      'does on invalid hook name'
    );

    is(
      dies { Test2::Tools::PerlCritic->new({ files => '.'})->add_hook("progressive_check" => "foo")},
      match qr/^hook is not a code reference/,
      'does on invalid hook name'
    );

    is(
      dies {
        Test2::Tools::PerlCritic
          ->new({ files => '.'})
          ->add_hook( progressive_check => sub {})
          ->add_hook( progressive_check => sub {})
      },
      match qr/^Only one progressive_check hook allowed/,
      'does not allow the same hook more than once',
    );

  };

  subtest 'progressive_check' => sub {

    subtest 'has legacy violation' => sub {

      my $test_critic = Test2::Tools::PerlCritic->new({
        critic => do {
          my $critic = Perl::Critic->new( -only => 1 );
          $critic->add_policy( -policy => 'Perl::Critic::Policy::Foo::Bar' );
          $critic;
        },
        files => 'corpus/lib1',
      });

      my %actual_args;

      $test_critic->add_hook( progressive_check => sub {
        $actual_args{$_[2]} = \@_;
        return 1;
      });

      is(
        intercept { $test_critic->perl_critic_ok },
        array {
          event Pass => sub {
            call name => 'no Perl::Critic policy violations for corpus/lib1';
          };
          event Note => sub {
            call message => $_;
          } for (
                '### The following violations were grandfathered from before ###',
                '### these polcies were applied and so should be fixed only  ###',
                '### when practical                                          ###',
                '',
                'Perl::Critic::Policy::Foo::Bar [sev 5]',
                'Foo Bar found',
                '    No diagnostics available',
                '',
                'found at corpus/lib1/Bar.pm line 1 column 1',
                'found at corpus/lib1/Baz.pm line 1 column 1',
                'found at corpus/lib1/Foo.pm line 1 column 1',
          );
        },
        'does not fail with legacy violations'
      );

      is(
        \%actual_args,
        hash {
          field 'corpus/lib1/Bar.pm' => array {
            item object {
              prop blessed => 'Test2::Tools::PerlCritic';
            };
            item 'Perl::Critic::Policy::Foo::Bar';
            item 'corpus/lib1/Bar.pm';
            item 1;
            end;
          };
          etc;
        },
        'got expected args',
      );

    };

    subtest 'partial legacy violations' => sub {

      my $test_critic = Test2::Tools::PerlCritic->new({
        critic => do {
          my $critic = Perl::Critic->new( -only => 1 );
          $critic->add_policy( -policy => 'Perl::Critic::Policy::Foo::Bar' );
          $critic;
        },
        files => 'corpus/lib1',
      });

      $test_critic->add_hook( progressive_check => sub ($test_critic, $policy, $filename, $count) {
        return $filename eq 'corpus/lib1/Bar.pm';
      });

      is(
        intercept { $test_critic->perl_critic_ok },
        array {
          event Fail => sub {
            call name => 'no Perl::Critic policy violations for corpus/lib1';
            call facet_data => hash {
              field info => [map {
                my %foo = ( debug => 1, tag => 'DIAG', details => $_ );
                \%foo;
              } (
                '',
                'Perl::Critic::Policy::Foo::Bar [sev 5]',
                'Foo Bar found',
                '    No diagnostics available',
                '',
                'found at corpus/lib1/Baz.pm line 1 column 1',
                'found at corpus/lib1/Foo.pm line 1 column 1',
              )];
              etc;
            };
          };
          event Note => sub {
            call message => $_;
          } for (
                '### The following violations were grandfathered from before ###',
                '### these polcies were applied and so should be fixed only  ###',
                '### when practical                                          ###',
                '',
                'Perl::Critic::Policy::Foo::Bar [sev 5]',
                'Foo Bar found',
                '    No diagnostics available',
                '',
                'found at corpus/lib1/Bar.pm line 1 column 1',
          );
        },
        'does not fail with legacy violations'
      );

    };

  };

  subtest 'cleanup' => sub {

    my $test_critic = Test2::Tools::PerlCritic->new({
      files => ['corpus/lib1'],
    });

    my @actual_args;
    my $count = 0;

    $test_critic->add_hook( cleanup => sub ($test_critic, $global) {
      push @actual_args, [ ref $test_critic, $global ];
      $count += 1;
    });

    $test_critic->add_hook( cleanup => sub {
      $count += 2;
    });

    undef $test_critic;

    is(
      \@actual_args,
      [ [ 'Test2::Tools::PerlCritic', F() ] ],
      'expected args',
    );

    is(
      $count,
      3,
      'called both cleanup hooks',
    );

  };

  subtest 'violations' => sub {

    my $test_critic = Test2::Tools::PerlCritic->new({
      critic => do {
        my $critic = Perl::Critic->new( -only => 1 );
        $critic->add_policy( -policy => 'Perl::Critic::Policy::Foo::Bar' );
        $critic;
      },
      files => 'corpus/lib1',
    });

    my @args;
    my $count = 0;

    $test_critic->add_hook( violations => sub {
      # count the number of violations which is
      # one less that the size of the argument
      # list since the first argument is the
      # test critic instance
      $count+= scalar(@_)-1;
      @args = @_;
    });

    intercept { $test_critic->perl_critic_ok };

    is(
      \@args,
      array {
        item object {
          prop blessed => 'Test2::Tools::PerlCritic';
        };
        item object {
          prop blessed => 'Perl::Critic::Violation';
        };
      },
      'expected argument types',
    );

    is(
      $count,
      3,
      'expected number of violations',
    );

  };

};

done_testing;

package main {}
package Perl::Critic::Policy::Foo::Bar {

  use base qw( Perl::Critic::Policy );
  use Perl::Critic::Utils qw( :booleans :severities );

  sub supported_parameters {
    return {
      name => 'foo_bar',
      description => 'A violation of the simple Foo Bar principal',
    };
  }

  sub default_severity { $SEVERITY_HIGHEST }
  sub default_themes { () }
  sub applies_to { 'PPI::Token::Word' }

  sub violates {
    my($self, $elem) = @_;
    if($elem->literal eq 'package')
    {
      return $self->violation( 'Foo Bar found', [29], $elem);
    }
    return;
  }

}

