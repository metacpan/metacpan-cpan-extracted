package WebService::Browshot;

use 5.006006;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use URI;
use URI::Encode qw(uri_encode);
use File::Basename;
use File::Path qw(make_path);

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
use IO::Socket::SSL;
IO::Socket::SSL::set_ctx_defaults( 
     SSL_verifycn_scheme => 'www', 
     SSL_verify_mode => 0,
     verify_mode => 0,
);

our $VERSION = '2.0.0';

=head1 NAME

WebService::Browshot - Perl extension for Browshot (L<https://browshot.com/>), a web service to create screenshots of web pages.

=head1 SYNOPSIS

  use WebService::Browshot;

  my $browshot = WebService::Browshot->new(key => 'my_key');
  my $screenshot = $browshot->screenshot_create(url => 'http://www.google.com/');
  [...]
  $browshot->screenshot_thumbnail_file(id => $screenshot->{id}, file => 'google.png');

=head1 DESCRIPTION

Browshot (L<http://www.browshot.com/>) is a web service to easily make screenshots of web pages in any screen size, as any device: iPhone, iPad, Android, Nook, PC, etc. Browshot supports JavaScript, CSS, and HTML5.

The latest API version is detailed at L<http://browshot.com/api/documentation>. WebService::Browshot follows the API documentation very closely: the function names are similar to the URLs used (screenshot/create becomes C<screenshot_create()>, instance/list becomes C<instance_list()>, etc.), the request arguments are exactly the same, etc.

The library supports Browshot API v1 and v2. Calls with legacy instance,
screen, details, hook, or hosting arguments use v1. Instance lookup and
C<screenshot_host()> also use v1. Other calls prefer v2 where supported.
V2 captures accept C<browser>, C<country>, C<screen_width>, C<screen_height>,
C<mobile>, or a named C<device>. C<instance_id> is optional.

Pass C<api_version =E<gt> 1> or C<api_version =E<gt> 2> to select the response
format for a call. This option is consumed by the library. An explicit C<base>
pins the version for calls without an override. In automatic mode, a request
supported by both versions can use v1 if the server reports that the v2 route
is unavailable.

The source code is available on github at L<https://github.com/juliensobrier/browshot-perl>.


=head1 METHODS

=head2 new()

  my $browshot = WebService::Browshot->new(key => 'my_key', debug => 1);

Create a new WebService::Browshot object. You must pass your API key (go to you Dashboard to find your API key).

Arguments:

=over 4

=item key

Required.  API key.

=item base

Optional. Pin all requests to a specific base URL, for example
C<https://api.browshot.com/api/v1/> for the v1 response format. By default the
library selects a version for each request. Use HTTPS to protect your API key.

=item debug

Optional. Set to 1 to print debug output to the standard output. 0 (disabled) by default.

=item timeout

Optional. Set the request timeout - in seconds - against the API. Defaults to 90s.

=back

C<last_error> contains the last error message, it is NEVER reset, i.e last_error may not be empty after a successful API call if an earlier call failed.

=cut

sub new {
  	my ($self, %args) = @_;

	my $ua = LWP::UserAgent->new();
	$ua->timeout($args{'timeout'} || 90);
	$ua->env_proxy;
	$ua->max_redirect(32); # for the simple API only
	$ua->agent("WebService::Browshot $VERSION");
	$ua->ssl_opts( verify_hostnames => 0 );

  	my $browshot = {	
		_key	=> $args{key}	|| '',
		_base	=> $args{base}	|| 'https://api.browshot.com/api/v2/',
		_auto_api => ! $args{base},
		_debug	=> $args{debug}	|| 0,

		_retry	=> 2,
		last_error	=> '',

		_ua		=> $ua,
	};

  return bless($browshot, $self);
}


=head2 api_version()

Return the newest API version supported by the library. This is independent of the version selected for a particular request.

=cut

sub api_version {
	my ($self, %args) = @_;

	if ($VERSION =~ /^(\d+\.\d+)\.\d/) {
		return $1;
	}

	return $VERSION;
}



=head2 simple()

   $browshot->simple(url => 'http://mobilito.net')

Retrieve a screenshot in one function. Note: by default, screenshots are cached for 24 hours. You can tune this value with the cache=X parameter.

Return an array (status code, PNG). See L<http://browshot.com/api/documentation#simple> for the list of possible status codes.

Arguments:

See L<http://browshot.com/api/documentation#simple> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=back

=cut

sub simple {
	my ($self, %args) = @_;

	my $res = $self->_request('get', action => 'simple', parameters => { %args });

	# $self->info($res->message);
	# $self->info($res->request->as_string);
	# $self->info($res->as_string);
	
	return ($res->code, $res->decoded_content);
}

=head2 simple_file()

   $browshot->simple_file(url => 'http://mobilito.net', file => '/tmp/mobilito.png')

Retrieve a screenshot and save it locally in one function. Note: by default, screenshots are cached for 24 hours. You can tune this value with the cache=X parameter.

Return an array (status code, file name). The file name is empty if the screenshot was not retrieved. See L<http://browshot.com/api/documentation#simple> for the list of possible status codes.

Arguments:

See L<http://browshot.com/api/documentation#simple> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=item file

Required. Local file name to write to.

=back

=cut

sub simple_file {
	my ($self, %args) 	= @_;
	my $file		= $args{file}	|| $self->error("Missing file in simple_file");
	
	if (-d $file) {
		$self->error("You must specify a file path, not a folder, to save the screenshot");
		return (400, '');
	}

	my $res = $self->_request('get', action => 'simple', parameters => { %args });

	my $content = $res->decoded_content;

	if ($content ne '') {
		open TARGET, "> $file" or $self->error("Cannot open $file for writing: $!");
		binmode TARGET;
		print TARGET $content;
		close TARGET;

		return ($res->code, $file);
	}
	else {
		$self->error("No thumbnail retrieved");
		return ($res->code, '');
	}
}

=head2 instance_list()

Return the list of instances as a hash reference. See L<http://browshot.com/api/documentation#instance_list> for the response format.

=cut

sub instance_list {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'instance/list', parameters => { %args });
}

=head2 instance_info()

   $browshot->instance_info(id => 2)

Return the details of an instance. See L<http://browshot.com/api/documentation#instance_info> for the response format.

Arguments:

=over 4

=item id

Required. Instance ID

=back

=cut

sub instance_info  {
	my ($self, %args) 	= @_;
	my $id							= $args{id}	|| $self->error("Missing id in instance_info");

	return $self->return_reply(action => 'instance/info', parameters => { %args, id => $id });
}

=head2 browser_list()

Return the list of browsers as a hash reference. See L<http://browshot.com/api/documentation#browser_list> for the response format.

=cut

sub browser_list {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'browser/list', parameters => { %args });
}

