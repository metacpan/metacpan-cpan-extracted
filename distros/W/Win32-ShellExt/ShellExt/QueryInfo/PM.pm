# -*- cperl -*-
#
# sample extension that extracts the package version number out of a .pm file.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::PM;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

$Win32::ShellExt::QueryInfo::PM::VERSION='0.1';
@Win32::ShellExt::QueryInfo::PM::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  local *F;
  open F,$file;
  my $body = undef;
  while(<F>) {
    if(!defined($body) && m!VERSION!) {
      $body = $_;
      $body =~ s!^.*VERSION\s*=\s*'([^']+)'.*!$1!g;
      $body =~ s!\n!!g;
      $body =~ s!\r!!g;
    } # this loop sucks, it'll read the whole file even if the info we look for is at the beginning.
  }
  close F;

  {
    local *D;
    open D,">>D:\\log9.txt";
    print D "\nWin32::ShellExt::QueryInfo::PM::get_info_tip=>$file=>$body\n";
    close D;
  }
  "perl package: version $body";
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{1F625BE8-40F4-4692-AE18-A47371A0E322}",
	   "extension" => "pm",
	   "package" => "Win32::ShellExt::QueryInfo::PM"
	  };
  $h;
}

1;

