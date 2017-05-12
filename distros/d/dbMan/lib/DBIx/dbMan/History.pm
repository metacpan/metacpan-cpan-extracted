package DBIx::dbMan::History;

use strict;
use locale;
use POSIX;
use DBIx::dbMan::Config;

our $VERSION = '0.04';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	$obj->{buffer} = [];
	$obj->{position} = -1;
	return $obj;
}

sub load_and_store {
	my $obj = shift;

	my $file = $obj->historyfile;

	return () unless $file;
	
	my @lines = ();

	if (open F,$file) {
		while (<F>) {
			chomp;
			push @lines,$_;
		}	
		close F;
	}
	$obj->{buffer} = \@lines;
	$obj->{position} = 1+$#lines;
}

sub load {
	my $obj = shift;

	my $file = $obj->historyfile;

	return () unless $file;
	
	my @lines = ();

	if (open F,$file) {
		while (<F>) {
			chomp;
			push @lines,$_;
		}	
		close F;
	}
	return @lines;
}

sub historyfile {
	my $obj = shift;
	
	return $ENV{DBMAN_HISTORY} if $ENV{DBMAN_HISTORY};
	return $obj->{-config}->history if $obj->{-config}->history;
	mkdir $ENV{HOME}.'/.dbman' unless -d $ENV{HOME}.'/.dbman';
	return $ENV{HOME}.'/.dbman/history';
}

sub add {
	my $obj = shift;
	my $line = join "\n",@_;

	my $file = $obj->historyfile;
	return unless $file;
	
	if (open F,">>$file") {
		print F "$line\n";
		close F;
	}
	push @{$obj->{buffer}},$line;
	$obj->{position} = scalar @{$obj->{buffer}};
}

sub clear {
	my $obj = shift;
	my $file = $obj->historyfile;
	return unless $file;

	unlink $file;
	$obj->{buffer} = [];
	$obj->{position} = -1;
}

sub prev {
	my $obj = shift;
	return '' if $obj->{position} < 0;
	--$obj->{position};
	return '' if $obj->{position} < 0;
	return $obj->{buffer}->[$obj->{position}];
}

sub next {
	my $obj = shift;
	return '' if $obj->{position} >= scalar @{$obj->{buffer}};
	++$obj->{position};
	return '' if $obj->{position} >= scalar @{$obj->{buffer}};
	return $obj->{buffer}->[$obj->{position}];
}

sub reverse_search {
	my ($obj,$pattern,$dec) = @_;

	$dec = 0 unless defined $dec;
	my $curr = $obj->{position}-$dec;
	while ($curr >= 0) {
		if ($obj->{buffer}->[$curr] =~ /$pattern/i) {
			$obj->{position} = $curr;
			return $obj->{buffer}->[$obj->{position}];
		}
		--$curr;
	}
	return undef;
}
