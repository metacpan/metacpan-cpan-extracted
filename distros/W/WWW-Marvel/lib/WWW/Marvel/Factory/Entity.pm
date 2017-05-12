package WWW::Marvel::Factory::Entity;
use strict;
use warnings;
use Carp;
use Module::Load;

my @ENTITY_TYPES = (qw/ Character /);
my %MODULES = map { lc($_) => "WWW::Marvel::Entity::$_" } @ENTITY_TYPES;

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub identify {
	my ($self, $data) = @_;

	my $ent;
	if ($self->is_character($data)) {
		load $MODULES{character};
		$ent = $MODULES{character}->new($data);
	}

	confess "Unidentified data" if !defined $ent;
	
	return $ent;
}

sub is_character {
	my ($self, $data) = @_;
	my $res = 1;
	my @character_fields = (qw/id comics description events modified name resourceURI series stories thumbnail urls/);

	$res = 0 if $data->{resourceURI} !~ m#/characters/[0-9]+#;

	if ($res) {
		for my $k (@character_fields) {
			next if exists $data->{ $k };
			$res = 0;
			last;
		}
	}

	if ($res) {
		my %character_fields = map {$_,1} @character_fields;
		for my $k (keys %$data) {
			next if exists $character_fields{ $k };
			$res = 0;
			last;
		}
	}

	return $res;
}

1;
