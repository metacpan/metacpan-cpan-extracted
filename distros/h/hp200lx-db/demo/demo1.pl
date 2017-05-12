#!/usr/local/bin/perl
# FILE demo1.pl
#
# simple demonstration to show how to use the HP 200LX DB module
#
# written:       1998-06-18
# latest update: 1998-06-18 16:47:18

use HP200LX::DB;

$db= &HP200LX::DB::openDB ($ARGV[0]);

tie (@db, HP200LX::DB, $db);

# it is necessary to retrieve the size of the array
my $db_cnt= $db->get_last_index ();

for ($i= 0; $i <= $db_cnt; $i++)
{
  $rec= $db[$i];                 # fetch the DB record as a has reference
  foreach $fn (sort keys %$rec)
  {
    next if ($fn =~ /\&nr$/);    # this is a dummy field for the note number

    $fv= $rec->{$fn};            # retrieve the field value
    next if ($fv eq '');         # ignore blank fields
    print "$fn=$fv\n";
  }
  print '-'x72, "\n";
}
