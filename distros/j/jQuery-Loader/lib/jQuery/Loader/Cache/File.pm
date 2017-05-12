package jQuery::Loader::Cache::File;

use Moose;
extends qw/jQuery::Loader::Cache/;
use jQuery::Loader::Carp;

use File::Copy qw/copy/;
use LWP::UserAgent;

has location => qw/is ro/, handles => [qw/recalculate/];
has agent => qw/is ro required 1 lazy 1/, default => sub {
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy;
    return $agent;
};

sub BUILD {
    my $self = shift;
    my $given = shift;

    my $location = $given->{location};
    $self->{location} = do {

        croak "Wasn't given a file" unless my $file = $given->{file};

        $file = "$file/\%l" if -d $file; # TODO Moar checking, Path::Class::Dir, etc.

        jQuery::Loader::Location->new(template => $self->template, file => $file, location => $location);
    }
    unless blessed $location;
}

sub file {
    my $self = shift;

    my $file = $self->location->file(@_);

    unless (-f $file && -s $file) {
        my $source = $self->source;
        if (my $source_file = $source->file) {
            copy $source_file, $file or croak "Unable to copy $source_file, $file: $!";
        }
        elsif (my $source_uri = $source->uri) {
            my $response = $self->request($source_uri);
            $file->parent->mkpath unless -d $file->parent;
            $file->openw->print($response->content);
        }
        else {
            croak "Unable to source anything!";
        }
    }

    return $file;
}

sub request {
    my $self = shift;
    my $uri = shift;
    my $response = $self->agent->get($uri);

    croak "Didn't get a response for \"$uri\"\n" unless $response;
    croak "Didn't get a successful response for \"$uri\": ", $response->status_line, "\n"  unless $response->is_success;

    return $response;
}

1;
