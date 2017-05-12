#!/usr/local/bin/perl
# FILE .../CPAN/hp200lx-db/DB/vpt.pm
#
# View Point Management
# +  retrieve view point definintions
# +  retrieve view point tables
#
# Note:
# View Points are managed using two associated entities:
# 1. a view point definition, defining properties such as
#    + column arrangement
#    + criteria to select data records included in the view point
#    + sorting criteria
# 2. a view point table, containing the actual list of data record
#    indices in the appropriately sorted sequece and filtered using
#    the defined SSL criterium.
# 3. SSL == Select and Sort List (or so)
#
# At least one view point (VPT #0) is always present, it does not allow
# a SSL criterium and always includes all data.  However, sorting criteria
# and column arrangement are possible
#
# included by DB.pm
#
# exported methods:
#   $db->find_viewptdef                 retrieve a view point definition
#   $db->get_viewptdef_count
#
# exported functions:
#   get_viewptdef                       decode a view point definition
#   get_viewpttable                     decode a view point table
#   find_viewpttable                    retrieve a view point table
#   refresh_viewpt                      actively refresh a view point
#
# internal functions:
#   refresh_viewpt_table                perform the refreshing of a view point
#   time_cmp                            sort function to compare two time vals
#   sort_viewpt                         sort a complete view point table
#   parse_ssl_tok_str                   analyze the SSL string
#
# diagnostics and debugging methods:
#   show_viewptdef                      print details about a view point
#
# T2D:
# + re-calculate a view point table
#   DONE: SSL parser and evaluater are present but not complete
#   MISSING: sorting all the fields
# + converter for SSL string to SSL tokens (and vica versa?)
#   This can be used to edit the SSL string in an application
# + currently, there is no difference between a view point which
#   needs to be rebuilt and a view point with no data records.
#   In both cases, the view point table is empty.
#   DONE: view points are re-calculated even if no data is there.
#
# written:       1998-06-01
# latest update: 2001-03-03 20:54:08
# $Id: vpt.pm,v 1.4 2001/03/05 02:04:20 gonter Exp $
#

package HP200LX::DB::vpt;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

$VERSION= '0.09';
@ISA= qw(Exporter);
@EXPORT= qw(get_viewptdef   find_viewptdef   get_viewptdef_count
            get_viewpttable find_viewpttable
            refresh_viewpt
           );

my $delim= '-' x 74;            # optic delimiter
my $no_val=  65535;             # NIL, empty list, -1 etc.
my $MAX_SORT_FIELDS= 3;         # HP-200LX limitation

# ----------------------------------------------------------------------------
sub get_viewptdef
{
  my $def= shift;

  # print "\n", $delim, "\n", ">>>> viewptdef\n"; &HP200LX::DB::hex_dump ($def);

  my ($tok_lng, $str_lng, $flg)= unpack ('vvv', $def);
  # a view point name may have up to 32 characters but the first NULL
  # character indicates the end too.  The rest contains garabge!
  # my $name= &HP200LX::DB::upto_EOS (substr ($def, 7, 32));
  my $name= substr ($def, 7, 32);
  $name=~ s/\0.*$//s;  # ignore new lines!

  $def= substr ($def, 39);
  # print "name='$name'\n";

  # extract sorting information
  my ($s1, $s2, $s3, $a1, $a2, $a3)= unpack ('vvvvvv', $def);
  my $sort=
  [ { 'idx' => $s1, 'asc' => $a1 },
    { 'idx' => $s2, 'asc' => $a2 },
    { 'idx' => $s3, 'asc' => $a3 },
  ];

  # extract column arangements
  my (@cols, $i);
  $def= substr ($def, 12);
  # &HP200LX::DB::hex_dump ($def);
  for ($i= 0; $i < 20; $i++)
  {
    my ($num, $width)= unpack ('cc', substr ($def, $i*2, 2));
    last if ($num == -1);
    push (@cols, { num => $num, width => $width });
  }

  # T2D: $def= SSL String; decode SSL tokens+strings
  $def= substr ($def, 40);

  my $vptd=
  {
    'name'      => $name,
    'index'     => 0,           # filled in by calling module
    'flags'     => $flg,
    'tok_lng'   => $tok_lng,
    'str_lng'   => $str_lng,
    'tok_str'   => substr ($def, 0, $tok_lng),
    'str_str'   => substr ($def, $tok_lng, $str_lng),
    'sort'      => $sort,
    'cols'      => \@cols,
  };

  # &show_viewptdef ($vptd, *STDOUT);
  bless ($vptd);
}

