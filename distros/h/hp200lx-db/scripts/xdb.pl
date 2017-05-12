#!/usr/local/bin/perl
# FILE %usr/unixonly/hp200lx/xdb.pl
#
# currently configured to start a GDB browser using Tk
#
# written:       1997-12-28
# latest update: 1999-02-22 20:40:41
#

use lib '.';
use HP200LX::DB ('openDB');
use HP200LX::DBgui ('browse_db');

$diag= 0;
@DBs= ();       # list of opened databases
$first= 'list'; # first opened GUI widget
%pars= ();      # additional parameters for the GUI module

my @FIXUP_NDB=
(
  { '&num' => 2, 'w' => 156, } # w= 16 is not enough
);

my @FIXUP_WDB=
(
# { '&num' =>  0, 'w' => 128, },
  { '&num' =>  4, 'y' =>  38, },
  { '&num' =>  8, 'y' =>  61, },
  { '&num' =>  9, 'y' =>  61, },
  { '&num' => 10, 'y' =>  61, },
  { '&num' => 12, 'y' =>  82, },
  { '&num' => 13, 'y' =>  82, },
  { '&num' => 14, 'y' =>  82, },
  { '&num' => 15, 'y' =>  82, 'w' => 96 },
  { '&num' => 18, 'y' => 101, },
  { '&num' => 19, 'y' => 101, },
);

while (defined ($arg= shift (@ARGV)))
{
  if ($arg =~ /^-/)
  {
    if ($arg eq '-d')           { $diag++; }
    elsif ($arg eq '-card')     { $first= 'card'; }
    elsif ($arg eq '-list')     { $first= 'list'; }
    elsif ($arg eq '-view')     { $first= 'list'; $pars{'-view'}= shift (@ARGV);}
    elsif ($arg eq '-vpt')      { $first= 'vpt'; }
    else
    {
      &usage;
      exit (0);
    }
    next;
  }

  my $db= &openDB ($arg);
  push (@DBs, $db);

  $db->dump_def (1)     if ($diag > 0);
  $db->show_card_def () if ($diag > 0);
  $db->show_db_def ()   if ($diag > 0);
  $db->show_data ()     if ($diag > 1);

  # $db->{'__DEBUG__'}= 0x01;

  my $APT= $db->{APT};
  my $t= $APT . ' ' . $arg;
  if ($APT eq 'NDB') { &fixup_ndb ($db); }
  elsif ($APT eq 'WDB') { &fixup_wdb ($db); }

  new HP200LX::DBgui ($db, $t, '-first' => $first, %pars);

  # $db->recover_key (0, 'ned00.c', 'key.bin');
}

&browse_db ();

exit (0);

# ----------------------------------------------------------------------------
sub usage
{
  print <<EOX;
usage: $0 [-options] db-name+

Options:
-d      ... increase debugging level
-vpt    ... start with view point
EOX
}

# ----------------------------------------------------------------------------
# The NDB file format is slightly different from a GDB file,
# here we fix the application speicifc layout bugs
sub fixup_ndb
{
  my $db= shift;
  my $fcd= &clone_definition ($db, 'carddef');

  &fixup_data ($fcd, \@FIXUP_NDB);
  # fix sequence: title, category, notes
  $db->{APT_Data}->{field_sequence}= [ 0, 2, 1];
}

# ----------------------------------------------------------------------------
# The WDB file format is slightly different from a GDB file,
# here we fix the application speicifc layout bugs
sub fixup_wdb
{
  my $db= shift;
  my $fcd= &clone_definition ($db, 'carddef');

  foreach $i (0..3, 5)
  {
    print "fixup: i=$i\n";
    $f= $fcd->[$i];
    $f->{w} *= 8;
  }

  &fixup_data ($fcd, \@FIXUP_WDB);
  # fix sequence: title, category, notes
  # $db->{APT_Data}->{field_sequence}= [ 0, 2, 1];
}

# ----------------------------------------------------------------------------
# general cloning functions; move to DB.pm ?
sub fixup_data
{
  my $ar= shift;
  my $fr= shift;

  my ($f, $i, $k, $v);
  foreach $f (@$fr)
  {
    next unless (defined ($i= $f->{'&num'}));
    foreach $k (keys %$f)
    {
      next if ($k eq '&num');
      print "fixup data: num=$i k=$k v=$f->{$k}\n";
      $ar->[$i]->{$k}= $f->{$k};
    }
  }
}

# ----------------------------------------------------------------------------
sub clone_definition
{
  my $db= shift;
  my $what= shift;

  my $orig= $db->{$what};
  my @fixed;

  my ($ocd, $fcd, $ocn, $ocv);
  foreach $ocd (@$orig)
  {
    $fcd= {};
    push (@fixed, $fcd);

    foreach $ocn (keys %$ocd)
    {
      $fcd->{$ocn}= $ocd->{$ocn};
    }
  }

  $db->{APT_Data}->{$what}= \@fixed;
}
