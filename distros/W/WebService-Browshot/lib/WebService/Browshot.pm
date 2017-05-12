package WebService::Browshot;

use 5.006006;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use URI::Encode qw(uri_encode);

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
use IO::Socket::SSL;
IO::Socket::SSL::set_ctx_defaults( 
     SSL_verifycn_scheme => 'www', 
     SSL_verify_mode => 0,
     verify_mode => 0,
);

our $VERSION = '1.14.1';

=head1 NAME

WebService::Browshot - Perl extension for Browshot (L<https://browshot.com/>), a web service to create screenshots of web pages.

=head1 SYNOPSIS

  use WebService::Browshot;
  
  my $browshot = WebService::Browshot->new(key => 'my_key');
  my $screenshot = $browshot->screenshot_create(url => 'http://www.google.com/');
  [...]
  $browshot->screenshot_thumbnail_file(id => $screenshot->{id}, file => 'google.png');

=head1 DESCRIPTION

Browshot (L<http://www.browshot.com/>) is a web service to easily make screenshots of web pages in any screen size, as any device: iPhone, iPad, Android, Nook, PC, etc. Browshot has full Flash, JavaScript, CSS, & HTML5 support.

The latest API version is detailed at L<http://browshot.com/api/documentation>. WebService::Browshot follows the API documentation very closely: the function names are similar to the URLs used (screenshot/create becomes C<screenshot_create()>, instance/list becomes C<instance_list()>, etc.), the request arguments are exactly the same, etc.

The library version matches closely the API version it handles: WebService::Browshot 1.0.0 is the first release for the API 1.0, WebService::Browshot 1.1.1 is the second release for the API 1.1, etc.

WebService::Browshot can handle most the API updates within the same major version, e.g. WebService::Browshot 1.0.0 should be compatible with the API 1.1 or 1.2.

The source code is available on github at L<https://github.com/juliensobrier/browshot-perl>.


=head1 METHODS

=over 4

=head2 new()

  my $browshot = WebService::Browshot->new(key => 'my_key', base => 'http://api.browshot.com/api/v1/', debug => 1]);

Create a new WebService::Browshot object. You must pass your API key (go to you Dashboard to find your API key).

Arguments:

=over 4

=item key

Required.  API key.

=item base

 Optional. Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.

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
		_base	=> $args{base}	|| 'https://api.browshot.com/api/v1/',
		_debug	=> $args{debug}	|| 0,

		_retry	=> 2,
		last_error	=> '',

		_ua		=> $ua,
	};

  return bless($browshot, $self);
}


=head2 api_version()

Return the API version handled by the library. Note that this library can usually handle new arguments in requests without requiring an update.

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

	my $url	= $self->make_url(action => 'simple', parameters => { %args });
	my $res = $self->{_ua}->get($url);

# 	$self->info($res->message);
# 	$self->info($res->request->as_string);
# 	$self->info($res->as_string);
	
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

	my $url	= $self->make_url(action => 'simple', parameters => { %args });
	my $res = $self->{_ua}->get($url);

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
	
	return $self->return_reply(action => 'instance/list');
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
	my $id				= $args{id}	|| $self->error("Missing id in instance_info");

	return $self->return_reply(action => 'instance/info', parameters => { id => $id });
}

=head2 browser_list()

Return the list of browsers as a hash reference. See L<http://browshot.com/api/documentation#browser_list> for the response format.

=cut

sub browser_list {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'browser/list');
}

=head2 browser_info()

   $browshot->browser_info(id => 2)

Return the details of a browser. See L<http://browshot.com/api/documentation#browser_info> for the response format.

Arguments:

=over 4

=item id

Required. Browser ID

=back

=cut

sub browser_info  {
	my ($self, %args) 	= @_;
	my $id				= $args{id}	|| $self->error("Missing id in browser_info");

	return $self->return_reply(action => 'browser/info', parameters => { id => $id });
}


=head2 screenshot_create()

  $browshot->screenshot_create(url => 'http://wwww.google.com/', instance_id => 3, size => 'page')

Request a screenshot. See L<http://browshot.com/api/documentation#screenshot_create> for the response format.
Note: by default, screenshots are cached for 24 hours. You can tune this value with the cache=X parameter.

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
# 	my $url				= $args{url}			|| $self->error("Missing url in screenshot_create");
# 	my $instance_id		= $args{instance_id};
# 	my $screen			= $args{screen};
# 	my $size			= $args{size}			|| "screen";
# 	my $cache			= $args{cache};
# 	my $priority		= $args{priority};

	$self->error("Missing url in screenshot_create") 	if (! defined($args{url}));
