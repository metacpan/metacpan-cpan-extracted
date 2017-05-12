package WebService::Lingr::Archives;
use strict;
use warnings;
use 5.10.0;
use Carp;
use LWP::UserAgent;
use URI;
use JSON qw(decode_json);

our $VERSION = '0.03';

sub new {
    my ($class, %args) = @_;
    if(!defined($args{user})) {
        croak "user parameter is mandatory";
    }
    if(!defined($args{password})) {
        croak "password parameter is mandatory";
    }
    my $self = bless {
        user_agent => $args{user_agent} // do {
            my $ua = LWP::UserAgent->new;
            $ua->env_proxy();
            $ua;
        },
        user => $args{user},
        password => $args{password},
        app_key => $args{app_key},
        api_base => $args{api_base} // 'http://lingr.com/api',
        session_id => undef,
    }, $class;
    $self->{api_base} =~ s{/+$}{};
    return $self;
}

sub get_archives {
    my ($self, $room, $options) = @_;
    $options //= {};
    if(!defined($room)) {
        croak "room parameter is mandatory";
    }
    my $retry_allowed = 1;
    if(!defined($self->{session_id})) {
        $self->_create_session();
        $retry_allowed = 0;
    }
    my $result = $self->_get_request('/room/get_archives', [
        session => $self->{session_id}, room => $room,
        before => $options->{before} // 99999999,
        (defined($options->{limit}) ? (limit => $options->{limit}) : ())
    ]);
    if(!defined($result->{status}) || lc($result->{status}) ne "ok") {
        if($retry_allowed) {
            $self->{session_id} = undef;
            return $self->get_archives($room, $options);
        }
        croak "Lingr API Error: code =  $result->{code}, detail = $result->{detail}";
    }
    return @{$result->{messages}};
}

sub _create_session {
    my ($self) = @_;
    my $result = $self->_get_request('/session/create', [user => $self->{user},
                                                         password => $self->{password},
                                                         (defined($self->{app_key}) ? (app_key => $self->{app_key}) : ())]);
    if(!defined($result->{status}) || lc($result->{status}) ne "ok") {
        croak "Cannot create session with user $self->{user}: $result->{code}, $result->{detail}";
    }
    $self->{session_id} = $result->{session};
}

sub _get_request {
    my ($self, $endpoint, $params) = @_;
    my $url = URI->new($self->{api_base} . $endpoint);
    $url->query_form($params);
    my $res = $self->{user_agent}->get($url);
    if(!$res->is_success) {
        croak "Network Error: " . $res->status_line;
    }
    return decode_json($res->content);
}

1;

__END__

=pod

=head1 NAME

WebService::Lingr::Archives - load archived messages from lingr.com

=head1 SYNOPSIS

    use WebService::Lingr::Archives;
    use Encode qw(encode_utf8);
   
    my $lingr = WebService::Lingr::Archives->new(
        user     => "your lingr username",
        password => "your lingr password",
        app_key  => "your lingr App key",  ## optional
    );
   
    my @messages = $lingr->get_archives("perl_jp", {limit => 100});
   
    foreach my $m (@messages) {
        print encode_utf8("[$m->{timestamp}] $m->{id} $m->{nickname} : $m->{text}\n");
    }

=head1 DESCRIPTION

This is a front-end module specifically for Lingr archives API.

Lingr (L<http://lingr.com>) is a group chat Web service.
L<WebService::Lingr::Archives> uses its Web API to fetch archived message data from a chat room.

=head1 CLASS METHODS

=head2 $lingr = WebService::Lingr::Archives->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<user> => STR (mandatory)

Username for your Lingr account.

=item C<password> => STR (mandatory)

Password for your Lingr account.

=item C<app_key> => STR (optional)

Lingr App key. Although it's not required, you can register your app in L<http://lingr.com/developer>.

=item C<api_base> => STR (optional, default: "http://lingr.com/api")

API base URL.

=item C<user_agent> => OBJECT (optional, default: L<LWP::UserAgent> with env_proxy() called)

HTTP UserAgent object to access the API.

=back

=head1 OBJECT METHODS

=head2 @messages = $lingr->get_archives($room_id[, $options])

Get archived messages from the chat room specified by C<$room_id>.

Optional parameter C<$options> is a hash-ref. Its fields are:

=over

=item C<before> => MESSAGE ID (optional, default: 99999999)

C<get_archives()> returns messages whose ID is less than this number.
By default, C<before> parameter is set to a very big number,
meaning C<get_archives()> returns the latest messages.

=item C<limit> => INT (optional)

Number of messages C<get_messages()> tries to return.

=back

In success, this method returns a list of hash-refs.
Each hash-ref represents a message created in the chat room.

In failure, this method dies.

=head1 SEE ALSO

=over

=item *

L<AnyEvent::Lingr> - Event-driven Lingr API client. Useful for interactive programs, like bots.

=item *

Lingr - L<http://lingr.com>

=item *

Lingr Developer Resources - L<https://github.com/lingr/lingr/wiki>

=back

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

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

