#! /usr/bin/perl
use Modern::Perl;
use YAML;
use Test::More;
use XML::Tag;

$_ = as_xml
    { author => {qw< name mc email mc@nowhere >} };

ok $_, "tagified author";
ok s{^<author>}//, "opening tag";

for my $chunk (1..2) { 
    ok s{^ <email>mc\@nowhere</email> 
        | <name>mc</name> }//x
    , "chunk $chunk"
}

ok s{^</author>}// , "closing tag";

ok /^$/, "no garbage"; 

done_testing;


