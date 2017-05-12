package DBIx::dbMan::Config;

use strict;
use locale;
use vars qw/$AUTOLOAD/;
use POSIX;

our $VERSION = '0.04';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;

	$obj->{config} = {};
	$obj->{configfile} = $obj->{-file} || $obj->_configfile();
	$obj->_load if $obj->{configfile};

	return $obj;
}

sub _bhashes {
	my $line = shift;

	$line =~ s/#/\\#/g;
	return $line;
}

sub _load {
	my $obj = shift;
	if (open F,$obj->{configfile}) {
		while (<F>) {
			my $key;  my $value;
			chomp;
			s/\\/\\\\/g;			# double backslashes
			s/^(['"])(.*?)([^\\])\1/$1.(_bhashes($2.$3)).$1/eg;
			s/([^\\])(['"])(.*?)([^\\])\2/$1.$2.(_bhashes($3.$4)).$2/eg;
					# backslash # in ''
			s/^#.*$//;			# whole-line comment
			s/([^\\])#.*$/$1/;		# other comment
			s/\\#/#/g;			# unbackslash #
			s/\\\\/\\/g;			# single backslashes
			s/^\s+//;			# starting whitespaces
			s/\s+$//;			# ending whitespaces
			next unless $_;			# empty line
			if (/^(\S+)\s+(.*)$/) {
				($key,$value) = ($1,$2);
			} else {
				($key,$value) = ($_,'');
			}
			$value =~ s/^(['"])(.*)\1$/$2/;	# quoted line
			push @{$obj->{config}->{$key}},$value;
		}
		close F;
	}
}

sub merge {
	my ($obj,$config) = @_;

	return 0 unless $config;

	for my $tag ($config->all_tags) {
		if ( ref $config->$tag eq "ARRAY" ) {
			push @{$obj->{config}->{$tag}}, @{$config->$tag};
		} else {
			push @{$obj->{config}->{$tag}}, $config->$tag;
		}
	}
	return 1;
}

sub _configfile {
	my $obj = shift;
	
	my $res = $ENV{DBMAN_CONFIG};
	return $res if $res and -e $res;

	$res = $ENV{HOME}.'/.dbman/config';
	return $res if -e $res;

	return '/etc/dbman.conf';
}

sub all_tags {
	my $obj = shift;
	return keys %{$obj->{config}};
}

sub AUTOLOAD {
	my $obj = shift;

	$AUTOLOAD =~ s/^DBIx::dbMan::Config:://;
	my $res = $obj->{config}->{$AUTOLOAD};
	if (defined $res) {
		if (ref $res and scalar @$res > 1) {
			return wantarray ? @$res : $res;
		} else {
			return wantarray ? @$res : $res->[0];
		}
	} else {
		return undef;
	}
}
