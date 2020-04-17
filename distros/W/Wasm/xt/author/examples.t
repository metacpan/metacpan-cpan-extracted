use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Test::Script';
use Test::Script;
use File::Glob qw( bsd_glob );

skip_all 'not tested with ciperl:static' if defined $ENV{CIPSTATIC} && $ENV{CIPSTATIC} eq 'true';

foreach my $example (bsd_glob 'examples/*.pl')
{
  my $out = '';
  my $err = '';
  script_compiles $example;
  script_runs $example, { stdout => \$out, stderr => \$err };
  note "[out]\n$out" if $out ne '';
  note "[err]\n$err" if $err ne '';
}

foreach my $example (bsd_glob 'examples/synopsis/*.pl')
{
  my $out = '';
  my $err = '';
  script_compiles $example;
  script_runs $example, { stdout => \$out, stderr => \$err };
  note "[out]\n$out" if $out ne '';
  note "[err]\n$err" if $err ne '';
}

done_testing;
