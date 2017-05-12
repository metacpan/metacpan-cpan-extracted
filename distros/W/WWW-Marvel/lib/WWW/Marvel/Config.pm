package WWW::Marvel::Config;
use strict;
use warnings;
use Carp;

# my $cfg = WWW::Marvel::Config->new({
#	private_key => 'a1b2',
#	public_key  => 'c3d4',
# });
# $cfg->get_private_key(); # a1b2
# $cfg->get_public_key();  # c3d4

my @KEYS = (qw/ private_key public_key /);

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;
	$self->_set_keys($args);

	return $self;
}

sub get_private_key { shift->_get_auth_key('private_key') }
sub get_public_key  { shift->_get_auth_key('public_key') }

sub _get_auth_key {
	my ($self, $name) = @_;
	croak "Unknown '$name' key" if !exists $self->{ $name };
	$self->{ $name };
}

sub _set_keys {
	my ($self, $hash) = @_;

	for my $k (@KEYS) {
		next if !exists $hash->{ $k };
		$self->{ $k } = $hash->{ $k };
	}
}

1;
