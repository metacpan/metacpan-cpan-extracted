#
# $Id: install-prereqs.pl,v 1.39 2003/11/11 19:08:26 rjohnst Exp $
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

use POSIX qw(uname);
use install;
use Benchmark;

use constant OUTPUT_DATA_FORMAT => "%-30s %-10s";
use constant OUTPUT_TITLE_FORMAT => "%-30s %-10s%s\n";
use constant OUTPUT_TITLE =>   "\n======================= PERL MODULE INSTALLATION ======================\n\n";
use constant OUTPUT_ENDING =>  "\n=======================================================================\n\n";
use constant OUTPUT_DIVIDER => "\n-----------------------------------------------------------------------\n\n";
use constant LOG_HIGHLITE => "=====================================================\n%s\n=====================================================\n";

#
# Set AUTOFLUSH to true
#
$| = 1;

# print the usage of this script
sub output_usage
{
    my $usage = "
Usage: $0 [options]

Options:

  -install_directory <directory>
        Use this option to install the modules under your own private
        directory.  By default, the installation directory for the
	perl modules is configured in the perl executable and
	the install directory for libexpat.a is /usr/local/lib.
	If this option is provided, the specified directory will be 
	the installation directory.  Make sure you set the environment 
	variable PERL5LIB to the same private directory before running 
	this script and the examples. 
	(e.g. setenv PERL5LIB /my/private/directory/lib)

  -force
	Upgrade all required modules to the versions specified and install
	even when 'make test' has failed.  By defaul, this script reports
	warning/failure as soon as it detects an existing module with an 
	older version or when 'make test' fails.  This option tells it
	to go ahead and force the installation.

  -force_update
        This does half of what -force does.  It tells the script to
        update the older module in the system to the required version.
        If 'make test' fails, the script still reports failure.

  -force_install
        This does half of what -force does.  It tells the script to
        go ahead and do 'make install' even when 'make test' fails.
        If an older version of the module exists, the script still 
	reports warning.

  -force_override
        This forces installation of all required modules regardless
        of whether the modules of the correct versions have already 
        been installed.

  -used_by <example>
        By default, the Perl modules required by JUNOS::Device,
	get_chassis_inventory, load_configuration and diagnose_bgp are
        installed.  If this option is provided, this script will
        install the required modules for the specified module or example
        only.  <example> can be JUNOS::Device, get_chassis_inventory,
	load_configuration, diagnose_bgp or RDB.

  -respository <directory>
        The directory where all of the packages are stored (.tar.gz).
        Default value is prereqs which is the name of the directory
        you see after you untar junoscript_prereqs.tgz.

  -mysql <directory>
        The directory is needed by the installation of DBD::mysql if
	the MySQL is not installed in /usr/local/mysql.

  -access <access_method>
        Install for one or more access methods.  For example ssh,
	ssh|telnet or all (for all access methods).  Please note
	that ssh is not available in the export distribution of 
	the JUNOScript Perl Client.  You must download the domestic
	distribution to be able to use the ssh access method.

  -maketest
        Perform 'make test' for all Perl modules.

\n\n";

    die $usage;
}

sub show_progress
{
    my $status = shift;
    if ($status) {
        print STDOUT "$status\n";
    } else {
        print STDOUT ".";
    }
}

