package VUser::Google::Groups;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;

has 'google' => (
    is       => 'rw',
    isa      => 'VUser::Google::ApiProtocol',
    required => 1
);

has base_url => (is => 'rw', isa => 'Str');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

#### Methods ####

## Util
#print out debugging to STDERR if debug is set
sub dprint
{
    my $self = shift;
    my $text = shift;
    my @args = @_;
    if( $self->debug and defined ($text) ) {
	print STDERR sprintf ("$text\n", @args);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
