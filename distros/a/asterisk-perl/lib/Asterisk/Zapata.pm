package Asterisk::Zapata;

require 5.004;

=head1 NAME

Asterisk::Zapata - Zapata stuff

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;

$VERSION = '0.01';

$DEBUG = 5;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'configfile'} = undef;
	$self->{'vars'} = {};
	$self->{'channel'} = {};

	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub configfile {
	my ($self, $configfile) = @_;

	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} else {
		$self->{'configfile'} = '/etc/asterisk/zapata.conf' if (!defined($self->{'configfile'}));
	}

	return $self->{'configfile'};
}

sub setvar {
	my ($self, $context, $var, $val) = @_;

	$self->{'vars'}{$context}{$var} = $val;
}

sub channels {
	my ($self, $context, $channels) = @_;

	my @chans = ();
	my $channel = '';
	my $x;

	if ($channels =~ /(\d+)\-(\d+)/) {
		my $beg = $1; my $end = $2;
		if ($end > $beg) {
			for ($x = $beg; $x <= $end; $x++) {
				push(@chans, $x);
			}
		}
	} elsif ($channels =~ /^(\d+)$/) {
		push(@chans, $channels);
	} elsif ($channels =~ /^\d+,/) {
		push(@chans, split(/,/, $channels));
	} else {
		print STDERR "channels got here: $channels\n" if ($DEBUG);
	}	

	foreach $channel (@chans) {

		$self->{'channel'}{$channel}{'channel'} = $channel;
		foreach $var (keys %{$self->{'vars'}{$context}}) {
			$self->{'channel'}{$channel}{$var} = $self->{'vars'}{$context}{$var};
		}
	}

}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';

	my $configfile = $self->configfile();

	open(CF, "<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
		chop($line);

		$line =~ s/;.*$//;
		$line =~ s/\s*$//;

		if ($line =~ /^;/) {
			next;
		} elsif ($line =~ /^\s*$/) {
			next;
		} elsif ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			print STDERR "Context: $context\n" if ($DEBUG>3);
		} elsif ($line =~ /^channel\s*[=>]+\s*(.*)$/) {
			$channel = $1;
			$self->channels($context, $1);
			print STDERR "Channel: $channel\n" if ($DEBUG>3);
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}

	}
	close(CF);

return 1;
}

1;