# 	$args{size} = "screen" 					if (! defined($args{size}));

	return $self->return_reply(action => 'screenshot/create', parameters => { %args });
}

=head2 screenshot_info()

  $browshot->screenshot_info(id => 568978)

Get information about a screenshot requested previously. See L<http://browshot.com/api/documentation#screenshot_info> for the response format.

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
	my $url			= $args{url}	|| $self->error("Missing id in screenshot_search");

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

	if (exists($args{url}) && $args{url} =~ /image\/(\d+)\?/i && ! exists($args{id})) {
		# get ID from url
		$args{id} = $1;

		if ($args{url}  =~ /&width=(\d+)\?/i && ! exists($args{width})) {
				$args{width} = $1;
		}
		if ($args{url}  =~ /&height=(\d+)\?/i && ! exists($args{height})) {
				$args{height} = $1;
		}
		
	}
	elsif(! exists($args{id}) ) {
		$self->error("Missing id and url in screenshot_thumbnail");
		return '';
	}


	my $url	= $self->make_url(action => 'screenshot/thumbnail', parameters => { %args });
	my $res =  $self->{_ua}->get($url);

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

	my $content = $self->screenshot_thumbnail(%args);

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

=head2 screenshot_multiple()

  $browshot->screenshot_multiple(urls => ['http://mobilito.net/'], instances => [22, 30])

Request multiple screenshots. See L<http://browshot.com/api/documentation#screenshot_multiple> for the response format.

Arguments:

=over 4

=item urls

Required. One or more URLs.

=item instances

Required. One or more instance_id.

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

Required. instance_id to use for all screenshots.

=back

=cut

sub batch_create {
	my ($self, %args) 	= @_;
	my $file		= $args{file}		|| $self->error("Missing file in batch_create");
	my $instance_id		= $args{instance_id}	|| $self->error("Missing instance_id} in batch_create");

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



=head2 account_info()

Return information about the user account. See L<http://browshot.com/api/documentation#account_info> for the response format.

=cut

sub account_info {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'account/info', parameters => { %args });
}


# Private methods

sub return_string {
	my ($self, %args) 	= @_;

	my $url	= $self->make_url(%args);
	
	my $res;
	my $try = 0;

	do {
		$self->info("Try $try");
		eval {
			$res = $self->{_ua}->get($url);
		};
		$self->error($@) if ($@);
		$try++;
	}
	until($try < $self->{_retry} && defined $@);

	if (! $res->is_success) {
		$self->error("Server sent back an error: " . $res->code);
	}
  
	return $res->decoded_content;
}

sub return_post_string {
	my ($self, %args) 	= @_;
	my $file 		= $args{'file'} || '';

	delete $args{'file'};
	my $url	= $self->make_url(%args);
	
	my $res;
	my $try = 0;

	do {
		$self->info("Try $try");
		eval {
			$res = $self->{_ua}->post(
			  $url,
			  Content_Type => 'form-data',
			  Content => [
			    file => [$file],
			  ]
			);
		};
		$self->error($@) if ($@);
		$try++;
	}
	until($try < $self->{_retry} && defined $@);

	if (! $res->is_success) {
		$self->error("Server sent back an error: " . $res->code);
	}
  
	return $res->decoded_content;
}

sub return_reply {
	my ($self, %args) 	= @_;

	my $content = $self->return_string(%args);

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

sub make_url {
	my ($self, %args) 	= @_;
	my $action		= $args{action}		|| '';
	my $parameters		= $args{parameters}	|| { };

	my $url = $self->{_base} . "$action?key=" . uri_encode($self->{_key}, 1);


	if (exists $parameters->{urls}) {
	  foreach my $uri (@{ $parameters->{urls} }) {
	    $url .= '&url=' . uri_encode($uri, 1);
	  }
	  delete  $parameters->{urls};
	}

	if (exists $parameters->{instances}) {
	  foreach my $instance_id (@{ $parameters->{instances} }) {
	    $url .= '&instance_id=' . uri_encode($instance_id, 1);
	  }
	  delete  $parameters->{instances};
	}

	foreach my $key (keys %$parameters) {
	  $url .= '&' . uri_encode($key) . '=' . uri_encode($parameters->{$key}, 1) if (defined $parameters->{$key});
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
