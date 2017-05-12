#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  tltail.pl
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: tltail.pl 4304 2007-09-19 07:52:33Z pho $
# -----------------------------------------------------------------------------
package Tripletail::Util::Tail;
use strict;
use warnings;
use Getopt::Long ();
use IO::Poll     qw(POLLIN);
use IO::Handle   (); # $io->blocking().

our $VERSION = '0.01';
$| = 1;

my $SEEK_SET = 0;
my $SEEK_END = 2;

our $ARG_SPECS = [
	"help|h"    => "Print this message.",
	"version|V" => "Print the version number.",
	"follow|f"  => "No-op. This option exists only for the compatibility with tail(1).",
	"verbose|v" => "Be verbose.",
	"quiet|q"   => "Be quiet.",
];

# -----------------------------------------------------------------------------
# boot.
#
caller or __PACKAGE__->do_work(@ARGV);

# -----------------------------------------------------------------------------
# my $opts = $pkg->_arg_to_hash(@ARGV);
#
sub _arg_to_hash
{
	my $pkg = shift;
	local(@ARGV) = @_;
	my $opts = {};
	my $p = Getopt::Long::Parser->new();
	$p->configure("bundling");
	$p->getoptions($opts, keys %{{@$ARG_SPECS}});
	$opts->{_extra} = [@ARGV];
	$opts;
}

