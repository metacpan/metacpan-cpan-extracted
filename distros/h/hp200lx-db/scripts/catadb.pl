#!/usr/local/bin/perl
# FILE .../CPAN/hp200lx-db/scripts/catadb.pl
#
# print ADB file in vCalendar format
# see usage
#
# T2D:
# + use formalized vCalendar module
# + generate vCalendar object for each vTodo and vEvent object
# + additional vTodo properties:
#   + X-200LX-COMPLETED         (reflecting completion check mark)
#   + X-200LX-CARRY-OVER        (reflecting carry over check box)
# + export flags:
#   + begin and end date (default: all)
#   + type: only To-Dos, Events, Dates ...
# + analyze notes field
#
# written:       1998-09-20
# latest update: 1999-05-23 11:41:27
#

# use HP200LX::DB;
use HP200LX::DB::recurrence;
use HP200LX::DB::adb qw(openADB);
use HP200LX::DB::tools;

$Author= 'g.gonter@ieee.org';
$Application= 'HP200LX::DB catadb.pl';
$Appl_Version= '0.07';

$format= 'vcs';
$folding= 'rfc';        # none, rfc [DEFAULT], simple
$show_db_def= $show_diag= 0;
$select= 'all'; # all or table

local *FO;
my $fnm_out;

ARGUMENT: while (defined ($arg= shift (@ARGV)))
{
  if ($arg =~ /^-/)
  {
    if ($arg eq '-')            { push (@JOBS, $arg);           }
    elsif ($arg eq '-dbdef')    { $show_db_def= 1;              }
    elsif ($arg eq '-diag')     { $show_diag= 1;                }
    elsif ($arg eq '-folding')  { $folding= shift (@ARGV);      }
    elsif ($arg eq '-select')   { $select= shift (@ARGV);       }
    elsif ($arg eq '-format')   { $format= shift (@ARGV);       }
    elsif ($arg eq '-o' || $arg eq '-a')
    {
      $fnm_out= shift (@ARGV);
      open (FO, ($arg eq '-o') ? ">$fnm_out" : ">>$fnm_out") || die;
    }
    else
    {
      &usage;
      exit (0);
    }
    next;
  }

  push (@JOBS, $arg);
}

*FO= *STDOUT unless ($fnm_out);
foreach $job (@JOBS)
{
  if ($format eq 'vcs') { &print_adb_vcs (*FO, $job); }
  else { &usage; }
}

# cleanup
close (FO) if ($fnm_out);

exit (0);

# ----------------------------------------------------------------------------
sub usage
{
  print <<END_OF_USAGE
usage: $0 [-options] [filenanme]

Options:
-help                   ... print help
-o <file>               ... export data to output file
-for[mat] <format>      ... select presentation format
                            vcs: vCard [DEFAULT]
-folding <scheme>       ... folding scheme applied to contents lines:
                            rfc: folding according to RFC 2426 etc. [DEFAULT]
                            simple: insert blanks before next line
                            none: don't do anything special
-select <part>          ... select items to be used
                            all: display all items [DEFAULT]
                            table: display only items listed in view table(?)

-dbdef                  ... print database definition
-diag                   ... print diagnositc information

Examples:
  $0 -o export.vcs -folding simple appt.adb
END_OF_USAGE
}

# ----------------------------------------------------------------------------
sub print_adb_vcs
{
  local *FO= shift;
  my $fnm= shift;

  my (@data, $i, $field, $val);

  my $db= openADB ($fnm);

  unless ($db->{APT} eq 'ADB')
  {
    print "not an appointment book! (ADB file)!\n",
          "try catgdb instead!\n";
    return;
  }

  $lang= $db->select_language ();
  print "selecting language '$lang->{_language}'\n" if ($show_diag);
  my $AD= $db->{APT_Data};
  my $table= $AD->{View_Table};

  if ($show_db_def)
  {
      print "database definition:\n:"; $db->show_db_def (*STDOUT);
      print "card definition:\n:";     $db->show_card_def (*STDOUT);
  }

  if ($show_diag)
  {
    print "header data of $fnm\n";
    print "    number of entries in view Table: ", $#$table, "\n";
    print "    head date=$AD->{Head_Date}\n";
    &HP200LX::DB::hex_dump ($AD->{Header}, *STDOUT);

    print '=' x72, "\n\n";
  }

  my $db_cnt= $db->get_last_index ();
  # tie (@data, HP200LX::DB, $db);

  if ($folding eq 'simple' || $folding eq 'none') { $VERSION= '1.0'; }
  elsif ($folding eq 'rfc') { $VERSION= '2.0'; }

  print FO <<EO_VCS;
BEGIN:VCALENDAR
VERSION:$VERSION
PRODID:-//$Author//NONSGML $Application $Appl_Version//EN
X-COUNT:$db_count

EO_VCS

  if ($select eq 'all')
  {
    for ($i= 0; $i <= $db_cnt; $i++) { &print_entry (*FO, $db, $i); }
  }
  elsif ($select eq 'table')
  {
    my $ptr;
    foreach $ptr (@$table)
    {
      print "entry date: $ptr->{'date'}\n";
      &print_entry (*FO, $db, $ptr->{num});
    }
  }

  print FO "END:VCALENDAR\n\n";
}

