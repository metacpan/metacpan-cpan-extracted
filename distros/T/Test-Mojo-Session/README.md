# NAME

Test::Mojo::Session - Testing session in Mojolicious applications

# SYNOPSIS

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
      ->session_is('/s3' => [1, 3])
      ->session_like('/s1' => qr/data/, 's1 contains "data"')
      ->session_unlike('/s1' => qr/foo/, 's1 does not contain "foo"');

    done_testing();

Use [Test::Mojo::Sesssion](https://metacpan.org/pod/Test%3A%3AMojo%3A%3ASesssion) via [Test::Mojo::WithRoles](https://metacpan.org/pod/Test%3A%3AMojo%3A%3AWithRoles).

    use Mojolicious::Lite;
    use Test::More;
    use Test::Mojo::WithRoles 'Session';

    get '/set' => sub {
      my $c = shift;
      $c->session(s1 => 'session data');
      $c->session(s3 => [1, 3]);
      $c->render(text => 's1');
    } => 'set';

    my $t = Test::Mojo::WithRoles->new;
    $t->get_ok('/set')
      ->status_is(200)
      ->session_ok
      ->session_has('/s1')
      ->session_is('/s1' => 'session data')
      ->session_hasnt('/s2')
      ->session_is('/s3' => [1, 3])
      ->session_like('/s1' => qr/data/, 's1 contains "data"')
      ->session_unlike('/s1' => qr/foo/, 's1 does not contain "foo"');

    done_testing();

# DESCRIPTION

[Test::Mojo::Session](https://metacpan.org/pod/Test%3A%3AMojo%3A%3ASession) is an extension for the [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo), which allows you
to conveniently test session in [Mojolicious](https://metacpan.org/pod/Mojolicious) applications.

# METHODS

[Test::Mojo::Sesssion](https://metacpan.org/pod/Test%3A%3AMojo%3A%3ASesssion) inherits all methods from [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo) and implements the
following new ones.

## session\_has

    $t = $t->session_has('/foo');
    $t = $t->session_has('/foo', 'session has "foo"');

Check if current session contains a value that can be identified using the given
JSON Pointer with [Mojo::JSON::Pointer](https://metacpan.org/pod/Mojo%3A%3AJSON%3A%3APointer).

## session\_hasnt

    $t = $t->session_hasnt('/bar');
    $t = $t->session_hasnt('/bar', 'session does not have "bar"');

Check if current session does not contain a value that can be identified using the given
JSON Pointer with [Mojo::JSON::Pointer](https://metacpan.org/pod/Mojo%3A%3AJSON%3A%3APointer).

## session\_is

    $t = $t->session_is('/pointer', 'value');
    $t = $t->session_is('/pointer', 'value', 'right value');

Check the session using the given JSON Pointer with [Mojo::JSON::Pointer](https://metacpan.org/pod/Mojo%3A%3AJSON%3A%3APointer).

## session\_like

    $t = $t->session_like('/pointer', qr/value/);
    $t = $t->session_like('/pointer', qr/value/, 'matched value');

Check if current session matches a regular expression.

## session\_unlike

    $t = $t->session_unlike('/pointer', qr/value/);
    $t = $t->session_unlike('/pointer', qr/value/, 'did not match value');

Check if current session does not match a regular expression.

## session\_ok

    $t = $t->session_ok;

Check for existence of the session in user agent.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo).

# AUTHOR

Andrey Khozov, `avkhozov@googlemail.com`.

# CREDITS

Renee, `reb@perl-services.de`

Gene Boggs, `gene.boggs@gmail.com`

# COPYRIGHT AND LICENSE

Copyright (C) 2013-2022, Andrey Khozov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
