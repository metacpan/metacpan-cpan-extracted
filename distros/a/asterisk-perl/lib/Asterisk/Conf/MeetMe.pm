package Asterisk::Conf::MeetMe;

require 5.004;

=head1 NAME

Asterisk::Config::MeetMe - MeetMe configuration stuff

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
	$self->{'name'} = 'MeetMe';
        $self->{'description'} = 'MeetMe Configuration';
	$self->{'configfile'} = '/etc/asterisk/meetme.conf';
	$self->{'config'} = {};
	$self->{'configtemp'} = {};
	$self->{'contextorder'} = ( 'rooms' );
	$self->{'channelgroup'} = {};

	$self->{'variables'} = { 
#this stuff can only be in general context

#need to put together some list of codecs somewhere
		'conf' => { 'default' => undef, 'type' => 'multitext', 'regex' => '^\w*$' },

	};


	bless $self, ref $class || $class;
	return $self;
}


1;
