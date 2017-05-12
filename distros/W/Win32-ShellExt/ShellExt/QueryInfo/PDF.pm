# -*- cperl -*-
#
# sample extension that extracts the package version number out of a .pm file.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::PDF;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;

use PDF;

$Win32::ShellExt::QueryInfo::PDF::VERSION='0.1';
@Win32::ShellExt::QueryInfo::PDF::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  my $PDFfile = PDF->new($file);

  my $s;
  if ($PDFfile->IsaPDF) {
    $s = "PDF version ". $PDFfile->Version ." file with ".$PDFfile->Pages ." pages";
  }
  $s;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{D63BF9A5-66D7-469C-A5A7-62B3559F8A9B}",
	   "extension" => "pdf",
	   "package" => "Win32::ShellExt::QueryInfo::PDF"
	  };
  $h;
}

1;

