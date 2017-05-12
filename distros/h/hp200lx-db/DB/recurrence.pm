#!/usr/local/bin/perl
# FILE %usr/unixonly/CPAN/hp200lx-db-0.04/DB/recurrence.pm
#
# handling of recurance rules in HP200LX ADB database
#
# T2D:
# + more precise perl representation
# + mapping HP200LX binary recurrence
# + mapping vCalendar recurrence format
#
# written:       1998-09-20
# latest update: 2001-03-11  2:21:16
# $Id: $
#

package HP200LX::DB::recurrence;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

use HP200LX::DB qw(fmt_date fmt_time pack_date hex_dump);

$VERSION= '0.09';
@ISA= qw(Exporter);
@EXPORT_OK= qw(:all
               new
               print_recurrence_status
              );

# ----------------------------------------------------------------------------
my $no_val=  65535;             # NIL, empty list, -1 etc.
my @BITS=
(
    1,    2,    4,    8,    16,    32,    64,   128,
  256,  512, 1024, 2048,  4096,  8192, 16384, 32768,
);

my @RECURRENCE_TEXT=
(
  'never', 'daily', 'weekly', 'monthly', 'yearly', 'special'
);

my @RECURRENCE_MONTH_GERMAN=
(
  'Januar',  'Februar',  'Maerz',
  'April',   'Mai',      'Juni',
  'Juli',    'August',   'September',
  'Oktober', 'November', 'Dezember'
);

my @RECURRENCE_MONTH=
(
  'January', 'February', 'March',
  'April',   'May',      'June',
  'July',    'August',   'September',
  'October', 'November', 'December'
);

my @RECURRENCE_WDAY=
(
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
);

my @RECURRENCE_DAY=
(
  '1st', '2nd', '3rd', '4th', 'last',
);

my %RECURRENCE_XAPIA=
(
   0 => 'U', 1 => 'N', 2 => 'D', 4 => 'W', 8 => 'M', 16 => 'Y', 32 => 'S'
);

my @RECURRENCE_EXCEPTION= ( 'deleted', 'checked-off' );

# ----------------------------------------------------------------------------
sub new
{
  my $class= shift;
  my $factor= shift;

  my $obj=
  {
    'recurrence'        => $factor,
    'recurrence_text'   => &get_bit_text ($factor, \@RECURRENCE_TEXT),
    'cycle'             => shift,
    'rec_days'          => shift,
    'rec_months'        => shift,
    'duration_begin'    => shift,
    'duration_end'      => shift,
  };

  bless $obj;
}

# ----------------------------------------------------------------------------
# decode the recurrence status of an ADB record
# for details about the data structure, see adb-format.html
sub decode
{
  my $class= shift;
  my $factor= shift;
  my $b= shift;
 
  my $error= 0;

  my $lng= length ($b);

  my ($cycle, $rec_days, $rec_months)= unpack ('Cvv', substr ($b, 0, 5));
  my $rep_beg= &HP200LX::DB::fmt_date (substr ($b, 5, 3));
  my $rep_end= &HP200LX::DB::fmt_date (substr ($b, 8, 3));

  my $obj=
  {
    'recurrence'        => $factor,
    'recurrence_text'   => &get_bit_text ($factor, \@RECURRENCE_TEXT),
    'cycle'             => $cycle,
    'rec_days'          => $rec_days,
    'rec_months'        => $rec_months,
    'duration_begin'    => $rep_beg,
    'duration_end'      => $rep_end,
  };

  my ($off, $cnt);
  if ($lng == 18)
  { # NOTE: there does not seem to be any other indication of the
    #       data type here except the total length
    $obj->{type}= 'checked-off';
    my ($idx, $prev, $next, $main)= unpack ('Cvvv', substr ($b, 0x0B));
    $obj->{check_off_pointer}=
    {
      'idx'  => $idx,
      'prev' => $prev,
      'next' => $next,
      'main' => $main,
    };
  }
  else
  {
    $obj->{type}= 'exceptions';
    $obj->{exceptions}= [];

    $cnt= unpack ('C', substr ($b, 0x0B, 1));
    print "hide cnt=$cnt, lng=$lng\n";

    for ($off= 0x0C; $cnt > 0; $cnt--)
    {
      if ($off > $lng)
      {
        $error++;
        last;
      }

      my $d= &fmt_date (substr ($b, $off, 3));
      my $c= unpack ('C', substr ($b, $off+3, 1));
      push (@{$obj->{exceptions}}, { 'date' => $d, 'status' => $c });

      $off += 4;
    } 

    $error++ if ($off < $lng);
  }

  if ($error)
  {
    print "\n", '-'x72, "\nerror processing recurrence record!\n";
    print "lng=$lng cnt=$cnt off=$off\n";
    &hex_dump ($b, *STDOUT);
    &print_recurrence_status ($obj, *STDOUT);
  }

  bless $obj;
}

# ----------------------------------------------------------------------------
# pack the recurrence status of an ADB record
sub pack
{
  my $rec= shift;
  my $b;

  $b= pack ('Cvv', $rec->{cycle}, $rec->{rec_days}, $rec->{rec_months});
  $b .= &pack_date ($rec->{duration_begin});
  $b .= &pack_date ($rec->{duration_end});

  if ($rec->{type} eq 'checked-off')
  {
    my ($idx, $prev, $next, $main)=
    my $op= $rec->{check_off_pointer};
    $b .= pack ('Cvvv',
                $op->{'idx'}, $op->{'prev'}, $op->{'next'}, $op->{'main'});
  }
  else
  {
    my $oe= $rec->{exceptions};
    my $cnt= $#$oe;
    if ($cnt > 254)
    {
      print "warning: can't pack $cnt exceptions, truncating to 254!\n";
      $cnt= 254;
    }

    $b .= pack ('C', $cnt+1);

    my ($ox);
    foreach $ox (@$oe)
    {
      $b .= &pack_date ($ox->{'date'});
      $b .= pack ('C', $ox->{'status'});
    } 
  }

  $b;
}