=head2 browser_info()

   $browshot->browser_info(id => 2)

Return the details of a browser. See L<http://browshot.com/api/documentation#browser_info> for the response format.

Arguments:

=over 4

=item id

Browser ID. Alternatively pass C<browser =E<gt> 'chrome'> or C<'firefox'> to use the v2 browser catalog.

=back

=cut

sub browser_info  {
	my ($self, %args) 	= @_;
	$self->error("Missing id or browser in browser_info") if (! defined $args{id} && ! defined $args{browser});
	return $self->return_reply(action => 'browser/info', parameters => { %args });
}


=head2 screenshot_create()

  $browshot->screenshot_create(url => 'http://wwww.google.com/', instance_id => 3, size => 'page')

Request a screenshot. See L<http://browshot.com/api/documentation#screenshot_create> for the response format.
Note: by default, screenshots are cached for 24 hours. You can tune this value with the cache=X parameter.

API 1.32 capture options are accepted as named arguments without conversion:
C<pdf>, C<pdf_format>, C<pdf_background>, C<pdf_landscape>, C<pdf_one_page>,
C<pdf_margin>, C<pdf_margin_top>, C<pdf_margin_bottom>, C<pdf_margin_left>,
C<pdf_margin_right>, C<video>, C<video_format>, C<video_duration>,
C<video_quality>, C<video_fps>, C<video_scale>, C<device_scale>, and C<hide_ads>.
These options also work with C<screenshot_multiple()>, C<batch_create()>, and
C<crawl_create()>.

Use C<pdf =E<gt> 1> to generate a PDF (1 additional credit), or
C<video =E<gt> 1> to record WebM, MP4, or animated GIF with
C<video_format =E<gt> 'webm'>, C<'mp4'>, or C<'gif'>. WebM is the default.
C<video_duration> is 1-30 seconds (default 15); video adds 1 credit per started
5 seconds of requested duration, for every format. PDF and video require
Chrome. With v1, use a paid Chrome instance. Wait for C<status> to be
C<finished> before downloading.

