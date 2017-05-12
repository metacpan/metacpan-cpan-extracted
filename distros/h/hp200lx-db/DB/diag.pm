#!/usr/local/bin/perl
# FILE .../hp200lx-db/DB/diag.pm
#
# written:       2001-01-01
# latest update: 2001-01-01 18:13:36
# $Id: diag.pm,v 1.1 2001/01/01 20:31:05 gonter Exp $
#

package HP200LX::DB::diag;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

$VERSION= '0.09';
@ISA= qw(Exporter);
@EXPORT= qw(
  print_db_def print_db_def_html
);

# ----------------------------------------------------------------------------
sub print_db_def
{
  my $db= shift;
  local *FO= shift;

  $db->dump_def (*FO);
  print FO "database definition:\n";
  $db->show_db_def (*FO);
  # print FO "card definition:\n";
  $db->show_card_def (*FO);

  my $vpt_cnt= $db->get_viewptdef_count;
  print FO "view point count=$vpt_cnt\n";

  my $i;
  for ($i= 0; $i <= $vpt_cnt+100; $i++)
  {
    print FO "view point definition [$i]:\n";
    my $def= $db->find_viewptdef ($i);
    last unless (defined ($def));

    # print FO ">>> ", join (':', keys %$def), "\n";
    print FO "&type:vpt\n";
    print FO "&idx:$i\n";
    HP200LX::DB::vpt::show_viewptdef ($def, *FO);
  }
}

# ----------------------------------------------------------------------------
sub print_db_def_html
{
  my $db= shift;
  local *FO= shift;

  my @CDEF= @{$db->{'carddef'}};
  my @FDEF= @{$db->{'fielddef'}};
  my ($i, $j);
  my @CARD_FIELDS= qw(x y h w Lsize);

  print FO <<EOX;
<table border=1>
<tr><th rowspan=2>idx<th rowspan=2>name<th colspan=3>type
    <th rowspan=2>fid<th rowspan=2>off
    <th rowspan=2>res<th rowspan=2>flags
EOX
    foreach $j (@CARD_FIELDS)
    {
      print FO "<th rowspan=2>", $j, "</th>";
    }
  print FO <<EOX;
</tr>
<tr><th>num<th>name<th>size</tr>
EOX

  for ($i= 0;; $i++)
  {
    my $cdef= shift (@CDEF);
    my $fdef= shift (@FDEF);
    last unless (defined ($cdef) && defined ($fdef));
    # print FO "cdef=$cdef fdef=$fdef\n";

    my $type= $fdef->{'ftype'};
    my $ftype= HP200LX::DB::get_field_type ($type);
    my $ttype= $ftype->{Desc} || "USER$type";
    my $x_siz= $ftype->{Size};
    # print ">> type=$type ftype=$ftype ttype=$ttype\n";

    my $x_off= sprintf ('0x%02X', $fdef->{off});
    my $x_flg= sprintf ('0x%02X', $fdef->{flg});
    my $x_name= $fdef->{name};
    # T2D!!! $x_name=~ s/[\x80-\xFF]/?/g;

    print FO "<tr><td align=right>$i<td>'$x_name'",
             "<td align=right>$type<td>$ttype<td align=right>$x_siz",
             "<td align=right>$fdef->{fid}<td align=right>$x_off",
             "<td align=right>$fdef->{res}<td align=right>$x_flg";
    foreach $j (@CARD_FIELDS)
    {
      print FO "<td align=right>", $cdef->{$j}, "</td>";
    }
    print FO "</tr>\n";
  }

  print FO <<EOX;
</table>
EOX

}

# ----------------------------------------------------------------------------
1;
