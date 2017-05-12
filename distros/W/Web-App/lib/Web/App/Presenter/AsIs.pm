package Web::App::Presenter::AsIs;

use Class::Easy;

use base qw(Web::App::Presenter);

sub headers {
	my $app = Web::App->app;
	my $headers = $app->response->headers;
	$headers->header ('Cache-Control' => 'no-store');
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub process {
	my $self = shift;
	my $app  = shift;
	my $data = shift;
	my %params = @_;
	
	critical "can't use whole stash, please use var parameter"
		unless $params{var};
	
	if ($params{content_type}) {
		my $headers = $app->response->headers;
		$headers->header ('Content-Type' => $params{content_type});
	} else {
		critical "you must define content_type parameter for this presenter";
	}
	
	return $data->{$params{var}};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub wrap_log {
	my $self = shift;
	my $content = shift;
	
	return join '', "\n<!--\n", $content, "\n-->\n";
}


1;

