package WebService::Megaplan;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(login password hostname port use_ssl secret_key access_id http));

use Digest::MD5 qw(md5_hex);
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use JSON qw(from_json);
use HTTP::Tiny ();
use MIME::Base64 qw(encode_base64);
use POSIX ();

use constant {
        AUTHORIZE_URL => '/BumsCommonApiV01/User/authorize.api',
    };

=head1 NAME

WebService::Megaplan - The API for Megaplan.ru service (Web-based business automatization service)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Module allows to call Megaplan API using Perl

See API details on http://wiki.megaplan.ru/API (Russian only)

Currently implemented only low-level API where you have to provide URI of API calls.

    use WebService::Megaplan;

    my $api = WebService::Megaplan->new(
                    login    => 'robot_user',
                    password => 'xxxxxx',
                    hostname => 'mycompany.megaplan.ru',
                    use_ssl  => 1,
                );
    my $employee_id = $api->authorize();

    # get list of tasks
    my $data = $api->get_data('/BumsTaskApiV01/Task/list.api', { OnlyActual => 'true' });
    my $task_list = $data->{data}->{tasks};

    # create new task
    my $task_reply = $api->post_data('/BumsTaskApiV01/Task/create.api', {
                                'Model[Name]'        => 'Test title',
                                'Model[SuperTask]'   => 'p1000001',
                                'Model[Statement]'   => 'Task long description',
                                'Model[Responsible]' => $employee_id, # number like 1000020
                            });
    printf "Created task #%d\n", $task_reply->{data}->{task}->{Id};

=head1 METHODS

=head2 new(%opt)

Create new API object, providing a hash of options:

=over 2

=item login    -- login

=item password -- password

=item hostname -- hostname of installed Megaplan, usually something like 'somename.megaplan.ru'

=item port     -- port to use to connect Megaplan, not required if default (80 http, 443 https)

=item use_ssl  -- 0 or 1, using SSL is recommended

=back

=cut

sub new {
    my($class, %opts) = @_;

    die "No login specified"    if(! $opts{login});
    die "No password specified" if(! $opts{password});
    die "No hostname specified" if(! $opts{hostname});

    $opts{use_ssl} ||= 0;

    my $http = HTTP::Tiny->new();
    $opts{http} = $http;

    return bless \%opts, $class;
}

=head2 authorize

Authenticate itself on Megaplan server and obtain AccessId and SecretKey values.

Returns true value on success (ID of logged in Employee). This method have to be called before any other API calls.

=cut

sub authorize {
    my $self = shift;

    my $params = $self->http->www_form_urlencode({
                                Login    => $self->login,
                                Password => md5_hex($self->password),
                            });
    my $url = ($self->use_ssl ? 'https' : 'http')
                    . '://'
                    . $self->hostname
                    . ($self->port ? ':' . $self->port : '')
                    . AUTHORIZE_URL
                    . '?'
                    . $params;
    #printf STDERR "GET %s\n", $url;

    my $response = $self->http->get($url);
    die 'No response from server' if(! $response);
    if(! $response->{success}) {
        die sprintf('Login failed: %03d %s', $response->{status}, $response->{reason});
    }

    my $data = from_json($response->{content});

    if($data->{status}->{code} ne 'ok') {
        die sprintf('Login failed: %s', $data->{status}->{message});
    }

    my $secret = $data->{data}->{SecretKey};
    my $access_id = $data->{data}->{AccessId};

    $self->secret_key($secret);
    $self->access_id($access_id);

    # also there are 'UserId' value
    return $data->{data}->{EmployeeId};
}

=head2 get_data(uri_path, params)

Low-level method to perform GET query to corresponding API method

=over 2

=item uri_path -- URI, for example '/BumsTaskApiV01/Task/list.api'

=item params   -- hash-reference of API call arguments (optional)

=back

Returns perl data, converted from resulted JSON. died in case of errors.

=cut

