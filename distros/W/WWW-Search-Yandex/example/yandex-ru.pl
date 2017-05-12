#!/usr/bin/perl
### Project: Yandex.RU Command-line interface
### File:    Yandex-ru.pl
### Creator: Artur Penttinen <artur+perl@niif.spb.su>
### Creation date: 12-08-2004 Thu 20:21:56 EEST
### Last modified: <Friday, 13-Aug-2004 01:06:01; artur>
###
### $Id:$
###

use strict;

use Getopt::Std;
use WWW::Search;
use Text::Wrap;

my $prg = $0; $prg =~ s|^.+/||;
my $VERSION = '$Revision:$'; $VERSION =~ s|[^\d.]+||g;

my %opt;

getopts ("hc:d:",\%opt);

my $chset = $opt{'c'} || ($^O =~ m/win/i) ? "windows-1251" : "koi8-r";
my $dbg = $opt{'d'} || 0;

if (exists ($opt{'h'}) || !@ARGV) {
    print STDERR "usage: $prg {options} text\n";
    print STDERR "\t-h\t- this text\n";
    print STDERR "\t-c chset - character set [$chset]\n";
    print STDERR "\t-d num\t- debug output [$dbg]\n";
    print STDERR "\n\t$prg version: $VERSION\n";
    exit;
}

my $search = new WWW::Search ("Yandex",'charset' => $chset);

$search->{'_debug'} = $dbg;

$search->native_query ("@ARGV");

my $cnt = 0;
while (my $r = $search->next_result ()) {
    printf "%2d: %s <URL:%s>\n%s\n",++$cnt,$r->title,$r->url,
      wrap ("\t","\t",$r->description);
}

exit (0);

# That's all, folks!
