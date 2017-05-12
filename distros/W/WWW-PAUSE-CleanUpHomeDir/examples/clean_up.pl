#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib (qw(../lib lib));
use WWW::PAUSE::CleanUpHomeDir;
use Data::Dumper;

die "Usage: clean_up.pl <PAUSE_ID> <PAUSE_password>\n"
    unless @ARGV;

my ( $Login, $Password ) = @ARGV;

my $pause = WWW::PAUSE::CleanUpHomeDir->new( $Login, $Password );

$pause->fetch_list
     or die $pause->error;

my @old_files = $pause->list_old;

die "No old dists were found\n"
    unless @old_files;
print @old_files . " old files were found:\n" . join "\n", @old_files, '';

print "\nEnter dist names you want to delete or just hit ENTER to"
        . " delete all of them\n";

my @to_delete = split ' ', <STDIN>;

my $deleted_ref = $pause->clean_up(\@to_delete)
     or die $pause->error;

print "Deleted: " . join "\n", @$deleted_ref, '';

print "\nWould you like to undelete any of these files? "
    . "Type their names, space separated"
        . "If not, just hit ENTER\n";

my @to_undelete = split ' ', <STDIN>;

die "Terminating..\n"
    unless @to_undelete;

$pause->undelete(\@to_undelete)
    or die $pause->error;

print "Success..\n";
