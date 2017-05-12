# -*- cperl -*-
#
# This one mimics the unix 'wc' utility,
# except it only reports line count.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::LineCount;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

$Win32::ShellExt::QueryInfo::WordCount::VERSION='0.1';
@Win32::ShellExt::QueryInfo::WordCount::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  local *F;
  open F,$file;
  my $wc = 0;
  while(<F>) { $wc++; }
  close F;

  "$wc lines";
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{67C1EC77-A84E-4e1f-BEF8-AF77B5E7F719}",
	   "extension" => "txt",
	   "package" => "Win32::ShellExt::QueryInfo::LineCount"
	  };
  $h;
}

1;

