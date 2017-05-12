use strict; $|++;

use XML::Comma::Pkg::Textsearch::Preprocessor_Fr;
use locale qw( fr );

my $what_word = shift || '';

my $matches   = 0;
my $unmatches = 0;

open ( FILE, "diffs.txt" ) || die "could not open diffs file: $!\n";

foreach my $line ( <FILE> ) {
  my ( $wrd, $target_stem, $stem );

  next if $line =~ /^#/;

  eval { 
    ( $wrd, $target_stem ) = get_pair ( $line ); 
  }; if ( $@ ) {
    print "$@\n";
    last;
  }

  next  if  ( $what_word and $wrd ne $what_word );

  ( $stem ) = 
    XML::Comma::Pkg::Textsearch::Preprocessor_Fr->stem ( $wrd );
#    XML::Comma::Pkg::Textsearch::Preprocessor_Fr::snowball_stem ( $wrd );
  if ( $stem ne $target_stem ) {
    printf ( " xx % 16.16s --> %16.16s (%s)\n", $wrd, $stem, $target_stem );
    $unmatches++;
     exit ( 0 );
  } else {
    printf ( "    % 16.16s --> %16.16s (%s)\n", $wrd, $stem, $target_stem);
    $matches++;
  }

}

close ( FILE );
print "good: $matches\n";
print "bad:  $unmatches\n";


sub get_pair {
  my $line = shift;

  unless ( $line =~ m|(\w+)\s+(\w+)| ) {
    die "bad line: $line\n";
  }
  return ( $1, $2 );
}






#  print join ( "\n", 
#               XML::Comma::Pkg::Textsearch::Preprocessor_Fr::suffixes() ) . "\n";

#  my ( $word, $rv_st, $rv_en, $r1_st, $r1_en, $r2_st, $r2_en ) =
#    XML::Comma::Pkg::Textsearch::Preprocessor_Fr::rv_r1_r2 ( shift );

#  print "word : $word\n";
#  print "rv_st: $rv_st\n";
#  print "rv_en: $rv_en\n";
#  print "r1_st: $r1_st\n";
#  print "r1_en: $r1_en\n";
#  print "r2_st: $r2_st\n";
#  print "r2_en: $r2_en\n";

