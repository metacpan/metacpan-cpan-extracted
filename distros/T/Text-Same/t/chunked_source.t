#!perl -T

use Test::More tests => 8;
use Text::Same::ChunkedSource;

my @t1 =
  ("",
   "dummy text0",
   "dummy TEXT1",
   "dummy text2",
   "",
   "dummy text3",
   " dummy text4",
   "dummy text5 ",
   "dummy    text6",
   " dummy    text7",
   " dummy    text8 ",
   "  dummy    text9 ",
   "dummy    text9 ",
   "dummy    text10  ",
   "text11",
   "text12 ABCDEF ghijkl",
   "",
   "",
   "text13",
   "text14",
   "");

my %expected =
  (  # key SPACE,BLANKS,CASE
   "0,0,0" => ["",
               "dummy text0",
               "dummy TEXT1",
               "dummy text2",
               "",
               "dummy text3",
               " dummy text4",
               "dummy text5 ",
               "dummy    text6",
               " dummy    text7",
               " dummy    text8 ",
               "  dummy    text9 ",
               "dummy    text9 ",
               "dummy    text10  ",
               "text11",
               "text12 ABCDEF ghijkl",
               "",
               "",
               "text13",
               "text14",
               ""],
   "0,0,1" => ["",
               "dummy text0",
               "dummy text1",
               "dummy text2",
               "",
               "dummy text3",
               " dummy text4",
               "dummy text5 ",
               "dummy    text6",
               " dummy    text7",
               " dummy    text8 ",
               "  dummy    text9 ",
               "dummy    text9 ",
               "dummy    text10  ",
               "text11",
               "text12 abcdef ghijkl",
               "",
               "",
               "text13",
               "text14",
               ""],
   "0,1,0" => ["dummy text0",
               "dummy TEXT1",
               "dummy text2",
               "dummy text3",
               " dummy text4",
               "dummy text5 ",
               "dummy    text6",
               " dummy    text7",
               " dummy    text8 ",
               "  dummy    text9 ",
               "dummy    text9 ",
               "dummy    text10  ",
               "text11",
               "text12 ABCDEF ghijkl",
               "text13",
               "text14"],
   "0,1,1" => ["dummy text0",
               "dummy text1",
               "dummy text2",
               "dummy text3",
               " dummy text4",
               "dummy text5 ",
               "dummy    text6",
               " dummy    text7",
               " dummy    text8 ",
               "  dummy    text9 ",
               "dummy    text9 ",
               "dummy    text10  ",
               "text11",
               "text12 abcdef ghijkl",
               "text13",
               "text14"],
   "1,0,0" => ["",
               "dummy text0",
               "dummy TEXT1",
               "dummy text2",
               "",
               "dummy text3",
               "dummy text4",
               "dummy text5",
               "dummy text6",
               "dummy text7",
               "dummy text8",
               "dummy text9",
               "dummy text9",
               "dummy text10",
               "text11",
               "text12 ABCDEF ghijkl",
               "",
               "",
               "text13",
               "text14",
               ""],
   "1,0,1" => ["",
               "dummy text0",
               "dummy text1",
               "dummy text2",
               "",
               "dummy text3",
               "dummy text4",
               "dummy text5",
               "dummy text6",
               "dummy text7",
               "dummy text8",
               "dummy text9",
               "dummy text9",
               "dummy text10",
               "text11",
               "text12 abcdef ghijkl",
               "",
               "",
               "text13",
               "text14",
               ""],
   "1,1,0" => ["dummy text0",
               "dummy TEXT1",
               "dummy text2",
               "dummy text3",
               "dummy text4",
               "dummy text5",
               "dummy text6",
               "dummy text7",
               "dummy text8",
               "dummy text9",
               "dummy text9",
               "dummy text10",
               "text11",
               "text12 ABCDEF ghijkl",
               "text13",
               "text14"],
   "1,1,1" => ["dummy text0",
               "dummy text1",
               "dummy text2",
               "dummy text3",
               "dummy text4",
               "dummy text5",
               "dummy text6",
               "dummy text7",
               "dummy text8",
               "dummy text9",
               "dummy text9",
               "dummy text10",
               "text11",
               "text12 abcdef ghijkl",
               "text13",
               "text14"],
  );

my $cs1 = new Text::Same::ChunkedSource(chunks=>\@t1);

sub array_comp(\@\@)
{
  my ($ar1, $ar2) = @_;
  my @a1 = @$ar1;
  my @a2 = @$ar2;
  if (scalar(@a1) == scalar(@a2)) {
    for (my $i = 0; $i < scalar(@a1); $i++) {
      if ($a1[$i] ne $a2[$i]) {
        return 0;
      }
    }
    return 1;
  } else {
    return 0;
  }
}

for my $ignore_space (0..1) {
  for my $ignore_blanks (0..1) {
    for my $ignore_case (0..1) {

      my @comp_array = @{$expected{"$ignore_space,$ignore_blanks,$ignore_case"}};

      my $options = { ignore_case=>$ignore_case, ignore_blanks=>$ignore_blanks,
                      ignore_space=>$ignore_space };

      my @cs1_chunk_hashes =
        map {
          my $text = ($cs1->get_all_chunks)[$_];
          Text::Same::ChunkedSource::hash($options, $text)
        } @{$cs1->get_filtered_chunk_indexes($options)};
      my @comp_chunk_hashes = map {Text::Same::ChunkedSource::hash({}, $_)} @comp_array;

      ok(array_comp(@cs1_chunk_hashes, @comp_chunk_hashes));
    }
  }
}
