package WWW::Marvel::Config::File;
use strict;
use warnings;
use base qw/ WWW::Marvel::Config /;
use Carp;
use Config::Tiny;

my $DEFAULT_CONFIG_FILENAME = 'marvel.conf';

sub new {
	my ($class, $config_filename) = @_;

	my $self = bless {}, $class;

	$config_filename //= $self->get_default_config_filename();
	my $cfg = Config::Tiny->read( $config_filename )
		or croak sprintf("problem with '%s' config: %s", $config_filename, Config::Tiny->errstr);
	$self->{'config_filename'} = $config_filename;

	$self->_set_keys( $cfg->{auth} );
	return $self;
}

sub get_default_config_filename { $DEFAULT_CONFIG_FILENAME }

sub get_config_filename { shift->{'config_filename'} }

1;
