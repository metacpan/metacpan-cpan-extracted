package WWW::Docker::Item::Image;
use Moose;
use namespace::autoclean;

extends 'WWW::Docker::Item';

################
## Attributes ##
################

has 'Created' => (
    is  => 'ro',
    isa => 'Int',
);

has 'Id' => (
    is  => 'ro',
    isa => 'Str', # TODO: better validation
);

has 'ParentId' => (
    is  => 'ro',
    isa => 'Str',
);

has 'RepoTags' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
);

has 'Size' => (
    is  => 'ro',
    isa => 'Int',
);

has 'VirtualSize' => (
    is  => 'ro',
    isa => 'Int',
);

__PACKAGE__->meta->make_immutable();

1;

__END__
