# -*- perl -*-

use ExtUtils::MakeMaker;

$| = 1;
print "Checking for Storable ... ";
eval { require Storable };
if ($@) {
    print STDERR "\nYou must have installed the 'Storable' module.\n";
    print STDERR "You get it at the CPAN. See 'man CPAN' or 'perldoc CPAN'";
    print STDERR "for more info.\n";
    exit 10;
}
print "ok\n";

print "Checking for Sys::Syslog ... ";
eval { require Sys::Syslog };
if ($@) {
    my $errmsg = $@;
    $errmsg =~ s/^/  /mg;
    if ($@ =~ /h2ph/) {
	print STDERR <<"MSG";

While loading the Sys::Syslog module, I received the following error message:

$errmsg

Most probably this means that you did not run the h2ph script after
installing Perl. You can do this now by executing the commands

    cd /usr/include
    h2ph *.h */*.h */*/*.h


MSG
        exit 10;
    }
    print STDERR "\nYou must have installed the 'Sys::Syslog' module.\n";
    print STDERR "You get it at the CPAN. See 'man CPAN' or 'perldoc CPAN'";
    print STDERR "for more info.\n";
    exit 10;
}
print "ok\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'RPC::pServer',
    'DISTNAME'  => 'pRPC-modules',
    'dist'      => { SUFFIX   => '.gz', DIST_DEFAULT => 'all tardist',
                     COMPRESS => 'gzip -9f' },
    'VERSION_FROM' => 'lib/RPC/pServer.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);

package MY;

sub libscan { my($self, $path) = @_; ($path =~ /\~$/) ? undef : $path }