C<device_scale =E<gt> 2> or C<3> enables retina screenshots and
C<hide_ads =E<gt> 1> enables ad blocking without an additional charge. Video
requires 1x resolution. Use C<country> for direct v2 captures, or select a
country-specific C<instance_id> from C<instance_list()> for v1.

  my $screenshot = $browshot->screenshot_create(
    url => 'https://example.org/', browser => 'chrome', country => 'fr',
    pdf => 1, pdf_format => 'a4', device_scale => 2, hide_ads => 1,
  );

See L<https://browshot.com/api/documentation> for option defaults and limits.

Arguments:

See L<http://browshot.com/api/documentation#screenshot_create> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=item instance_id

Optional. Instance ID to use for the screenshot.

=item size

Optional. Screenshot size.

=back

=cut

sub screenshot_create {
	my ($self, %args) 	= @_;
	# my $url				= $args{url}			|| $self->error("Missing url in screenshot_create");
	# my $instance_id		= $args{instance_id};
	# my $screen			= $args{screen};
	# my $size			= $args{size}			|| "screen";
	# my $cache			= $args{cache};
	# my $priority		= $args{priority};

	$self->error("Missing url in screenshot_create") 	if (! defined($args{url}));
# 	$args{size} = "screen" 					if (! defined($args{size}));

	return $self->return_reply(action => 'screenshot/create', parameters => { %args });
}

=head2 screenshot_info()

  $browshot->screenshot_info(id => 568978)

Get information about an existing screenshot. By default this uses v2 for
IDs created by either API version. Pass C<api_version =E<gt> 1> if you need
legacy response fields such as C<instance_id>.

  $browshot->screenshot_info(id => 568978, api_version => 1)

Arguments:

=over 4

=item id

Required. Screenshot ID.

=back

=cut

sub screenshot_info {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in screenshot_info");


	return $self->return_reply(action => 'screenshot/info', parameters => { %args });
}

=head2 screenshot_list()

  $browshot->screenshot_list(limit => 50)

Get details about screenshots requested. See L<http://browshot.com/api/documentation#screenshot_list> for the response format.

Arguments:

=over 4

=item limit

Optional. Maximum number of screenshots to retrieve.

=back

=cut

sub screenshot_list {
	my ($self, %args) 	= @_;

	return $self->return_reply(action => 'screenshot/list', parameters => { %args });
}

=head2 screenshot_search()

  $browshot->screenshot_search(url => 'google.com')

Get details about screenshots requested. See L<http://browshot.com/api/documentation#screenshot_search> for the response format.

Arguments:

=over 4

=item url

Required. URL string to look for.

=back

=cut

sub screenshot_search {
	my ($self, %args) 	= @_;
	my $url			= $args{url}	|| $self->error("Missing url in screenshot_search");

	return $self->return_reply(action => 'screenshot/search', parameters => { %args });
}

=head2 screenshot_host()

  $browshot->screenshot_host(id => 12345, hosting => 'browshot')

Host a screenshot or thumbnail. See L<http://browshot.com/api/documentation#screenshot_host> for the response format.

Arguments:

=over 4

=item id

Required. Screenshot ID.

=back

=cut

sub screenshot_host {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in screenshot_host");

	return $self->return_reply(action => 'screenshot/host', parameters => { %args });
}


=head2 screenshot_thumbnail()

  $browshot->screenshot_thumbnail(id => 52942, width => 500)

Retrieve the screenshot, or a thumbnail. See L<http://browshot.com/api/documentation#screenshot_thumbnail> for the response format.

Return an empty string if the image could not be retrieved.

Arguments:

See L<http://browshot.com/api/documentation#screenshot_thumbnail> for the full list of possible arguments.

=over 4

=item id

Required. Screenshot ID.

=item width

Optional. Maximum width of the thumbnail.

=item height

Optional. Maximum height of the thumbnail.

=back

