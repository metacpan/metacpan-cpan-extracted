package WWW::Docker::Item::Container;
use Moose;
use namespace::autoclean;

extends 'WWW::Docker::Item';

################
## Attributes ##
################

has 'Command' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'Created' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'Id' => (
    is       => 'ro',
    isa      => 'Str', # TODO: find a better validator for this later
    required => 1,
);

has 'Image' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'Names' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has 'Status' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable();

1;

__END__
