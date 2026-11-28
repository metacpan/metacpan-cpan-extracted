use strict;
use warnings;
use Test::More;
use HTTP::Response;
use URI;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use WebService::Browshot;

{
	package BrowshotTestUA;
	sub new { return bless { replies => [], requests => [] }, shift; }
	sub get {
		my ($self, $url) = @_;
		push @{$self->{requests}}, { method => 'GET', url => $url };
		die $self->{exception} if ($self->{exception});
		return shift @{$self->{replies}};
	}
	sub post {
		my ($self, $url, %args) = @_;
		push @{$self->{requests}}, { method => 'POST', url => $url, %args };
		return shift @{$self->{replies}};
	}
}

my $browshot = WebService::Browshot->new(key => 'unit-test-key');
my $ua = BrowshotTestUA->new();
$browshot->{_ua} = $ua;
my $directory = tempdir(CLEANUP => 1);

is($browshot->api_version(), '2.0', 'Latest supported API version');

my %options = (
	instance_id => 373, pdf => 1, pdf_format => 'a4', pdf_background => 1,
	pdf_landscape => 0, pdf_one_page => 0, pdf_margin => '10mm',
	pdf_margin_top => '1.5cm', pdf_margin_bottom => '0', pdf_margin_left => '2px',
	pdf_margin_right => '0.5in', video => 1, video_format => 'webm',
	video_duration => 5, video_quality => 30, video_fps => 20, video_scale => 0.5,
	device_scale => 1, hide_ads => 1,
);
my ($source, $source_file) = tempfile(DIR => $directory);
print {$source} "https://example.org/\n";
close $source;

foreach my $method ('screenshot_create', 'screenshot_multiple', 'batch_create', 'crawl_create') {
	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{"id":12345,"status":"in_process"}');
	my %args = (%options, url => 'https://example.org/', domain => 'example.org');
	$args{urls} = ['https://example.org/'] if ($method eq 'screenshot_multiple');
	$args{instances} = [373] if ($method eq 'screenshot_multiple');
	$args{file} = $source_file if ($method eq 'batch_create');
	my $reply = $browshot->$method(%args);
	is($reply->{id}, 12345, "$method keeps the JSON response format");
	my %query = URI->new($ua->{requests}->[-1]->{url})->query_form;
	foreach my $option (sort keys %options) {
		is($query{$option}, $options{$option}, "$method passes $option unchanged");
	}
	is($query{key}, 'unit-test-key', "$method uses existing API key authentication");
	if ($method eq 'batch_create') {
		is($ua->{requests}->[-1]->{method}, 'POST', 'Batch uses multipart POST');
		is($ua->{requests}->[-1]->{Content_Type}, 'form-data', 'Batch preserves multipart format');
	}
}

foreach my $format ('webm', 'mp4', 'gif') {
	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{"id":12345}');
	$browshot->screenshot_create(url => 'https://example.org/', video => 1, video_format => $format);
	my %query = URI->new($ua->{requests}->[-1]->{url})->query_form;
	is($query{video_format}, $format, "Accepts $format without changing existing create code");
}

foreach my $artifact (
	['pdf', 'application/pdf', "%PDF-1.7\n\000\200\377\r\n"],
	['video', 'video/webm', "\032\105\337\243\000\200\377\r\n"],
	['video', 'video/mp4', "\000\000\000\030ftypmp42\200\377\r\n"],
	['video', 'image/gif', "GIF89a\000\200\377\r\n"],
) {
	my ($kind, $type, $bytes) = @$artifact;
	my $method = 'screenshot_' . $kind;
	my $file_method = $method . '_file';
	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => $type], $bytes);
	is($browshot->$method(id => 12345), $bytes, "$type returns exact binary bytes");
	my $uri = URI->new($ua->{requests}->[-1]->{url});
	like($uri->path, qr{/screenshot/$kind$}, "$type uses the correct endpoint");
	my %query = $uri->query_form;
	is($query{id}, 12345, "$type forwards the local screenshot ID");
	is($query{key}, 'unit-test-key', "$type preserves authentication");

	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => "$type; charset=UTF-8"], $bytes);
	is($browshot->$method(id => 12345), $bytes, "$type ignores character encoding on binary files");
	my $file = File::Spec->catfile($directory, $kind, $type =~ m{/([^/]+)$} ? $1 : 'file', 'capture.bin');
	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => $type], $bytes);
	is($browshot->$file_method(id => 12345, file => $file), $file, "$type creates parent directories and returns the file name");
	open my $saved, '<', $file or die "Cannot read test file: $!";
	binmode $saved;
	local $/;
	is(<$saved>, $bytes, "$type file preserves all binary bytes");
	close $saved;
	my %file_query = URI->new($ua->{requests}->[-1]->{url})->query_form;
	ok(! exists $file_query{file}, "$type does not send the local filename to the API");
}

foreach my $kind ('pdf', 'video') {
	my $method = 'screenshot_' . $kind;
	my $file_method = $method . '_file';
	my $type = $kind eq 'pdf' ? 'application/pdf' : 'video/webm';
	my $requests = scalar @{$ua->{requests}};
	is($browshot->$method(), '', "$method requires an ID");
	like($browshot->{last_error}, qr/Missing id/, "$method records missing ID errors");
	is($browshot->$file_method(id => 12345), '', "$file_method requires a filename");
	is($browshot->$file_method(id => 12345, file => $directory), '', "$file_method rejects a directory");
	is(scalar @{$ua->{requests}}, $requests, "$method does not request invalid local arguments");

	foreach my $status (400, 401, 404, 503) {
		my $file = File::Spec->catfile($directory, "$kind-$status.bin");
		push @{$ua->{replies}}, HTTP::Response->new($status, 'Error', ['Content-Type' => 'application/json'], '{"error":"NOT_FOUND"}');
		is($browshot->$file_method(id => 12345, file => $file), '', "$file_method rejects HTTP $status");
		ok(! -e $file, "$file_method does not save HTTP $status errors");
		like($browshot->{last_error}, qr/$status/, "$method records HTTP $status");
	}
	foreach my $bad_type ('application/json', 'text/html', 'image/png', 'video/mp4evil') {
		push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => $bad_type], 'not-an-artifact');
		is($browshot->$method(id => 12345), '', "$method rejects $bad_type");
		like($browshot->{last_error}, qr/Unexpected content type/, "$method records the invalid content type");
	}
	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => $type], '');
	is($browshot->$method(id => 12345), '', "$method rejects empty downloads");
	like($browshot->{last_error}, qr/No file retrieved/, "$method records an empty download");
	$ua->{exception} = 'transport failure containing unit-test-key';
	is($browshot->$method(id => 12345), '', "$method handles transport exceptions");
	unlike($browshot->{last_error}, qr/unit-test-key/, "$method does not expose credentials in transport errors");
	delete $ua->{exception};

	push @{$ua->{replies}}, HTTP::Response->new(200, 'OK', ['Content-Type' => $type], 'binary');
	my $bad_file = File::Spec->catfile($source_file, 'capture.bin');
	is($browshot->$file_method(id => 12345, file => $bad_file), '', "$file_method handles directory creation errors");
	like($browshot->{last_error}, qr/Cannot create directory/, "$file_method records the filesystem error");
}

is(scalar @{$ua->{replies}}, 0, 'All fixture responses consumed');
done_testing;
