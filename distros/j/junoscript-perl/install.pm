#
# $Id: install.pm,v 1.17 2003/02/03 16:45:43 rjohnst Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package install;

use File::Basename;

sub redirect_input
{
    my $file = shift;

    open(OLDIN, ">&STDIN") || die "Can't duplicate standard input: $!";
    open(STDIN, "< $file") || die "Can't redirect standard input: $!";
}

sub restore_input
{
    close(STDIN) || die "Can't close STDIN: $!";
    open(STDIN, ">&OLDIN") || die "Can't restore standard input: $!";
    close(OLDIN) || die "Can't close OLDIN: $!";
}

sub redirect_output
{
    my $file = shift;
    my $append = shift;
    open(OLDOUT, ">&STDOUT") || die "Can't duplicate standard output: $!";
    open(OLDERR, ">&STDERR") || die "Can't duplicate standard error: $!";
    if ($append) {
        open(STDOUT, ">> $file") || die "Can't redirect standard output: $!";
    } else {
        open(STDOUT, "> $file") || die "Can't redirect standard output: $!";
	seek(STDOUT, 0, 0);
    }
    open(STDERR, ">&STDOUT") || die "Can't redirect standard error: $!";
}

sub restore_output
{
    close(STDOUT) || die "Can't close STDOUT: $!";
    close(STDERR) || die "Can't close STDERR: $!";
    open(STDERR, ">&OLDERR") || die "Can't restore standard error: $!";
    open(STDOUT, ">&OLDOUT") || die "Can't restore standard output: $!";
    close(OLDOUT) || die "Can't close OLDOUT: $!";
    close(OLDERR) || die "Can't close OLDERR: $!";
}

sub versions {
        my($current, $new) = @_;
        my(@A) = ($current =~ /(\.|\d+|[^\.\d]+)/g);
        my(@B) = ($new =~ /(\.|\d+|[^\.\d]+)/g);
        my($A,$B);
        while(@A and @B) {
                $A=shift @A;
                $B=shift @B;
                if($A eq "." and $B eq ".") {
                        next;
                } elsif( $A eq "." ) {
                        return -1;
                } elsif( $B eq "." ) {
                        return 1;
                } elsif($A =~ /^\d+$/ and $B =~ /^\d+$/) {
                        if ($A =~ /^0/ || $B =~ /^0/) {
                                return $A cmp $B if $A cmp $B;
                        } else {
                                return $A <=> $B if $A <=> $B;
                        }

                } else {
                        $A = uc $A;
                        $B = uc $B;
                        return $A cmp $B if $A cmp $B;
                }
        }
        @A <=> @B;
}

sub class_exists 
{
    my $class = shift;
    my $vers = shift;

    print "Checking to see if $class exists\n";
    my $command = "perl -e 'use $class;'";
    my $error = system($command);
    if ($error) { 
	print "Got Error : $error\n";
 	return 0;
    }
    $command = "perl -e 'use " . $class . '; print $' . $class . "::VERSION;'";
    my $my_version = `$command`;

    print "Checking to see if $vers is older\n";
    if ($vers) {
	print "Current version $my_version and proposed version $vers\n";
	if (versions($my_version, $vers) < 0) {
	    return 0;
	}
    }

    print "$class $vers is already installed\n";
    return $my_version if $my_version;
    return "unknown";
}

sub c_module_exists
{
    my ($module, $install_directory) = @_;
    if ($class_searchers{$module}) {
        return &{$class_searchers{$module}}($module, $install_directory);
    }
    if ( $module =~ /\.a$/ || $module =~ /\.so$/ )  {
	# this is a c libary, common defaults are /usr/local/lib and /usr/lib
	my @defaults = ('/usr/local/lib', '/usr/lib');
	push(@defaults, $install_directory) if $install_directory;
	for my $libdir (@defaults) {
	    if (-f "$libdir/$module") {
		return 1;
	    }
 	}
    } else {
	# this is a c executable
	return 1 if get_executable_path($module);
    }
    return 0;
}

