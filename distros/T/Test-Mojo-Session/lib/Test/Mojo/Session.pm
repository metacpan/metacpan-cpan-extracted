package Test::Mojo::Session;

use Mojo::Base 'Test::Mojo';
use Mojo::Util qw(b64_decode hmac_sha1_sum);
use Mojo::JSON qw(decode_json);

our $VERSION = '1.04';

sub new {
    my $self = shift->SUPER::new(@_);
    return $self;
}

sub session_has {
    my ($self, $p, $desc) = @_;
    $desc //= qq{session has value for JSON Pointer "$p"};
    my $session = $self->_extract_session;
    return $self->_test('ok', !!Mojo::JSON::Pointer->new($session)->contains($p), $desc);
}

sub session_hasnt {
    my ($self, $p, $desc) = @_;
    $desc //= qq{session has no value for JSON Pointer "$p"};
    my $session = $self->_extract_session;
    return $self->_test('ok', !Mojo::JSON::Pointer->new($session)->contains($p), $desc);
}

sub session_is {
    my ($self, $p, $data, $desc) = @_;
    $desc //= qq{session exact match for JSON Pointer "$p"};
    my $session = $self->_extract_session;
    return $self->_test('is_deeply', Mojo::JSON::Pointer->new($session)->get($p), $data, $desc);
}

sub session_ok {
    my $self = shift;
    my $session = $self->_extract_session;
    return $self->_test('ok', !!$session, 'session ok');
}

sub _extract_session {
    my $self = shift;

    my $app = $self->app;
    my $session_name = $app->sessions->cookie_name;

    my @cookies = $self->ua->cookie_jar->all;
    @cookies = @{$cookies[0]} if ref $cookies[0] eq 'ARRAY';
    my ($session_cookie) = grep { $_->name eq $session_name } @cookies;
    return unless $session_cookie;

    (my $value = $session_cookie->value) =~ s/--([^\-]+)$//;
    my $sign = $1;

    my $ok;
    $sign eq hmac_sha1_sum($value, $_) and $ok = 1 for @{$app->secrets};
    return unless $ok;

    my $session = decode_json(b64_decode $value);
    return $session;
}

1;

__END__

=head1 NAME

Test::Mojo::Session - Testing session in Mojolicious applications

=head1 SYNOPSIS

    use Mojolicious::Lite;
    use Test::More;
    use Test::Mojo::Session;

    get '/set' => sub {
        my $self = shift;
        $self->session(s1 => 'session data');
        $self->session(s3 => [1, 3]);
        $self->render(text => 's1');
    } => 'set';

    my $t = Test::Mojo::Session->new;
    $t->get_ok('/set')
        ->status_is(200)
        ->session_ok
        ->session_has('/s1')
        ->session_is('/s1' => 'session data')
        ->session_hasnt('/s2')
        ->session_is('/s3' => [1, 3]);

    done_testing();

=head1 DESCRIPTION

L<Test::Mojo::Session> is an extension for the L<Test::Mojo>, which allows you
to conveniently test session in L<Mojolicious> applications.

=head1 METHODS

L<Test::Mojo::Sesssion> inherits all methods from L<Test::Mojo> and implements the
following new ones.

=head2 session_has

    $t = $t->session_has('/foo');
    $t = $t->session_has('/foo', 'session has "foo"');

Check if current session contains a value that can be identified using the given
JSON Pointer with L<Mojo::JSON::Pointer>.

=head2 session_hasnt

    $t = $t->session_hasnt('/bar');
    $t = $t->session_hasnt('/bar', 'session does not has "bar"');

Check if current session no contains a value that can be identified using the given
JSON Pointer with L<Mojo::JSON::Pointer>.

=head2 session_is

    $t = $t->session_is('/pointer', 'value');
    $t = $t->session_is('/pointer', 'value', 'right halue');

Check the session using the given JSON Pointer with L<Mojo::JSON::Pointer>.

=head2 session_ok

    $t = $t->session_ok;

Check for existence of the session in user agent.

=head1 SEE ALSO

L<Mojolicious>, L<Test::Mojo>.

=head1 AUTHOR

Andrey Khozov, C<avkhozov@googlemail.com>.

=head1 CREDITS

Renee, C<reb@perl-services.de>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015, Andrey Khozov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