=cut
sub screenshot_thumbnail {
	my ($self, %args) 	= @_;

	if (! exists $args{id} && defined $args{url}) {
		my $uri = URI->new($args{url});
		my $path = $uri->path || '';
		my ($path_id) = $path =~ m{/image/(\d+)/?$}i;
		if (defined($path_id) || $path =~ m{/screenshot/thumbnail/?$}i) {
			my %query = $uri->query_form;
			$args{id} = defined($path_id) ? $path_id : $query{id};
			foreach my $name (qw(width height scale zoom ratio format quality shot left right top bottom)) {
				$args{$name} = $query{$name} if (! exists $args{$name} && exists $query{$name});
			}
		}
	}
	if (! defined $args{id}) {
		$self->error("Missing id and url in screenshot_thumbnail");
		return '';
	}
	delete $args{url};
	my $res = $self->_request('get', action => 'screenshot/thumbnail', parameters => { %args });

	if ($res->is_success) {
		return $res->decoded_content; # raw image file content
	}
	else {
		$self->error("Error in thumbnail request: " . $res->as_string);
		return '';
	}
}


=head2 screenshot_thumbnail_file()

  $browshot->screenshot_thumbnail_file(id => 123456, height => 500, file => '/tmp/google.png')

Retrieve the screenshot, or a thumbnail, and save it to a file. See L<http://browshot.com/api/documentation#thumbnails> for the response format.

Return an empty string if the image could not be retrieved or not saved. Returns the file name if successful.

Arguments:

See L<http://browshot.com/api/documentation#thumbnails> for the full list of possible arguments.

=over 4

=item url

 Required. URL of the screenshot (screenshot_url value retrieved from C<screenshot_create()> or C<screenshot_info()>). You will get the full image if no other argument is specified.

=item file

Required. Local file name to write to.

=item width

Optional. Maximum width of the thumbnail.

=item height

Optional. Maximum height of the thumbnail.

=back

=cut
sub screenshot_thumbnail_file {
	my ($self, %args) 	= @_;
	my $file		= $args{file}	|| $self->error("Missing file in screenshot_thumbnail_file");

	delete($args{file});
	my $content = $self->screenshot_thumbnail(%args);

	my $dir = dirname($file);
	if (! -d $dir) {
		make_path($dir)
	}

	if ($content ne '') {
		open TARGET, "> $file" or $self->error("Cannot open $file for writing: $!");
		binmode TARGET;
		print TARGET $content;
		close TARGET;

		return $file;
	}
	else {
		$self->error("No thumbnail retrieved");
		return '';
	}
}

=head2 screenshot_share()

  $browshot->screenshot_share(id => 12345, note => 'This is my screenshot')

Share a screenshot. See L<http://browshot.com/api/documentation#screenshot_share> for the response format.

Arguments:

=over 4

=item id

Required. Screenshot ID.

=item note

Optional. Public note to add to the screenshot.

=back

=cut

sub screenshot_share {
	my ($self, %args) 	= @_;
	my $id				= $args{id}	|| $self->error("Missing id in screenshot_share");

	return $self->return_reply(action => 'screenshot/share', parameters => { %args });
}


=head2 screenshot_delete()

  $browshot->screenshot_delete(id => 12345, data => 'url,metadata')

Delete details of a screenshot. See L<http://browshot.com/api/documentation#screenshot_delete> for the response format.

Arguments:

=over 4

=item id

Required. Screenshot ID.

=item data

Optional. Information to delete.

=back

=cut

sub screenshot_delete {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in screenshot_delete");

	return $self->return_reply(action => 'screenshot/delete', parameters => { %args });
}

=head2 screenshot_html()

  $browshot->screenshot_html(id => 12345)

Get the HTML code of the rendered page. See L<http://browshot.com/api/documentation#screenshot_html> for the response format.

Arguments:

=over 4

=item id

Required. Screenshot ID.

=back

=cut

sub screenshot_html {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in screenshot_html");

	return $self->return_string(action => 'screenshot/html', parameters => { %args });
}

=head2 screenshot_pdf()

  my $pdf = $browshot->screenshot_pdf(id => 12345);

Retrieve the PDF generated with C<pdf =E<gt> 1>.
Wait until C<screenshot_info()> reports C<status =E<gt> 'finished'>.
Returns the raw file bytes, or an empty string on failure with C<last_error>
set. Downloading does not cost additional credits.
See L<https://browshot.com/api/documentation#screenshot_pdf>.

Arguments:

=over 4

=item id

Required. Screenshot ID belonging to your account.

=back

=cut

sub screenshot_pdf {
	my ($self, %args) 	= @_;
	return $self->error("Missing id in screenshot_pdf") if (! defined($args{id}) || $args{id} eq '');

	return $self->return_binary(action => 'screenshot/pdf', parameters => { %args }, content_type => qr{^application/pdf(?:\s*;|\s*$)}i);
}