# ----------------------------------------------------------------------------
sub get_viewptdef_count
{
  my $db= shift;
  my $vptdl= $db->{viewptdef};  # view point definition list

  $#$vptdl;
}

# ----------------------------------------------------------------------------
sub find_viewptdef
{
  my $db= shift;
  my $view= shift;      # name or number of the view

  my $vptdl= $db->{viewptdef};  # view point definition list

  if ($view =~ /^\d+$/)
  {
    return ($view >= 0 && $view <= $#$vptdl) ? $vptdl->[$view] : undef;
  }

  # T2D: this should be part of a function to retrieve
  #      the view point number of a named view point!!!
  my ($v, $vptd);
  foreach $v (@$vptdl)
  {
    # print "match: name=$v->{name} view=$view\n";
    if ($v->{name} eq $view) { print "found! v=$v\n"; $vptd= $v; last; }
  }
  print "vptd=$vptd\n";
  $vptd;
}

# ----------------------------------------------------------------------------
sub show_viewptdef
{
  my $vptd= shift;
  local *FX= shift;
  my ($i, $ci);

  unless (defined ($vptd))
  {
    print FX "viewpoint not defined!\n";
    return;
  }

  print FX $delim, "\nViewpoint '", $vptd->{name},
           "' flags=", $vptd->{flags},
           " tok_lng=", $vptd->{tok_lng},
           " str_lng=", $vptd->{str_lng}, "\n";
  my $s= $vptd->{'sort'};
  my $c= $vptd->{cols};
  for ($i= 0; $i < 3; $i++)
  {
    printf FX ("sort field: %3d %d\n", $s->[$i]->{idx}, $s->[$i]->{asc});
  }

  foreach $ci (@$c)
  {
    printf FX ("column field: %3d width=%2d\n", $ci->{num}, $ci->{width});
  }

  my $tok_str= $vptd->{tok_str};
  print FX "SSL tokens: lng=", length ($tok_str), "\n";
  &HP200LX::DB::hex_dump ($tok_str, *FX);

  my $str_str= $vptd->{str_str};
  print FX "SSL string: lng=", length ($str_str), "\n";
  &HP200LX::DB::hex_dump ($str_str, *FX);

  print FX $delim, "\n\n";
}

# ----------------------------------------------------------------------------
sub get_viewpttable
{
  my $def= shift;
  my ($l, $v);
  my @vptt= ();
  my $lng= length ($def);

  # print "\n", $delim, "\n", ">>>> viewpttable\n"; &HP200LX::DB::hex_dump ($def);
  for ($l= 0; $l < $lng; $l += 2)
  {
    ($v)= unpack ('v', substr ($def, $l, 2));
    last if ($v == $no_val);
    push (@vptt, $v);
  }

  \@vptt;
}

# ----------------------------------------------------------------------------
sub pack_viewpt_table
{
  my $tbl= shift;
  my $t;
  my $def= '';  # must be initialized!
  foreach $t (@$tbl)
  {
    $def .= pack ('v', $t);
  }
  # $def= pack ('v', $no_val) unless ($def);  # dummy entry if empty
  # NOTE: adding $no_val results in too many entries
  $def;
}

# ----------------------------------------------------------------------------
sub find_viewpttable
{
  my $db= shift;
  my $view= shift;                      # number of the view

  my $vpttl= $db->{viewpttable};        # view point table list

# print "find_viewpttable 1 view=$view\n";
  return undef unless ($view >= 0 && $view <= $#$vpttl);
# print "find_viewpttable 2 view=$view\n";
  my $vptt= $vpttl->[$view];

  $vptt= $db->refresh_viewpt ($view) if ($#$vptt < 0);
  # &HP200LX::DB::hex_dump ($vptt);
  $vptt;
}

# ----------------------------------------------------------------------------
sub refresh_viewpt
{
  my $db= shift;
  my $view= shift;                      # number of the view
  $view= -1 unless (defined ($view));

  my $vpttl= $db->{viewpttable};        # view point table list
  my $vptdl= $db->{viewptdef};          # view point definition list
  my ($vptd, $vptt, $view_start, $view_end);
  my $T10= $db->{Types}->[10];

  if (($view_start= $view_end= $view) == -1)
  {
    $view_start= 0;
    $view_end= $#$vptdl;
  }
# print "refresh: view=$view start=$view_start end=$view_end\n";

  for ($view= $view_start; $view <= $view_end; $view++)
  {
    $vptd= $vptdl->[$view];
    # &show_viewptdef ($vptd, *STDOUT);
    $vptt= $vpttl->[$view]= &refresh_viewpt_table ($db, $vptd);
    print "refreshed vptt[$view]: ", $#$vptt+1, " entries\n";
    $T10->[$view]->{data}= &pack_viewpt_table ($vptt);
  }

  $vptt;
}

# ----------------------------------------------------------------------------
# This method refreshes one particular view point table.
# A view point depends on a filter definition (called SSL in HP-LX lingo)
# which selects those entries that are used in a view point.
# Those entries that match are then sorted using up to three (HP-LX limitation)
# sort fields; I call this the chain of search fields.  This chain may
# have no entries at all, in this case, the records are presented
# in the order they appear in the GDB field itself.
sub refresh_viewpt_table
{
  my $db= shift;
  my $vptd= shift;
  my $vptt= [];

  my @SSL= &parse_ssl_tok_str ($vptd->{tok_str});
  my $ssls= $vptd->{str_str};
  my $fd= $db->{fielddef};
  my $sort= {}; # sort definition tree
  my @SORT;     # names of fields used for the sort

  my ($i, $j, $x, $y, $z, $op, $match);
  # print ">>>> vptd keys: ", join (', ', keys %$vptd), "\n";

  # prepare chain of sort fields
  my $rec= $sort= $vptd->{'sort'};
  # print ">>>> vptd sorting: sort='$sort' ", join (',', @$sort);
  for ($i= 0; $i < $MAX_SORT_FIELDS; $i++)
  {
    $y= $rec->[$i];
    $x= $fd->[$y->{idx}];
    last if ($y->{idx} == $no_val);
    push (@SORT, $y->{name}= $x->{name});

    # get the sort mode handy:
    # 0= ascending string, 1= descending string,
    # 2= ascending number, 3= descending number
    # 4= ascending time,   5= descending time
    # T2D: sorting date and other fields, time seems to work...

    my $ft= $x->{ftype};
       if ($ft == 4) { $z= 1; }            # number
    elsif ($ft == 7) { $z= 2; }            # time
    else { $z= 0; }

    $z= $z*2+ (($y->{asc}) ? 0 : 1);
    $y->{smode}= $z;
    # print "sort mode: x=$x name=$x->{name} ft=$ft z=$z\n";
  }

  my $T= ($#SORT == -1) ? [] : {};    # sorted records by sort fields
  # SPECIAL CASE: no sort fields means that fields are sorted by
  # the order they occur in the GDB file!
  # We use an array reference for this case, otherwise the
  # array reference is at the end of the chain of sort-field names.

  my $cnt= $db->get_last_index ();    # total number of records
  # print "refreshing view point; ssl_str=$ssls num(SSL)=$#SSL dbcnt=$cnt\n";
  for ($i= 0; $i <= $cnt; $i++)
  {
    $rec= $db->FETCH ($i);
    # print "rec: ", join (':', keys %$rec), "\n";

    if ($#SSL < 0)
    {
      $match= 1;  # no SSL string thus use everything!
    }
    else
    { # SSL was defined
      $match= 0;
      # this is the SSL match engine, it works like a mini FORTH interpreter
      my @ST= ();   # Forth Stack
      my $SSL;
      foreach $SSL (@SSL)
      {
        $op= $SSL->{op};

        if ($op == 0x0012)
        { # convert field index to name
          $x= $fd->[$SSL->{idx}]->{name};
          $SSL->{name}= $x;
          $op= $SSL->{op}= 0x0112;
        }

           if ($op == 0x0001) { push (@ST, !pop (@ST)); }
        elsif ($op == 0x0002) { push (@ST, pop (@ST) || pop (@ST)); }
        elsif ($op == 0x0003) { push (@ST, pop (@ST) && pop (@ST)); }
        elsif ($op == 0x0004) { push (@ST, pop (@ST) == pop (@ST)); }
        elsif ($op == 0x0009) { push (@ST, pop (@ST) != pop (@ST)); }
        elsif ($op == 0x000B)
        {
          $x= pop (@ST);
          $y= pop (@ST);
          $z= ($y =~ /$x/);
          # print "contains: $x in $y -> $z\n";
          push (@ST, $z);
        }
        elsif ($op == 0x0011) { push (@ST, $SSL->{str}); }
        elsif ($op == 0x0112) { push (@ST, $rec->{$SSL->{name}}); }
        elsif ($op == 0x0018)
        {
          $z= pop (@ST);
          $match= 1 if ($z);
          # print "MATCH: $match\n";
        }
        else
        {
          print "unimplemented SSL op=$op\n";
        }
      }
    }

    if ($match)
    { # sorting: build up a sort tree
      # search the array reference holding the record indices
      # the tree looks something like this:
      #   $T->{$rec->{$SORT[0]}}->...->{$rec->{$SORT[n]}}= [ rec indices ]
      # The sort tree may be 1, 2, or 3 levels deep.
      $x= $T;
      $j= 0;
      for ($j= 0; $j <= $#SORT; $j++)
      {
        $y= $rec->{$SORT[$j]};
        if (defined ($z= $x->{$y})) { $x= $z; }
        else { $x= $x->{$y}= ($j == $#SORT) ? [] : {}; }
      }
      push (@$x, $i);
    }
  }

  my @sort= @$sort;
  &sort_viewpt ($vptt, $T, @sort);

  $vptt;
}

# ----------------------------------------------------------------------------
# compare two time strings
sub time_cmp
{
  # my ($a, $b)= @_;
  my $la= length ($a);
  my $lb= length ($b);

  # print "a=$a b=$b la=$la lb=$lb\n";
     if ($la == $lb)    { return ($a cmp $b); }
  elsif ($la <  $lb)    { return -1; }
  else                  { return 1;  }
}

# ----------------------------------------------------------------------------
# the HP-LX compares strings in lower case
sub cmpc
{
  my ($la, $lb)= ($a, $b);
  $la=~ tr/A-Z/a-z/;
  $lb=~ tr/A-Z/a-z/;
     if ($la eq $lb)    { return ($a cmp $b); }
  elsif ($la lt $lb)    { return -1; }
  else                  { return 1;  }
}

# ----------------------------------------------------------------------------
sub sort_viewpt
{
  my ($vptt, $T, @sort)= @_;
  my (@keys, $key);

  if (ref ($T) eq 'ARRAY')
  { # final leaf in the sort tree reached, push the array up...
    push (@$vptt, @$T);
  }
  elsif (ref ($T) eq 'HASH')
  {
    my $s= shift (@sort);
    my $sm= $s->{smode};

       if ($sm == 0) { @keys=         sort cmpc keys %$T; }
    elsif ($sm == 1) { @keys= reverse sort cmpc keys %$T; }
    elsif ($sm == 2) { @keys=         sort {$a <=> $b} keys %$T; }
    elsif ($sm == 3) { @keys=         sort {$b <=> $a} keys %$T; }
    elsif ($sm == 4) { @keys=         sort time_cmp keys %$T; }
    elsif ($sm == 5) { @keys= reverse sort time_cmp keys %$T; }

    foreach $key (@keys)
    {
      &sort_viewpt ($vptt, $T->{$key}, @sort);
    }
  }
}

# ----------------------------------------------------------------------------
sub parse_ssl_tok_str
{
  my $str= shift;

  # print ">>> parse_ssl_tok_str str='$str'\n"; HP200LX::DB::hex_dump ($str);
  return () unless ($str);

  my @res;
  my $i= 0;
  my ($ci, $nv);
  while (1)
  {
    $ci= unpack ('C', substr ($str, $i, 1));

    if ($ci >= 0x01 && $ci <= 0x0B) # string contains
    {
      $i++;
      push (@res, { op => $ci });
    }
    elsif ($ci == 0x11) # String token
    {
      $i++;
      $nv= '';
      while (1)
      {
        $ci= substr ($str, $i++, 1);
        last if ($ci eq "\x00");
        $nv .= $ci;
      }
      print "str: $nv\n";
      push (@res, { op => 0x11, str => $nv });
    }
    elsif ($ci == 0x12 || $ci == 0x13) # name or boolean token (field index token)
    {
      $nv= unpack ('v', substr ($str, $i+1, 2));
      $i += 3;
      print "field index: $nv\n";
      push (@res, { op => 0x12, idx => $nv });
    }
    elsif ($ci == 0x18) # last token
    {
      push (@res, { op => 0x18 });
      last;
    }
    else
    {
      printf (">>> unknown SSL token [%d] 0x%02X\n", $i, $ci);
      $i++;
    }
  }

  print "done parsing\n";

  @res;
}

# ----------------------------------------------------------------------------
1;
