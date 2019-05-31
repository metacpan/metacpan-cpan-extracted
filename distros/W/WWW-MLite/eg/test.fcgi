#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: test.fcgi 44 2019-05-31 10:06:54Z minus $
#
# Test script for demonstration of FastCGI work
#
#########################################################################
use strict;
use utf8;

=encoding utf8

=head1 NAME

Example of FastCGI test

=head1 SYNOPSIS

    <Location /fcgi>
        SetHandler "proxy:fcgi://localhost:8765"
    </Location>

=head1 DESCRIPTION

The FastCGI script demonstrate various examples of how WWW::MLite work.

=cut

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use base qw/ WWW::MLite /;

use File::Spec;
use Data::Dumper;
use HTTP::Status qw/:constants :is/;
use CGI::Fast(
        socket_path  => 'localhost:8765',
        listen_queue => 50
    );
use CGI qw//;

use constant {
    PROJECTNAME => "MyApp",
    CONFIG_DIR  => "conf",
};

my $handling_request = 0;
my $exit_requested = 0;
my $sig_handler = sub {
    $exit_requested = 1;
    exit(0) if !$handling_request;
};
$SIG{USR1} = $sig_handler;
$SIG{TERM} = $sig_handler;
$SIG{PIPE} = 'IGNORE';

=head1 METHODS

WWW::MLite methods

=head2 GET /fcgi

    curl -v --raw http://localhost/fcgi

    > GET /fcgi HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 09:06:27 GMT
    < Server: WWW::MLite/2.00
    < Connection: close
    < Content-Length: 467
    < Vary: Accept-Encoding
    < Content-Type: text/plain
    <
    {
      'attrs' => {
        'bar' => 'on',
        'deserialize' => 0,
        'foo' => 'blah-blah-blah',
        'serialize' => 1
      },
      'description' => 'Index page',
      'method' => 'GET',
      'name' => 'getIndex',
      'params' => [
        bless( {
          '.charset' => 'ISO-8859-1',
          '.fieldnames' => {},
          '.parameters' => [],
          'escape' => 1,
          'param' => {},
          'use_tempfile' => 1
        }, 'CGI::Fast' )
      ],
      'path' => '/fcgi',
      'requires' => [],
      'returns' => {}
    }

=cut

__PACKAGE__->register_method( # GET /fcgi
    name    => "getIndex",
    description => "Index page",
    method  => "GET",
    path    => "/fcgi",
    deep    => 0,
    attrs   => {
            foo         => 'blah-blah-blah',
            bar         => 'on',
            deserialize => 0,
            serialize   => 1,
        },
    requires => undef,
    returns => undef,
    code    => sub {
### CODE:
    my $self = shift;
    my @params = @_;

    $self->data(explain({
            params => [@params],
            name   => $self->name,
            description => $self->info("description"),
            attrs  => $self->info("attrs"),
            path   => $self->info("path"),
            method => $self->info("method"),
            requires => $self->info("requires"),
            returns => $self->info("returns"),
        }));
    #$self->data("Blah-Blah-Blah!\nЭто мой текст :)");
    return HTTP_OK; # HTTP RC
});

=head2 GET /fcgi/dump

    curl -v --raw http://localhost/fcgi/dump

    > GET /fcgi/dump HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 09:07:37 GMT
    < Server: WWW::MLite/2.00
    < Connection: close
    < Content-Length: 3384
    < Vary: Accept-Encoding
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # GET /fcgi/dump
    name    => "getDump",
    method  => "GET",
    path    => "/fcgi/dump",
    deep    => 0,
    attrs   => {},
    description => "Test (GET dump)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain($self));
    return HTTP_OK; # HTTP RC
});

=head2 GET /fcgi/env

    curl -v --raw http://localhost/fcgi/env

    > GET /fcgi/env HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 09:08:37 GMT
    < Server: WWW::MLite/2.00
    < Connection: close
    < Content-Length: 1037
    < Vary: Accept-Encoding
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # GET /fcgi/env
    name    => "getEnv",
    method  => "GET",
    path    => "/fcgi/env",
    deep    => 0,
    attrs   => {},
    description => "Test (GET env)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain(\%ENV));
    return HTTP_OK; # HTTP RC
});

my $server = __PACKAGE__->new(
    project     => PROJECTNAME,
    ident       => lc(PROJECTNAME),
    root        => File::Spec->catdir($Bin, CONFIG_DIR),
    #confopts    => {... Config::General options ...},
    configfile  => File::Spec->catfile($Bin, CONFIG_DIR, sprintf("%s.conf", lc(PROJECTNAME))),
    log         => "on",
    #logfd       => fileno(STDERR),
    #logfile     => '/path/to/log/file.log',
    logfacility => 24, # Sys::Syslog::LOG_DAEMON
    nph         => 0, # NPH (no-parsed-header)
);

# FastCGI worker
while (my $q = CGI::Fast->new) {
    print $server->call($q->request_method, $q->request_uri, $q) or die($server->error);
    $handling_request = 0;
    last if $exit_requested;
}
exit(0);

sub explain {
    my $dumper = new Data::Dumper( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}

1;

=head1 SEE ALSO

L<CGI>, L<HTTP::Message>, L<CGI::Fast>, L<http://httpd.apache.org/docs/2.4/mod/mod_proxy_fcgi.html>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

__END__
