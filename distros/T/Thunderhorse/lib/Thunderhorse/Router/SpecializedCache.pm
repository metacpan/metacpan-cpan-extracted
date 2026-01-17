package Thunderhorse::Router::SpecializedCache;
$Thunderhorse::Router::SpecializedCache::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard, -role;

use Gears::X::Thunderhorse;

requires qw(
	get
	set
);

has field 'router' => (
	isa => InstanceOf ['Thunderhorse::Router'],
	writer => 1,
	weak_ref => 1,
);

# store needs to clone
my sub store ($matches)
{
	return undef unless defined $matches;

	my @new_matches = $matches->@*;
	foreach my $match (@new_matches) {
		if ($match isa 'Gears::Router::Match') {
			$match = {
				_match_class => ref $match,
				location => $match->location->name,
				matched => $match->matched,
			};
		}
		elsif (ref $match eq 'ARRAY') {
			$match = __SUB__->($match);
		}
	}

	return \@new_matches;
}

my sub retrieve ($router, $matches)
{
	return undef unless defined $matches;

	my @new_matches = $matches->@*;
	foreach my $match (@new_matches) {
		if (ref $match eq 'HASH' && $match->{_match_class}) {
			my %args = $match->%*;
			my $class = delete $args{_match_class};
			my $location = $args{location};
			$args{location} = $router->find($location);

			# locations must be created in a deterministic order - otherwise,
			# this error may occur
			Gears::X::Thunderhorse->raise("invalid cached location $location")
				unless $args{location};
			$match = bless \%args, $class;
		}
		elsif (ref $match eq 'ARRAY') {
			$match = __SUB__->($router, $match);
		}
	}

	return \@new_matches;
}

around set => sub ($orig, $self, $key, $value, @args) {
	return $self->$orig($key, store($value), @args);
};

around get => sub ($orig, $self, @args) {
	return retrieve($self->router, $self->$orig(@args));
};

