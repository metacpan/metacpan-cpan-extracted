#!/usr/local/bin/perl
# FILE .../CPAN/hp200lx-db/DB/adb.pm
#
# process ADB data
#
# written:       1999-05-23
# latest update: 2001-01-01 18:11:11
# $Id: adb.pm,v 1.2 2001/01/01 20:31:05 gonter Exp $
#

package HP200LX::DB::adb;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
use HP200LX::DB qw(hex_dump);

use HP200LX::DB::recurrence;

$VERSION= '0.09';
@ISA= qw(Exporter HP200LX::DB);
@EXPORT_OK= qw(openADB);

# ----------------------------------------------------------------------------
my $Author= 'g.gonter@ieee.org';

my %LANG=
(
  'German' =>
  {
    '_language'         => 'German',

    # Both
    'SUMMARY'         => 'Beschreib.',
    'CATEGORIES'      => 'Kategorie',           # how can this be set??
    'DTSTART'         => 'Beginndatum',         # append time!
    'DESCRIPTION'     => 'Notiz',

    # Date/Event
    'START_TIME'      => 'Beginnzeit',
    'END_TIME'        => 'Endzeit   ',
    'ALARM'           => 'Meldung',
    'ALARM_ADV'       => 'Vorlauf',
    'LOCATION'        => 'Ort      ',
    'X-200LX-NUM-DAYS'  => "# aufein\'folg. Tage",

    # To-Do
    'X-200LX-DUE'       => "F\204lligkeitstermin ",   # Offset it days! (T2D)
    'COMPLETED'         => "Abschlu\341datum",
    'X-200LX-PRIORITY'  => 'Priorit\204t   ',
  },

  'English' =>
  {
    '_language'         => 'English',

    # Both
    'SUMMARY'         => 'Description',
    'CATEGORIES'      => 'Category',           # how can this be set??
    'DTSTART'         => 'Start Date ',         # append time!
    'DESCRIPTION'     => 'Note',

    # Date/Event
    'START_TIME'      => 'Start Time ',
    'END_TIME'        => 'End Time   ',
    'ALARM'           => 'Alarm',
    'ALARM_ADV'       => 'Leadtime',
    'LOCATION'        => 'Location   ',
    'X-200LX-NUM-DAYS'  => '#Consecutive Days',

    # To-Do
    'X-200LX-DUE'       => 'Due Date   ',   # Offset it days! (T2D)
    'COMPLETED'         => 'Completion Date',
    'X-200LX-PRIORITY'  => 'Priority   ',
  },
);

# ----------------------------------------------------------------------------
sub openADB
{
  bless HP200LX::DB::openDB (@_);
}

# ----------------------------------------------------------------------------
sub select_language
{
  my $db= shift;

  my $desc= $db->get_field_def (0);
  my $desc_name= $desc->{name};

  my ($lng, $lang);
  foreach $lng (keys %LANG)
  {
    $lang= $LANG{$lng};
    if ($lang->{SUMMARY} eq $desc_name)
    {
      return $lang;
    }
  }

  print <<EO_NOTE;
unknown language, name of description field= '$desc_name' !
please send a sample of an appointment book in this language to
  $Author
EO_NOTE

  return undef;
}

# ----------------------------------------------------------------------------
sub fetch_adb_entry
{
  my $db= shift;
  my $idx= shift;
  my $show_diag= shift;

  my $rec= $db->FETCH ($idx);
  my $raw= $db->FETCH_data_raw ($idx);

  my ($v1, $cat, $loc, $recurrence_descriptor, $n, $prev, $next)=
     unpack ('vvvvvvv', $raw);

  my ($recurrence, $blk);
  if ($recurrence_descriptor < length ($raw))
  {
    $recurrence= decode HP200LX::DB::recurrence ($rec->{repeat},
                    $blk= substr ($raw, $recurrence_descriptor));

    if ($show_diag)
    { # TEST packing of recurrence record
      my $re_packed= $recurrence->pack ();
      if ($re_packed ne $blk)
      {
        print "\n", '*' x72, "\n";
        print "YYY ERR recurrence re-packing failed\n";
        print "original\n";
        &hex_dump ($blk, *STDOUT);
        print "re-packed\n";
        &hex_dump ($re_packed, *STDOUT);
        print '*' x72, "\n\n";
      }
      else
      {
        print "YYY OK recurrence re-packing\n";
      }
    }
  }

  # insert additional items into the fetched record
  $rec->{'_idx'}=  $idx;        # index of item
  $rec->{'_cat'}=  $cat;        # apparently not used by the HP-LX
  $rec->{'_prev'}= $prev;
  $rec->{'_next'}= $next;
  $rec->{'_raw'}= \$raw;
  $rec->{'_recurrence'}= $recurrence;

  $rec;
}

# ----------------------------------------------------------------------------
1;
