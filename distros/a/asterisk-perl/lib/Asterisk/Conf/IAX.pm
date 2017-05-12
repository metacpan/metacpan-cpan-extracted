package Asterisk::Conf::IAX;

require 5.004;

=head1 NAME

Asterisk::Config::IAX - IAX configuration stuff

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;
use Asterisk::Conf;
@ISA = ('Asterisk::Conf');

$VERSION = '0.01';

$DEBUG = 5;

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'name'} = 'IAX';
        $self->{'description'} = 'IAX Channel Driver Configuration';
	$self->{'configfile'} = '/etc/asterisk/iax.conf';
	$self->{'config'} = {};
	$self->{'configtemp'} = {};
	$self->{'contextorder'} = ( 'general' );
	$self->{'channelgroup'} = {};

	$self->{'variables'} = { 
#this stuff can only be in general context

#need to put together some list of codecs somewhere
		'allow' => { 'default' => 'gsm', 'type' => 'multitext', 'contextregex' => '^general$' },
		'disallow' => { 'default' => 'lpc10', 'type' => 'multitext', 'contextregex' => '^general$' },
		'bindaddr' => { 'default' => undef, 'type' => 'text', 'regex' => '^\w*$', 'contextregex' => '^general$' },
		'bandwidth' => { 'default' => 'low', 'type' => 'one', 'values' => [ 'low', 'medium', 'high' ], 'contextregex' => '^general$' },
		'jitterbuffer' => { 'default' => 'yes', 'type' => 'one', 'values' => [ 'yes', 'no' ], 'contextregex' => '^general$' },
		'dropcount' => { 'default' => '3', 'type' => 'text', 'regex' => '^\d*$', 'contextregex' => '^general$' },

		'permit' => { 'default' => undef, 'type' => 'multitext' },
		'deny' => { 'default' => undef, 'type' => 'multitext', 'negcontextregex' => '^general$' },
		'context' => { 'default' => 'default', 'type' => 'multitext' },
		'port' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'type' => { 'default' => 'user', 'type' => 'one', 'values' => [ 'user', 'peer', 'friend'] },
		'context' => { 'default' => 'default', 'type' => 'multitext' },
		'secret' => { 'default' => undef, 'type' => 'text', 'regex' => '^\w*$', 'negcontextregex' => '^general$' },
		'username' => { 'default' => undef, 'type' => 'text', 'regex' => '^\w*$', 'negcontextregex' => '^general$' },
				


	};


	bless $self, ref $class || $class;
	return $self;
}


1;
