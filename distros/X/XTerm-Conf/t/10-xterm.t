#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp qw(tempfile);
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp module\n";
	exit;
    }
}

my @xterm_likes = qw(xterm rxvt urxvt);

my $tests = 5;
plan tests => $tests * @xterm_likes;

my(undef,$file) = tempfile(UNLINK => 1);

for my $xterm (@xterm_likes) {
 SKIP: {
	skip("No $xterm and/or DISPLAY on this system available", $tests)
	    if (!is_in_path("$xterm") || !$ENV{DISPLAY});

	my $run_xterm_cmd = sub (\@$;$) {
	    my($cmd, $testlabel, $run_tests) = @_;
	    $run_tests = 1 if !defined $run_tests;

	    my $pid = fork;
	    if (!defined $pid) {
		die "Can't fork: $!";
	    }
	    if ($pid == 0) {
		exec @$cmd;
		die $!;
	    }
	    local $SIG{ALRM} = sub { die "Timeout" };
	    alarm(30);
	    eval {
		waitpid $pid, 0;
	    };
	    alarm(0);
	    if ($run_tests) {
		is $@, '', "No hangs if $xterm is running with $testlabel"
		    or diag "Command was '@$cmd'";
		is $?, 0, 'exit code is success'
		    or diag "Command was '@$cmd'";
	    }
	    if ($@) {
		kill 9 => $pid;
	    }
	};

	$run_xterm_cmd->([$xterm, "-geometry", "+10+10", "-e", $^X, "-e", q{print STDERR "# $xterm can be started\n"}], undef, 0);
	skip("Cannot start $xterm", $tests)
	    if $? != 0;

	if ($xterm eq 'rxvt' || $xterm eq 'urxvt') {
	    my $rxvt_version;
	    if ($xterm eq 'rxvt') {
		my $help_output = `$xterm --help 2>&1`;
		for my $l (split /\n/, $help_output) {
		    next if $l eq '';
		    last if $l =~ m{^rxvt.*options.*command};
		    $rxvt_version .= $l . "\n";
		}
	    } elsif ($xterm eq 'urxvt') {
		my $help_output = `$xterm --help 2>&1`;
		for my $l (split /\n/, $help_output) {
		    next if $l eq '';
		    last if $l =~ m{^Usage.*urxvt.*options};
		    $rxvt_version .= $l . "\n";
		}
	    }
	    diag("\n$xterm\n$rxvt_version");
	} else {
	    my $xterm_version;
	    $xterm_version = `$xterm -v`;
	    diag("\n$xterm version $xterm_version");
	}

	$run_xterm_cmd->([$xterm, "-xrm", "*allowWindowOps:true", "-T", "XTerm::Conf test suite", "-geometry", "+10+10", "-e", $^X, "$FindBin::RealBin/10-xterm.pl", $file], 'allowWindowOps:true');
	
	open FH, "< $file"
	    or die "Can't open $file: $!";
	chomp(my $success = join "", <FH>);
	is($success, "success", "live $xterm tests");

	$run_xterm_cmd->([$xterm, "-xrm", "*allowWindowOps:false", "-T", "XTerm::Conf test suite", "-geometry", "+10+10", "-e", $^X, "$FindBin::RealBin/11-xterm.pl", $file], 'allowWindowOps:false');
    }
}

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/work/srezic-repository 
# REPO MD5 e18e6687a056e4a3cbcea4496aaaa1db

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my($prog) = @_;
    if (file_name_is_absolute($prog)) {
	if ($^O eq 'MSWin32') {
	    return $prog       if (-f $prog && -x $prog);
	    return "$prog.bat" if (-f "$prog.bat" && -x "$prog.bat");
	    return "$prog.com" if (-f "$prog.com" && -x "$prog.com");
	    return "$prog.exe" if (-f "$prog.exe" && -x "$prog.exe");
	    return "$prog.cmd" if (-f "$prog.cmd" && -x "$prog.cmd");
	} else {
	    return $prog if -f $prog and -x $prog;
	}
    }
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"     if (-f "$_\\$prog" && -x "$_\\$prog");
	    return "$_\\$prog.bat" if (-f "$_\\$prog.bat" && -x "$_\\$prog.bat");
	    return "$_\\$prog.com" if (-f "$_\\$prog.com" && -x "$_\\$prog.com");
	    return "$_\\$prog.exe" if (-f "$_\\$prog.exe" && -x "$_\\$prog.exe");
	    return "$_\\$prog.cmd" if (-f "$_\\$prog.cmd" && -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

# REPO BEGIN
# REPO NAME file_name_is_absolute /home/e/eserte/work/srezic-repository 
# REPO MD5 89d0fdf16d11771f0f6e82c7d0ebf3a8

=head2 file_name_is_absolute($file)

=for category File

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

BEGIN {
    if (eval { require File::Spec; defined &File::Spec::file_name_is_absolute }) {
	*file_name_is_absolute = \&File::Spec::file_name_is_absolute;
    } else {
	*file_name_is_absolute = sub {
	    my $file = shift;
	    my $r;
	    if ($^O eq 'MSWin32') {
		$r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	    } else {
		$r = ($file =~ m|^/|);
	    }
	    $r;
	};
    }
}
# REPO END


__END__
