#!perl
use strict;
use warnings;
use utf8;

use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Temp;
use File::Spec::Functions qw/catdir catfile/;
use Test::More tests => 55;
use Data::Dumper;
use Cwd;

my $cwd = getcwd();
my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
chdir $workingdir or die "Cannot chdir";
my $testfile = "test.muse";
my $c = Text::Amuse::Compile->new;

{
    my $muse = <<MUSE;
#title blah
#author author
#subtitle subtitle
#deleted 1
#cover 11 Name.jpg
#coverwidth blablabla
#nocoverpage 0

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok $header->is_deleted, "File is deleted";
    is $header->language, "en", "Language is en";
    ok !$header->wants_slides, "No slides";
    ok !$header->cover, "No cover";
    ok !$header->coverwidth, "No coverwidth";
    ok !$header->nocoverpage, "Nocoverpage is false";
    is $header->title, 'blah';
    is $header->author, 'author';
    is $header->subtitle, 'subtitle';
    is $header->listtitle, '';
    diag Dumper($header->tex_metadata);
}

{
    my $muse = <<MUSE;
#title blah
#LISTtitle 001 blah
#deleted
#lang it
#slides NO
#cover -invalid-name.pdf
#coverwidth 1

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->listtitle, '001 blah';
    is $header->language, "it", "Language is it";
    ok !$header->wants_slides, "File doesn't want slides";
    ok !$header->cover, "No cover";
    ok !$header->coverwidth, "No coverwidth";
    is $header->tex_metadata->{title}, '001 blah';
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.png

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.png", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.png', "Found the cover";
    is $header->coverwidth, 1, "width is 1";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.png
#coverwidth 0.5

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.png", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.png', "Found the cover";
    is $header->coverwidth, '0.5', "width is 0.5";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.png
#coverwidth 0.77

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.png", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.png', "Found the cover";
    is $header->coverwidth, '0.77', "width is 0.5";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.png
#coverwidth 0.771
#nocoverpage 1

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.png", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.png', "Found the cover";
    is $header->coverwidth, '1', "width is 1";
    is $header->nocoverpage, 1, "nocoverpage ok";
}

{
    my $muse = <<MUSE;
#title blah
#topics first, second, third
#authors second; first, last

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply ($header->topics, [qw/first second third/]);
    is_deeply ($header->authors, ['second', 'first, last']);
}

{
    my $muse = <<MUSE;
#title blah
#topics first, last;
#authors ;

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply ($header->topics, [q/first, last/]);
    is_deeply ($header->authors, []);
}

{
    my $muse = <<MUSE;
#title blah
#sorttopics first, last
#sortauthors ;
#cat bla foo, try

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply ($header->topics, [qw/bla foo try first last/]);
    is_deeply ($header->authors, []);
}

{
    my $muse = <<MUSE;
#title blah
#SORTtopics *first*, =last=;
#SORTauthors my **fist, <em>author</em>;
#cat bla foo, try

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply ($header->topics, [qw/bla foo try/, "*first*, =last="]);
    is_deeply ([$header->topics_as_html_list],
               [qw/bla foo try/, "<em>first</em>, <code>last</code>"],
               'html ok for topics');
    is_deeply ($header->authors, ['my **fist, <em>author</em>']);
    is_deeply ([$header->authors_as_html_list],
               ['my **fist, <em>author</em>'], 'html for authors ok');
}

{
    my $muse = <<'MUSE';
#title \blah\
#SORTtopics >first, =&'last=<;
#SORTauthors my **fist, <em>"author"</em>;
#cat bla foo, try
#subtitle /hullo\

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply ($header->topics, [qw/bla foo try/, ">first, =&'last=<"]);
    is_deeply ([$header->topics_as_html_list],
               [qw/bla foo try/, "&gt;first, <code>&amp;&#x27;last</code>&lt;"]);
    is_deeply ($header->authors, ['my **fist, <em>"author"</em>']);
    is_deeply ([$header->authors_as_html_list],
               ['my **fist, <em>&quot;author&quot;</em>']);
    diag Dumper($header->tex_metadata);
    is_deeply($header->tex_metadata,
              {
               'author' => 'my **fist, <em>"author"<\Slash{}em>',
               'title' => '\\textbackslash{}blah\\textbackslash{}',
               'keywords' => 'bla; foo; try; >first, =\\&\'last=<',
               'subject' => '\\Slash{}hullo\\textbackslash{}'
              });
}

{
    my $muse = <<'MUSE';
#title \blah/
#author pippo
#subtitle -

x
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    is_deeply($header->tex_metadata,
              {
               title => '\\textbackslash{}blah\\Slash{}',
               author => 'pippo',
               keywords => '',
               subject => '',
              });
    is $header->listing_title, '\blah/';
}

chdir $cwd;
