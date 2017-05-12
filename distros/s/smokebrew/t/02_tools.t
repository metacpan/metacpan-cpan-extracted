use strict;
use warnings;
use Test::More qw[no_plan];
use File::Temp qw[tempdir];
use File::Path qw[rmtree];
use Perl::Version;
use App::SmokeBrew::Tools;

{
  my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

  my $fetchtests = 1;

  {
    # Check we can fetch a file from a CPAN mirror
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new( PeerAddr => 'cpan.hexten.net', PeerPort => 80, Timeout => 20 )
       or $fetchtests = 0;
  }

  SKIP: {
    skip "Can't talk to a CPAN mirror skipping fetch and extraction tests", 3 unless $fetchtests;

    my $foo = App::SmokeBrew::Tools->fetch('authors/01mailrc.txt.gz', $tmpdir);
    ok( $foo, 'Foo is okay' );
    ok( -e $foo, 'The file exists' );
    my $extract = App::SmokeBrew::Tools->extract( $foo, $tmpdir );
    ok( $extract, 'Extract is okay' );

  }

  my @perls = App::SmokeBrew::Tools->perls();
  ok( scalar @perls, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @perls;
    is( scalar @pvs, scalar @perls, 'Do the two perl arrays have the same number of elements');
  }
  my @devs = App::SmokeBrew::Tools->perls('dev');
  ok( scalar @devs, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @devs;
    is( scalar @pvs, scalar @devs, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { $_->version % 2 } @pvs ), scalar @devs, 'They are all dev releases' );
  }
  my @rels = App::SmokeBrew::Tools->perls('rel');
  ok( scalar @rels, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @rels;
    is( scalar @pvs, scalar @rels, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { !( $_->version % 2 ) } @pvs ), scalar @rels, 'They are all dev releases' );
  }
  my @recents = App::SmokeBrew::Tools->perls('recent');
  ok( scalar @recents, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @recents;
    is( scalar @pvs, scalar @recents, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { $_->numify >= 5.008009 } @pvs ), scalar @recents, 'They are all recent releases' );
  }
  my @moderns = App::SmokeBrew::Tools->perls('modern');
  ok( scalar @moderns, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @moderns;
    is( scalar @pvs, scalar @moderns, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { $_->numify >= 5.010000 } @pvs ), scalar @moderns, 'They are all modern releases' );
  }
  my @latests = App::SmokeBrew::Tools->perls('latest');
  ok( scalar @latests, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @latests;
    is( scalar @pvs, scalar @latests, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { $_->numify >= 5.008009 } @pvs ), scalar @latests, 'They are all latest releases' );
  }
  my @install = App::SmokeBrew::Tools->perls('perl-5.10.1');
  ok( scalar @install, 'We got something back' );
  {
    my @pvs = map { Perl::Version->new($_) } @install;
    is( scalar @pvs, scalar @install, 'Do the two perl arrays have the same number of elements');
    is( ( scalar grep { $_->numify == 5.010001 } @pvs ), scalar @install, 'It is the right Perl Version' );
  }
}

{
  ok( App::SmokeBrew::Tools->devel_perl('5.13.0'), 'It is a development perl' );
  ok( !App::SmokeBrew::Tools->devel_perl('5.12.0'), 'It is not a development perl' );
}

{
  is( App::SmokeBrew::Tools->perl_version('5.6.0'), 'perl-5.6.0', 'Formatted correctly' );
  is( App::SmokeBrew::Tools->perl_version('5.003_07'), 'perl5.003_07', 'Formatted correctly' );
}

{
  my $cwd = File::Spec->rel2abs('.');
  local $ENV{PERL5_SMOKEBREW_DIR} = $cwd;
  my $smdir = App::SmokeBrew::Tools->smokebrew_dir();
  is( $smdir, $cwd, 'The smokebrew_dir is okay' );
}