sub is_c_module 
{
    my $lib = shift;
    for my $module (@c_modules) {
	return 1 if ($lib eq $module);
    }
    if ($lib =~ /.*\.a/){
       return 1;
    } 
    return 0;
}

sub add_access_method
{
    my(%access_info) = @_;
    my $arg = $access_info{c_modules};
    my @access_c_modules = @$arg;
    $arg = $access_info{prereqs};
    my %access_prereqs = %$arg;
    $arg = $access_info{estimates};
    my %access_estimates = %$arg;
    $arg = $access_info{tarballs};
    my %access_tarballs = %$arg;
    $arg = $access_info{authors};
    my %access_authors = %$arg;
    $arg = $access_info{class_searchers};
    my %access_class_searchers = %$arg;
    $arg = $access_info{modifiers};
    my %access_modifiers = %$arg;
    $arg = $access_info{install_flags};
    my %access_install_flags = %$arg;

    push(@accesses, $access_info{name});
    push(@c_modules, @access_c_modules);
    my %merged = (%prereqs, %access_prereqs);
    %prereqs = %merged;
    %merged = (%estimates, %access_estimates);
    %estimates = %merged;
    %merged = (%tarballs, %access_tarballs);
    %tarballs = %merged;
    %merged = (%authors, %access_authors);
    %authors = %merged;
    %merged = (%class_searchers, %access_class_searchers);
    %class_searchers = %merged;
    %merged = (%modifiers, %access_modifiers);
    %modifiers = %merged;
    %merged = (%install_flags, %access_install_flags);
    %install_flags = %merged;

    return 1;
}

#
# accesses[] gives us the list of access methods this installation supports
# classes[] gives us the list of class in the order they must be installed
# prereqs{} gives us the version that must be installed
# tarballs{} gives us the name of the file that we must install
# authors{} gives us the name of the author of the module
#

use constant ACCESS_TELNET => 'telnet';
use constant ACCESS_ALL => 'all';
use constant ACCESS_DEFAULT => 'default';

@accesses = ( ACCESS_TELNET );

@acmethod_telnet_classes = qw(
    libexpat.a
    MIME::Base64
    URI
    Date::Manip
    Parse::Yapp::Driver
    HTML::Tagset
    HTML::Parser
    Net::FTP
    Digest::MD5
    LWP
    XML::Parser
    XML::Parser::PerlSAX
    XML::DOM
    IO::Tty
);

@acmethod_telnet_classes_excp = qw(
);

@c_modules = qw(
    libexpat.a
    gtkdoc
    libxml2.a
    libxslt.a
);

@get_chassis_inventory_classes = qw (
    gtkdoc
    libxml2.a
    libxslt.a
);

@get_chassis_inventory_classes_excp = qw (
    Term::ReadKey 
);

@diagnose_bgp_classes = qw(
    gtkdoc
    libxml2.a
    libxslt.a
);

@diagnose_bgp_classes_excp = qw(
    Term::ReadKey
);

@load_configuration_classes = qw(
);

@load_configuration_classes_excp = qw(
    Term::ReadKey
);

#  DBIx::Recordset installation is interactive, should be installed by hand
@RDB_classes = qw(
    DBI
    DBD::mysql
    DBIx::DBSchema
    DBIx::Sequence
    FreezeThaw
);

@RDB_classes_excp = qw(
    DBIx::Recordset
);