sub install_perl_module 
{
    my $class = shift;
    my $manual = shift;

    my $success_ret = 1;

    my $tarball = install::get_tarball($class);
    my $dir = $tarball;
    $dir =~ s/.tar.gz$//;

    my $file = $class;
    $file =~ s;::;/;g;
    $file .= ".pm";

    my $vers = install::get_version($class);

    printf(OUTPUT_DATA_FORMAT, $class, install::get_estimate($class));

    # Redirect standard output and error to logfile
    my $logfile = "$tmp/$output/$dir.log";
    install::redirect_output($logfile, 0);

    #============================================================
    # Check whether the class already exists
    #============================================================
    unless ($force_override) {
        my $myversion = install::class_exists($class);
        if ($myversion) {
    
	    # check whether the vers is correct.
            if ($vers) {
                if (install::class_exists($class, $vers)) {
	            install::restore_output;
	            show_progress "ok => $myversion";
                    return $success_ret;
                } else {
                    print "Class $class ($tarball) is installed but old\n";
                    unless ($force_update) {
                        print "This class $class must be installed by hand\n";
		        install::restore_output;
		        show_progress "fail, see $dir.log";
                        return 0;
                    }
                }
	    } else {
	        install::restore_output;
	        show_progress "ok => $myversion";
                return $success_ret;
     	    }
	}
    }

    #============================================================
    # Unzip and Untar the archive file
    #============================================================

    $dir = $tarball;
    $dir =~ s/\.tar\.gz*$//;

    my $path = "$repository/$tarball";

    unless (-f $path) {
	print "\n$class: Cannot open ${repository}/${tarball}";
	install::restore_output;
	show_progress "fail, see $dir.log";
        return 0;
    }

    my $tarcommand = "tar -C %s -zxf %s";
    my $kernel = (uname)[0];
    print "Installing $class on $kernel\n";
    if ($kernel eq "SunOS") {
        $tarcommand = "cd %s && gzip -dc %s | tar xf -";
    } 
    my $cmd = sprintf($tarcommand, $tmp, $path);
    print "=====================================================\n";
    print "Invoking: $cmd\n";
    print "=====================================================\n";
    system($cmd);

    my $patch = $path;
    $patch =~ s/\.tar\.gz*$/.patch/;
    my $patches = $patch . 'es';
    if (-f $patch) {
      $cmd = "cd $tmp/$dir && patch < $patch";
      printf(LOG_HIGHLITE, "Invoking: $cmd");
      system($cmd);
    } elsif (-d $patches) {
      $cmd = "cd $tmp/$dir && for p in $patches/patch*; do patch < \$p; done";
      printf(LOG_HIGHLITE, "Invoking: $cmd");
      system($cmd);
    }
	
    #============================================================
    # perl Makefile.PL
    #============================================================

    $cmd = "cd $tmp/$dir && $Perl Makefile.PL " . install::get_install_flags($class) . " $install_option";
    printf(LOG_HIGHLITE, "Invoking: $cmd");

    # if this is a manual installation output of perl Makefile.PL to STDOUT
    install::restore_output if ($manual);

    if (system($cmd)) {
        install::redirect_output($logfile, 1) if ($manual);
	print "$cmd Failed\n";
	install::restore_output;
	show_progress "fail, see $dir.log";
	return 0;
    } else {
        install::redirect_output($logfile, 1) if ($manual);
    }

    my $modifier = install::get_modifier($class);
    print "Modifying $class with $modifier\n";
    &{$modifier}($kernel, "$tmp/$dir", $install_directory) if ($modifier);

    #============================================================
    # make
    #============================================================
   
    $cmd = "cd $tmp/$dir && make PERL=$Perl FULLPERL=$Perl";
    printf(LOG_HIGHLITE, "Invoking: $cmd");
    if (system($cmd)) {
	print "$cmd Failed\n";
	install::restore_output;
	show_progress "fail, see $dir.log";
	return 0;
    }

    #============================================================
    # make test
    #============================================================

    if ($maketest) {

        $cmd = "cd $tmp/$dir && make test";
        printf(LOG_HIGHLITE, "Invoking: $cmd");

        # if this is a manual installation output of make test to STDOUT
        install::restore_output if ($manual);

        if (system($cmd)) {
            install::redirect_output($logfile, 1) if ($manual);
	    print "$cmd Failed\n";
	    print "\n\n**********************************************************************\n";
	    print "*** MAKE TEST HAS FAILED.  \n";
	    print "*** PLEASE REPORT THE ERROR(S) TO MODULE'S AUTHOR, \n";
	    print "*** install::get_author($class).\n";
	    print "**********************************************************************\n\n\n";
	    if ($force_install) {
	        $success_ret = 2;
	    } else {
	        install::restore_output;
	        show_progress "fail, see $dir.log";
	        return 0;
	    }
        } else {
            install::redirect_output($logfile, 1) if ($manual);
        }
    }

    #============================================================
    # make install
    #============================================================

    $cmd = "cd $tmp/$dir && make install";
    printf(LOG_HIGHLITE, "Invoking: $cmd");
    if (system($cmd)) {
        if (install::class_exists($class)) {
	    $success_ret = 2;
 	} else {
	    print "$cmd Failed\n";
	    install::restore_output;
	    show_progress "fail, see $dir.log";
	    return 0;
	} 
    }

    #============================================================
    # done
    #============================================================

    # Restore standard output and error
    install::restore_output;
    if ($success_ret == 2) {
	show_progress "warning, see $dir.log";
    } else {
        show_progress "ok => $vers" if $vers;
        show_progress "ok" unless $vers;
    }

    return $success_ret;
}

