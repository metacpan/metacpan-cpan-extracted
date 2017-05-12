#
# $Id$
#
package Asterisk;

require 5.004;

use vars qw($VERSION);

$VERSION = '1.08';

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{configfile} = undef;
	$self->{config} = {};
	bless $self, ref $class || $class;
	return $self;
}

sub DESTROY { }

package asterisk::perl;

=head1 NAME

asterisk::perl

This module exists solely to satisfy packaging requirements.

=cut


1;
