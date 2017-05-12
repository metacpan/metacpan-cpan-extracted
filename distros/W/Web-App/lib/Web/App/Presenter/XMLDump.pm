package Web::App::Presenter::XMLDump;
# $Id: XMLDump.pm,v 1.6 2009/06/09 08:13:38 apla Exp $

use Class::Easy;

use Web::App::Presenter;
use base qw(Web::App::Presenter);

use Data::Dump::XML;

sub headers {
	my $app = Web::App->app;
	my $headers = $app->response->headers;
	$headers->header ('Content-Type'  => 'text/xml');
	$headers->header ('Cache-Control' => 'no-store');
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub process {
	my $self = shift;
	my $app  = shift;
	my $data = shift;
	my %params = @_;
	
	if ($params{var}) {
		debug "dumping only $params{var} section";
		$data = $data->{$params{var}};
	}
	
	my $xml = Data::Dump::XML->new (%params);
	my $source = $xml->dump_xml ($data);
	
	# debug $source->toString(1);
	
	return $source->toString(1);

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