=head2 screenshot_pdf_file()

  $browshot->screenshot_pdf_file(id => 12345, file => '/tmp/capture.pdf');

Retrieve the PDF and save it in binary mode. Missing parent
directories are created as with C<screenshot_thumbnail_file()>.
Returns the file name on success, or an empty string on failure with
C<last_error> set. Failed API responses are not saved as files.

Arguments:

=over 4

=item id

Required. Screenshot ID belonging to your account.

=item file

Required. Local file name to write to. Use the extension for the recorded format.

=back

=cut

sub screenshot_pdf_file {
	my ($self, %args) 	= @_;

	return $self->save_binary(method => 'screenshot_pdf', parameters => { %args });
}

=head2 screenshot_video()

  my $video = $browshot->screenshot_video(id => 12345);

Retrieve the WebM or MP4 video, or animated GIF generated with C<video =E<gt> 1>.
Wait until C<screenshot_info()> reports C<status =E<gt> 'finished'>.
Returns the raw file bytes, or an empty string on failure with C<last_error>
set. Downloading does not cost additional credits.
See L<https://browshot.com/api/documentation#screenshot_video>.

Arguments:

=over 4

=item id

Required. Screenshot ID belonging to your account.

=back

=cut

sub screenshot_video {
	my ($self, %args) 	= @_;
	return $self->error("Missing id in screenshot_video") if (! defined($args{id}) || $args{id} eq '');

	return $self->return_binary(action => 'screenshot/video', parameters => { %args }, content_type => qr{^(?:video/(?:webm|mp4)|image/gif)(?:\s*;|\s*$)}i);
}

=head2 screenshot_video_file()

  $browshot->screenshot_video_file(id => 12345, file => '/tmp/capture.webm');

Retrieve the WebM or MP4 video, or animated GIF and save it in binary mode. Missing parent
directories are created as with C<screenshot_thumbnail_file()>.
Returns the file name on success, or an empty string on failure with
C<last_error> set. Failed API responses are not saved as files.

Arguments:

=over 4

=item id

Required. Screenshot ID belonging to your account.

=item file

Required. Local file name to write to. Use the extension for the recorded format.

=back

=cut

sub screenshot_video_file {
	my ($self, %args) 	= @_;

	return $self->save_binary(method => 'screenshot_video', parameters => { %args });
}

=head2 screenshot_multiple()

  $browshot->screenshot_multiple(urls => ['http://mobilito.net/'], instances => [22, 30])

Request multiple screenshots. See L<http://browshot.com/api/documentation#screenshot_multiple> for the response format.

Arguments:

=over 4

=item urls

Required. One or more URLs.

=item instances

Optional. One or more instance IDs for a v1 request. For v2, use the direct
capture options or pass C<profiles> as an array of capture settings. The
reply is keyed by screenshot ID.

=back

=cut

sub screenshot_multiple {
	my ($self, %args) 	= @_;
# 	my $urls		= $args{urls}		|| $self->error("Missing urls in screenshot_multiple");
# 	my $instances		= $args{instances}	|| $self->error("Missing instances in screenshot_multiple");

	return $self->return_reply(action => 'screenshot/multiple', parameters => { %args });
}


=head2 batch_create()

  $browshot->batch_create(file => '/my/file/urls.txt', instance_id => 65)

Request multiple screenshots from a text file. See L<http://browshot.com/api/documentation#batch_create> for the response format.

Arguments:

=over 4

=item file

Required. Path to the text file which contains the list of URLs.

=item instance_id

Optional. Instance ID to use for all screenshots in a v1 request.

=back

=cut

sub batch_create {
	my ($self, %args) 	= @_;
	my $file		= $args{file}		|| $self->error("Missing file in batch_create");

	delete $args{file};
	return $self->return_post_reply(action => 'batch/create', parameters => { %args }, file => $file);
}

=head2 batch_info()

  $browshot->batch_info(id => 5)

Get information about a screenshot batch requested previously. See L<http://browshot.com/api/documentation#batch_info> for the response format.

Arguments:

=over 4

=item id

Required. Batch ID.

=back

=cut

sub batch_info {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in batch_info");

	return $self->return_reply(action => 'batch/info', parameters => { %args });
}


