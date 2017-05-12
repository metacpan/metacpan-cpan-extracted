# -*- cperl -*-
#
# (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
#

local *F;
#undef $/; undef $\; # i never remember which one is the end-of-input-record variable.
#open F,"d:\\build\\Win32-shellExt-0.1\\ShellExt.pm";
open F,"C:\\Documents and Settings\\jb\\My Documents\\testShellExt.pm";
#my $body = <F>;
my $body = undef;
while(<F>) {
  if(!defined($body) && m!VERSION!) {
    $body = $_;
    $body =~ s!^.*VERSION\s*=\s*'([^']+)'.*$!$1!g;
  }
}
close F;

print "\nWin32::ShellExt::QueryInfo::PM::get_info_tip=>$body\n";

