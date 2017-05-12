package WebService::Bitly;

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;

our $VERSION = '0.06';

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON;

use WebService::Bitly::Result::HTTPError;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    user_name
    user_api_key
    end_user_name
    end_user_api_key
    domain
    version

    base_url
    ua
));

sub new {
    my ($class, %args) = @_;
    if (!defined $args{user_name} || !defined $args{user_api_key}) {
        croak("user_name and user_api_key are both required parameters.\n");
    }

    $args{version} ||= 'v3';
    $args{ua} ||= LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 30,
    );
    $args{base_url} ||= 'http://api.bit.ly/';

    return $class->SUPER::new(\%args);
}

sub shorten {
    my ($self, $url) = @_;
    if (!defined $url) {
        croak("url is required parameter.\n");
    }

    my $api_url = $self->_api_url("shorten");
       $api_url->query_param(x_login  => $self->end_user_name)    if $self->end_user_name;
       $api_url->query_param(x_apiKey => $self->end_user_api_key) if $self->end_user_api_key;
       $api_url->query_param(domain   => $self->domain)           if $self->domain;
       $api_url->query_param(longUrl  => $url);

    $self->_do_request($api_url, 'Shorten');
}

sub expand {
    my ($self, %args) = @_;
    my $short_urls = $args{short_urls} || undef;
    my $hashes     = $args{hashes} || undef;
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = $self->_api_url("expand");
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Expand');
}

sub validate {
    my ($self) = @_;

    my $api_url = $self->_api_url("validate");
       $api_url->query_param(x_login  => $self->end_user_name);
       $api_url->query_param(x_apiKey => $self->end_user_api_key);

    $self->_do_request($api_url, 'Validate');
}

sub set_end_user_info {
    my ($self, $end_user_name, $end_user_api_key) = @_;

    if (!defined $end_user_name || !defined $end_user_api_key) {
        croak("end_user_name and end_user_api_key are both required parameters.\n");
    }

    $self->end_user_name($end_user_name);
    $self->end_user_api_key($end_user_api_key);

    return $self;
}

sub clicks {
    my ($self, %args) = @_;
    my $short_urls   = $args{short_urls} || undef;
    my $hashes       = $args{hashes} || undef;
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = $self->_api_url("clicks");
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Clicks');
}

sub referrers {
    my ($self, %args) = @_;
    my $short_url = $args{short_url} || '';
    my $hash      = $args{hash} || '';

    unless ($short_url xor $hash) {
        croak("please input either short_url or hash, not both.");
    }

    my $api_url = $self->_api_url("referrers");
       $api_url->query_param(shortUrl => $short_url) if $short_url;
       $api_url->query_param(hash     => $hash)      if $hash;

    $self->_do_request($api_url, 'Referrers');
}

sub countries {
    my ($self, %args) = @_;
    my $short_url = $args{short_url} || '';
    my $hash      = $args{hash} || '';

    unless ($short_url xor $hash) {
        croak("please input either short_url or hash, not both.");
    }

    my $api_url = $self->_api_url("countries");
       $api_url->query_param(shortUrl => $short_url) if $short_url;
       $api_url->query_param(hash     => $hash)      if $hash;

    $self->_do_request($api_url, 'Countries');
}

sub clicks_by_minute {
    my ($self, %args) = @_;
    my $short_urls = $args{short_urls} || undef;
    my $hashes     = $args{hashes} || undef;
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = $self->_api_url("clicks_by_minute");
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'ClicksByMinute');
}

sub clicks_by_day {
    my ($self, %args) = @_;
    my $short_urls = $args{short_urls} || undef;
    my $hashes     = $args{hashes} || undef;
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = $self->_api_url("clicks_by_day");
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'ClicksByDay');
}

sub bitly_pro_domain {
    my ($self, $domain) = @_;
    if (!$domain) {
        croak("domain is required parameter.\n");
    }

    my $api_url = $self->_api_url("bitly_pro_domain");
       $api_url->query_param(domain   => $domain);

    $self->_do_request($api_url, 'BitlyProDomain');
}

sub lookup {
    my ($self, $urls) = @_;
    if (!$urls) {
        croak("urls is required parameter.\n");
    }

    my $api_url = $self->_api_url("lookup");
       $api_url->query_param(url      => reverse(@$urls));

    $self->_do_request($api_url, 'Lookup');
}

