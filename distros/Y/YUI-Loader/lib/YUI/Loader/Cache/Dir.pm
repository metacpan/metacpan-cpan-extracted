package YUI::Loader::Cache::Dir;

use Moose;
extends qw/YUI::Loader::Cache/;

use File::Copy qw/copy/;
use YUI::Loader::Carp;
use LWP::UserAgent;

has dir => qw/is ro/;

my $agent = LWP::UserAgent->new;

sub BUILD {
    my $self = shift;
    my $given = shift;

    my ($dir) = @$given{qw/dir/};

    croak "Don't have a dir" unless $dir;

    $dir = Path::Class::Dir->new("$dir") unless blessed $dir && $dir->isa("Path::Class");

    $self->{dir} = $dir;
}

sub _file {
    my $self = shift;
    my $item = shift;

    $item = $self->catalog->item($item);
    my $file = $item->file;
    my $path = $self->dir->file($file);

    unless (-f $path && -s $path) {
        my $source = $self->source;
        if (my $source_file = $source->file($item)) {
            copy $source_file, $path or croak "Unable to copy $source_file, $path: $!";
        }
        elsif (my $source_uri = $source->uri($item)) {
            my $response = $self->request($source_uri);
            $path->parent->mkpath unless -d $path->parent;
            $path->openw->print($response->content);
        }
        else {
            croak "Unable to source anything!";
        }
    }

    return ($path, $file);
}

override file => sub {
    my $self = shift;

    my ($file) = $self->_file(@_);
    return $file;
};

sub request {
    my $self = shift;
    my $uri = shift;
    my $response = $agent->get($uri);

    croak "Didn't get a response for \"$uri\"\n" unless $response;
    croak "Didn't get a successful response for \"$uri\": ", $response->status_line, "\n"  unless $response->is_success;

    return $response;
}

1;
