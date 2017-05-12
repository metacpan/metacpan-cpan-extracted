package jQuery::Loader::Cache::URI;

use Moose;
extends qw/jQuery::Loader::Cache::File/;
use jQuery::Loader::Carp;

use Path::Abstract;

sub BUILD {
    my $self = shift;
    my $given = shift;

    my $location = $given->{location};
    $self->{location} = do {

        my ($file, $uri);
        if (my $rsc = $given->{rsc}) {
            if (blessed $rsc && $rsc->isa("Path::Resource")) {
                $file = $rsc->file;
                $uri = $rsc->uri;
            }
        }
        else {
            ($file, $uri) = @$given{qw/file uri/};
        }

        croak "Wasn't given a file" unless $file;
        croak "Wasn't given a URI" unless $uri;

        $file = "$file/\%l" if -d $file; # TODO Moar checking, Path::Class::Dir, etc.

        jQuery::Loader::Location->new(template => $self->template, file => $file, uri => $uri, location => $location);
    }
    unless blessed $location;
}

sub uri {
    my $self = shift;
    $self->file; # Load up the file if it doesn't exist
    return $self->location->uri(@_);
}

1;
