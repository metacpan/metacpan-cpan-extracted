#! /usr/bin/perl
use Modern::Perl;
use YAML;
use XML::Tag;
use Test::More;

my $got;
$got = tag 'o' => sub {"haha"};
is $got, '<o>haha</o>', "tag with content";
$got = tag 'o' => sub {};
is $got, '<o/>', "empty tag";
$got = tag 'o' => sub { tag 'a' => sub {"haha"}}; 
is $got, '<o><a>haha</a></o>', "import tag";
done_testing;
