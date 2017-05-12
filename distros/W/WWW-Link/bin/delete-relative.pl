#!/usr/bin/perl

=head1 delete relative

Delete every entry in a dbm where the key seems to be a single filename with no path given.

=cut

$::old="old.bdbm";
$::new="new.bdbm";

use Fcntl;
use DB_File;
tie %old_db, "DB_File", $::old, O_RDONLY, 0666, $::DB_HASH
  or die $!;
tie %new_db, "DB_File", $::new, O_RDWR|O_CREAT, 0666, $::DB_HASH
  or die $!;
while (($key,$value) = each %old_db) {
  if ( $key =~ m,/, ) {
    $new_db{$key}=$value;
  } else {
    print STDERR "deleting $key\n";
  }
}
