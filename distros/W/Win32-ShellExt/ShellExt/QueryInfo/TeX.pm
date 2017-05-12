# -*- cperl -*-
#
# sample extension that extracts some info out of a .tex file.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::TeX;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

$Win32::ShellExt::QueryInfo::TeX::VERSION='0.1';
@Win32::ShellExt::QueryInfo::TeX::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  local *F;
  open F,$file;
  my $body = undef;
  my $type = "TeX";
  my $author = undef;
  while(<F>) {
    $type="LATeX" if(m!documentclass!);
    if(m!\@!) {
      s!^.*[ \t{]([A-z0-9._-]+@[A-z0-9._-]+)[ \t}e].*$!$1!g;
      $author = " by $_";
    }
  }
  close F;

  "$type document$author";
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{1003AC09-0A04-46CC-9511-E9B2D7BA56C8}",
	   "extension" => "tex",
	   "package" => "Win32::ShellExt::QueryInfo::TeX"
	  };
  $h;
}

1;

