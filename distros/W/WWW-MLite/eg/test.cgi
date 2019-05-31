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
# $Id: test.cgi 44 2019-05-31 10:06:54Z minus $
#
# Test script for demonstration of classical CGI work
#
#########################################################################
use strict;
use utf8;

=encoding utf8

=head1 NAME

Example of CGI test

=head1 SYNOPSIS

    ScriptAlias "/myapp" "/path/to/test.cgi"
    # ... or:
    # ScriptAliasMatch "^/myapp" "/path/to/test.cgi"

=head1 DESCRIPTION

The script demonstrate various examples of how WWW::MLite work.

=cut

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use base qw/ WWW::MLite /;

use CGI;
use File::Spec;
use Data::Dumper;
use HTTP::Status qw/:constants :is/;

use constant {
    PROJECTNAME => "MyApp",
    CONFIG_DIR  => "conf",
};

my $q = new CGI;

=head1 METHODS

WWW::MLite methods

=head2 GET /myapp

    curl -v --raw http://localhost/myapp

    > GET /myapp HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 05:37:27 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 462
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
        }, 'CGI' )
      ],
      'path' => '/myapp',
      'requires' => [],
      'returns' => {}
    }

=cut

__PACKAGE__->register_method( # GET /myapp
    name    => "getIndex",
    description => "Index page",
    method  => "GET",
    path    => "/myapp",
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

=head2 GET /myapp/foo

    curl -v --raw http://localhost/myapp/foo

    > GET /myapp/foo HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 05:41:34 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 16
    < Content-Type: text/plain
    <
    Blah-Blah-Blah!

=cut

__PACKAGE__->register_method( # GET /myapp/foo
    name    => "getTest",
    method  => "GET",
    path    => "/myapp/foo",
    deep    => 1,
    attrs   => {
            serialize       => 1,
        },
    description => "Test (GET foo)",
    code    => sub {
### CODE:
    my $self = shift;
    my @params = @_;

    $self->data("Blah-Blah-Blah!");

    return HTTP_OK; # HTTP RC
});

=head2 GET /myapp/void

    curl -v --raw http://localhost/myapp/void

    > GET /myapp/void HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 204 No Content
    < Date: Fri, 31 May 2019 06:03:53 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # GET /myapp/void
    name    => "Test (Void)",
    method  => "GET",
    path    => "/myapp/void",
    deep    => 1,
    attrs   => {},
    description => "Test (Void)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->log_info($self->info("description"));
    return HTTP_NO_CONTENT;
});

=head2 GET /myapp/dump

    curl -v --raw http://localhost/myapp/dump

    > GET /myapp/dump HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 06:04:49 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 3912
    < Vary: Accept-Encoding
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # GET /myapp/dump
    name    => "getDump",
    method  => "GET",
    path    => "/myapp/dump",
    deep    => 0,
    attrs   => {},
    description => "Test (GET dump)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain($self));
    return HTTP_OK; # HTTP RC
});

=head2 GET /myapp/env

    curl -v --raw http://localhost/myapp/env

    > GET /myapp/env HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 06:45:29 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 1007
    < Vary: Accept-Encoding
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # GET /myapp/env
    name    => "getEnv",
    method  => "GET",
    path    => "/myapp/env",
    deep    => 0,
    attrs   => {},
    description => "Test (GET env)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain(\%ENV));
    return HTTP_OK; # HTTP RC
});

=head2 POST /myapp

    curl -v -d '{"object": "list_services"}' --raw -H "Content-Type: application/json" http://localhost/myapp

    > POST /myapp HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 27
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 06:51:16 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 27
    < Content-Type: text/plain
    <
    {"object": "list_services"}

=cut

__PACKAGE__->register_method( # POST /myapp
    name    => "postData",
    method  => "POST",
    path    => "/myapp",
    deep    => 0,
    attrs   => {},
    description => "POST Test",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    $self->data($q->param("POSTDATA"));
    return HTTP_OK; # HTTP RC
});

=head2 PUT /myapp

    curl -X PUT -v -d 'My post data' --raw -H "Content-Type: text/plain" http://localhost/myapp

    > PUT /myapp HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: text/plain
    > Content-Length: 12
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 06:55:00 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 12
    < Content-Type: text/plain
    <
    My post data

=cut

__PACKAGE__->register_method( # PUT /myapp
    name    => "putData",
    method  => "PUT",
    path    => "/myapp",
    deep    => 0,
    attrs   => {},
    description => "PUT Test",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    $self->data($q->param("PUTDATA"));
    return HTTP_OK; # HTTP RC
});

=head2 PATCH /myapp

    curl -X PATCH -v -d 'My patch data' --raw -H "Content-Type: text/plain" http://localhost/myapp

    > PATCH /myapp HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: text/plain
    > Content-Length: 13
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 06:57:28 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 13
    < Content-Type: text/plain
    <
    My patch data

=cut

__PACKAGE__->register_method( # PATCH /myapp
    name    => "patchData",
    method  => "PATCH",
    path    => "/myapp",
    deep    => 0,
    attrs   => {},
    description => "PATCH Test",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    $self->data($q->param("PATCHDATA"));
    return HTTP_OK; # HTTP RC
});

=head2 DELETE /myapp

    curl -v --raw -X DELETE http://localhost/myapp

    > DELETE /myapp HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 204 No Content
    < Date: Fri, 31 May 2019 07:00:45 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # DELETE /myapp
    name    => "delete",
    method  => "DELETE",
    path    => "/myapp",
    deep    => 0,
    attrs   => {},
    description => "DELETE Test",
    code    => sub {
### CODE:
    return HTTP_NO_CONTENT; # HTTP RC
});


my $server = __PACKAGE__->new(
    project     => PROJECTNAME,
    ident       => lc(PROJECTNAME),
    root        => File::Spec->catdir($Bin, CONFIG_DIR),
    #confopts    => {... Config::General options ...},
    configfile  => File::Spec->catfile($Bin, CONFIG_DIR, sprintf("%s.conf", lc(PROJECTNAME))),
    log         => "on",
    logfd       => fileno(STDERR),
    #logfile     => '/path/to/log/file.log',
    nph         => 0, # NPH (no-parsed-header)
);
print $server->call($q->request_method, $q->request_uri, $q) or die($server->error);

sub explain {
    my $dumper = new Data::Dumper( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}

1;

=head1 SEE ALSO

L<CGI>, L<HTTP::Message>

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