sub info {
    my ($self, %args) = @_;
    my $short_urls   = $args{short_urls} || undef;
    my $hashes       = $args{hashes} || undef;
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = $self->_api_url("info");
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Info');
}

sub _do_request {
    my ($self, $url, $result_class) = @_;

    $url->query_param(login    => $self->user_name);
    $url->query_param(apiKey   => $self->user_api_key);
    $url->query_param(format   => 'json');

    my $response = $self->ua->get($url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    $result_class = 'WebService::Bitly::Result::' . $result_class;
    $result_class->require;

    my $bitly_response = from_json($response->content);
    return $result_class->new($bitly_response);
}

sub _api_url {
    my ($self, $api_name) = @_;
    return URI->new($self->base_url . $self->version . "/". $api_name);
}

1;

__END__;

=head1 NAME

WebService::Bitly - A Perl interface to the bit.ly API

=head1 VERSION

This document describes version 0.06 of WebService::Bitly.

=head1 SYNOPSIS

    use WebService::Bitly;

    my $bitly = WebService::Bitly->new(
        user_name => 'shibayu',
        user_api_key => 'R_1234567890abcdefg',
    );

    my $shorten = $bitly->shorten('http://example.com/');
    if ($shorten->is_error) {
        warn $shorten->status_code;
        warn $shorten->status_txt;
    }
    else {
        my $short_url = $shorten->short_url;
    }

=head1 DESCRIPTION

WebService::Bitly provides an interface to the bit.ly API.

this module is similar as WWW::Shorten::Bitly, but WWW::Shorten::Bitly only supports shorten and expand API.  WebService::Bitly supports all.

To get information about bit.ly API, see http://code.google.com/p/bitly-api/wiki/ApiDocumentation.

=head1 METHODS

=head2 new(%param)

Create a new WebService::Bitly object with hash parameter.

    my $bitly = WebService::Bitly->new(
        user_name        => 'shibayu36',
        user_api_key     => 'R_1234567890abcdefg',
        end_user_name    => 'bitly_end_user',
        end_user_api_key => 'R_abcdefg123456789',
        domain           => 'j.mp',
    );

Set up initial state by following parameters.

=over 4

=item * user_name

Required parameter.  bit.ly user name.

=item * user_api_key

Required parameter.  bit.ly user api key.

=item * end_user_name

Optional parameter.  bit.ly end-user name.  This parameter is used by shorten and validate method.

=item * end_user_api_key

Optional parameter.  bit.ly end-user api key.  This parameter is used by shorten and validate method.

=item * domain

Optional parameter.  Specify 'j.mp', if you want to use j.mp domain in shorten method.

=back

=head2 shorten($url)

Get shorten result from long url.
you can make requests on behalf of another bit.ly user,  if you specify end_user_name and end_user_api_key in new or set_end_user_info method.

    my $shorten = $bitly->shorten('http://example.com');
    if (!$shorten->is_error) {
        print $shorten->short_url;
        print $shorten->hash;
    }

You can get data by following method of result object.

=over 4

=item * is_error

return 1, if request is failed.

=item * short_url

=item * is_new_hash

return 1, if specified url was shortened first time.

=item * hash

=item * global_hash

=item * long_url

=back

=head2 expand(%param)

Get long URL from given bit.ly URL or hash (or multiple).

=head3 parameters

=over 4

=item short_urls

bit.ly short url arrayref

=item hashes

bit.ly hash arrayref

=back

    my $expand = $bitly->expand(
        short_urls => ['http://bit.ly/abcdef', 'http://bit.ly/fedcba'],
        hashes     => ['123456', '654321'],
    );
    if (!$expand->is_error) {
        for $result ($expand->results) {
            print $result->long_url if !$result->is_error;
        }
    }

You can get expand results by $expand->results method. This method returns array in array context, or returns array refference in scalar context. Each result object has following method.

=over 4

=item * short_url

=item * hash

=item * user_hash

=item * global_hash

=item * long_url

=item * is_error

return error message, if error occured by the url.

=back

=head2 validate

Validate end-user name and end-user api key, which are set by new or set_end_user_info method.

    $bitly->set_end_user_info('end_user', 'R_1234567890123456');
    print $bitly->end_user_name;    # 'end_user'
    print $bitly->end_user_api_key; # 'R_1234567890123456'
    if ($bitly->validate->is_valid) {
        ...
    }

=head2 set_end_user_info($end_user_name, $end_user_api_key)

Set end-user name and end-user api key.

=head2 clicks(%param)

Get statistics about the clicks from given bit.ly URL or hash (or multiple).
You can use this in much the same way as expand method.  Each result object has following method.

=over 4

=item * short_url

=item * hash

=item * user_hash

=item * global_hash

=item * user_clicks

=item * global_clicks

=item * is_error

=back

=head2 referrers(%param)

Get a list of referring sites for a specified short url or hash.

=head3 parameters

Specify either short_url or hash, but not both.

=over 4

=item short_url

bit.ly short url

=item hash

bit.ly hash

=back

You can get data by following method of result object.

=over 4

=item * is_error

=item * created_by

=item * global_hash

=item * short_url

=item * user_hash

=item * referrers

returns array or arrayref of referrer information object.  array context returns array,  and scalar context returns arrayref.  you can use accessor method such as clicks, referrer, referrer_app and url.

=back

   my $result = $bitly->referrers(short_url => 'http://bit.ly/abcdef');
   print $result->short_url;
   for my $referrer ($result->refferers) {
       printf '%s : %s', $referrer->referrer, $referrer->clicks;
   }

=head2 countries

Get a list of countries for a specified short url or hash.  You can use this in much the same way as referrers method.  you are be able to data by following method of result object.

=over 4

=item * is_error

=item * created_by

=item * global_hash

=item * short_url

=item * user_hash

=item * countries

returns array or arrayref of arrayref of countries information object depending on context.  you can use accessor method such as clicks and country.

=back

=head2 clicks_by_minute

Get time series clicks per minute by short urls and hashes.  You can use this in much the same way as expand method.  Each result object has following method.

=over 4

=item * is_error

=item * short_url

=item * hash

=item * user_hash

=item * global_hash

=item * clicks

arrayref of the number of clicks per minutes.

=back

=head2 clicks_by_day

Get time series clicks per day for the last 30 days by short urls and hashes.  You can use this in much the same way as clicks_by_minute method.  Each result object has following method.

=over 4

=item * is_error

=item * short_url

=item * hash

=item * user_hash

=item * global_hash

=item * clicks

arrayref of clicks information object.  each object has accessor for clicks and day_start.

=back

   my $result_clicks = $bitly->clicks_by_day(short_url => ['http://bit.ly/abcdef'], hash => ['abcdef']);
   for my $result (@{$result_clicks->results}) {
       print $result->user_hash;
       for my $clicks (@{$result->clicks}) {
           print $clicks->clicks;
           print $clicks->day_start;
       }
   }

=head2 bitly_pro_domain($domain)

Check whether a given short domain is assigned for bitly.Pro.

    my $result = $bitly->bitly_pro_domain('nyti.ms');
    if ($result->is_pro_domain) {
        ...
    }

=head2 lookup([@urls])

Get shortened url information from given urls.

    my $lookup = $bitly->lookup([
        'http://code.google.com/p/bitly-api/wiki/ApiDocumentation',
        'http://betaworks.com/',
    ]);
    if (!$lookup->is_error) {
        for my $result ($lookup->results) {
            print $result->short_url;
        }
    }

Each result object has following method.

=over 4

=item * global_hash

=item * short_url

=item * url

=item * is_error

return error message, if error occured by the url.

=back

=head2 info(%param)

Get detail page information from given bit.ly URL or hash (or multiple).
You can use this in much the same way as expand method.  Each result object has following method.

=over 4

=item * short_url

=item * hash

=item * user_hash

=item * global_hash

=item * title

page title.

=item * created_by

the bit.ly username that originally shortened this link.

=item * is_error

return error message, if error occured by the url.

=back

=head1 SEE ALSO

=over 4

=item * bit.ly API Documentation

http://code.google.com/p/bitly-api/wiki/ApiDocumentation

=back

=head1 REPOSITORY

http://github.com/shiba-yu36/WebService-Bitly

=head1 AUTHOR

Yuki Shibazaki, C<< <shibayu36 at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Yuki Shibazaki.

WebService::Bitly is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
