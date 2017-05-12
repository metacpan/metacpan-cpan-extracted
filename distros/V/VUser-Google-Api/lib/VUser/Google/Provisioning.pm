package VUser::Google::Provisioning;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;

has 'google' => (
    is => 'rw',
    isa => 'VUser::Google::ApiProtocol',
    required => 1
);

has 'base_url' => (is => 'rw', isa => 'Str');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

#### Methods

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

# Escape " with &quot; for XML
sub _escape_quotes {
    my $self = shift;
    my $text = shift;

    $text =~ s/\"/&quot;/;

    return $text;
}

# Replace 1 with 'true' other with 0
sub _as_bool {
    my $self  = shift;
    my $value = shift;

    return $value ? 'true' : 'false';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
