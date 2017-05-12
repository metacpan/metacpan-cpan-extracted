package Time::Vector;

use strict;

use Time::Simple::Range;
use Time::Seconds;
use Bit::Vector::Overload; # this thingy can't be subclassed :(

use base qw/ Class::Accessor::Fast /;

use overload
	'fallback'	=> 0,
	'&'		=> 'and',
	'|'		=> 'or',
	'='		=> 'clone',
	'""'		=> 'stringify';

our $VERSION = '1.1';

__PACKAGE__->mk_accessors(qw/ vec first last /);


use constant BITS_PER_DAY	=> 1440; # 1 bit per minute

sub new
{
	my ($proto, $vec) = @_;
	my $class = ref($proto) || $proto;

	my $self = bless $proto->SUPER::new(), $class;

	$self->vec(defined $vec ? $vec : Bit::Vector->new(BITS_PER_DAY));
	$self->first(undef);
	$self->last(undef);

	return bless $self, $class;
}

sub new_range
{
	my ($proto, @range) = @_;
	
	my $self = new Time::Vector;

	while (scalar @range >= 2) {
		my @r = splice(@range, 0, 2);
		$self->add_range(Time::Simple::Range->new($r[0], $r[1]));
	}

	return $self;
}


sub add_range
{
	my ($self, $range) = @_;

	my $start = $range->start->hours * 60 + $range->start->minutes;
	my $end = $range->end->hours * 60 + $range->end->minutes;

	$end--
		unless $range->end->seconds == 59;

	$self->first($range->start)
		if not defined $self->first
		or $range->start < $self->first;	

	$self->last($range->end)
		if not defined $self->last
		or $range->end > $self->last;	

	# Bitwise OR between old vector and range vector
	my $nv = $self->vec | Bit::Vector->new_Enum(BITS_PER_DAY, "$start-$end");

	$self->vec($nv);
}

sub after
{
	my $self = shift;
	return undef unless defined $self->last;
	return Time::Vector->new_range($self->last, Time::Simple->new('23:59:59'));
}

sub before
{
	my $self = shift;
	return undef unless defined $self->first;
	return Time::Vector->new_range(Time::Simple->new('00:00:00'), $self->first);
}

sub range
{
	my $self = shift;
	my @range;

	my $base = Time::Simple->new('00:00:00');
	
	my $enum = $self->vec->to_Enum;
	foreach my $r (split(/,/, $enum)) {
		if ($r =~ /^(\d+)-(\d+)$/) {
			my $s = $base + ($1 * 60);
			my $e = $base + ($2 * 60) + 60;

			push(@range, Time::Simple::Range->new($s, $e));
		} elsif ($r =~ /^(\d+)$/) {
			my $s = $base + ($1 * 60);
			my $e = $s + 60;
			push(@range, Time::Simple::Range->new($s, $e));
		}
	}

	return @range;
}

sub duration
{
	my $self = shift;
	my $d = 0;

	foreach ($self->range) {
		$d += $_->duration;
	}

	return new Time::Seconds($d);
}

sub and
{
	my ($a, $b) = @_;
	my $vec = $a->vec & $b->vec;
	return Time::Vector->new($vec);
}

sub or
{
	my ($a, $b) = @_;
	my $vec = $a->vec | $b->vec;
	return Time::Vector->new($vec);
}

sub stringify
{
	return join(',', map {
		$_->start->format('%H:%M')
		. '-'
		. $_->end->format('%H:%M')
	} (shift)->range);
}

sub clone
{
	my $self = shift;
	return Time::Vector->new($self->vec->Clone);
}


1;