sub get_data {
    my ($self, $uri_path, $params) = @_;

    $params ||= {};

    $self->authorize() if(! $self->secret_key);
    die "No secret key, failed login?" if(! $self->secret_key);

    my ($signature, $date) = $self->_make_signature(
                                    method => 'GET',
                                    content => '',
                                    uri_path => $uri_path,
                                    query_params => $params,
                                );

    my $query_string = $self->http->www_form_urlencode($params);
    my $url = ($self->use_ssl ? 'https' : 'http')
                    . '://'
                    . $self->hostname
                    . ($self->port ? ':' . $self->port : '')
                    . $uri_path;
    if($query_string) {
        $url .= '?' . $query_string;
    }

    #printf STDERR "GET %s\n", $url;

    my $response = $self->http->get($url, {
                            headers => {
                                Date              => $date,
                                'X-Sdf-Date'      => $date,
                                Accept            => 'application/json',
                                'X-Authorization' => join(':', $self->access_id, $signature),
                            },
                        });

    die 'No response from server' if(! $response);
    if(! $response->{success}) {
        die sprintf('GET failed: %03d %s', $response->{status}, $response->{reason});
    }

    my $data = from_json($response->{content});

    if($data->{status}->{code} ne 'ok') {
        die sprintf('GET failed: %s', $data->{status}->{message});
    }

    return $data;
}

=head2 post_data(uri_path, params)

Low-level method to perform POST request to API - to create new objects or update existing ones

=over 2

=item uri_path -- URI, for example '/BumsCommonApiV01/Comment/create.api'

=item params   -- hash-reference of API call arguments

=back

Returns perl data, converted from resulted JSON. died in case of errors.

=cut

sub post_data {
    my ($self, $uri_path, $params) = @_;

    # it's unlikely that $params is empty

    $self->authorize() if(! $self->secret_key);
    die "No secret key, failed login?" if(! $self->secret_key);

    my $content = $self->http->www_form_urlencode($params);

    my ($signature, $date) = $self->_make_signature(
                                    method       => 'POST',
                                    content      => $content,
                                    uri_path     => $uri_path
                                );
    my $url = ($self->use_ssl ? 'https' : 'http')
                    . '://'
                    . $self->hostname
                    . ($self->port ? ':' . $self->port : '')
                    . $uri_path;

    my $response = $self->http->post_form($url, $params, {
                            headers => {
                                Date              => $date,
                                'X-Sdf-Date'      => $date,
                                Accept            => 'application/json',
                                'X-Authorization' => join(':', $self->access_id, $signature),
                                'Content-MD5'     => md5_hex($content),
                            },
                        });

    die 'No response from server' if(! $response);
    if(! $response->{success}) {
        die sprintf('POST failed: %03d %s', $response->{status}, $response->{reason});
    }

    my $data = from_json($response->{content});

    if($data->{status}->{code} ne 'ok') {
        die sprintf('POST failed: %s', $data->{status}->{message});
    }

    return $data;
}

#-------------- private
sub _make_signature {
    my ($self, %opts) = @_;

    # method, content_md5, content_type, date, url
    my @fields = ($opts{method});
    if($opts{content}) {
        push @fields,
                md5_hex($opts{content}),
                'application/x-www-form-urlencoded';
    }
    else {
        push @fields, '', '';
    }

    my $old_locale = POSIX::setlocale(&POSIX::LC_TIME, 'C');
    my $date = POSIX::strftime('%a, %d %b %Y %H:%M:%S %z', localtime);
    push @fields, $date;
    POSIX::setlocale(&POSIX::LC_TIME, $old_locale);

    # I think that port should not be included here, but never tested
    my $url = $self->hostname . $opts{uri_path};
    if( ($opts{method} eq 'GET') && $opts{query_params} && scalar(keys %{ $opts{query_params} }) > 0) {
        my $query_string = $self->http->www_form_urlencode($opts{query_params});
        $url .= '?' . $query_string;
    }
    push @fields, $url;

    #printf STDERR "Signature for:\n%s\n", join("\n", @fields);

    my $signature = encode_base64( hmac_sha1_hex(join("\n", @fields), $self->secret_key), '');

    return ($signature, $date);
}


=head1 AUTHOR

Sergey Leschenko, C<< <sergle.ua at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-megaplan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Megaplan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Megaplan


You can also look for information at:

=over 4

=item * Megaplan API (Russian only)

L<http://wiki.megaplan.ru/API>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Megaplan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Megaplan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Megaplan>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Megaplan/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sergey Leschenko.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Megaplan
