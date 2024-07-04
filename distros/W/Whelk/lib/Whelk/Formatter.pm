package Whelk::Formatter;
$Whelk::Formatter::VERSION = '0.02';
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

