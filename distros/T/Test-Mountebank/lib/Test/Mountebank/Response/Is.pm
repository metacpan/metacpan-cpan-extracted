package Test::Mountebank::Response::Is;

use Moose;
our $VERSION = '0.001';
use Method::Signatures;
use Test::Mountebank::Types qw( HTTPHeaders );
use JSON::Tiny qw(encode_json);
use File::Slurper qw/read_text/;
use Carp;
use MIME::Types;

has status_code    => ( is => 'ro', isa => 'Int', required => 1 );
has body           => ( is => 'rw', isa => 'Str | HashRef' );

has headers        => (
    is      => 'ro',
    isa     => HTTPHeaders,
    coerce  => 1,
    default => sub { HTTP::Headers->new() },
);

has body_from_file => (
    is         => 'ro',
    isa        => 'Str',
    trigger    => \&_read_body_from_file,
);

method _read_body_from_file($file, ...) {
    my $body = read_text($file);
    croak ("Empty response body read from file: " . $file) if length($body) < 1;
    $self->body($body);
}

# The trigger is used only to set the content type header in the HTTP::Headers
# object right after the object has been created. This is the only reason why
# the attribute exists in the first place. It supports the ability to specify
# it in a Moose-normal way when creating the object. After creation, the value
# is fetched from the HTTP::Headers object.

has content_type => (
    is         => 'ro',
    isa        => 'Str',
    trigger    => method($content_type) {
        my $mt = MIME::Types->new;
        croak ("Invalid content type: " . $content_type) if !$mt->type($content_type);
        $self->headers->content_type($content_type);
    }
);

# The content_type attribute itself is ignored when getting the content_type value.
# Instead, it is fetched from the HTTP::Headers object.

around 'content_type' => func($orig, $self) {
    return $self->headers->content_type();
};

method as_hashref() {
    my $hashref = ();
    $hashref->{body} = $self->body if $self->body;
    $hashref->{statusCode} = $self->status_code if $self->status_code;
    if ($self->headers) {
        my %headers = $self->headers->flatten;
        $hashref->{headers} = \%headers if %headers;
    }
    return { is => $hashref };
}

1;