=head2 crawl_create()

  $browshot->crawl_create(domain => 'blitapp.com', url => 'https://blitapp.com/', max => 50, instance_id => 65)

Crawl a domain and screenshot all pages. See L<http://browshot.com/api/documentation#crawl_create> for the response format.

Arguments:

=over 4

=item domain

Required. Domain to crawl.

=item url

Optional. URL to start with. The server defaults to the domain root.

=item instance_id

Optional. Instance ID to use for all screenshots in a v1 request.

=back

=cut

sub crawl_create {
	my ($self, %args) = @_;
	my $domain				= $args{domain}			|| $self->error("Missing domain in crawl_create");

	return $self->return_reply(action => 'crawl/create', parameters => { %args });
}

=head2 crawl__info()

  $browshot->crawl__info(id => 5)

Get information about a crawl_ requested previously. See L<http://browshot.com/api/documentation#crawl__info> for the response format.

Arguments:

=over 4

=item id

Required. Crawl ID.

=back

=cut

sub crawl_info {
	my ($self, %args) 	= @_;
	my $id			= $args{id}	|| $self->error("Missing id in crawl_info");

	return $self->return_reply(action => 'crawl/info', parameters => { %args });
}

=head2 account_info()

Return information about the user account. See L<http://browshot.com/api/documentation#account_info> for the response format.

=cut

sub account_info {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'account/info', parameters => { %args });
}


=head2 device_list()

Return the named device catalog for v2 captures.

=cut

sub device_list {
	my ($self, %args) = @_;
	return $self->return_reply(action => 'device/list', parameters => { %args });
}

=head2 app_list(), app_info()

List account apps, or get one app by ID.

  my $apps = $browshot->app_list();
  my $app = $browshot->app_info(id => 42);

=cut

sub app_list {
	my ($self, %args) = @_;
	return $self->return_reply(action => 'app/list', parameters => { %args });
}

sub app_info {
	my ($self, %args) = @_;
	return $self->return_reply(action => 'app/info', parameters => { %args });
}

=head2 app_create(), app_update(), app_delete(), app_test(), app_run()

Manage and run v2 webhook and S3 apps. Pass C<config> as a hash reference and
C<apps> to C<app_run()> as an array of app slugs or configuration IDs.

  my $app = $browshot->app_create(
    type => 'webhook', app_id => 'notify', name => 'Notifications',
    config => { url => 'https://example.org/events' },
  );
  $browshot->app_test(id => $app->{id});
  $browshot->app_run(screenshot_id => 12345, apps => ['notify']);

For a new capture, pass C<apps =E<gt> ['notify', 'archive']>. To override S3
filenames, pass a hash reference such as
C<apps =E<gt> { archive =E<gt> 'captures/{id}.png' }>.

=cut

sub app_create { return shift->_app_post('app/create', @_); }
sub app_update { return shift->_app_post('app/update', @_); }
sub app_delete { return shift->_app_post('app/delete', @_); }
sub app_test { return shift->_app_post('app/test', @_); }
sub app_run { return shift->_app_post('app/run', @_); }

# Private methods

sub return_binary {
	my ($self, %args) 	= @_;
	my $res;
	eval { $res = $self->_request('get', %args); };
	return $self->error("Cannot retrieve $args{action}") if ($@ || ! defined($res));
	return $self->error("Server sent back an error: " . $res->code) if (! $res->is_success);
	return $self->error("Unexpected content type in $args{action}") if (($res->header('Content-Type') || '') !~ $args{content_type});

	my $content;
	eval { $content = $res->decoded_content(charset => 'none'); };
	return $self->error("No file retrieved from $args{action}") if ($@ || ! defined($content) || $content eq '');
	return $content;
}

sub save_binary {
	my ($self, %args) 	= @_;
	my %parameters	= %{$args{parameters}};
	my $method	= $args{method};
	my $file	= delete $parameters{file};
	return $self->error("Missing file in ${method}_file") if (! defined($file) || $file eq '');
	return $self->error("You must specify a file path, not a folder, to save the file") if (-d $file);

	my $content = $self->$method(%parameters);
	return '' if ($content eq '');
	my $dir = dirname($file);
	eval { make_path($dir) if (! -d $dir); };
	return $self->error("Cannot create directory $dir") if ($@);
	open my $target, '>', $file or return $self->error("Cannot open $file for writing: $!");
	binmode $target;
	my $written = print {$target} $content;
	my $closed = close $target;
	return $self->error("Cannot write $file: $!") if (! $written || ! $closed);
	return $file;
}

