package jQuery::Loader::Source::File;

use Moose;
extends qw/jQuery::Loader::Source/;
use jQuery::Loader::Carp;

use jQuery::Loader::Location;
use jQuery::Loader::Template;

has location => qw/is ro/, handles => [qw/recalculate file/];
has template => qw/is ro required 1 lazy 1 isa jQuery::Loader::Template/, default => sub { return jQuery::Loader::Template->new };

sub BUILD {
    my $self = shift;
    my $given = shift;

    my $location = $given->{location};
    $self->{location} = do {

        croak "Wasn't given a file" unless $given->{file};

        jQuery::Loader::Location->new(template => $self->template, file => $given->{file}, location => $location);

    }
    unless blessed $location;
}

1;
