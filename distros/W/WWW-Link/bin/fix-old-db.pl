#!/usr/bin/perl

=head1 fix-old-db

A little script designed to fix up old LinkController databases
generated with the old version of the link module not much use to you
because that version wasn't distributed.

=cut

$::old="old.bdbm";
$::new="new.bdbm";

use Fcntl;
use DB_File;
use MLDBM qw(DB_File);
tie %old_db, "MLDBM", $::new, O_RDONLY, 0666, $::DB_HASH
  or die $!;
tie %new_db, "MLDBM", $::old, O_RDWR|O_CREAT, 0666, $::DB_HASH
  or die $!;
while (($key,$value) = each %old_db) {
  $value->{"redirects"}=$value->{"fix_suggestions"};
  delete $value->{"fix_suggestions"};
  $new_db{$key}=$value;
}
