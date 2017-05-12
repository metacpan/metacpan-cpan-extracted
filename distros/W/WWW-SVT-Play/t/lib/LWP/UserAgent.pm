# Mock LWP::UA module
package LWP::UserAgent;

use warnings;
use strict;
use HTTP::Response;
use Encode;
use JSON;

# LWP interface

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub env_proxy {
	my $self = shift;
	$self->{_proxy_set} = 1;
}

sub get {
	my $self = shift;
	my $url = shift;

	if ($url =~ /[&?]output=json(?:&.*)?$/) {
		return $self->_gen_resp($url, _test_fname($url, 'json'));
	}

	return;
}

sub is_success {
	1;
}

# Mock helpers

sub _load_aliases {
	open my $fh, '<', 't/data/aliases.json' or
		die("Could not open alias file: $!");
	my $blob = do { local $/=''; <$fh> };
	close $fh;
	return decode_json($blob);
}

sub _gen_resp {
	my $self = shift;
	my $url = shift;
	my $fname = shift;

	return _gen_404($url, $fname) unless -r $fname;
	return _gen_200($url, $fname);
}

sub _gen_404 {
	return HTTP::Response->new(404, 'Not found');
}

sub _gen_200 {
	my $url = shift;
	my $fname = shift;
	my $data = _read_file($fname);

	return HTTP::Response->new(500, 'Internal server error')
		unless $data;

	return HTTP::Response->new(200, 'OK', [
		Server => 'Play! Framework;1.2.4;prod',
		'Content-Type' => 'text/html; charset=utf-8',
		'Cache-Control' => 'max-age=45',
		Date => 'Mon, 16 Jul 2012 22:08:20 GMT',
		'Content-Length' => '8479',
		Connection => 'keep-alive',
	], $data);
}

sub _video_id {
	my $uri = shift;
	my ($id) = $uri =~ m;/(?:video|klipp)/([^/]+)/;;

	# defaulting to 42: if what you supplied wasn't an
	# svtplay url you could get anything back...
	return $id // 42;
}

sub _read_file {
	my $fname = shift;
	open my $fh, '<', $fname
		or die("Could not open test data file $fname: $!");
	my $data = join '', <$fh>;
	close $fh;
	return encode('UTF-8', $data);
}

sub _test_fname {
	my $url = shift;
	my $ext = shift;
	my $vid = _video_id($url);

	my $aliases = _load_aliases();
	my $path = URI->new($url)->path;
	$vid = $aliases->{path} // _video_id($url);
	return sprintf 't/data/%s.%s', $vid, $ext;
}

1;
