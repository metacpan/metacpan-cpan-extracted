package WebService::ImKayac::Simple;
use 5.008005;
use strict;
use warnings;
use Carp;
use Digest::SHA1 qw/sha1_hex/;
use Encode qw/encode_utf8 decode_utf8/;
use Furl;
use JSON ();

use constant IM_KAYAC_BASE_URL => 'http://im.kayac.com/api/post/';

our $VERSION = '0.10';

sub new {
    my ($class, @arg) = @_;

    my $user;
    my $password;
    my $type;
    if (scalar @arg == 1) {
        require YAML::Tiny;
        my $yaml_file = shift @arg;
        my $conf = YAML::Tiny->read($yaml_file)->[0];
        $user     = $conf->{user};
        $type     = $conf->{type}     || '';
        $password = $conf->{password} || '';
    }
    else {
        my %arg = @arg;
        $user     = $arg{user};
        $type     = $arg{type}     || '';
        $password = $arg{password} || '';
    }

    croak '[ERROR] User name is required' unless $user;
    if ($type) {
        if ($type !~ /^(?:password|secret)$/) {
            croak "[ERROR] Invalid type: $type (type must be 'password' or 'secret')";
        }
        croak '[ERROR] Password is required' unless $password;
    }

    bless {
        user     => $user,
        password => $password,
        type     => $type,
        furl     => Furl->new(
            agent   => 'WebService::ImKayac::Simple (Perl)',
            timeout => 10,
        ),
    }, $class;
}

sub send {
    my ($self, $message, $handler) = @_;

    croak '[ERROR] Message is required' unless $message;
    eval { $message = decode_utf8($message) };
    $message = encode_utf8($message);

    my $param = {message => $message};

    if (my $type = $self->{type}) {
        if ($type eq 'password') {
            $param->{password} = $self->{password};
        }
        elsif ($type eq 'secret') {
            $param->{sig} = sha1_hex($message . $self->{password});
        }
    }

    if ($handler) {
        $param->{handler} = $handler;
    }

    my $res = $self->{furl}->post(
        IM_KAYAC_BASE_URL . $self->{user},
        ['Content-Type' => 'application/x-www-form-urlencoded'],
        $param,
    );

    unless ($res->is_success) {
        croak "[ERROR] " . $res->status_line;
    }

    my $json = JSON::decode_json($res->{content});
    if (my $error = $json->{error}) {
        croak "[ERROR] $error";
    }
}

1;
__END__

=encoding utf-8

=for stopwords $im->send($message utf-8

=head1 NAME

WebService::ImKayac::Simple - Simple message sender for im.kayac

=head1 SYNOPSIS

    use WebService::ImKayac::Simple;

    my $im = WebService::ImKayac::Simple->new(
        type     => 'password',
        user     => '__USER_NAME__',
        password => '__PASSWORD__',
    );

    $im->send('Hello!');
    $im->send('Hello!', 'mailto:example@example.com'); # you can append handler to the message

=head1 DESCRIPTION

WebService::ImKayac::Simple is the simple message sender for im.kayac (L<http://im.kayac.com/>).

=head1 METHODS

=over 4

=item * WebService::ImKayac::Simple->new()

Constructor. You can specify C<user>, C<password> and C<type> through this method.

Essential arguments are changed according to the C<type>. C<type> allows only
"password", "secret" or empty. Please refer to the following for details of each type.

With no authentication:

    my $im = WebService::ImKayac::Simple->new(
        user => '__USER_NAME__',
    );

With password authentication:

    my $im = WebService::ImKayac::Simple->new(
        type     => 'password',
        user     => '__USER_NAME__',
        password => '__PASSWORD__',
    );

With secret key authentication:

    my $im = WebService::ImKayac::Simple->new(
        type     => 'secret',
        user     => '__USER_NAME__',
        password => '__SECRET_KEY__',
    );

Also you can configure by YAML file:

    my $im = WebService::ImKayac::Simple->new('path/to/config.yml');

Sample of YAML config file:

    user: foo
    password: bar
    type: __TYPE__

=item * $im->send($message, $handler)

Send message.

C<$message> is required. It must be utf-8 string or perl string.

C<$handler> is optional. Please refer L<http://im.kayac.com/#docs> if you want to get details.

=back

=head1 FOR DEVELOPERS

Tests which are calling web API directly in F<xt/webapi>. If you want to run these tests, please execute like so;

    $ IM_KAYAC_NONE_USER=__USER_NAME__ prove xt/webapi/00_none.t

=head1 SEE ALSO

L<AnyEvent::WebService::ImKayac>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

