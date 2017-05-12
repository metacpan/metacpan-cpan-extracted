#!/usr/local/bin/perl
# FILE .../CPAN/hp200lx-db/DB/tools.pm
#
# written:       1999-02-21
# latest update: 2001-01-01 18:11:21
# $Id: tools.pm,v 1.3 2001/01/01 20:31:05 gonter Exp $
#

package HP200LX::DB::tools;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

$VERSION= '0.09';
@ISA= qw(Exporter);
@EXPORT= qw(
  print_list
  print_content_line
);

# ----------------------------------------------------------------------------
# possibly only for ADB files!
sub print_list
{
  local *FO= shift;
  my $rec= shift;
  my $lang= shift;
  my $supress_null= shift;
  my $folding= shift;

  my ($field, $val);
  foreach $field (@_)
  {
    $val= $lang->{$field};
    # print "field='$field' val='$val'\n";
    next unless (exists ($rec->{$val}) && ($val= $rec->{$val}) ne '');
    next if ($supress_null && $val == 0);

    &print_content_line (*FO, $field, $val, $folding, 0);
  }
}

# ----------------------------------------------------------------------------
sub print_content_line
{
  local *FO= shift;
  my $field= shift;
  my $val= shift;
  my $folding= shift;
  my $multi= shift;             # true => may contain multiple values

  my ($val1, @lines);

  # multi line encoding, folding
  $val=~ s/\r//g;
  $val=~ s/\n+$//;              # remove any trainling new line at the end

    if ($folding eq 'none')
    {
      print FO $field, ':', $val, "\n";
    }
    elsif ($folding eq 'simple')
    {
      $val=~ s/\n/\n /g;   # this may be required, unsure ...

      print FO $field, ':', $val, "\n";
    }
    elsif ($folding eq 'rfc')
    {
      $val=~ s/([;\\])/\\$1/g; # basic escaping rules
      $val=~ s/([,])/\\$1/g unless ($multi); # escaping 
      $val=~ s/\n/\\n/g;        # backslash encoding

      $val= $field.':'.$val;
      while (length ($val) > 75)
      {
        $val1= substr ($val, 0, 75);
        $val= substr ($val, 75);
        print FO $val1, "\n ";
      }

      print FO $val, "\n";
    }
}

# ----------------------------------------------------------------------------
1;
