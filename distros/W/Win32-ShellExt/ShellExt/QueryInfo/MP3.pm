# -*- cperl -*-
#
# sample extension that extracts the package version number out of a .pm file.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::MP3;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo;
use MP3::Info qw(:all);

$Win32::ShellExt::QueryInfo::MP3::VERSION='0.1';
@Win32::ShellExt::QueryInfo::MP3::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  my $tag = get_mp3tag($file);
  my $s = "MP3 file :\n" . $tag->{ARTIST} . "\n" . $tag->{ALBUM} . "\n" . $tag->{TITLE};
  $s;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{A534E290-6136-4306-B57B-25500325DA05}",
	   "extension" => "mp3",
	   "package" => "Win32::ShellExt::QueryInfo::MP3"
	  };
  $h;
}

1;