sub return_string {
	my ($self, %args) 	= @_;

	my $res;
	my $try = 0;

	do {
		$self->info("Try $try");
		eval {
			$res = $self->_request('get', %args);
		};
		$self->error($@) if ($@);
		$try++;
	}
	until($try < $self->{_retry} && defined $@);
	return $self->error("Cannot retrieve $args{action}") if (! defined $res);

	if (! $res->is_success) {
		$self->error("Server sent back an error: " . $res->code);
	}
  
	return $args{json_response} ? $res->decoded_content(charset => 'none') : $res->decoded_content;
}

sub return_post_string {
	my ($self, %args) 	= @_;
	my @body = exists $args{json}
		? (Content_Type => 'application/json', Content => encode_json($args{json}))
		: (Content_Type => 'form-data', Content => [file => [$args{file} || '']]);
	my $res = eval { $self->_request('post', %args, body => \@body); };
	return $self->error("Cannot retrieve $args{action}") if ($@ || ! defined $res);

	if (! $res->is_success) {
		$self->error("Server sent back an error: " . $res->code);
		if (! exists $args{json}) {
			$self->info($res->request->as_string) if ($res->request);
			$self->info($res->as_string);
		}
	}
  
	return $res->decoded_content(charset => 'none');
}

sub return_reply {
	my ($self, %args) 	= @_;

	my $content = $self->return_string(%args, json_response => 1);

	my $info;
	eval {
		$info = decode_json($content);
	};
	if ($@) {
		$self->error("Invalid server response: " . $@);
		return $self->generic_error($@);
	}

	return $info;
}

sub return_post_reply {
	my ($self, %args) 	= @_;

	my $content = $self->return_post_string(%args);

	my $info;
	eval {
		$info = decode_json($content);
	};
	if ($@) {
		$self->error("Invalid server response: " . $@);
		return $self->generic_error($@);
	}

	return $info;
}

sub _app_post {
	my ($self, $action, %body) = @_;
	my %parameters;
	$parameters{api_version} = delete $body{api_version} if (exists $body{api_version});
	foreach my $field (qw(id screenshot_id)) {
		$body{$field} = 0 + $body{$field} if (defined $body{$field} && $body{$field} =~ /^\d+$/);
	}
	if (defined $body{isActive} && ! ref($body{isActive}) && $body{isActive} =~ /^[01]$/) {
		$body{isActive} = $body{isActive} ? JSON::true : JSON::false;
	}
	if (ref($body{apps}) eq 'ARRAY') {
		$body{apps} = [map { "$_" } @{$body{apps}}];
	}
	return $self->return_post_reply(action => $action, parameters => \%parameters, json => \%body);
}

sub _version_for {
	my ($self, $action, $parameters) = @_;
	return $parameters->{api_version} if (defined $parameters->{api_version} && $parameters->{api_version} =~ /^[12]$/);
	return undef if (! $self->{_auto_api});
	return 1 if ($action =~ m{^(?:instance/|screenshot/host$)});
	return 1 if grep {
		defined $parameters->{$_} && /^(?:
			instance_id|instance_ids|instances|screen|details|ids|hook|hook_.+|
			hosting|hosting_.+|device_name|device_touch|device_mobile|device_landscape|user_agent
		)$/x && (ref($parameters->{$_}) ne 'ARRAY' || @{$parameters->{$_}})
	} keys %$parameters;
	if ($action eq 'browser/info' && defined $parameters->{id}) {
		return 1 if ($parameters->{id} !~ /^(?:40|42)$/);
	}
	return 2;
}

sub _request {
	my ($self, $method, %args) = @_;
	my $parameters = $args{parameters} || {};
	my $action = $args{action};
	my $version = $self->_version_for($action, $parameters);
	my @body = @{$args{body} || []};
	my $response = $self->{_ua}->$method($self->make_url(%args), @body);
	if ($self->{_auto_api} && ! defined $parameters->{api_version} && $version == 2 &&
	    $action !~ m{^(?:app/|device/)} &&
	    ! grep { defined $parameters->{$_} && /^(?:browser|country|mobile|device|profiles|apps(?:\[.*\])?)$/ } keys %$parameters) {
		# The v2 router returns this exact response before dispatch when v2 is
		# unavailable. Ordinary resource errors cannot trigger another request.
		if (defined $response && $response->code == 404 && ($response->header('Content-Type') || '') =~ m{^application/json(?:;|$)}i) {
			my $error = eval { decode_json($response->content) };
			if (ref($error) eq 'HASH' && ($error->{error} || '') eq 'NOT_FOUND' &&
			    ($error->{message} || '') eq 'Page not found' && exists $error->{success} && ! $error->{success}) {
				return $self->{_ua}->$method($self->make_url(%args, parameters => { %$parameters, api_version => 1 }), @body);
			}
		}
	}
	return $response;
}

