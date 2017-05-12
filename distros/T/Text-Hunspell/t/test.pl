#!/usr/bin/perl -w
# first install perl-devel
#  then install Text::Hunspell
#
use Text::Hunspell;
use Data::Dumper;
    my $curDir;
    $currDir = `pwd`;
    chomp $currDir;
 #   print $currDir."/test.aff","\n";
   my $affloc = "$currDir/t/test.aff";
   my $dicloc = "$currDir/t/test.dic";
   if(!(-e $affloc) || !(-e $dicloc)){
     $affloc = "$currDir/test.aff";
     $dicloc = "$currDir/test.dic";
   }
   if(!(-e $affloc) || !(-e $dicloc)){
      die "test.aff or test.dic not found- dieing\n";
   }
   print $affloc." ".$dicloc."\n";
   my $speller = Text::Hunspell->new($affloc, $dicloc);

    die unless $speller;

    # Set some words
    my $word = "lótól";
    my $word1 = "lóotól";
    my $misspelled = "lóo";
    my $stem = "ló";
#    my $word = "romtól";
#    my $word1 = "romnak";
#    my $misspelled = "romtóol";
#    my $stem = "rom";
    my $stem1 = "haj";
    my $count, $i;
    my $res;

    # check  word & word1
    print $speller->check( $word )
          ? "$word found\n"
          : "$word not found!\n";
    print $speller->check( $word1 )
          ? "$word1 found\n"
          : "$word1 not found!\n";

    # lookup correction for bad word
    my @suggestions;
    @suggestions = $speller->suggest( $misspelled );
    print $misspelled.": Suggest result\n";
    print Data::Dumper::Dumper( \@suggestions ); 

    # check morphological analysis for ABL class word
    @suggestions = $speller->analyze($word);
    print $word.": Analyze result\n";
    print Data::Dumper::Dumper( \@suggestions ); 

    # check morphological analysis for stem class word
    @suggestions = $speller->analyze($stem);
    print $stem.": Analyze result\n";
    print Data::Dumper::Dumper( \@suggestions ); 
 
    # Test here generator for morphological modification (NOM->ACC)
    @suggestions = $speller->analyze($stem);
    $count = @suggestions;
    print "cnt:".$count." element count:".$#suggestions." ".$stem.": Analyze result\n";
    print Data::Dumper::Dumper( \@suggestions ); 

    # modify analyze output for required class (ACC)
    for($i = 0; $i < $count; $i++){
       $res = @suggestions[$i];
       $res =~ s/NOM/ACC/g;
       print "res:".$res."\n";
       @suggestions[$i] = $res;
    }
    print Data::Dumper::Dumper( \@suggestions ); 
    # generate ACC class of stem
    @suggestions = $speller->generate2($stem, \@suggestions);
    print "generate2 result\n";
    print Data::Dumper::Dumper( \@suggestions ); 
    # end of generator for morphological modification (NOM->ACC) test 
    
    # stem test
    @suggestions = $speller->stem($word);
    print $word.": Stem result\n";
    print Data::Dumper::Dumper( \@suggestions ); 
 
    # test generator for mrphological modification, modify $stem like $word
    @suggestions = $speller->generate($stem, $word);
    print $stem." ".$word.": Generate result\n";
    print Data::Dumper::Dumper( \@suggestions ); 


    $speller->delete($speller);
    print "1..3\n";
    print "ok\n";
    print "ok\n";
    print "ok\n";

