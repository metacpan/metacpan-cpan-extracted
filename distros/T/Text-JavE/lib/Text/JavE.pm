#!/usr/bin/perl -w

package Text::JavE;
use strict;

our $VERSION='0.0.3';

=head1 NAME

Text::JavE - view and manipulate ascii art and manipulation files created in JavE.

=head1 DESCRIPTION

JavE (http://www.jave.de/) is an excellent Ascii art editor and animator
written in Java.  Unfortunately it doesn't yet have a scripting interface.
This module aims to make the work of processing its standard files (.jmov)
easy within Perl.

=head1 SYNOPSIS

  use Text::JavE;

  my $j = new Text::JavE;
  while (my $file=shift @ARGV) {
    $j->open_jmov($file);
    for (@{$j->{frames}}) {
      system "cls"; # on Win32.  Try system "clear" on Unix.
      $_->display;
      my $time = $_->{msec};
      select (undef, undef, undef, $time/1000);
    }
  }

=head2 new()

Constructor.  Returns a Text::JavE object which can play or otherwise
manipulate jmov files.

=cut

sub new {
	my $class=shift;
	my $self={
		decoded => [],
	};
	return bless {}, $class;
}

=head2 decode($text)

Internal method to decode a jmov line containing a compressed ascii frame.
There are 2 submethods decode_a and decode_b implementing the various
encoding algorithms JavE currently uses.

=cut

sub decode {
	my $self=shift;
	my $text=shift;
	$self->{code}=$text;
	$text=~s/^([A-Z])(\d+) (\d+) // or die "Text::JavE: invalid format: $text\n";
	(my $alg, $self->{xsize}, $self->{ysize})=($1, $2, $3);
	$self->{algorithm} = $alg;

	if    ($alg eq "A") { $self->decode_a($text);	} 
	elsif ($alg eq "B") { $self->decode_b($text);	} 
	else { 
		warn "Unsupported algorithm: $alg\n" ;
		return;
	}
}

sub decode_a {
	my $self=shift;
	my $text=shift;
	my @decoded; my $decode_line='';
	$self->{decoded}=\@decoded;
	my ($x, $y) = ($self->{xsize}, $self->{ysize});
	while ($text) {
		# print "($text)\n\n";

		# Add normal text
		if ($text=~s/^([^\%]+)//) {
			$decode_line.=$1;
			# print "($1)\n";
		}

		# Add % signs signalled by %%
		if ($text=~s/^((?:%%)+)//) {
			$decode_line.='%' x (length($1)/2);
		}

		# Add newlines (%0)
		if ($text=~s/^%0//) { 
			if (length $decode_line > $x) {
				warn "Line longer than $x declared!\n";
			}
			push @decoded, $decode_line;
			$decode_line='';
		}

		# Add repeated number characters (%3%8 e.g. 3 x "8")
		if ($text=~s/^%([1-9]\d*)%(\d)//) {
			$decode_line.=( $2 x $1); 
		#print "($2 x $1)\n";
		}

		# Add repeated characters (%9x   %3%% etc.)
		if ($text=~s/^%([1-9]\d*)([^%0-9]|%%)//) {
			$decode_line.=( $2 x $1); 
		#print "($2 x $1)\n";
		}

	}
	if (length $decode_line > $x) {
		warn "Line longer than $x declared!\n";
	}
	if (@decoded > $y) {
		warn "More than $y lines declared!\n";
	}
	push @decoded, $decode_line;
}

sub decode_b {
	my $self=shift;
	my $text=shift;
	my ($x, $y) = ($self->{xsize}, $self->{ysize});
	#print "($x, $y)\n";
	my @decoded=unpack( ("A$x" x $y), $text); 
	$self->{decoded}=\@decoded;
}

=head2 display()

Shows the current frame.

=cut

sub display {
	my $self=shift;
	my @decoded=@{$self->{decoded}};
	my $y=$self->{ysize};
	push @decoded, ('') x ($y-@decoded);
	print join "\n", @decoded;
	print "\n";
}

=head2 open_clipart($file)

Opens a clipart file in JavE's .jcf format.
(As far as I know this isn't officially documented, but a
number of sample files are distributed with JavE).

=cut

sub open_clipart {
	my $self=shift;
	my $file=shift;
	my @clips;
	$self->{clips}=\@clips;

	open (JCF, '<', $file) or die "Couldn't open file $file: $!\n";;
	while (my $title=<JCF>) {
		my $j=Text::JavE->new;
		chomp $title;
		chomp(my $artist=<JCF>);
		chomp(my $clip=<JCF>);
		<JCF>; # discard empty line;
		if ($j->decode($clip)) {
			push @clips, {
				title  => $title,
				artist => $artist,
				clip   => $j,
			};
		}
	}
}


=head2 open_jmov($file)

Opens a file in jmov format.
This format is described in detail at 
http://www.jave.de/player/jmov_specification.html

A sample Chickenman animation is included in the
distribution as t.jmov.  More can be found at
http://osfameron.perlmonk.org/chickenman/
Other jmov files can be found at http://www.jave.de

=cut

sub open_jmov {
	my $self=shift;
	my $file=shift;
	my (@frames, %frames);
	$self->{frames}=\@frames;
	$self->{frames_dict}=\%frames;
	my $framenum=0;

	open (JMOV, '<', $file) or die "Couldn't open file $file: $!\n";;
	my $lnum=0;
	my $frame;
	$self->{curr_frame}=\$frame;
	while (my $line=<JMOV>) {
		print "$lnum.";
		#print "[$lnum]\t$line\n";
		$lnum++;
		$line=~/^(.):(.*)$/ or die "JMOV: invalid format at line $lnum: $line\n";
		my ($action, $data)=($1, $2);
		CASE: for ($action) {
			/!/  and do { $self->{filename}=$data; last CASE};
			/\*/ and do { $self->{title}   =$data; last CASE};
			/D/  and do { $self->{date}    =$data; last CASE};
			/J/  and do { 
				$frame=new Text::JavE; 
				$framenum++;
				for (qw(cursorpos cpos2 colour msec action)) {
					$frame->{$_} = $self->{$_};
				} 
				$frame->{num}=$framenum;
				$frame->{frametitle}="frame $framenum";
				$frame->decode($data);
				push @frames, $frame; 	
				last CASE};
			/\|/ and do { $self->{cursorpos}=$data; $frame->{cursorpos}=$data; last CASE};
			/\^/ and do { $self->{cpos2}=$data; $frame->{cpos2}=$data; last CASE};
			/\+/ and do { $self->{msec}=$data; $frame->{msec}=$data; last CASE};
			/C/  and do { $self->{colour}=$data; $frame->{colour}=$data; last CASE};
			/A/  and do { $self->{action}=$data; $frame->{action}=$data; last CASE};
			/T/  and do { $frame->{frametitle}=$data; 
					# print $data;
					last CASE};
		}
	}
	for (@frames) {
		push @{$frames{$_->{frametitle}}}, $_;
	};
	close JMOV or die;
	# print "DONE!";
}

=head1 BUGS

Code is boneheaded and documentation is poor in v0.0.2.
(In v.0.0.1 it consisted of "blah blah blah" so at least
it's improving).

=head1 AUTHOR

osfameron - osfameron@cpan.org

=cut

1; # return true value
