use lib qw( ../lib ); # -*- cperl -*- 

use strict;
use warnings;
use utf8;

use Test::More;
use File::Slurp::Tiny 'read_file';
use Test::Text::Sentence qw(split_sentences);

my $dir = 'text/en';
if ( !-e $dir ) {
  $dir =  "../text/en";
}

my @files = glob("$dir/*.md $dir/*.tex $dir/*.txt $dir/*.markdown)");

for my $f ( @files ) {
  my @sentences = split_sentences( read_file($f) );
  ok( @sentences, "Splits in sentences" );
  cmp_ok( $#sentences, ">=", 0, "There's at least one sentence");
}

done_testing;
