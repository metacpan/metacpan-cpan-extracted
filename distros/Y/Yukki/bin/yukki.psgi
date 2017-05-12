#!/usr/bin/env plackup
use 5.12.1;

use Plack::App::File;
use Plack::Builder;
use YAML qw( LoadFile );

use Yukki::Web;

my $server = Yukki::Web->new;
my $app = sub {
    my $env = shift;
    return $server->dispatch($env);
};

builder {
    mount "/style"    => Plack::App::File->new( root => $server->locate_dir('static_path', 'style') );
    mount "/script"   => Plack::App::File->new( root => $server->locate_dir('static_path', 'script') );
    mount "/template" => Plack::App::File->new( root => $server->locate_dir('static_path', 'template') );

    mount "/"       => builder { 
        enable $server->session_middleware;

        $app;
    };
};

# ABSTRACT: the Yukki web application
# PODNAME: yukki.psgi

__END__

=pod

=head1 NAME

yukki.psgi - the Yukki web application

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  yukki.psgi

=head1 DESCRIPTION

If you have L<Plack> installed, you should be able to run this script from the
command line to start a simple test server. It is not recommend that you use
this web server in production.

See L<Yukki::Manual::Installation>.

=head1 ENVIRONMENT

Normally, this script tries to find F<etc/yukki.conf> from the current working
directory. If no configuraiton file is found, it checks C<YUKKI_CONFIG> for the
path to this file.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
