package Web::App::Presenter::JSON;
# $Id: JSON.pm,v 1.5 2009/03/29 10:08:42 apla Exp $

use Class::Easy;

use JSON;

use Web::App::Presenter;
use base qw(Web::App::Presenter);

1;

sub headers {
	my $app = Web::App->app;
	my $headers = $app->response->headers;
	$headers->header ('Content-Type' => 'text/plain; charset=utf-8');
	# $headers->header ('Content-Type' => 'application/json');
	$headers->header ('Cache-Control' => 'no-store');
	# $headers->header ('Expires' => localtime); # automatic conversion
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub process {
	my $pack   = shift;
	my $app    = shift;
	my $data   = shift;
	my %params = @_;
	
	my $json = JSON->new;
	$json->allow_blessed (1);
	$json->convert_blessed (1);
	$json->pretty (1);
	$json->space_before (0);
	$json->space_after (0);
	
	my $json_text;
	
	my $t = timer ('dumping json');
	
	if ($params{var}) {
		my @vars_to_dump = split /[^a-z0-9_]+/i, $params{var};
		
		my @vars_list = map {
			($params{'no-var-name'} ? '' : "web_app_$_ = ")
			. (ref $data->{$_} ? $json->encode ($data->{$_}) : '"'.$data->{$_}.'"')
		} grep {
			defined $data->{$_}
		} @vars_to_dump;
		
		$json_text = join "\n", @vars_list;
	} else {
		$json_text = $json->encode ($data);
	}
	
	$t->end;
	
	return $json_text;

}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub wrap_log {
	my $self = shift;
	my $content = shift;
	
	$content =~ s/\*\//***COMMENT END***/gs;
	return join '', "\n/********************\n", $content, "\n********************/\n";
}