%prereqs = (
	    'libexpat.a' => "1.95.5",
	    'libxml2.a' => "2.4.28",
	    'libxslt.a' => "1.0.23",
	    DBD::mysql => "2.1020",
	    DBI => "1.32",
	    DBIx::DBSchema => "0.21",
	    DBIx::Recordset => "0.24",
	    DBIx::Sequence => "1.3",
	    Date::Manip => "5.40",
            Digest::MD5 => "2.20",
	    FreezeThaw => "0.43",
	    HTML::Parser => "3.26",
	    HTML::Tagset => "3.03",
	    IO::Tty => "1.02",
	    LWP => "5.65",
	    MIME::Base64 => "2.12",
            Net::FTP => "1.12",
	    Parse::Yapp::Driver => "1.05",
	    Term::ReadKey => "2.21",
	    URI => "1.22",
	    XML::DOM => "1.05",
	    XML::Parser => "2.31",
	    XML::Parser::PerlSAX => "0.07",
    	    gtkdoc => "0.9",
);

%estimates = (
	    'libexpat.a' => "00:00:08",
	    'libxml2.a' => "00:00:32",
	    'libxslt.a' => "00:01:46",
	    DBD::mysql => "00:00:45",
	    DBI => "00:00:17",
	    DBIx::DBSchema => "00:00:04",
	    DBIx::Recordset => "00:00:05",
	    DBIx::Sequence => "00:00:03",
	    Date::Manip => "00:00:25",
            Digest::MD5 => "00:00:06",
	    FreezeThaw => "00:00:03",
	    HTML::Parser => "00:00:15",
	    HTML::Tagset => "00:00:03",
	    IO::Tty => "00:00:05",
	    LWP => "00:00:31",
	    MIME::Base64 => "00:00:04",
            Net::FTP => "00:00:10",
	    Parse::Yapp::Driver => "00:00:10",
	    Term::ReadKey => "00:00:20",
	    URI => "00:00:10",
	    XML::DOM => "00:01:05",
	    XML::Parser => "00:00:14",
	    XML::Parser::PerlSAX => "00:00:10",
    	    gtkdoc => "00:00:04",
);

%tarballs = (
	    'libexpat.a' => "expat-1.95.5.tar.gz",
	    'libxml2.a' => "libxml2-2.4.28.tar.gz",
	    'libxslt.a' => "libxslt-1.0.23.tar.gz",
	    DBD::mysql => "DBD-mysql-2.1020.tar.gz",
	    DBI => "DBI-1.32.tar.gz",
	    DBIx::DBSchema => "DBIx-DBSchema-0.21.tar.gz",
	    DBIx::Recordset => "DBIx-Recordset-0.24.tar.gz",
	    DBIx::Sequence => "DBIx-Sequence-1.3.tar.gz",
	    Date::Manip => "DateManip-5.40.tar.gz",
            Digest::MD5 => "Digest-MD5-2.20.tar.gz",
	    FreezeThaw => "FreezeThaw-0.43.tar.gz",
	    HTML::Parser => "HTML-Parser-3.26.tar.gz",
	    HTML::Tagset => "HTML-Tagset-3.03.tar.gz",
	    IO::Tty => "IO-Tty-1.02.tar.gz",
	    LWP => "libwww-perl-5.65.tar.gz",
	    MIME::Base64 => "MIME-Base64-2.12.tar.gz",
            Net::FTP => "libnet-1.12.tar.gz",
	    Parse::Yapp::Driver => "Parse-Yapp-1.05.tar.gz",
	    Term::ReadKey => "TermReadKey-2.21.tar.gz",
	    URI => "URI-1.22.tar.gz",
	    XML::DOM => "libxml-enno-1.05.tar.gz",
	    XML::Parser => "XML-Parser-2.31.tar.gz",
	    XML::Parser::PerlSAX => "libxml-perl-0.07.tar.gz",
    	    gtkdoc => "gtk-doc-0.9.tar.gz",
);

