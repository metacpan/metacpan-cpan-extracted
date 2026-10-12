package oEdtk::Dict;
use strict;
use warnings;

use Config::IniFiles;
use Exporter;
our $VERSION	= 2.1109;
our @ISA		= qw(Exporter);

# Create a dictionary from an INI file.
sub new {
	my ($class, $path, $options) = @_;

	my $invert      = $options->{'invert'} || 0;
	my $section     = $options->{'section'} || 'DEFAULT';
	my $ignore_case = $options->{'ignore_case'} || 1;

	# warn "INFO : Path EDTK_DICO >$path< \n";
	tie my %ini, 'Config::IniFiles',
	    (-file => $path, -default => $section);

	my $dico = $ini{$section};
	if ($invert) {
		# Invert the hash.
		my %tr = ();
		while (my ($key, $val) = each %$dico) {
			if (ref($val) eq 'ARRAY') {
				$tr{$_} = $key foreach @$val;
			} else {
				$tr{$val} = $key;
			}
		}
		$dico = \%tr;
	}
	if ($ignore_case) {
		my $dico2 = {};
		while (my ($key, $val) = each %$dico) {
			$dico2->{lc($key)} = $val;
		}
		$dico = $dico2;
	}
	my $self = {
		ignore_case => $ignore_case,
		dico        => $dico
	};

# 	warn "INFO : Dict object $class $self ($section $path) created...\n";
	return bless $self, $class;
}


sub translate {
	# pass the 'check' option to request a check that the value is present in the dictionary
	# if the value is absent from the dictionary, returns 'undef'
	my ($self, $word, $check) = @_;

	my $key = $word;
	if ($self->{'ignore_case'}) {
		$key = lc($key);
	}
	my $val = $self->{'dico'}->{$key};
	if (!$check && !defined($val)) {
		$val = $word;
	}

return $val;
}


sub substitue {
	my ($self, $var) = @_;
#	warn "DEBUG: Dict::substitute value = '$var'\n";

	if (defined($var) && length($var) > 0) {
		while (my ($key, $val) = each %{$self->{'dico'}}) {
			$var =~s/$key/$val/ig;
		}

#		warn "DEBUG: Dict::substitute value = '$var'\n";
	}

return $var ;
}


1;
