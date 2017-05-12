# -*- cperl -*-
#
# (C) 2002 jbnivoit@cpan.org
#
package Win32::ShellExt::QueryInfo::ELisp;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

$Win32::ShellExt::QueryInfo::ELisp::VERSION='0.1';
@Win32::ShellExt::QueryInfo::ELisp::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  "Emacs Lisp code";
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{A957E76F-9700-4F97-B8E2-1B3C6F687C19}",
	   "extension" => "tex",
	   "package" => "Win32::ShellExt::QueryInfo::ELisp"
	  };
  $h;
}

1;