# ----------------------------------------------------------------------------
# check-off a recurrence entry
sub check_off
{
  my $obj= shift;

  if ($obj->{type} eq 'exceptions')
  {
    print "warning: overwriting recurrence exceptions!\n";
  }

  $obj->{type}= 'checked-off';
  my ($idx, $prev, $next, $main)= unpack ('Cvvv', substr ($b, 0x0B));

  $obj->{check_off_pointer}=
  {
    'idx'  => shift,            # index within main entry
    'prev' => shift || $no_val,
    'next' => shift || $no_val,
    'main' => shift || $no_val,
  };
}

# ----------------------------------------------------------------------------
# set recurrence exception
# $recurrence->exception (date => status, ...);
sub exception
{
  my $obj= shift;
  my %dates= @_;

  if ($obj->{type} eq 'checked-off')
  {
    print "warning: overwriting recurrence check-off marker!\n";
  }

  unless ($obj->{type} eq 'exceptions')
  {
    $obj->{type}= 'exceptions';
    $obj->{exceptions}= [];
  }
  my $ex= $obj->{exceptions};

  my ($d);
  foreach $d (sort keys %dates)
  {
    push (@$ex, { 'date' => $d, 'status' => $dates{$d}});
  }
}

# ----------------------------------------------------------------------------
sub get_bit_text
{
  my $val= shift;
  my $text= shift;
  my ($str, $i);

  # $str= "$val:";
  for ($i= 0; $i <= $#$text; $i++)
  {
    if ($val & $BITS[$i])
    {
      $str .= ' ' if ($str);
      $str .= $text->[$i];
    }
  }
  $str;
}

# ----------------------------------------------------------------------------
sub get_recurrence_wdays_text
{
  &get_bit_text (shift, \@RECURRENCE_WDAY);
}

# ----------------------------------------------------------------------------
sub get_recurrence_months_text
{
  &get_bit_text (shift, \@RECURRENCE_MONTH);
}

# ----------------------------------------------------------------------------
sub get_recurrence_days_text
{
  my $val= shift;
  my $str;

  # $str .= sprintf (" [rec_days=0x%04X]", $val);
  if ($val & 0x0080)
  {
    $str .= &get_bit_text ($val >> 8, \@RECURRENCE_DAY);
    $str .= ' '. &get_recurrence_wdays_text ($val & 0x7F);
  }
  else
  {
    $str= sprintf (" on the %d.", $val & 0x7F);
  }
  $str;
}

# ----------------------------------------------------------------------------
sub print_recurrence_status
{
  my $obj= shift;
  local *FO= shift;

  my $recurrence= $obj->{recurrence};
  my $str= $obj->{recurrence_text};
  $str .= ', cycle='. $obj->{cycle} if ($recurrence >= 2 && $recurrence <= 16);

  if ($recurrence == 4)
  {
    $str .= ', '. &get_recurrence_wdays_text ($obj->{rec_days} & 0x7F);
  }

  if ($recurrence >= 8)
  {
    $str .= ', '. &get_recurrence_days_text ($obj->{rec_days});
  }

  if ($recurrence >= 16)
  {
    $str .= ' of '. &get_recurrence_months_text ($obj->{rec_months});
    # $str .= sprintf (" [rec_months=0x%04X]", $obj->{rec_months});
  }

  print FO <<EOX;
recurrence: [$recurrence] $str
duration:  $obj->{duration_begin}..$obj->{duration_end}
EOX

  if ($obj->{type} eq 'exceptions')
  {
    my $ex= $obj->{exceptions};
    if ($#$ex >= 0)
    {
      print FO "exceptions:\n",
      my $inst;
      foreach $inst (@$ex)
      {
        printf FO ("  %s %02X %s\n", $inst->{'date'}, $inst->{'status'},
                   @RECURRENCE_EXCEPTION [$inst->{'status'}] || '??');
      }
    }
  }
  elsif ($obj->{type} eq 'checked-off')
  {
    my $ptr= $obj->{check_off_pointer};
    print FO "checked-off item:\n",
             "  main entry/idx: $ptr->{main}/$ptr->{idx}\n",
             "  prev: $ptr->{prev}\n",
             "  next: $ptr->{next}\n";
  }
  else
  {
    print FO "unknown recurrence status: ", $obj->{type}, "\n";
  }
}

# ----------------------------------------------------------------------------
sub export_to_vCalendar
{
  my $obj= shift;
  my $time= shift || 'T00:00:00';

  my $rule= $RECURRENCE_XAPIA{$obj->{recurrence}} . $obj->{cycle} . ' '
            . $obj->{duration_end} . $time;

  my $exdate= join (',', map { $_->{'date'} . $time } @{$obj->{exceptions}});

  my $res=
  {
    'RRULE'     => $rule,
    'DTSTART'   => $obj->{duration_begin} . $time,
  };

  $res->{'EXDATE'}= $exdate if ($exdate);
  $res;
}

# ----------------------------------------------------------------------------
1;
