#!/usr/local/bin/perl
# FILE %usr/unixonly/hp200lx/catgdb.pl
#
# print data records of a HP 200LX DB 
#
# written:       1998-01-11
# latest update: 2000-08-15 21:11:30
my $ID= '$Id: catgdb.pl,v 1.7 2001/01/01 20:29:52 gonter Exp $';
#

use lib '.';
use HP200LX::DB;
use HP200LX::DB::tools;
use HP200LX::DB::diag;

# initializiation
$FS= ';';
$RS= "\n";
$RStart= '';
$show_fields= 1;
$show_db_def= 0;
$show_db_def_html= 0;
$show_notes= 1;
$show_note_cards= 0;    # print notes as indivdula cards
$format= 1;
$print_header= 1;

ARGUMENT: while (defined ($arg= shift (@ARGV)))
{
  if ($arg =~ /^-/)
  {
    if ($arg eq '-')            { push (@JOBS, $arg);   }
    elsif ($arg =~ /^-noh/)     { $show_fields= 0;      }
    elsif ($arg =~ /^-dbdef/)   { $show_db_def= 1;      }
    elsif ($arg =~ /^-html/)    { $show_db_def_html= 1; }
    elsif ($arg =~ /^-nono/)    { $show_notes= 0;       }
    elsif ($arg =~ /^-nc/)      { $show_note_cards= 1;  }
    elsif ($arg =~ /^-for/)     { $format= shift (@ARGV); }
    elsif ($arg =~ /^-sum/)     { $format= 'summary'; }
    elsif ($arg =~ /^-dump/)    { $format= 'dump'; }
    elsif ($arg eq '-FS')       { $FS= shift (@ARGV); }
    elsif ($arg eq '-CSV')      { $FS= '","'; $RStart= '"', $RS= "\"\n"; }
    else
    {
      &usage;
      exit (0);
    }
    next;
  }

  push (@JOBS, $arg);
}

foreach $job (@JOBS)
{
     if ($format eq '2')        { &print_gdb_2 ($job); }
  elsif ($format eq 'dump')     { &print_gdb_dump ($job); }
  elsif ($format eq 'summary')  { &print_gdb_summary ($job); }
  else { &print_gdb ($job); }
}

# cleanup

exit (0);

# ----------------------------------------------------------------------------
sub usage
{
  print <<END_OF_USAGE
usage: $0 [-options] [filenanme]

Module Version: $HP200LX::DB::VERSION

Options:
-help                   ... print help
-dbdef                  ... dump database definition
-noh                    ... hide header
-nonotes                ... hide the notes records
-nc                     ... show notes records in card format
-format <name>          ... dump data in format
-dump                   ... dump everything in printable form
-sum)ary                ... write only a summary line abut each DB
-FS <sep>               ... use field seperator

-format 2               Full Export Format (to be completed)
missing items:
  cardpage
  db_header

T2D (format 2):
  option: show names of empty fields

$ID
END_OF_USAGE
}

# ----------------------------------------------------------------------------
sub print_gdb
{
  my $fnm= shift;
  my $view= '';  # retrieve a view description

  my (@data, $i);
  my @show;                     # field names in the order used for display
  my ($note_name, $notes_nr);   # name of notes field and notes number field
  my @note_cards;               # list of note records to display as cards

  my $db= HP200LX::DB::openDB ($fnm);

  &print_db_def ($db, *STDOUT) if ($show_db_def);
  &print_db_def_html ($db, *STDOUT) if ($show_db_def_html);

  my $db_cnt= $db->get_last_index ();
  tie (@data, HP200LX::DB, $db);

  for ($i= 0; $i <= $db_cnt; $i++)
  {
    my $rec= $data[$i];
    my $fld;

    if ($i == 0)
    { # when the first record is processed, print header and find notes
      my %show= map {$_ => 1} keys %$rec;
      # Extension: fetch list of displayed columns from some other source
      foreach $fld (sort keys %show)
      {
        if (!$show_notes && $fld =~ /(.+)\&/)
        { # HP200LX::DB uses: appends '&nr' to the name of the notes
          # field for the element that contains the notes number
          $notes_name= $1;
          $notes_nr= $fld;
          $show{$notes_name}= 0;
          # $show{$notes_nr}= 0;
        }
      }

      # prepare list of displayed fields
      foreach (sort keys %show)
      {
        push (@show, $_) if ($show{$_});
      }

      print $RStart, join ($FS, @show), $RS if ($show_fields);
      $show_fields= 0;
    }

    if ($show_note_cards)
    {
      my $nn= $rec->{$notes_nr};
      push (@note_cards, $nn) if ($nn != 65535);
    }

    print $RStart, join ($FS, map { $rec->{$_} } @show), $RS;
  }

  if ($#note_cards >= 0)
  {
    my $nn;
    foreach $nn (sort {$a <=> $b} @note_cards)
    {
      printf ("----- [%s %5d] ", $notes_name, $nn);
      print '-'x50, "\n";
      my $nv= $db->FETCH_note_raw ($nn);
      $nv=~ s/\x0D//g;
      print $nv, "\n\n";
    }
  }
}

# ----------------------------------------------------------------------------
sub print_gdb_summary
{
  my $fnm= shift;

  my (@data, $i);

  my $db= HP200LX::DB::openDB ($fnm, undef, 1); # no decryption
  $db->print_summary ($print_header);
  $print_header= 0;
}

# ----------------------------------------------------------------------------
sub print_gdb_dump
{
  my $fnm_db= shift;
  my $fnm_out= shift;
  local *FO;

  if (defined ($fnm_out))
  {
    unless (open (FO, ">$fnm_out"))
    {
      print STDERR "can't write to $fnm_out\n";
    }
  }
  else { *FO= *STDOUT; }

  my $db= HP200LX::DB::openDB ($fnm_db, undef, 1);

  $db->dump_type (*FO);

  close (FO) if (defined ($fnm_out));
}

# ----------------------------------------------------------------------------
sub print_gdb_2
{
  my $fnm= shift;

  my (@data, $i);

  my $db= HP200LX::DB::openDB ($fnm);

  &print_db_def ($db, *STDOUT) if ($show_db_def);
  &print_db_def_html ($db, *STDOUT) if ($show_db_def_html);

  my $db_cnt= $db->get_last_index ();
  tie (@data, HP200LX::DB, $db);

  for ($i= 0; $i <= $db_cnt; $i++)
  {
    my $rec= $data[$i];
    my $fld;

    print "&type:data\n";
    print "&idx:$i\n";
    foreach $fld (sort keys %$rec)
    {
      my $val= $rec->{$fld};
      # print $fld, '=', $val, "\n" if ($val);
      print_content_line (*STDOUT, $fld, $val, 'rfc', 0) if ($val);
    }
    print "\n";
  }
}

