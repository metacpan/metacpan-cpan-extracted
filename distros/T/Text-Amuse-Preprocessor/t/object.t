#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 7;
use Text::Amuse::Preprocessor;
use File::Temp;
use File::Spec::Functions qw/catfile/;
my $wd = File::Temp->newdir(CLEANUP => 1);
my $dirname = $wd->dirname;

my $html = '<p>
	Your text here... &amp; &quot; &ograve;</p>
<p>
Hello
</p>';

is(Text::Amuse::Preprocessor->html_to_muse($html),
   "\n\nYour text here... & \" ò\n\nHello\n\n", "Testing a basic html");

is(Text::Amuse::Preprocessor->html_to_muse('<pre>hello</pre>'),
   "\n<example>\nhello\n</example>\n", "Testing <pre>");

my $output_string;
my $input_string = "hello there č\n";
my $pptest = Text::Amuse::Preprocessor->new(
                                            input => \$input_string,
                                            output => \$output_string,
                                           );

$pptest->process;

is $output_string, $input_string;


ok(-f $pptest->_infile, "internal infile exists")
  and diag "Infile is " . $pptest->_infile;
is read_file($pptest->_infile), $input_string, "internal infile content match string";




diag "Using $dirname as temporary dir";
my $muse = <<'MUSE';
#title "Test" "Test"
#lang en

http://prova.org http://example.org

ground . . . ground . . . hello --- world --- world - hello

 - 1
 - 2
 - 3

'80 '90 '01 "hello" "there" 80-90 90-100

MUSE

my $expected = <<'MUSE';
#title “Test” “Test”
#lang en

[[http://prova.org][prova.org]] [[http://example.org][example.org]]

ground ... ground ... hello — world — world — hello

 - 1
 - 2
 - 3

’80 ’90 ’01 “hello” “there” 80–90 90–100

MUSE

my $infile = catfile($dirname, 'input.muse');
my $outfile = catfile($dirname, 'output.muse');
write_file($infile, $muse);

my $preprocessor = Text::Amuse::Preprocessor->new(
                                                  input => $infile,
                                                  output => $outfile,
                                                  fix_links => 1,
                                                  fix_typography  => 1,
                                                  debug => 0,
                                                 );

is $preprocessor->process, $outfile, "process return the outfile";
is_deeply([ split /\n/, read_file($outfile) ],
          [ split /\n/, $expected ],
          "processing correct");

sub read_file {
    return Text::Amuse::Preprocessor->_read_file(@_);
}

sub write_file {
    return Text::Amuse::Preprocessor->_write_file(@_);
}
