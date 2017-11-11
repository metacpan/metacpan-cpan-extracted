#! /usr/local/bin/perl -w

# vim: tabstop=4

# Makefile generator for libintl-perl.
# Copyright (C) 2002-2017 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335,
# USA.

use 5.004;
use ExtUtils::MakeMaker;

use strict;

# Make standard channels unbuffered.
select STDERR; $| = 1;
select STDOUT; $| = 1; 

sub ac_try_link;

use Config;

# Now try to compile and link a simple test program that uses all
# gettext facilities we need.  Failure of the test is not fatal
# since the pure Perl implementation will provide the same functionality.
# However, any help on making this test more portable would be
# highly appreciated!

unlink "config.log";

my $c = <<'EOF';
/* The following code only compiles if the interface to gettext is
   complete.  */

#include <libintl.h>
/* Handle the case that we link against GNU libintl but include a non
 * GNU libintl.h.  */
#ifndef __USE_GNU_GETTEXT
# error "<libintl.h> is not GNU gettext.  Maybe you have to adjust your include path."
#endif

#include <locale.h>

int
main (argc, argv)
	int argc;
    char* argv[];
{
	/* FIXME: The gettext runtime libraries provided by Solaris 8 and 9
       are not sufficient.  Those of Solaris 10 *may* work.  To play
       safe, we currently only compile the XS version for GNU gettext
       and use some undocumented features, to test for that.  Thanks
       to Bruno Haible for the hint.  */
	extern int _nl_msg_cat_cntr;
#if 0
        /* This seems to be defined in the GNU libc only, not in standalone
         * GNU gettext.  */
        extern int* _nl_domain_bindings;
#endif

	textdomain ("dummy");
	bindtextdomain ("dummy", ".");
	bind_textdomain_codeset ("dummy", "us-ascii");

	gettext ("msgid");
    	dgettext ("dummy", "msgid");
    	dcgettext ("dummy", "msgid", LC_MESSAGES);
	ngettext ("msgid", "msgid_plural", 
#if 0
		  _nl_msg_cat_cntr + *_nl_domain_bindings); 
#else
                  _nl_msg_cat_cntr);
#endif
	dngettext ("dummy", "msgid", "msgid_plural", 1);
	dcngettext ("dummy", "msgid", "msgid_plural", 1, LC_MESSAGES);

    	return 0;
}
EOF

my $build_gettext_xs = ac_try_link $c, "Checking whether we can compile the XS version";
unless ($build_gettext_xs) {
    $build_gettext_xs = ac_try_link $c, "  Trying again with -lintl", "-lintl";
}
unless ($build_gettext_xs) {
    $build_gettext_xs = ac_try_link $c, "  Trying again with -lintl -liconv", "-lintl", "-liconv";
}
unless ($build_gettext_xs) {
    $build_gettext_xs = ac_try_link $c, "  Trying again with -liconv", "-liconv";
}

unless ($build_gettext_xs) {
	print STDERR <<EOF;
=> Cannot build the XS version of libintl-perl (see 'config.log' for
=> details).  This is harmless!
EOF
} else {
	print STDERR <<EOF;
=> Building the XS version of libintl-perl.
EOF
}

sub ac_try_link {
    my ($c_code, $msg, @options) = @_;

	print STDERR "$msg ... ";
    local *HANDLE;
    open HANDLE, ">gettest.c" or die "cannot create file 'gettest.c': $!\n";
    print HANDLE $c_code;
    close HANDLE or die "cannot close file 'gettest.c': $!\n";

	my @cmd = $Config{cc};
    push @cmd, $Config{ccflags};
    push @cmd, $Config{ldflags};
    push @cmd, $Config{perllibs};
	push @cmd, @options;
    push @cmd, "-o", "gettest.exe", "gettest.c";

    # Temporarily redirect stdout and stderr.
    open OLDOUT, ">&STDOUT" or die "cannot dup STDOUT: $!";
    open OLDERR, ">&STDERR" or die "cannot dup STDERR: $!";
    open STDOUT, ">>config.log" or die "cannot redirect STDOUT: $!";
    open STDERR, ">&STDOUT" or die "cannot dup STDOUT: $!";
    select STDERR; $| = 1;
    select STDOUT; $| = 1;

    my $cmd = join ' ', @cmd;
    print <<EOC;
cat >gettext.c <<EOF
$c_code
EOF
EOC
    print "$cmd\n";
    my $result = system $cmd;

	# Restore standard file descriptors
	close STDOUT; #or die "cannot close STDOUT: $!";
	close STDERR; #or die "cannot close STDERR: $!";
	open STDOUT, ">&OLDOUT" or die "cannot dup \$oldout: $!";
	open STDERR, ">&OLDERR" or die "cannot dup OLDERR: $!";
	close OLDOUT; close OLDERR; # Shut up warnings.

	unlink "gettest.c", "gettest.exe";

	print STDERR $result ? "no.\n" : "yes.\n";

	return !$result;
}

