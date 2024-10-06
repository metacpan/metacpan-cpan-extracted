package Whelk::Formatter;
$Whelk::Formatter::VERSION = '1.01';
use Kelp::Base;
use Carp;
use Whelk::Exception;

attr response_format => sub { ... };
attr full_response_format => sub { $_[0]->supported_format($_[0]->response_format) };
attr supported_formats => sub { {} };

sub load_formats
{
	my ($self, $app) = @_;
	my $app_encoders = $app->encoder_modules;

	my %supported = (
		json => 'application/json',
		yaml => 'text/yaml',
	);

	foreach my $encoder (keys %supported) {
		delete $supported{$encoder}
			if !exists $app_encoders->{$encoder};
	}

	$self->supported_formats(\%supported);
	return $self;
}

sub supported_format
{
	my ($self, $format) = @_;
	my $formats = $self->supported_formats;

	croak "Format $format is not supported"
		unless exists $formats->{$format};

	return $formats->{$format};
}

sub match_format
{
	my ($self, $app) = @_;
	my $formats = $self->supported_formats;

	foreach my $format (keys %$formats) {
		return $format
			if $app->req->content_type_is($formats->{$format});
	}

	Whelk::Exception->throw(400, hint => "Unsupported Content-Type");
}

sub get_request_body
{
	my ($self, $app) = @_;
	my $format = $self->match_format($app);

	return
		$format eq 'json' ? $app->req->json_content :
		$format eq 'yaml' ? $app->req->yaml_content :
		undef;
}

sub format_response
{
	my ($self, $app, $data, $special_encoder) = @_;
	my $res = $app->res;
	my $ct = $res->content_type;

	# ensure proper content-type
	$res->set_content_type($self->full_response_format, $res->charset // $app->charset)
		if !$ct;

	# only encode manually if we have a special encoder requested
	return $app->get_encoder($self->response_format => $special_encoder)->encode($data)
		if $special_encoder && ref $data && (!$ct || $ct eq $self->full_response_format);

	# otherwise, let Kelp try to handle this
	return $data;
}

sub new
{
	my ($class, %args) = @_;

	my $app = delete $args{app};
	croak 'app is required in new'
		if !$app;

	my $self = $class->SUPER::new(%args);
	$self->load_formats($app);

	return $self;
}

1;

__END__

=pod

=head1 NAME

Whelk::Formatter - Base class for formatters

=head1 SYNOPSIS

	package Whelk::Formatter::MyFormatter;

	use Kelp::Base 'Whelk::Formatter';

	# at the very least, this attribute must be given a default
	attr response_format => 'json';

=head1 DESCRIPTION

Whelk::Formatter is a base class for formatters. Formatter's job is to
implement logic necessary decode content from requests and encode content for
responses. Whelk assumes that while a range of content types can be supported
from the request, endpoints will always have just one response format, for
example C<JSON>.

Whelk implements two basic formatters which can be used out of the box:
L<Whelk::Formatter::JSON> (the default) and L<Whelk::Formatter::YAML>. All they
do is have different L</response_format> values.

The base implementation uses Kelp modules L<Kelp::Module::JSON> and
L<Kelp::Module::YAML> to get the encoders for each of those formats. If one of
these modules is not loaded, the application will not support that format.

=head1 ATTRIBUTES

This class defines a couple attributes, which generally are loaded once and
then reused as long as the app is running.

=head2 response_format

A response format in short form, for example C<'json'>.

=head2 full_response_format

A full response format in content type form, for example C<application/json>.
It will be loaded from L</response_format> using L</supported_format> method.

=head2 supported_formats

A cache of all formats supported by this formatter. It is created by a call to
L</load_formats>.

It is in form of a hash reference, where keys are short format names like
C<json> and values are full format content types like C<application/json>.

=head1 METHODS

=head2 load_formats

	$formatter->load_formats($app);

Called by the constructor to load formats into L</supported_formats>. Uses the
application instance to see if the formats are actually supported by Kelp.

=head2 supported_format

	my $full_format = $formatter->supported_format($short_format);

Checks if the format is supported by the formatter according to
L</supported_formats> and returns the long form of the format. If it is not
supported then an exception is raised.

=head2 match_format

	my $short_format = $formatter->match_format($app);

Tries to match the application's current request's content type and returns one
of the formats in the short form if request content type is supported. Throws
L<Whelk::Exception> with code 400 if request's content type is unsupported.

=head2 get_request_body

	my $decoded = $formatter->get_request_body($app);

Tries to decode the request body and returns a perl structure containing
decoded data. May return undef if the request data isn't well formed. Uses
L</match_format> to decide the format, so may also throw an exception.

=head2 format_response

	my $maybe_encoded = $formatter->format_response($app, $data, $special_encoder = undef);

Encodes C<$data> to L</response_format> and sets the proper content type on the
response (unless it was set manually). Will only do the actual encoding if
C<$special_encoder> was specified (a name of the encoder to use, see
L<Kelp/get_encoder>. Otherwise, will return the structure unchanged to let Kelp
handle it internally.

