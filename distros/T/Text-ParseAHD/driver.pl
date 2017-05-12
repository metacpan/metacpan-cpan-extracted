#!/usr/bin/perl
#use base qw(Text::ParseAHD::Base);
use Text::ParseAHD;
#use Text::ParseAHD::Word;

$fileName= '</home/roger/projects/comprehension/dictionary/dictionary.reference.com/browse/cat';
open INFILE,$fileName;
$text = join('',<INFILE>);

my $parser = Text::ParseAHD->new({'html',$text,'word', 'cat'});

$parser->parse_html();

#print $text;
