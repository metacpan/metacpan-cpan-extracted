#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/filter_csv.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: filter_csv.t 4281 2007-09-13 05:37:32Z mikage $
# -----------------------------------------------------------------------------
use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Spec;
our $TL;

check_fork();
plan tests => 5;
&test_001;

sub check_fork
{
	my $pid = eval{ fork(); };
	$@ and plan skip_all => "fork required";
	if( $pid )
	{
		waitpid($pid, 0);
		return; # success.
	}elsif( !defined($pid) )
	{
		plan skip_all => "fork failed: $!";
	}else
	{
		# child;
		exit(0);
	}
}

# my $pid = my_fork(my $stdout);
sub my_fork
{
	my $r = pipe(my$stdout_r,my$stdout_w);
	$r or die "pipe: $!";
	my $pid = fork();
	if( !defined($pid) )
	{
		die "fork failed: $!";
	}elsif( $pid )
	{
		# parent.
		$_[0] = $stdout_r;
		close($stdout_w);
		return $pid;
	}else
	{
		# child.
		open(STDIN,  "<",  "/dev/null") or die "reset STDIN failed: $!";
		if( $^O eq 'MSWin32' )
		{
			# dup handle not work correctly on win32?
			*STDOUT = $stdout_w;
			*STDERR = $stdout_w;
		}else
		{
			open(STDOUT, ">&", $stdout_w)   or die "reset STDOUT failed: $!";
			open(STDERR, ">&", $stdout_w)   or die "reset STDERR failed: $!";
			close($stdout_w);
		}
		close($stdout_r);
		return $pid;
	}
}

sub run_cgi(&;$)
{
	my $code  = shift;
	my $param = shift || {};
	
	my $pid = my_fork(my $stdout);
	defined($pid) or die "open failed: $!";
	if( !$pid )
	{	# child.
		$ENV{GATEWAY_INTERFACE} = 'RUN/0.1';
		$ENV{REQUEST_URI}       = '/';
		$ENV{REQUEST_METHOD}    = 'GET';
		$ENV{QUERY_STRING}      = join('&', map{"$_=$param->{$_}"}keys %$param);
		eval
		{
			require Tripletail;
			Tripletail->import(File::Spec->devnull);
			$TL->startCgi(-main=>sub{
				&$code;
			});
			exit 0;
		};
		exit 1;
	}
	my $out = join('', <$stdout>);
	my $kid = waitpid($pid, 0);
	$kid==$pid or die "catch another process (pid:$kid), expected $pid";
	my $sig = $?&127;
	my $core = $?&128 ? 1 : 0;
	my $ret = $?>>8;
	$?==0 or die "fail with $ret (sig:$sig, core:$core)";
	$out =~ s/.*\r?\n\r?\n//;
	$out;
}

sub _set_csv_filter(;$)
{
	my $filename = shift;
	$TL->setContentFilter(
		'Tripletail::Filter::CSV',
		charset  => 'UTF-8',
		#($filename ? (filename => $filename) : ())
	);
}

sub test_001
{
	is(run_cgi(sub{$TL->print("test run")}), "test run", "test run.");
	
	is(run_cgi(sub{
		_set_csv_filter();
	  $TL->print( 'aaa,"b,b,b",ccc,ddd' . "\r\n");
	}),qq/aaa,"b,b,b",ccc,ddd\r\n/, "print with string");
	
	is(run_cgi(sub{
		_set_csv_filter();
	  $TL->print( ['aaa', 'b,b,b', 'ccc', 'ddd'] );
	}),qq/aaa,"b,b,b",ccc,ddd\r\n/, "print with arrayref");
	
	is(run_cgi(sub{
		_set_csv_filter();
	  $TL->print( ['aaa', '"b,b,b"', 'ccc', 'ddd'] );
	}),qq/aaa,"""b,b,b""",ccc,ddd\r\n/, "print with arrayref with escape");
	
	is(run_cgi(sub{
		_set_csv_filter();
	  $TL->print( 'aaa,"b,b,b",' );
	  $TL->print( 'CCC,DDD' );
	  $TL->print( "\r\n" );
	}), qq/aaa,"b,b,b",CCC,DDD\r\n/, "print as some strings");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