# -----------------------------------------------------------------------------
# $pkg->_print_usage().
#
sub _print_usage
{
	my $pkg = shift;
	print "usage: tltail [OPTIONS] FILES ...\n";
	print "OPTIONS:\n";
	foreach my $i (grep{$_%2==0} 0..$#$ARG_SPECS)
	{
		my ($k,$v) = @$ARG_SPECS[$i,$i+1];
		$k = join(', ', sort{length($a)<=>length($b)} map{(length($_)==1?'-':'--').$_}split(/\|/, $k));
		my $padding = " "x(14-length($k));
		print "  $k$padding $v\n";
	}
}

# -----------------------------------------------------------------------------
# $pkg->do_work(@ARGV).
#
sub do_work
{
	my $pkg = shift;
	my $opts = $pkg->_arg_to_hash(@_);
	$opts->{help}    and return _print_usage();
	if( $opts->{version} )
	{
		print "tltail version $VERSION\n";
		return;
	}
	
	my $start_at = time;
	my $streams = $pkg->_setup({now=>$start_at, files=>$opts->{_extra}});
	my $data = {
		streams   => $streams,
		opts      => $opts,
		prev_file => '',
	};
	
	for(;;)
	{
		if( my $poll = $streams->{poll} )
		{
			my $ev = $poll->poll(0);
			$ev==-1 and die "poll: $!";
			foreach my $handle ($poll->handles(POLLIN))
			{
				my $item = $streams->{handles}{$handle};
				READ:{
					my $len = sysread($handle, $item->{buffer}, 1024, length $item->{buffer});
					if( $len )
					{
						_show($data, $item);
						redo READ;
					}
					if( defined($len) )
					{
						# eof.
						print "$item->{name}: eof\n";
						$poll->remove($handle);
						delete $streams->{handles}{$handle};
						last READ;
					}
					$!{EAGAIN} and last READ;
					die "$item->{name}: $!";
				}
			}
		}
		
		my $now = time;
		my $dirs  = $streams->{dirs};
		my $files = $streams->{files};
		my ($fdir, $fname, $open_at, $close_at);
		foreach my $item (@$dirs)
		{
			$item->{type} eq 'dir' or next;
			$item->{open_at} <= $now or next;
			$fdir or ($fdir, $fname) = _time2name($now);
			my $file = "$item->{dir}/$fdir/$fname";
			-e $file or next;
			
			$open_at  ||= $now - $now%3600 + 3600;
			$close_at ||= $now - $now%3600 + 3600 + 3;
			print "open: $file\n";
			open(my $fh, '<', $file) or die "$file: $!";
			my $pos = sysseek($fh, 0, $SEEK_END) || 0;
			push(@$files, +{
				name   => $file,
				type   => 'file',
				handle => $fh,
				pos    => $pos,
				close_at => $close_at,
				buffer => '',
			});
			$item->{open_at} = $open_at;
		}
		
		foreach my $item (@$files)
		{
			$item->{type} eq 'file' or next;
			if( $item->{close_at} && $item->{close_at} < $now )
			{
				print "close: $item->{name}\n";
				close $item->{handle};
				$item = undef;
				next;
			}
			my $pos = sysseek($item->{handle}, 0, $SEEK_END);
			defined($pos) or die "$item->{name}: $!";
			$pos==$item->{pos} and next;
			sysseek($item->{handle}, $item->{pos}, $SEEK_SET);
			
			my $len = sysread($item->{handle}, $item->{buffer}, $pos-$item->{pos}, length $item->{buffer});
			$item->{pos} = $pos;
			if( $len )
			{
				_show($data, $item);
			}elsif( defined($len) )
			{
				# eof.
				die "$item->{name}: eof";
			}else
			{
				$!{EAGAIN} and last READ;
				die "$item->{name}: $!";
			}
		}
		@$files = grep{$_} @$files;
		select(undef,undef,undef,0.1);
	}
}

sub _show
{
	my $data = shift;
	my $item = shift;
	
	my $opts = $data->{opts};
	my $show_file = !$opts->{quiet} && ($opts->{verbose} || @{$opts->{_extra}}>1);
	if( $show_file && $item->{name} ne $data->{prev_file} )
	{
		print "==> $item->{name} <==\n";
		$data->{prev_file} = $item->{name};
	}
	if( $item->{buffer} =~ s/^(.*\n)//s )
	{
		print $1;
	}
}

sub _time2name
{
	my $time = shift || time;
	my @st = localtime($time);
	my $fdir  = sprintf('%04d%02d', $st[5]+1900, $st[4]+1); # yyyymm
	my $fname = sprintf('%02d-%02d.log', $st[3], $st[2]);   # dd-hh.log
	($fdir, $fname);
}

sub _setup
{
	my $pkg  = shift;
	my $opts = shift;
	
	my $files = $opts->{files} || [];
	@$files or $files = ['-'];
	my $now = $opts->{now} || time;
	my ($fdir, $fname) = _time2name($now);
	
	my $close_at = $now - $now%3600 + 3600 + 3;
	my $poll;
	my %handles;
	my @files;
	my @dirs;
	foreach my $file (@$files)
	{
		if( $file eq '-' )
		{
			$poll ||= IO::Poll->new();
			my $fh = \*STDIN;
			$fh->blocking(0);
			$handles{$fh} = {
				name   => '-',
				type   => 'handle',
				handle => $fh,
			};
			$poll->mask($fh, POLLIN);
			next;
		}
		if( -d $file )
		{
			push(@dirs, +{
				name    => "$file/",
				type    => 'dir',
				open_at => $now,
				dir     => $file,
			});
			$dirs[-1]->{dir} =~ s{/$}{};
			next;
		}
		open(my $fh, '<', $file) or die "$file: $!";
		my $pos = sysseek($fh, 0, $SEEK_END) || 0;
		push(@files, +{
			name   => $file,
			type   => 'file',
			handle => $fh,
			pos    => $pos,
			close_at => $close_at,
		});
	}
	foreach my $item (values %handles, @files)
	{
		$item->{buffer} = '';
	}
	+{
		poll    => $poll,
		handles => \%handles,
		files   => \@files,
		dirs    => \@dirs,
	};
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf-8

=head1 NAME

tltail.pl - tailing separated log files.

=head1 NAME (ja)

tltail.pl - 分割されたログファイルのtail.

=head1 SYNOPSIS

  $ tltail.pl /path/to/logdir
  
=head1 DESCRIPTION

Tripletail で出力される, yyyymm/dd-hh.log 形式の
ログファイルを続けて読み込んでコンソールに出力します. 

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2007 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
