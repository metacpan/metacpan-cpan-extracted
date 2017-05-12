# -*- cperl -*-
#
# (C) 2002 jbnivoit@cpan.org
#

package Win32::ShellExt::CopyHook::Veto;

use 5.006;
use warnings;
use Win32::ShellExt::CopyHook;

$Win32::ShellExt::CopyHook::Veto::VERSION='0.1';
@Win32::ShellExt::CopyHook::Veto::ISA=qw(Win32::ShellExt::CopyHook);

sub copycb() {
  local *F;
  open F,">d:\\log12.txt";
  print F join ' ', @_;
  close F;
  undef;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{8A1565B1-A8A1-4BCD-9708-7E34AD675632}",
	   "package" => "Win32::ShellExt::CopyHook::Veto"
	  };
  $h;
}

1;