sub install_c_module
{
    my $class = shift;

    my $tarball = install::get_tarball($class);
    my $dir = $tarball;
    my $path = "$repository/$tarball";
    my $res = "ok";

    my $instdir = "/usr/local/lib";
    $instdir = $install_directory if ($install_directory);

    printf(OUTPUT_DATA_FORMAT, $class, install::get_estimate($class));

    if ($dir =~ /.tar.gz$/) {
        $dir =~ s/.tar.gz$//;
    } else {
        $dir =~ s/.tgz$//;
    }

    my $logfile = "$tmp/$output/$dir.log";
    install::redirect_output($logfile, 0);

    #============================================================
    # Check whether c module exists
    #============================================================
    unless ($force_override) {
        if (install::c_module_exists($class, $install_directory)) {
            install::restore_output;
            show_progress "ok";
            return 1;
        }
    }
    unless (-f $path) {
        print "\n$class: Cannot open ${repository}/${tarball}";
        install::restore_output;
        show_progress "fail, see $dir.log";
	return 0;
    }

    #============================================================
    # Unzip and Untar the archive file
    #============================================================

    my $tarcommand = "tar -C %s -zxf %s";
    my $kernel = (uname)[0];
    print "Installing $class on $kernel\n";
    if ($kernel eq "SunOS") {
        $tarcommand = "cd %s && gzip -dc %s | tar xf -";
    }
    my $cmd = sprintf($tarcommand, $tmp, $path);
    print "=====================================================\n";
    print "Invoking: $cmd\n";
    print "=====================================================\n";
    system($cmd);

    #============================================================
    # ./configure or ./Configure
    #============================================================

    $cmd = "cd $tmp/$dir && " . install::get_install_flags($class);
    printf(LOG_HIGHLITE, "Invoking: $cmd");

    if (system($cmd)) {
        print "$cmd Failed\n";
        install::restore_output;
        show_progress "fail, see $dir.log";
        return 0;
    } 

    my $modifier = install::get_modifier($class);
    print "Modifying $class with $modifier\n";
    &{$modifier}($kernel, "$tmp/$dir", $install_directory) if ($modifier);

    #============================================================
    # make
    #============================================================
  
    $cmd = "cd $tmp/$dir && make";
    printf(LOG_HIGHLITE, "Invoking: $cmd");
    if (system($cmd)) {
        print "$cmd Failed\n";
        install::restore_output;
        show_progress "fail, see $dir.log";
        return 0;
    }
    
    #============================================================
    # make install
    #============================================================
       
    $cmd = "cd $tmp/$dir && make install";
    printf(LOG_HIGHLITE, "Invoking: $cmd");
    if (system($cmd)) {
        print "$cmd Failed\n";
        install::restore_output;
        show_progress "fail, see $dir.log";
        return 0;
    }

    #============================================================
    # done
    #============================================================

    install::restore_output;
    show_progress "ok";
    return 1;
}