package MY;

# FIXME: This is really a hack! Problem: Depending on the build system,
# we may or may not build and install the XS version.  If the XS version
# is being built, the directory blib/arch will be populated, if it is
# not being built, blib/arch will be empty.  Unfortunately, if blib/arch
# is not empty, *all* library files will be installed in the architecture
# dependent locations, if it is empty, they will be installed in the
# architecture independent tree.
#
# Unfortunately, ExtUtils::MakeMaker does not take care of uninstalling
# files from previous installations.  Consequently, we cannot determine
# which version of the library will be loaded, since this depends on the
# current value of @INC.
#
# The solution does not really make me happy.  The Makefile will be patched,
# so that instead of ExtUtils::Install a custom module MyInstall.pm will
# be used.  This custom module overwrites the subroutine that detects
# whether a directory is empty in ExtUtils::Install, and will lie if that
# directory happens to be "blib/arch".  This little hack effectively disables 
# the annoying behavior of ExtUtils::Install (and I sincerely hope that
# this is portable).
sub libscan 
{
	my ($self, $file) = @_;

	return if 'MyInstall.pm' eq $file;

	$self->SUPER::libscan ($file);	
}

sub tools_other 
{
	my $self = shift;

	my $fragment = $self->SUPER::tools_other (@_);

	$fragment =~ s/^MOD_INSTALL\s*=\s*(.*?)-MExtUtils::Install
		/MOD_INSTALL =$1-I. -MMyInstall/msx;

	return $fragment;
}

package main;

my $name = $0;
$name =~ s,Makefile\.PL$,xs_disabled,;
local *HANDLE;
open HANDLE, ">$name" or die "cannot open '$name' for writing: $!";
print HANDLE !$build_gettext_xs;
close HANDLE or die "cannot close '$name': $!";

WriteMakefile (
    NAME		    => 'libintl-perl',
	VERSION_FROM	=> 'lib/Locale/Messages.pm',
    ($] >= 5.005 ?
         (ABSTRACT          => 'High-Level Interface to Uniforum Message'
                                 . ' Translation',
	  AUTHOR	    => 'Guido Flohr <guido.flohr@cantanea.com>',
	 ) : (),
    ),
    PREREQ_PM		    => { 'File::Spec' => 0, version => 0.77 },
    META_MERGE		    => {
        recommends => { 'File::ShareDir' => 0 },
        resources  => {
            homepage   => 'http://www.guido-flohr.net/en/projects/',
            bugtracker => 'https://github.com/gflohr/libintl-perl/issues',
            repository => 'https://github.com/gflohr/libintl-perl.git',
        },
    },
    PL_FILES                => {},
    DIR		            => [$build_gettext_xs ? ('gettext_xs') : ()],
    clean		    => { FILES => 'xs_disabled build_xs' },
    (MM->can ('signature_target') ? (SIGN => 1) : ()),
    # If you want to build the XS version although the automatic detection
    # suggests not to build it, uncomment the following line.
    #DIR => [ ('gettext_xs') ],
);

sub MY::postamble {
        # This is for developers only.
        return '' if ! -e '.git';

        '
all :: Credits Changes README

# Make search.cpan.org happy but still follow GNU standards:
# # (Thanks to Graham Barr for the hint)
Credits: THANKS
	cat THANKS >$@

Changes: NEWS
	cat NEWS >$@

README: README.md
	cat README.md >$@
'
}

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
