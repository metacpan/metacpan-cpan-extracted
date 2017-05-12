package Text::Placeholder;

use strict;
use warnings;
use Carp qw();
use parent qw(
	Object::By::Array);

our $VERSION = '0.04';

sub P_PLACEHOLDER_RE() { 0 }
sub build_parser($) {
	my $placeholder_re = $_[P_PLACEHOLDER_RE];
	$placeholder_re =~ s,/,\\/,sg;
	my $parser = eval "sub {
		return unless(\$_[0] =~ s/$placeholder_re//s);
		return(\$1, \$2);
	};";
	Carp::confess($@) if ($@);
	return($parser);
}
my $default_parser = build_parser('^(.*?)\[=([^=\]]+)=\]');

sub THIS() { 0 }

sub ATR_PARSER() { 0 }
sub ATR_GROUPS() { 1 }
sub ATR_COLLECTOR() { 2 }

sub _init {
	my $this = shift;

	if (ref($_[0]) eq 'CODE') {
		$this->[ATR_PARSER] = shift;
#	} elsif ($_[0] =~ m,[^\w\:],s) {
#		$this->[ATR_PARSER] = build_parser(shift);
	} else {
		$this->[ATR_PARSER] = $default_parser;
	}
	$this->[ATR_GROUPS] = [];
	$this->[ATR_COLLECTOR] = undef;
	$this->add_group(@_);

	return;
}

sub P_PARSER() { 1 }
sub parser {
	if(exists($_[P_PARSER])) {
		$_[THIS][ATR_PARSER] = (ref($_[P_PARSER]) eq '')
			? build_parser($_[P_PARSER])
			: $_[P_PARSER];
		return;
	} else {
		return($_[THIS][ATR_PARSER]);
	}
}

sub default_parser {
	if(exists($_[P_PARSER])) {
		$default_parser = (ref($_[P_PARSER]) eq '')
			? build_parser($_[P_PARSER])
			: $_[P_PARSER];
		return;
	} else {
		return($default_parser);
	}
}

sub add_group {
	my $this = shift;

	foreach my $group (@_) {
		if(ref($group) eq '') {
			unless($group =~ m,^((|::)(\w+))+$,) {
				Carp::confess("Invalid package name '$group'.");
			}
			if(substr($group, 0, 2) eq '::') {
				$group = __PACKAGE__."::Group$group";
			}
			eval "use $group;";
			Carp::confess($@) if ($@);
			$group = $group->new;
		}
		push(@{$this->[ATR_GROUPS]}, $group);
	}
	return;
}

sub compile {
	my ($this, $format) = @_;

	my @parts = ();
	my @dynamic_values = ();
	while (my ($text, $placeholder) = $this->[ATR_PARSER]->($format)) {
		push(@parts, $text, '');
		foreach my $group (@{$this->[ATR_GROUPS]}) {
			next unless(defined(my $collector = $group->lookup($placeholder)));
			push(@dynamic_values, [$collector, $#parts]);
			last;
		}
	}
	push(@parts, $format);

	$this->[ATR_COLLECTOR] = sub {
		foreach my $value (@dynamic_values) {
			my ($collector, $offset) = @$value;
			$parts[$offset] = $collector->[0]->($collector->[1]);
		}
		return(\join(q{}, @parts));
	};

	return;
}

sub execute {
	return(shift->[ATR_COLLECTOR]->(@_));
}

1;
