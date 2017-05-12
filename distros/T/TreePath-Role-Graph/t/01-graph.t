use utf8;
use strict;

use Test::More 'no_plan';
use File::stat;
use lib 't/lib';

use TreePath::Graph::Test;

my $simpletree = [
    {
        id => '1',
        source => 'File',
        file => '/tmp/file1.txt'},
    {
        id => '2',
        source => 'File',
        file => '/tmp/file2.txt'},
    {
        id => '1',
        source => 'Page',
        parent => '',
        files => [ { 'File_1'}, {'File_2'}],
        name => '/',},
    {
        id => '2',
        source => 'Page',
        parent => { 'Page_1' },
        name => 'A'},
    {
        id => '3',
        source => 'Page',
        parent =>  { 'Page_2' },
        name => 'B'},
    {
        id => '4',
        source => 'Page',
        parent =>  { 'Page_3' },
        name => 'C'},
    {
        id => '5',
        source => 'Page',
        parent =>  { 'Page_4' },
        name => 'D'},
    {
        id => '6',
        source => 'Page',
        parent =>  { 'Page_4' },
        name => 'E'},
    {
        id => '7',
        source => 'Page',
        parent =>  { 'Page_2' },
        name => '♥'},
    {
        id => '8',
        source => 'Page',
        parent =>  { 'Page_7' },
        name => 'G'},
    {
        id => '9',
        source => 'Page',
        parent => { 'Page_7' },
        name => 'E'},
    {
        id => '10',
        source => 'Page',
        parent =>  { 'Page_9' },
        name => 'I'},
    {
        id => '11',
        source => 'Page',
        parent => { 'Page_9' },
        name => 'J'},
    {
        id => '1',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '2',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '3',
        source => 'Comment',
        parent => { 'Page_2' }},
    {
        id => '4',
        source => 'Comment',
        parent => { 'Page_2' }},
    {
        id => '5',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '6',
        source => 'Comment',
        parent => { 'Page_7' }},
    {
        id => '7',
        source => 'Comment',
        parent => { 'Page_11' }},
    {
        id => '8',
        source => 'Comment',
        parent => { 'Page_11' }},

];


my $colors_source = {
    'Page' => { fg => 'blue'},
    'Comment' => { fg => 'magenta'},
};


ok( my $tp = TreePath::Graph::Test->new(  datas   => $simpletree,
                                          colors => $colors_source,
                                          output => 't/test.png',
                                          ),
    "New TreePath ( conf => $simpletree) with TreePath::Role::Graph");

$tp->load;
$tp->graph;

my $sb = stat($tp->output);
ok( $sb->size > 0, "png size is not nulle");

unlink $tp->output;
