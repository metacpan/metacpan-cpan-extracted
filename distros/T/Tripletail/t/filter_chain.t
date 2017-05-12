#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/filter_chain.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: filter_chain.t 4093 2007-03-08 07:27:08Z hio $
# -----------------------------------------------------------------------------
use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Spec;
our $TL;

check_fork();
plan tests => 5;
&setup;
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
			$SIG{__DIE__} = sub{ print "Content-Type: text/plain\r\n\r\ndied: ".shift; exit; };
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
	$out =~ s/(.*?\r?\n)?\r?\n//;
	$out;
}

sub _make_filter
{
	my $name = shift;
	my $sub = shift;
	$INC{"Tripletail/Filter/$name.pm"} = $0;
	my $pkg = "Tripletail::Filter::$name";
	no strict 'refs';
	push(@{$pkg.'::ISA'}, qw(Tripletail::Filter));
	*{$pkg.'::print'} = $sub;
}

sub setup
{
	_make_filter(WrapBrackets => sub{
		my $pkg = shift;
		my $content = shift;
		"[$content]";
	});
	_make_filter(WrapBraces => sub{
		my $pkg = shift;
		my $content = shift;
		"{$content}";
	});
}

sub _set_filter($;$)
{
	my $filter   = shift;
	my $priority = shift;
	$filter = "Tripletail::Filter::$filter";
	if( $priority )
	{
		$TL->setContentFilter( [$filter, $priority] );
	}else
	{
		$TL->setContentFilter( $filter );
	}
}

sub test_001
{
	is(run_cgi(sub{
		_set_filter(TEXT=>'');
		$TL->print("AAA");
	}), "AAA", "TEXT filter");
	is(run_cgi(sub{
		_set_filter(TEXT=>'');
		_set_filter(TEXT=>500);
		$TL->print("AAA");
	}), "Content-Type: text/plain; charset=Shift_JIS\r\n\r\nAAA", "twice TEXT filter makes headers double");
	
	is(run_cgi(sub{
		_set_filter(WrapBrackets=>undef);
		$TL->print("AAA");
	}), "[AAA][]", "wrap with brackets");
	is(run_cgi(sub{
		_set_filter(WrapBraces  =>undef);
		$TL->print("AAA");
	}), "{AAA}{}", "wrap with braces");
	
	is(run_cgi(sub{
		_set_filter(WrapBrackets=> 500); # before std filter.
		_set_filter(WrapBraces  =>1500); # after std filter.
		$TL->print("BBB");
		$TL->print("CCC");
	}), "[BBB]}{[CCC]}{[]\r\n}\r\n", "wrap with both brackets and braces");
	# first `{' is prepended to headers.
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
