# NAME

XML::Atom::Server::PSGI - XML::Atom::Server for PSGI

# SYNOPSIS

    use XML::Atom::Server::PSGI;

    my $server = XML::Atom::Server::PSGI->new(
        callbacks => {
            on_password_for_user => sub { ... }
            on_handle_request => sub { ... }
        }
    );
    $server->psgi_app;

    package MyServer;
    use strict;
    use base qw(XML::Atom::Server::PSGI);

    sub handle_request {
        ...
    }

    1;

    MyServer->new->psgi_app;

# DESCRIPTION

XML::Atom::Server::PSGI is a drop in replacement for XML::Atom::Server, which assumes either mod\_perl or CGI environment. This module assumes, you guessed it, that you use it from a PSGI compatible app.

# LICENSE

Copyright (C) Daisuke Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke Maki <lestrrat+github@gmail.com>
