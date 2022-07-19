#!/usr/bin/env perl
# 010-struct.t - recycling 1999 example code as a test loading a struct
# Copyright (c) 1999,2022 Ian Kluft
use strict;
use warnings;
use utf8;
use Carp;
use File::Temp;
use File::Slurp qw(read_file);
use WebFetch::Input::PerlStruct;
use WebFetch::Data::Store;
use WebFetch::Output::Dump;
use Test::More tests => 6;
use Test::Exception;

# constants
my $outfilename = "perlstruct.txt";

# data from 1999 example - the URLs long since no longer exist
my @example_data = (
    {
        "url" => "http://www.svlug.org/news.shtml#19990410-000",
        "title" => "EHeadlines puts SVLUG news on your Enlightenment desktop"
    },
    {
        "url" => "http://www.svlug.org/news.shtml#19990408-000",
        "title" => "SVLUG has released WebFetch 0.04"
    },
    {
        "url" => "http://www.svlug.org/news.shtml#19990402-000",
        "title" => "comp.os.linux.announce and CNN Linux news added to SVLUG home page"
    },
    {
        "url" => "http://www.svlug.org/news.shtml#19990330-000",
        "title" => "SVLUG Editorial on Competition for DNS"
    },
    {
        "url" => "http://www.svlug.org/news.shtml#19990329-000",
        "title" => "Linux 2.2.5 released"
    },
    {
        "url" => "http://www.svlug.org/news.shtml#19990310-000",
        "title" => "Marc Merlin's LinuxWorld Report and Pictures"
    }
);

# package example data for WebFetch::Input::PerlStruct
my @content = (
    fields => [ qw(title url) ],
    content => [ @example_data ],
);

# data to verify contents of written file
my $file_verify = bless({
    'records' => [],
    'feed' => {},
    'no_fetch' => 1,
    'wk_names' => {},
    'findex' => {},
    'fields' => [ 'title', 'url' ],
    'wkindex' => {},
    'content' => [ @example_data ],
}, 'WebFetch::Data::Store' );

# set up temporary directory
my $tmpdir = File::Temp->newdir();

# instantiate test object
my %params = (
    "content" => WebFetch::Data::Store->new(@content),
    "dir" => $tmpdir,
    "source_format" => 'perlstruct',
	"dest" => $outfilename,
    "dest_format" => "dump",
);
my $exitcode;
lives_ok( sub {$exitcode = WebFetch::Input::PerlStruct->run(\%params)}, "call WebFetch::Input::PerlStruct->run()");
is($exitcode, 0, "run() method returned 0");

# verify file was written with correct contents
my $dump_path = "$tmpdir/$outfilename";
#note("data dump output at $dump_path");
ok(-e $dump_path, "output data file exists");
ok(-f $dump_path, "output data file is a regular file");
ok(-r $dump_path, "output data file is readable");
my $slurped_text = read_file($dump_path);

{
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $slurped_data;
    substr($slurped_text, 0, 5, '$slurped_data'); # force eval to read data into $slurped_data
    my $result = eval $slurped_text;
    if ($@) {
        print STDERR "slurped data error: $@\n";
    }
    is_deeply($slurped_data, $file_verify, "output file content verification");
}
