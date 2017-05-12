#!/usr/bin/perl -w

use XML::Code;

my $content = new XML::Code ('content');
$content->version ('1.0');
$content->encoding ('Windows-1251');
$content->stylesheet ('test.xslt');

$content->{'level'} = "top";
my $sub_content = new XML::Code ('sub-content');
$content->add_child ($sub_content);
$sub_content->set_text ('inner <=> text');

my $sub2 = new XML::Code ('sub2');
$sub2->{'xyz'} = 123;
$sub2->add_child (XML::Code->new ('sub3'));
$content->add_child ($sub2);

my $sub4 = new XML::Code ('sub4');
$sub2->comment ('sub2 comment');
$sub2->add_child ($sub4);
$sub4->{'attr'} = 'value';
$sub4->set_text ('text of sub4');

$content->comment ('This is a comment & more');
$content->pi ("instruction intro=\"hi\"");

$content->add_empty ('hr');

print $content->code();
