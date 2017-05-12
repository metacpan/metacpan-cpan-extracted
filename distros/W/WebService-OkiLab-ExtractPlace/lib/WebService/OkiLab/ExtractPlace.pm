package WebService::OkiLab::ExtractPlace;

use warnings;
use strict;
use Carp;

our $VERSION = 0.02;

use HTTP::Request::Common qw(GET POST);
use LWP::UserAgent;
use JSON;

sub new {
	my $class = shift;
	my $self  = bless {}, $class;
	$self->url('http://okilab.jp/project/location/api/v1/extract_place/');
	my $ua = LWP::UserAgent->new();
	$ua->env_proxy();
	$self->ua($ua);
	return $self;
}

sub param {
	my $self = shift;
	if (@_) {
		my $key  = shift;
		$self->{"_$key"} = shift if (@_);
		return $self->{"_$key"};
	} else {
		my @keys = sort map { substr($_, 1) } grep { /^_/ } keys(%{$self});
		return @keys;
	}
}

sub ua  { my $self = shift; return $self->param('ua',  @_); }
sub url { my $self = shift; return $self->param('url', @_); }
sub res { my $self = shift; return $self->param('res', @_); }
sub req { my $self = shift; return $self->param('req', @_); }

sub extract {
	my $self = shift;
	my $text = shift;
	my $ua   = $self->ua();
	my $url  = URI->new($self->url());
	return $self->error("Can't load LWP::UserAgent object.") if (not UNIVERSAL::isa($ua, 'LWP::UserAgent'));
	return $self->error("Web service url is invalid. ($url)") if ($url->scheme ne 'http');
	return $self->error("Text is empty.") if ($text !~ /\S/);
	# create HTTP::Response
	my $method = uc($self->param('method')) || 'POST';
	$url->query_form('text' => $text) if ($method eq 'GET');
	my $req = ($method eq 'GET') ? GET($url) : POST($url, ['text' => $text]);
	# do reqeust
	$self->req($req);
	my $res = $ua->request($req);
	$self->res($res) || return $self->error('Response is empty.');
	$res->is_success || return $self->error(sprintf('Request failed. (%s)', $res->status_line));
	# parse result
	my $json = $res->content() || return $self->error('Response content is empty.');
	my $result = jsonToObj($json) || return $self->error("Can't parse response content.");
	return $result;
}

1;
__END__

=head1 NAME

WebService::OkiLab::ExtractPlace - Perl interface to the OkiLab ExtractPlace web service

=head1 VERSION

This document describes WebService::OkiLab::ExtractPlace version 0.0.2

=head1 SYNOPSIS

    use WebService::OkiLab::ExtractPlace;
    use Data::Dumper;
    
    my $text = '東京から名古屋駅を通過して大阪駅に行きました。大阪市中央区本町に到着しました。'; # must be UTF-8
    
    my $explace = WebService::OkiLab::ExtractPlace->new;
    my $result = $explace->extract($text);
    print Dumper($result);

or

    use WebService::OkiLab::ExtractPlace;
    use Data::Dumper;
    
    my $text = '東京から名古屋駅を通過して大阪駅に行きました。大阪市中央区本町に到着しました。'; # must be UTF-8
    print Dumper(WebService::OkiLab::ExtractPlace->new->extract($text));

=head1 DESCRIPTION

WebService::OkiLab::ExtractPlace is a simple Perl interface to the okilab.jp ExtractPlace WebService API.

ExtractPlace is experimental service by okilab.jp. For details, see http://okilab.jp/location/2007/11/api_1.html .

=head1 INTERFACE 

=head2 new

Constructor method. It returns WebService::OkiLab::ExtractPlace object.

=head2 extract

It is a method for the extraction of the place.
The text with UTF-8 encoded that becomes an analytical target is received.

It returns the following hash references.

  {
    'result_select' => [
      [
        {
          'lat' => '34.702499',
          'lng' => '135.494982',
          'text' => '大阪駅',
          'type' => 'spot',
          'weight' => 1
        },
        {
          'lat' => '34.686394',
          'lng' => '135.519994',
          'text' => '大阪',
          'type' => 'spot',
          'weight' => 1
        },
        ...
      ]
    ]
  };

When failed, it returns undef.
Please confirm the content of the error by errstr(). 

=head2 errstr

It returns the text of the content of the latest error.

=head2 ua

It returns LWP::UserAgent object which WebService::OkiLab::ExtractPlace uses to access web service.
This method can be used to do some operations to LWP::UserAgent object such as specification of proxy information, etc.

=head2 url

It returns request url of the web services.
Default url is 'http://okilab.jp/project/location/api/v1/extract_place/'.
You can specify other url as argment.

=head2 req

It returns recent HTTP::Request object which is send to the WebService.

=head2 res

It returns recent HTTP::Response object which is send to the WebService.

=head2 Internal methods

Belows are internal method.

=over 4

=item param

Accessor and mutator method to some params such as 'ua', 'url', 'req', 'res'.
When no arguments has passed, it returns existing parameter name. 
When parameter name has passed, it returns the parameter value. 
When parameter name and value have passed, it set the value as the parameter value and returns set value. 

=back

=head1 DIAGNOSTICS

It only return undef when something failed.
In that time 

The error text can be acquired in the errstr method at this time. 
These are as follows. 

=over 4

=item Can't load LWP::UserAgent object.

It occurs when WebService::OkiLab::ExtractPlace can't get LWP::UserAgent object.
Maybe LWP::UserAgent is not available, or invalid value has been set with ua method.

=item Web service url is invalid. (%s)

It occurs when url of seb service is invalid.
Current value is set into '%s'.
Maybe invalid value has been set with url method.

=item Text is empty.

It occurs when the text to be analyzed is empty (or blank).
Please confirm the argument given to extract(). 

=item Response is empty.

It occurs when it fails to receive response from the Web service.
Please confirm the state of the LWP::UserAgent object, HTTP::Request object by ua() and req().

=item Request failed. (%s)

It occurs when response from the Web service does not indicate success.
HTTP response code and message is set into '%s'.
Please confirm the state of the HTTP::Request object, HTTP::Response object by req() and res().

=item Response content is empty.

It occurs when the response content is empty (or blank).
Please confirm the state of the HTTP::Request object, HTTP::Response object by req() and res().

=item Can't parse response content.

It occurs when the response content is not able to parse as JSON data.
Please confirm the content of the HTTP::Request object by res().

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::OkiLab::ExtractPlace accesses to the Web service via http.
When it is necessary to use proxy, you may set environment variable HTTP_PROXY.
When proxy needs authentication, the following notations can be used. 

 HTTP_PROXY=http://user:password@host:port

You can specify proxy settings directory to LWP::UserAgent object instead of using environment variable.

=head1 DEPENDENCIES

=over 4

=item * Class::ErrorHandler

=item * LWP::UserAgent

=item * JSON

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 SEE ALSO

=over 4

=item * http://okilab.jp/location/2007/11/api_1.html

=back

=head1 AUTHOR

Makio Tsukamoto  C<< <tsukamoto@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Makio Tsukamoto C<< <tsukamoto@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
