#-----------------------------------------------------------------
package DeltaX::Config;
#-----------------------------------------------------------------
# $Id: Config.pm,v 1.2 2003/10/30 15:51:44 spicak Exp $
# 
# (c) DELTA E.S., 2002 - 2003
# This package is free software; you can use it under "Artistic License" from
# Perl.
#-----------------------------------------------------------------
$DeltaX::Config::VERSION = '1.0';

use strict;
use Carp;

#-----------------------------------------------------------------
sub new {
#-----------------------------------------------------------------
# CONSTRUCTOR
#
	my $pkg = shift;
	my $self = {};
	bless ($self, $pkg);

	$self->{filename} = '';
	$self->{db} = '';
	$self->{app} = '';
	$self->{db_table} = 'app_lang';
	$self->{lang} = 'CZ';

	croak ("$pkg created with odd number of parameters - should be of the form option => value")
		if (@_ % 2);
	for (my $x = 0; $x <= $#_; $x += 2) {
		if (exists $self->{$_[$x]}) {
			$self->{$_[$x]} = $_[$x+1];
		} 
		else {
			$self->{special}{$_[$x]} = $_[$x+1];
		}
	}

	$self->{error} = '';

	croak ("$pkg: You must set db handle or filename!")
		if (! $self->{filename} and ! $self->{db});
	croak ("$pkg: You must set application name for db handle!")
		if ($self->{db} and ! $self->{app});

	return $self;
}
# END OF new()

#-----------------------------------------------------------------
sub read {
#-----------------------------------------------------------------
#
	my $self = shift;

	if ($self->{filename}) {
		return $self->_read_file();
	}
	if ($self->{db}) {
		return $self->_read_db();
	}

	return undef;

}
# END OF read()

#-----------------------------------------------------------------
sub _read_file {
#-----------------------------------------------------------------
#
	my $self = shift;

	local(*INF);
	if (! open INF, $self->{filename}) {
		$self->{error} = "cannot read file '".$self->{filename}."': $!";
		return undef;
	}

	my %ret;
	my $place;
	my $prev_line = '';
	while (<INF>) {
		chomp;

		if ($prev_line) { 
			# zrusime mezery na zacatku
			s/^[ \t]*//g;
			$_ = $prev_line . ' '. $_;
			$prev_line = '';
		}

		if (! $_) { next; }

		if (/^[ ]*#/) {
			s/[ ]*#[ ]*//g;
			if (/^!(.*)$/) {
				my $tmp = $self->_special($1);
				return undef unless defined $tmp;
				foreach my $key (keys %{$tmp}) {
					$ret{$key} = $tmp->{$key} unless exists $ret{$key};
				}
			}
		}
		else {
			s/#.*$//g;

			# zrusime mezery na zacatku a na konci
			s/^[ \t]*//g;
			s/[ \t]*$//g;

			# pokud je nakonci zpetne lomitko, zapamatujeme si to a pridame k
			# pristimu radku
			if (/\\$/) {
				$prev_line = substr($_, 0, -1);
				# zrusime mezery na konci
				$prev_line =~ s/[ \t]*$//g;
				next;
			}

			my ($key, $val) = split(/=/, $_, 2);
			$key = '' if !defined $key;
			$val = '' if !defined $val;
			$key =~ s/^[ ]*//g;
			$key =~ s/[ ]*$//g;
			$val =~ s/^[ ]*//g;
			$val =~ s/[ ]*$//g;
			if (length($key) < 1) { next; }
      # untaint!
      if ($key =~ /^([-\w.]+)$/) {
        $key = $1;
      }
      else {
        $self->{error} = "Invalid key '$key' in file!";
        return undef;
      }

			my $tmp = '$ret{\''.join("'}{'", split(/\./, $key)).'\'}';
			$place = eval "\\($tmp)";
			$$place = $val;
		}
	}

	close INF;

	return \%ret;

}
# END OF _read_file()

#-----------------------------------------------------------------
sub get_error {
#-----------------------------------------------------------------
#
	my $self = shift;

	return $self->{error};
}
# END OF get_error()

#-----------------------------------------------------------------
sub _special {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $token = shift;

	$token =~ s/^\s*//g;
	
	if ($token =~ /^include/) {
		$token =~ /^include\s+(\S+)\s*$/;
		return $self->_include($1);
	}
	if ($token =~ /^import/) {
		$token =~ /^import\s+(\S+)\s*$/;
		my $tmp = $self->_include($1);
		if ($tmp) {
			my %tmp;
			my $key = $1;
			$key = substr($key, 0, rindex($key, '.')) if (rindex($key, '.') > 0);
			$tmp{$key} = $tmp;
			return \%tmp;
		}
		else {
			return undef;
		}
	}

	$token =~ /^(\S+)\s*(.*)$/s;
	my @args;
	if ($2) { @args = split(/,/, $2); }
	# other special command
	if (! exists $self->{special}{$1}) {
		$self->{error} = "unknown directive '$1'";
		return undef;
	}
	return $self->{special}{$1}->(@args);

}
# END OF _special

#-----------------------------------------------------------------
sub _include {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $arg  = shift;

	# relative path!
	if ($arg !~ /^\//) {
		if ($self->{filename} =~ /^(.*)\/[^\/]*$/) {
			if ($self->{special}{'include'}) {
				$arg = $self->{special}{'include'}->($arg);
			} else {
				$arg = "$1/$arg";
			}
		}
	}
	if (!$arg) { 
		$self->{error} = "include: no file found";
		return undef;
	}

	my @spec;
	foreach my $s (sort keys %{$self->{special}}) {
		push @spec, $s, $self->{special}{$s};
	} 
	foreach my $s (keys %{$self}) {
		push @spec, $s, $self->{$s}
			unless ($s eq 'filename' or $s eq 'special' or $s eq 'error');
	}
	my $inc = new DeltaX::Config(filename=>$arg, @spec);
	my $ret = $inc->read();
	if (! defined $ret) {
		$self->{error} = "include: unable to read '$arg': ". $inc->get_error();
		return undef;
	}
	return $ret;
}
# END OF _include()

#-----------------------------------------------------------------
sub DESTROY {
#-----------------------------------------------------------------
#
	my $self = shift;

}
# END OF DESTROY()

1;
