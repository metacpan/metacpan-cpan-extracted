package Test::SourceFile;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use Path::Tiny ();
use List::Util 1.29 qw( pairmap );
use base qw( Exporter );

our @EXPORT = qw( file splitter );

sub file ($name, $content)
{
  state $root;
  $root ||= Path::Tiny->tempdir;
  my $path = $root->child($name);
  $path->parent->mkpath;
  $path->spew_utf8($content);
  $path;
}

sub splitter
{
  state $splitter;
  $splitter ||= do {
    require Text::HumanComputerWords;
    my @args = pairmap { $a eq 'path_name' ? ('skip', $b) : ($a,$b) } Text::HumanComputerWords->default_perl;
    Text::HumanComputerWords->new(@args);
  };
}

1;
