# -*- cperl -*-
#
# Show the URL when hovering over a .URL shortcut file.
#
# (C) 2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::Shortcut;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

$Win32::ShellExt::QueryInfo::Shortcut::VERSION='0.1';
@Win32::ShellExt::QueryInfo::Shortcut::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  local *F;
  open F,$file;
  <F>;
  <F>;
  s!URL=!!g;
  $_;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{E4C274F5-C773-48DC-AA47-BC779C31740F}",
	   "extension" => "URL",
	   "package" => "Win32::ShellExt::QueryInfo::Shortcut"
	  };
  $h;
}

1;

