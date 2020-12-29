use strict;
use warnings;
use File::Spec;
use File::Temp;
use ExtUtils::MakeMaker;

sub is_dot_installed {
  # 1: Create a temp file containing DOT commands.
  # The EXLOCK option is for BSD-based systems.
  # newdir() croaks() if it fails, which is what we want.
  my $temp_dir = File::Temp->newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
  my $gv_file = File::Spec->catfile($temp_dir, 'test.gv');
  open my $fh, ">", $gv_file or die "Can't create temp file: $!\n";
  print $fh "digraph graph_14 {node_14}\n" or die "Can't write to temp file: $!\n";
  close $fh or die "Can't close temp file: $!\n";
  my $stdout = `dot -Tsvg $gv_file`;
  die "Please install Graphviz from http://www.graphviz.org/\n" if $stdout !~ m|</svg>|;
}

is_dot_installed();

my $repo = 'graphviz-perl/Tk-GraphViz';
WriteMakefile(
  NAME => 'Tk::GraphViz',
  VERSION_FROM => 'lib/Tk/GraphViz.pm',
  PREREQ_PM => {
    Tk => '800.020',
  },
  ABSTRACT => 'Tk widget (derived from Canvas) for displaying graphs in the GraphViz format.',
  AUTHOR => 'Jeremy Slade <jeremy@jkslade.net>',
  EXE_FILES => [ glob 'scripts/*' ],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => "git\@github.com:$repo.git",
        web => "https://github.com/$repo",
      },
      bugtracker  => {
        web => "https://github.com/$repo/issues",
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      runtime => {
        recommends => {
          'Tk::MatchEntry' => '0.5',
        },
      },
      develop => {
        requires => {
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
        },
      },
    },
  },
);