sub auto_install 
{
    my @list = @_;
    my $fail_count = 0;
    my $ok_count = 0;
    my $warn_count = 0;
    my $res;
    my $total = 0;

    install::redirect_input('/dev/null');
    print "\nBegin automatic installation:\n\n";
    printf(OUTPUT_TITLE_FORMAT, "Module", "Est Time", "Result");
    printf(OUTPUT_TITLE_FORMAT, "------", "--------", "------");

    for my $class (@list) {
	$total++;
	my $t0 = new Benchmark if $timeinstall;
	if (install::is_c_module($class)) {
            $res = install_c_module($class);
	} else {
            $res = install_perl_module($class);
	}
	if ($timeinstall) {
	    my $t1 = new Benchmark;
	    my $td = timediff($t1, $t0);
	    print TIMEFILE "$class " . timestr($td) . "\n";
	}
        if ($res) {
            $ok_count++;
	    if ($res == 2) {
		$warn_count++;
	    }
	} else {
	    $fail_count++;
	}
    }
    install::restore_input;
    printf("\nAutomatic installation completed: success %d/%d, failure %d/%d, warnings %d.\n", $ok_count, $total, $fail_count, $total, $warn_count);

    # Do not start manual installation until this is fixed.
    if ($fail_count) {
	print "\n** See the files under $tmp/$output corresponding to the failed tests \n** for instructions to correct the failures.\n";
	die "\n** Please fix the failures and invoke this script again.\n\n";
    }
}

sub manual_install 
{
    my @list = @_;
    my $fail_count = 0;
    my $ok_count = 0;
    my $warn_count = 0;
    my $res;
    my $total = 0;

    print OUTPUT_DIVIDER;
    print "Begin manual installation:\n\n";
    printf(OUTPUT_TITLE_FORMAT, "Module", "Est Time", "Result");
    printf(OUTPUT_TITLE_FORMAT, "------", "--------", "------");

    for my $class (@list) {
	$total++;
	my $t0 = new Benchmark if $timeinstall;
        $res = install_perl_module($class, 1);
	if ($timeinstall) {
	    my $t1 = new Benchmark;
	    my $td = timediff($t1, $t0);
	    print TIMEFILE "$class " . timestr($td) . "\n";
	}
        if ($res) {
            $ok_count++;
	    if ($res == 2) {
		$warn_count++;
	    }
	} else {
	    $fail_count++;
	}
    }
    printf("\nManual installation completed: success %d/%d, failure %d/%d, warnings %d.\n", $ok_count, $total, $fail_count, $total, $warn_count);

}

#
#  Main Begins
#

chomp($pwd = `pwd`);
$repository = $pwd . "/prereqs";
$tmp = "tmp";
$output = "output";
$Perl = $^X;			# if we run as /usr/local/bin/perl use it.

while (@ARGV) {
    $arg = shift @ARGV;
    if ("-repository" =~ /^$arg/) {
	$repository = shift @ARGV;
    } elsif ("-force" =~ /^$arg/) {
	    $force_update = 1;
	    $force_install = 1;
    } elsif ("-maketest" =~ /^$arg/) {
	    $maketest = 1;
    } elsif ("-force_update" =~ /^$arg/) {
	    $force_update = 1;
    } elsif ("-force_install" =~ /^$arg/) {
	    $force_install = 1;
    } elsif ("-force_override" =~ /^$arg/) {
	    $force_override = 1;
    } elsif ("-install_directory" =~ /^$arg/) {
	    $install_directory = shift @ARGV;
    } elsif ("-access" =~ /^$arg/) {
	    $access = shift @ARGV;
    } elsif ("-used_by" =~ /^$arg/) {
	    $used_by = shift @ARGV;
    } elsif ("-timeinstall" =~ /^$arg/) {
	    $timeinstall = 1;
    } elsif ("-mysql" =~ /^$arg/) {
	    $mysql = shift @ARGV;
    } else {
	    output_usage;
    }
}

#
# install_flags{} are flags to append to the perl Makefile.PL command
#
install::set_install_flags('libexpat.a', 
    $install_directory?"./configure --prefix $install_directory/..":"./configure");

install::set_install_flags('libxml2.a', 
    $install_directory?"./configure --prefix=$install_directory/..":"./configure");

