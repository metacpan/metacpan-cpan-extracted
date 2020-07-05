#!/usr/bin/env perl
# https://community.notepad-plus-plus.org/topic/19015/feature-request-md5-in-the-context-menu
#
# Installation:
#   1) Save this file as c:\path\to\npp_selection_filenames_md5.pl
#   2) Install perl (such as from strawberryperl.com)
#   3) Install required modules:
#       cpanm Digest::MD5 Win32::Mechanize::NotepadPlusPlus
#
# Instructions:
#   1) select a list of filenames in Notepad++, one filename per line
#   2) run this script
#       * Run > Run: c:\strawberry\perl\bin\perl.exe c:\path\to\npp_selection_filenames_md5.pl
#   3) the script will print out the MD5 list, similar to Tools > MD5 > Generate from files...
#       but doesn't require using the dialog boxes
#
use strict;
use warnings;
use Win32::Mechanize::NotepadPlusPlus qw/:all/;
use Digest::MD5;
use autodie;

my $eol = ("\r\n", "\r", "\n")[editor->getEOLMode()];

my $txt = editor->getSelText();
if( $txt eq "\0" or length($txt)<1) {
    die "\nusage: make a selection of filename-per-line in Notepad++, then run this script\n\n";
}

my @lines = split /$eol/, editor->getSelText();
for my $fname (@lines) {
    #printf qq(>>%s<<\n), $fname;
    my $ctx = Digest::MD5->new;
    open my $fh, '<', $fname;
    $ctx->addfile($fh);
    printf qq(%32.32s  %s\n), $ctx->hexdigest, $fname;
}

__DATA__
select these two lines:
C:\usr\local\share\PassThru\perl\nppCommunity\19015-md5-on-list-of-files.pl
C:\usr\local\share\PassThru\perl\nppCommunity\gen-md.pl

example output:
9b09a8de81cb5861670d012958423d4e  19015-md5-on-list-of-files.pl
b6d8e167ca1dc1d444b646a2985bd6bf  gen-md.pl
