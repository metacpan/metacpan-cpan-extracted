# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/text_similarity.t'
# Note that because of the file paths used this must be run from the 
# directory in which /t resides 
#
# Last modified by : $Id: text_similarity.t,v 1.1.1.1 2013/06/26 02:38:12 tpederse Exp $
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;

# set up file access in an OS neutral way
use File::Spec;

$text_similarity_pl = File::Spec->catfile ('bin','text_similarity.pl');
ok (-e $text_similarity_pl);

$stoplist_txt = File::Spec->catfile ('samples','stoplist-nsp.regex');
ok (-e $stoplist_txt);

$file1_txt = File::Spec->catfile ('t','file1.txt');
ok (-e $file1_txt);

$file11_txt = File::Spec->catfile ('t','file11.txt');
ok (-e $file11_txt);

$file2_txt = File::Spec->catfile ('t','file2.txt');
ok (-e $file2_txt);

$file22_txt = File::Spec->catfile ('t','file22.txt');
ok (-e $file22_txt);

# use this to find Text::Similarity::Overlaps module

$inc = "-Iblib/lib";

# ---------------------------------------------------------------------
# test default operation with two different files 

$output = `$^X $inc $text_similarity_pl --type Text::Similarity::Overlaps $file1_txt $file2_txt`; 
chomp $output;

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization

$output = `$^X $inc $text_similarity_pl --nonormalize --type Text::Similarity::Overlaps $file1_txt $file2_txt`; 
chomp $output;

is ($output, 40, "basic file comparison with nonormalize");

# ---------------------------------------------------------------------
# test two different files w normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --type Text::Similarity::Overlaps $file1_txt $file2_txt`; 
chomp $output;

# result is around 

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --nonormalize --type Text::Similarity::Overlaps $file1_txt $file2_txt`; 
chomp $output;

# result is around 

is ($output, 21, "basic file comparison with nonormalize and stoplist");

# ---------------------------------------------------------------------
# same tests as above, except use one file that has all content on one line
# ---------------------------------------------------------------------
# test default operation with two different files 

$output = `$^X $inc $text_similarity_pl --type Text::Similarity::Overlaps $file1_txt $file22_txt`; 
chomp $output;

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization

$output = `$^X $inc $text_similarity_pl --nonormalize --type Text::Similarity::Overlaps $file1_txt $file22_txt`; 
chomp $output;

is ($output, 40, "basic file comparison with nonormalize");

# ---------------------------------------------------------------------
# test two different files w normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --type Text::Similarity::Overlaps $file1_txt $file22_txt`; 
chomp $output;

# result is around 

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --nonormalize --type Text::Similarity::Overlaps $file1_txt $file22_txt`; 
chomp $output;

# result is around 

is ($output, 21, "basic file comparison with nonormalize and stoplist");

# ---------------------------------------------------------------------
# same tests as above, except both files have all content on one line
# ---------------------------------------------------------------------
# test default operation with two different files 

$output = `$^X $inc $text_similarity_pl --type Text::Similarity::Overlaps $file11_txt $file22_txt`; 
chomp $output;

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization

$output = `$^X $inc $text_similarity_pl --nonormalize --type Text::Similarity::Overlaps $file11_txt $file22_txt`; 
chomp $output;

is ($output, 40, "basic file comparison with nonormalize");

# ---------------------------------------------------------------------
# test two different files w normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --type Text::Similarity::Overlaps $file11_txt $file22_txt`; 
chomp $output;

# result is around 

# result is around .5

cmp_ok ($output, '>', .4);
cmp_ok ($output, '<', .6);

# ---------------------------------------------------------------------
# test two different files and no normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --nonormalize --type Text::Similarity::Overlaps $file11_txt $file22_txt`; 
chomp $output;

# result is around 

is ($output, 21, "basic file comparison with nonormalize and stoplist");


# ---------------------------------------------------------------------
# same tests as above, except files are identical
# ---------------------------------------------------------------------
# test default operation with two different $files 

$output = `$^X $inc $text_similarity_pl --type Text::Similarity::Overlaps $file1_txt $file1_txt`; 
chomp $output;

# result is 1 

is ($output, 1, "test on identical files");

# ---------------------------------------------------------------------
# test two different files and no normalization

$output = `$^X $inc $text_similarity_pl --nonormalize --type Text::Similarity::Overlaps $file1_txt $file1_txt`; 
chomp $output;

is ($output, 80, "basic file comparison with nonormalize on identical files");

# ---------------------------------------------------------------------
# test two different files w normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --type Text::Similarity::Overlaps $file1_txt $file1_txt`; 
chomp $output;

# result is 1

is ($output, 1, "test on identical files w stoplist");

# ---------------------------------------------------------------------
# test two different files and no normalization and stoplist

$output = `$^X $inc $text_similarity_pl --stoplist $stoplist_txt --nonormalize --type Text::Similarity::Overlaps $file1_txt $file1_txt`; 
chomp $output;

# result is around 

is ($output, 44, "basic file comparison with nonormalize and stoplist");