install::set_install_flags('libxslt.a', 
    $install_directory?"./configure --prefix=$install_directory/.. --with-libxml-prefix=$install_directory/..":"./configure");

install::set_install_flags('gtkdoc', 
    $install_directory?"./configure --prefix=$install_directory/..":"./configure");

install::set_install_flags('gmp', 
    $install_directory?"./configure --prefix=$install_directory/..":"./configure");

install::set_install_flags('XML::Parser', 
    $install_directory?"EXPATLIBPATH=/usr/local/lib EXPATINCPATH=/usr/local/include":"EXPATLIBPATH=/usr/local/lib EXPATINCPATH=/usr/local/include");  # may be further modified by the subroutine libexpat_exists

install::set_install_flags('DBD::mysql', "--cflags=-I$mysql/include") if $mysql;

if ($install_directory) {
    install::set_install_flags('XML::Parser', "EXPATLIBPATH=$install_directory EXPATINCPATH=$install_directory/../include");
    install::set_install_flags('Compress::Zlib', "INC=-I$install_directory/../include LDFROM=\"-L$install_directory/../lib \\\$(OBJECT)\"");
    install::set_install_flags('Math::GMP', "INC=-I$install_directory/../include");
}

install::activate_access_methods($install_directory);

$access = "all" unless ($access);

if ($used_by) {
    if ($used_by ne "RDB" &&
	$used_by ne "diagnose_bgp" &&
	$used_by ne "get_chassis_inventory" &&
	$used_by ne "load_configuration" &&
	$used_by ne "JUNOS::Device" &&
	$used_by ne "default") {
	output_usage;
    }
} else {
    $used_by = "default";
}

@modules = install::get_auto_classes($access, $used_by);
@byhand = install::get_manual_classes($access, $used_by);

if (defined $install_directory) {
    $ENV{PERL5LIB} = $install_directory;
    $ENV{PATH} = "$install_directory/../bin:$ENV{PATH}";
    $install_option = "LIB=$install_directory PREFIX=$install_directory/.. INSTALLMAN1DIR=$install_directory/../man/man1 INSTALLMAN3DIR=$install_directory/../man/man3";
} 

# Set LANG since some versions of perl don't play nicely with nonstandard
$ENV{LANG} = "C";
$ENV{LC_ALL} = "C";

mkdir($tmp, 0755);
mkdir("$tmp/$output", 0755);
die "Could not create temporary directory: $tmp/$output" if (not -d "$tmp/$output");

print OUTPUT_TITLE;

print "This script installs all modules required by $used_by.\n";
if ($install_directory) {
    print "These modules will be installed in the private directory \n$install_directory.\n";
} else {
    print "These modules will be installed in the system directory.\n";
}
print "\n";

if ($used_by eq "JUNOS::Device" || $used_by eq "default") {
     print "This installation takes around ". 15 * install::get_access_count($access) . " minutes\n";
}

open(TIMEFILE, "> time.log") if $timeinstall;

my $total0 = new Benchmark if $timeinstall;

if (@modules && scalar(@modules)) {
    auto_install @modules;
}

# Some module installations are more interactively, we need to install
# them differently
if (@byhand && scalar(@byhand)) {
    manual_install @byhand;
}

if ($timeinstall) {
    my $total1 = new Benchmark;
    my $total = timediff($total1, $total0);
    print TIMEFILE "TOTAL: " . timestr($total) . "\n";
}

if (defined $install_directory) {
    print "\nPLEASE REMEMBER TO SET THE FOLLOWING ENVIRONMENT VARIABLES BEFORE \n";
    print "RUNNING THE EXAMPLES:\n";
    print "     export PERL5LIB=$install_directory\n"; 
    print "     export LD_LIBRARY_PATH=$install_directory\n"; 
    print '     export PATH=$PATH:' . $install_directory . "/../bin\n"; 
    print '     export MANPATH=$MANPATH:' . $install_directory . "/../man\n"; 
}

close TIMEFILE if $timeinstall;

print OUTPUT_ENDING;