%authors = (
	    'libexpat.a' => 'expat-bugs@lists.sourceforge.net',
	    'libxml2.a' => 'Daniel Veillard daniel@veillard.com',
	    'libxslt.a' => 'Daniel Veillard Daniel.Veillard@imag.fr',
	    DBD::mysql => 'Jochen Wiedmann (joe@ispsoft.de)',
	    DBI => 'Tim Bunce (dbi-users@perl.org)',
	    DBIx::DBSchema => 'Ivan Kohler (ivan-pause@420.am)',
	    DBIx::Recordset => 'Gerald Richter (richter@ecos.de)',
	    DBIx::Sequence => 'Benoit Beausejour (bbeausej@pobox.com)',
	    Date::Manip => 'Sullivan Beck (sbeck@cpan.org)',
            Digest::MD5 => 'Gisle Aas (gisle@ActiveState.com)',
	    FreezeThaw => 'Ilya Zakharevich (ilya@math.ohio-state.edu)',
	    HTML::Parser => 'Gisle Aas (gisle@ActiveState.com)',
	    HTML::Tagset => 'Sean M. Burke (sburke@cpan.org)',
	    IO::Tty => 'Graham Barr (gbarr@pobox.com)',
	    LWP => 'Gisle Aas (gisle@ActiveState.com)',
	    MIME::Base64 => 'Gisle Aas (gisle@ActiveState.com)',
            Net::FTP => 'Graham Barr (gbarr@pobox.com)',
	    Parse::Yapp::Driver => 'Francois Desarmenien (francois@fdesar.net)',
	    Term::ReadKey => 'Kenneth Albanowski (kjahds@kjahds.com)',
	    URI => 'Gisle Aas (gisle@ActiveState.com)',
	    XML::DOM => 'T.J. Mather (tjmather@tjmather.com)',
	    XML::Parser => 'Clark Cooper (coopercc@netheaven.com)',
	    XML::Parser::PerlSAX => 'Ken MacLeod (ken@bitsko.slc.ut.us)',
    	    gtkdoc => 'Damon Chaplin (damon@ximian.com)',
);

%class_searchers = (
	    gtkdoc => "install::gtkdoc_exists",
	    'libexpat.a' => "install::libexpat_exists",
);

%modifiers = (
      'libxml2.a' => "install::modify_libxml2_a",
);

#
# install_flags{} are flags to append to the perl Makefile.PL command
#
%install_flags = ();

sub activate_access_methods
{
    my $install_directory = shift;
    if (opendir(DIR, 'access')) {
        while(defined($file = readdir(DIR))) {
	    if ($file =~/.pm$/) {
	        require "access/$file";
	        my $method = $file;
	        $method =~ s/\.pm//;
	        $method = "install::$method" . "_add_install_flags";
	        &{$method}($install_directory);
	    }
        }
    }
}

sub get_access_count
{
    my($access_list) = @_;
    my $total = 0;
    for my $acmethod (@accesses) {
	if (access_allowed($acmethod, $access_list)) {
	    $total++;
     	}
    }
    return $total;
}

sub access_allowed
{
    my ($access, $access_list) = @_;
    return 1 if $access_list eq ACCESS_ALL;

    # Always allow telnet
    return 1 if $access eq ACCESS_TELNET;
    
    if ($access_list =~ /$access/) {
	return 1;
    }
    return;
}

sub get_auto_classes
{
    my ($access, $used_by) = @_;
    my @modules;

    for my $acmethod (@accesses) {
	if (access_allowed($acmethod, $access)) {
	    my $class_list = 'acmethod_' . $acmethod . '_classes';
	    push(@all_acclasses, @$class_list);
	}
    }

    if ($used_by eq "RDB") {
        @modules = @RDB_classes;
    } elsif ($used_by eq "diagnose_bgp") {
        @modules = @diagnose_bgp_classes;
    } elsif ($used_by eq "get_chassis_inventory") {
        @modules = @get_chassis_inventory_classes;
    } elsif ($used_by eq "load_configuration") {
        @modules = @load_configuration_classes;
    } elsif ($used_by eq "JUNOS::Device") {
        @modules = @all_acclasses;
    } else {
        @modules = (@all_acclasses,@get_chassis_inventory_classes);
    }

    return @modules;;
}

