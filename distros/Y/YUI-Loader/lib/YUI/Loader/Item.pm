package YUI::Loader::Item;

use Moose;
use Path::Abstract;
use YUI::Loader::Carp;

has filter => qw/is ro/;
has entry => qw/is ro required 1 isa YUI::Loader::Entry/, handles => [qw/name/];

sub _filter ($$) {
    my $path = shift;
    my $filter = shift;

    $path =~ s/(.*)(\..{2,4})$/$1-$filter$2/ or croak "Don't understand path \"$path\"";

    return $path;
}

sub _filter_path ($$) {
    my $path = shift;
    my $filter = shift;

    return $path unless $filter;

    $filter =~ m/^\s*min\s*$/i and return _filter $path, "min";
    $filter =~ m/^\s*debug\s*$/i and return _filter $path, "debug";

    return $path;
}

sub file {
    my $self = shift;
    return _filter_path $self->entry->file, $self->filter;
}

sub path {
    my $self = shift;
    return _filter_path $self->entry->path, $self->filter;
}

sub _uri ($$) {
    my $base = shift;
    my $path = shift;

    my $uri = $base->clone;
    $uri->path(Path::Abstract->new($uri->path, "/$path")->stringify);
    return $uri;
}

sub file_uri {
    my $self = shift;
    my $base = shift;
    return _uri $base, $self->file;
}

sub path_uri {
    my $self = shift;
    my $base = shift;
    return _uri $base, $self->path;
}

1;
