use Test2::V0 -no_srand => 1;
use Test::Script;
use File::Temp qw( tempdir );
use Data::Dumper qw( Dumper );
use Probe::Perl;

# Use the Perl interpreter as the program since it's the only one we know
# exists.  The files in t/bin do not use any modules, so we don't have
# to worry about passing @INC down.
my $perl = Probe::Perl->find_perl_interpreter() or die "Can't find perl";

subtest 'script_fails' => sub {
  my $rv;
  my $events;

  is(
    $events = intercept {
      $rv = script_fails( ['t/bin/liveordie.pl', 'fail', 111 ], { exit => 111 }) },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'Script t/bin/liveordie.pl fails';
      };
      end;
    },
    'script that failes with expected exit code passes .',
  );

  $events = intercept {
    $rv = script_fails('t/bin/liveordie.pl', {exit=>255})};
  is( $events->[0]{pass}, 0, 'script that lives fails script_fails');

};

subtest exception => sub {
  my $events;

  $events = intercept { program_fails( [$perl, 't/bin/missing.pl'],{ exit => 255 } ) };
  is( $events->[0]{pass}, 0, 'missing program failed for program_fails');

  like (
    dies {
      script_fails( ['t/bin/liveordie.pl', 'die' ], undef, 'test named X') },
    qr/exit is a mandatory option/,
    'exit is a mandatory option for script_fails'
  );

  like (
    dies { program_fails( [$perl, 't/bin/missing.pl'], 'test named X' ) },
    # dies sub { program_fails( [$perl, 't/bin/missing.pl'], 'test named X'},
    qr/exit is a mandatory option for program_fails/,
    'exit is a mandatory option for program_fails'
  );
};

subtest 'program_fails' => sub {
  my $events;

  $events = intercept {
      program_fails( [ $perl, 't/bin/missing.pl' ], { exit => 0 } )
  };
  is( $events->[0]{pass}, 0, 'missing program failed for program_fails' );
  is( $events->[0]{name},
      'program_fails', 'testname set to program_fails when none provided',
  );
  program_fails(
      [ $perl, 't/bin/liveordie.pl', 'fail', 16 ],
      { exit => 16 },
      'parameters in array'
  );

  program_fails(
      ["$perl t/bin/liveordie.pl fail 17"],
      { exit => 17 },
      'parameters in string with program name'
  );

  $events = intercept {
      program_fails( [ $perl, 't/bin/liveordie.pl', 'fail', 18 ],
          { exit => 17 } )
  };
  is( $events->[0]{pass},
      0, 'program had wrong exit code is marked failure' );

};

done_testing;
