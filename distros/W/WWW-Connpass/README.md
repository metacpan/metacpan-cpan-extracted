# NAME

WWW::Connpass - browser for connpass(R)

# SYNOPSIS

    use WWW::Connpass;

    my $client = WWW::Connpass->new;
    my $session = $client->login('username', 'password');
    my @events = $session->fetch_organized_events();
    for my $event (@events) {
        # ...
    }

    my $event = $session->new_event(title => '');
    $event = $event->edit(
        ...
    );

# DESCRIPTION

WWW::Connpass is browser for [http://connpass.com/](http://connpass.com/).

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