sub make_url {
	my ($self, %args) = @_;
	my $action = $args{action} || '';
	my %parameters = %{$args{parameters} || {}};
	my $version = $self->_version_for($action, \%parameters);
	delete $parameters{api_version};
	my $base = $self->{_base};
	$base =~ s{/api/v[12]/?$}{/api/v$version/} if (defined $version);
	my $url = $base . "$action?key=" . uri_encode($self->{_key}, 1);

	foreach my $name (sort keys %parameters) {
		my $value = $parameters{$name};
		next if (! defined $value);
		my $key = $name eq 'urls' ? 'url' : $name eq 'instances' ? 'instance_id' : $name;
		if ($key eq 'profiles' && ref($value) eq 'ARRAY') {
			$value = JSON->new->encode($value);
		}
		if ($key eq 'apps' && ref($value) eq 'HASH') {
			foreach my $app (sort keys %$value) {
				$url .= '&' . uri_encode("apps[$app]", 1) . '=' . uri_encode($value->{$app}, 1) if (defined $value->{$app});
			}
			next;
		}
		my @values = ref($value) eq 'ARRAY' && $key =~ /^(?:url|instance_id|apps)$/ ? @$value : ($value);
		foreach my $item (@values) {
			$url .= '&' . uri_encode($key, 1) . '=' . uri_encode($item, 1) if (defined $item);
		}
	}

	$self->info($url);
	return $url;
}

sub info {
	my ($self, $message) = @_;

	if ($self->{_debug}) {
	  print $message, "\n";
	}

	return '';
}

sub error {
	my ($self, $message) = @_;

	$self->{last_error} = $message;

	if ($self->{_debug}) {
		print $message, "\n";
	}

	return '';
}

sub generic_error {
	my ($self, $message) = @_;


	return { error => 1, message => $message };
}

=head1 CHANGES

=over 4

=item 2.0.0

Select API v1 or v2 per request. Add direct capture options, device lookup,
and app management. Allow v2 screenshot lookup with existing IDs.

=item 1.32.0

API 1.32. Add C<screenshot_pdf>, C<screenshot_pdf_file>, C<screenshot_video>,
and C<screenshot_video_file>. Document new capture options and native instance IDs.

=item 1.24.0

C<screenshot_thumbnail_file> creates the directory structure as needed.

=item 1.16.0

Check if the file is not a folder in simple_file

=item 1.14.1

Remove deprecated API calls.

=item 1.14.0

Add C<batch_create> and C<batch_info> for API 1.14.

=item 1.13.0

Add C<screenshot_html> and C<screenshot_multiple> for API 1.13.

=item 1.12

Add C<screenshot_search> for API 1.12.

=item 1.11.1

Return Browshot response in case of error if the reply is valid JSON.

=item 1.11

Compatible with API 1.11. Optional HTTP timeout.

=item 1.10

Add C<screenshot_delete> for API 1.10.

=item 1.9.4

Fix status code in error messages.

=item 1.9.3

Keep backward compatibility for C<screenshot_thumbnail>.

=item 1.9.0

Add C<screenshot_share> for API 1.9.

=item 1.8.0

Update C<screenshot_thumbnail> to use new API.

=item 1.7.0

Update C<screenshot_info> to handle additional parameters

=item 1.5.1

Use binmode to create valid PNG files on Windows.

=item 1.4.1

Fix URI encoding.

=item 1.4.0

Add C<simple> and C<simple_file> methods.

=item 1.3.1

Retry requests (up to 2 times) to browshot.com in case of error

=back

=head1 SEE ALSO

See L<http://browshot.com/api/documentation> for the API documentation.

Create a free account at L<http://browshot.com/login> to get your free API key.

Go to L<http://browshot.com/dashboard> to find your API key after you registered.

=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