# ----------------------------------------------------------------------------
sub print_entry
{
  local *FO= shift;
  my $db= shift;
  my $idx= shift;
  my $blk;

  my $rec= $db->fetch_adb_entry ($idx, $show_diag);
  return unless (defined ($rec));
  my $recurrence= $rec->{_recurrence};
  my $raw= $rec->{_raw};

  print "entry number: $idx\n" if ($show_diag);
  my $entry_type= $rec->{type};

  if ($entry_type eq 'Date')
  {
      print FO <<EO_VCS;
BEGIN:VEVENT
CATEGORIES:PERSONAL
CLASS:PRIVATE
EO_VCS

      my $start_time= $rec->{$lang->{START_TIME}};
      my $dt_start= &get_dt ($rec->{$lang->{DTSTART}}, $start_time);
      my $dt_end=   &get_dt ($rec->{$lang->{DTSTART}},
                             $rec->{$lang->{END_TIME}});

      print FO "DTSTART:$dt_start\n";
      print FO "DTEND:$dt_end\n";

      &print_recurrence (*FO, $recurrence, 'T'.$start_time.':00');

      &print_list (*FO, $rec, $lang, 0, $folding, 'SUMMARY', 'LOCATION', 'DESCRIPTION');
      &print_list (*FO, $rec, $lang, 1, $folding, 'X-200LX-NUM-DAYS');

      print FO "END:VEVENT\n\n";
  }
  else
  {
      print FO <<EO_VCS;
BEGIN:VTODO
CATEGORIES:PERSONAL
CLASS:PRIVAT
EO_VCS

      foreach $field ('DTSTART', 'COMPLETED')
      {
        $val= $rec->{$lang->{$field}};
        next if ($val eq '2155-256-01');
        # $val=~ s/-//g;
        print FO $field, ':', $val, "T00:00:00\n";
      }

      &print_recurrence (*FO, $recurrence);

      &print_list (*FO, $rec, $lang, 0, $folding, 'SUMMARY', 'DESCRIPTION',
                                        'X-200LX-PRIORITY');
      &print_list (*FO, $rec, $lang, 1, $folding, 'X-200LX-DUE');

      print FO "END:VTODO\n\n";
  }

  if ($show_diag)
  {
    my $fld;
    foreach $fld (sort keys %$rec)
    {
      print $fld, '=', $rec->{$fld}, "\n";
    }
  }

  if ($recurrence)
  {
    $recurrence->print_recurrence_status (*STDOUT);
  }

  # &HP200LX::DB::hex_dump ($$raw, *STDOUT);
  if ($show_diag)
  {
    my $cat_str= HP200LX::DB::get_str ($raw, $rec->{_cat});

    printf ("YYY 1 prev=0x%04X next=0x%04X lng=0x%04X\n",
            $rec->{'_prev'}, $rec->{'_next'}, length ($$raw));
    printf ("YYY 2 cat=0x%04X cat_str='%s'\n", $rec->{_cat}, $cat_str)
      if ($cat_str);

    if ($recurrence)
    {
      print "recurrence data\n";
      &HP200LX::DB::hex_dump ($blk, *STDOUT);
    }
  }

  if ($show_diag)
  {
    print "record data\n";
    &HP200LX::DB::hex_dump ($$raw, *STDOUT);

    print '=' x72, "\n\n";
  }
}

# ----------------------------------------------------------------------------
sub print_recurrence
{
  local *FO= shift;
  my $recurrence= shift;
  my $start_time= shift;

  return unless ($recurrence);

  my $vc_rec= $recurrence->export_to_vCalendar ($start_time);
  my $k;

  foreach $k (keys %$vc_rec)
  { # T2D: Folding!!!
    &print_content_line (*FO, $k, $vc_rec->{$k}, $folding, 1);
  }
}

# ----------------------------------------------------------------------------
sub get_dt
{
  my $date= shift;
  my $time= shift;

  # $date=~ s/-//g;
  # $time=~ s/://g;
  $date . 'T' . $time . ':00';
}
