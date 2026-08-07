package WebService::OurWorldInData::Error;
# ABSTRACT: Error object for Our World in Data Chart API

use Moo;
#extends 'WebService::OurWorldInData';

use Carp;
use Types::Standard qw( Str ); # Bool Enum Int ArrayRef HashRef InstanceOf ConsumerOf

has error => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has message => (
    is      => 'ro',
    isa     => Str,
);

has details => (
    is      => 'ro',
    isa     => Str,
);

1; # Perl is my Igor

=head1 DESCRIPTION

Basic Error object for containing errors sent by the OWID API

=cut