sub get_manual_classes
{
    my ($access, $used_by) = @_;
    my @byhand;

    for my $acmethod (@accesses) {
	if (access_allowed($acmethod, $access)) {
	    my $class_list = 'acmethod_' . $acmethod . '_classes_excp';
	    push(@all_acclasses_excp, @$class_list);
	}
    }

    if ($used_by eq "RDB") {
        @byhand = @RDB_classes_excp;
    } elsif ($used_by eq "diagnose_bgp") {
        @byhand = @diagnose_bgp_classes_excp;
    } elsif ($used_by eq "get_chassis_inventory") {
        @byhand = @get_chassis_inventory_classes_excp;
    } elsif ($used_by eq "load_configuration") {
        @byhand = @load_configuration_classes_excp;
    } elsif ($used_by eq "JUNOS::Device") {
        @byhand = @all_acclasses_excp;
    } else {
        @byhand = (@all_acclasses_excp,@get_chassis_inventory_classes_excp);
    } 

    return @byhand;;
}

sub get_version
{
    my $class = shift;
    return $prereqs{$class};
}

sub get_estimate
{
    my $class = shift;
    return $estimates{$class};
}

sub get_tarball
{
    my $class = shift;
    return $tarballs{$class};
}

sub get_author
{
    my $class = shift;
    return $authors{$class};
}

sub get_install_flags
{
    my $class = shift;
    return $install_flags{$class};
}

sub set_install_flags
{
    my ($class, $flags) = @_;
    $install_flags{$class} = $flags;
}

sub get_modifier 
{
    my $class = shift;
    return $modifiers{$class};
}

sub get_executable_path
{
    my $exec = shift;
    foreach (split(/:/, $ENV{PATH})) {
        return $_ if (-x $_."/$exec") # or '-x' even
    }
    return;
}

#
# Customization
# The following subroutines are here to deal with special cases of modules
# that don't have a pattern on checking for its existence, installation
# invocation, etc.
# 

sub modify_file
{  
    my $file = shift;
    my $old = shift;
    my $new = shift;

    my $tmp = "$file.tmp";

    if (!open(ORG, "< $file")) {
        print "can't open $file: $!\n";
        return 0;
    }
    if (!open(TMP, "> $tmp")) {
        print "can't open $tmp: $!\n";
        return 0;
    }
   
    while(<ORG>) {
        s/$old/$new/ge;
        print TMP $_;
    }

    if (!close(ORG)) {
        print "can't close $file: $!\n";
        return 0;
    }
    if (!close(TMP)) {
        print "can't close $tmp: $!\n";
        return 0;
    }
    if (!rename($file, "$file.orig")) {
        print "can't rename $file to $file.orig: $!\n";
        return 0;
    }
    if (!rename($tmp, $file)) {
        print "can't rename $tmp to $file: $!\n";
        return 0;
    }
    return 1;
}

sub modify_libxml2_a
{
    my ($kernel, $prefix, $install_directory) = @_;
    print "**** Patching libxml2.a\n";
    modify_file("$prefix/Makefile", "^libxml2_la_LIBADD = ", "libxml2_la_LIBADD = -L$install_directory ");
}

#
# Special handling subroutines to check whether a c module exists, this is
# needed only if the c library cannot be found through the standard means.
#
sub gtkdoc_exists
{
    my ($module, $install_directory) = @_;
    # As long as libxml2.a is installed, things are cool
    if (c_module_exists('libxml2.a', $install_directory)) {
	return 1;
    }
    return 0;
}

sub libexpat_exists
{
    my ($module, $install_directory) = @_;

    my @defaults = ('/usr/local/lib', '/usr/lib');
    push(@defults, $install_directory) if ($install_directory);
    for my $libdir (@defaults) {
        if (-f "$libdir/$module") {
	    set_install_flags('XML::Parser', "EXPATLIBPATH=$libdir EXPATINCPATH=$libdir/../include");
	    return 1;
	}
    }
    return 0;
}

#
# End of Customization
#

1;
