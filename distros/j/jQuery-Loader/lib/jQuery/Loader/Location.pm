package jQuery::Loader::Location;

use Moose;
extends qw/jQuery::Loader::Source/;
use jQuery::Loader::Carp;

use jQuery::Loader::Template;
use Path::Class;
use URI;

has template => qw/is ro required 1 lazy 1 isa jQuery::Loader::Template/, default => sub { return jQuery::Loader::Template->new };

has location_pattern => qw/is rw/, default => "\%j";
has file_pattern => qw/is rw/;
has uri_pattern => qw/is rw/;

has location => qw/is rw/;
has file => qw/is rw/;
has uri => qw/is rw/;

sub BUILD {
    my $self = shift;
    my $given = shift;

    defined $given->{$_} and $self->{"$_\_pattern"} = $given->{$_} for qw/location file uri/;
    $self->recalculate;
}

sub recalculate {
    my $self = shift;

    my $process_location = sub { return shift };

    my ($uri, $file, $location);

    if ($self->location_pattern) {

        $location = $self->{location} = $self->template->process($self->location_pattern);

        $process_location = sub {
            my $template = shift;
            my $result = $template;
            $result =~ s/\%l/$location/g;
            $result =~ s/\%\.l/$location ? "\.$location" : ""/ge;
            $result =~ s/\%\-l/$location ? "\-$location" : ""/ge;
            $result =~ s/\%\/l/$location ? "\/$location" : ""/ge;
            return $result;
        };

    }

    if ($self->uri_pattern) {
        my $result = $self->template->process($self->uri_pattern);
        $uri = $process_location->($result);
    }
    $uri = $self->{uri} = defined $uri ? URI->new($uri) : undef;

    if ($self->file_pattern) {
        my $result = $self->template->process($self->file_pattern);
        $file = $process_location->($result);
    }
    $file = $self->{file} = defined $file ? Path::Class::File->new($file) : undef;

    return 1;
}

for my $attribute qw/location file uri/ {

    my $attribute_pattern = "$attribute\_pattern";

    around $attribute => sub {
        my $inner = shift;
        my $self = shift;

        return $self->$inner() unless @_;
        $self->$attribute_pattern(@_);
        return $self->recalculate && $self->{$attribute};
    }

}

1;

__END__

has base_uri => qw/is ro/, default => "";
has base_dir => qw/is ro/, default => "";
has uri => qw/is ro lazy_build 1/;
sub _build_uri {
    my $self = shift;
    my $uri = $self->base_uri || "";
    $uri .= $self->location;
    return URI->new($uri);
};
has file => qw/is ro lazy_build 1/;
sub _build_file {
    my $self = shift;
    my $file = $self->base_dir || "";
    return concatenate_file $file, $self->location;
};

sub concatenate_uri($$) {
    my $base = shift;
    my $location = shift;

    my $uri = $base . $location;
    return URI->new($uri);
}

sub concatenate_file($$) {
    my $base = shift;
    my $location = shift;

    return $base->file($file) if blessed $base && $base->isa("Path::Class::Dir");
    croak "Don't know how to concatenate $base and $location" if blessed $base && $base->isa("Path::Class::File");
    return Path::Class::File->new($base . $location);
}

