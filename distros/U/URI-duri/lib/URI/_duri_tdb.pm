package URI::_duri_tdb;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$URI::_duri_tdb::AUTHORITY = 'cpan:TOBYINK';
	$URI::_duri_tdb::VERSION   = '0.003';
}

use Carp;
use DateTime::Incomplete;
use POSIX qw[floor];
use Scalar::Util qw[blessed reftype];

use base 'URI';

my $re_datetime = qr{
	(?<year>\d{4})
	(?:
		\-(?<month>\d{2})
		(?:
			\-(?<day>\d{2})
			(?:
				T(?<hour>\d{2}):(?<minute>\d{2})
				(?:
					:(?<second> \d{2} (?:\.\d+)? )
				)?
			)?
		)?
	)?
	(?<time_zone>
		[Z] |
		[+-]\d{2}:\d{2} |
		[+-]\d{4} |
		[+-]\d{2}
	)?
}ix;

sub new
{
	my $param = $_[1];
	
	if (not ref $param)
		{ goto \&_new_from_string }
	elsif (reftype $param eq 'HASH')
		{ goto \&_new_from_hashref }

	croak "cannot construct URI::duri object";
}

sub _new_from_string
{
	my ($class, $str) = @_;
	my $self = bless \$str => $class;
	$self->_deconstruct;
	return $self;
}

sub _new_from_hashref
{
	my ($class, $hashref) = @_;
	
	my $str  = $class->_preferred_scheme . ':2001:urn:example:1';
	my $self = bless \$str => $class;

	if ($hashref->{datetime_string})
		{ $self->datetime_string($self->{datetime_string}) }
	elsif ($hashref->{datetime})
		{ $self->datetime($self->{datetime}) }
	else
		{ $self->datetime(DateTime->now) }
	
	exists $hashref->{embedded_uri}
		or croak "need embedded_uri hash key";
	$self->embedded_uri($hashref->{embedded_uri});
	
	return $self;
}

sub _parse_datetime
{
	my ($self, $str) = @_;
	
	confess "_parse_datetime called with undefined argument" unless defined $str;
	
	if ($str =~ /^$re_datetime$/)
	{
		my %parts = %+;
		if (defined $parts{time_zone} 
		and lc $parts{time_zone} eq 'z')
		{
			$parts{time_zone} = 'UTC';
		}
		elsif (defined $parts{time_zone})
		{
			$parts{time_zone} =~ s/://;
			$parts{time_zone} .= '00'
				if length $parts{time_zone} == 3;
		}
		
		if (defined $parts{second}
		and $parts{second} > floor $parts{second})
		{
			my $frac = $parts{second} - floor $parts{second};
			$parts{second}     = floor $parts{second};
			$parts{nanosecond} = $frac * 1_000_000_000;
		}
		
		return DateTime::Incomplete->new(%parts);
	}
	
	croak "datetime does not match regular expression";
}

sub _serialize_datetime
{
	my ($self, $dt) = @_;
	
	if ($dt->isa('DateTime::Incomplete'))
	{
		croak "datetime has no year"
			unless $dt->has_year;
		
		my $str = sprintf('%04d' => $dt->year);
		my $tz  = '';
		
		if ($dt->has_time_zone and $dt->time_zone->is_utc)
			{ $tz = 'Z' }
		elsif ($dt->has_time_zone and $dt->time_zone->is_floating)
			{ $tz = '' }
		elsif ($dt->has_time_zone)
			{ croak "non-UTC timezone specified" }
		
		$dt->has_month
			? do { $str .= sprintf('-%02d' => $dt->month) }
			: return $str.$tz;
			
		$dt->has_day
			? do { $str .= sprintf('-%02d' => $dt->day) }
			: return $str.$tz;
		
		$dt->has_hour && $dt->has_minute
			? do { $str .= sprintf('T%02d:%02d' => $dt->hour, $dt->minute) }
			: return $str.$tz;
		
		$dt->has_second
			? do { $str .= sprintf(':%02d' => $dt->second) }
			: return $str.$tz;
		
		$dt->has_nanosecond && $dt->nanosecond > 0
			? do { $str .= sprintf('.%09d' => $dt->nanosecond); $str =~ s/0+$//; }
			: return $str.$tz;
		
		return $str.$tz;
	}
	elsif ($dt->isa('DateTime'))
	{
		unless ($dt->time_zone->is_floating or $dt->time_zone->is_utc)
		{
			$dt->set_time_zone('UTC');
		}
		
		my $str = $dt->strftime('%FT%T.%9N');
		$str =~ s/0+$//;
		$str =~ s/\.$//;
		
		if ($dt->time_zone->is_utc)
		{
			$str .= 'Z';
		}
		
		return $str;
	}
	
	confess "can't serialize";
}

sub datetime
{
	my $self = shift;
	
	if (@_)
	{
		my $dt = shift;
		croak "expected DateTime object"
			unless (
				blessed($dt) and
				$dt->isa('DateTime') || $dt->isa('DateTime::Incomplete')
			);
		my $ser = $self->_serialize_datetime($dt);
		$self->datetime_string($ser, 1);
		return $ser;
	}
	
	$self->_parse_datetime($self->datetime_string);
}

sub datetime_string
{
	my $self  = shift;
	my @parts = $self->_deconstruct;
	
	if (@_)
	{
		my ($dt, $skip_check) = @_;
		unless ($skip_check)
		{
			$dt =~ /^$re_datetime$/
				or croak "string '$dt' cannot be parsed as a DateTime: $@";
		}
		$parts[1] = $dt;
		$self->_reconstruct(@parts);
	}
	
	return $parts[1];
}

sub embedded_uri
{
	my $self  = shift;
	my @parts = $self->_deconstruct;
	
	if (@_)
	{
		my $uri = shift;
		$parts[2] = blessed($uri) ? $uri : URI->new("$uri");
		$self->_reconstruct(@parts);
	}
	
	return URI->new($parts[2]);
}

sub _reconstruct
{
	my $self = shift;	
	$$self = sprintf('%s:%s:%s', @_);
	return $self;
}

sub _deconstruct
{
	my $self = shift;
	
	if (my @r = ($$self =~ m{
		^
		(?<scheme>[A-Za-z][A-Za-z0-9+-]*)
		\:
		(?<datetime>$re_datetime)
		\:
		(?<embedded>.+)
		$
	}x))
	{
		# NOTE: We cannot just return the hash slice. We need to do
		# the assignment first. This is a workaround to a bizarro bug
		# in Perl 5.10 and 5.12 (and maybe 5.14?)
		my @parts = @+{qw< scheme datetime embedded >};
		return @parts;
	}
	
	else
	{
		confess "couldn't match regexp";
	}
}

__PACKAGE__
