package XML::Atom::Server::PSGI;
use strict;
use Digest::SHA1 ();
use MIME::Base64 ();
use Plack::Request;
use Scope::Guard ();
use XML::Atom::Entry;
use XML::Atom::Util ();

use Class::Accessor::Lite
    rw => [ qw(callbacks request response xml_parser) ],
;

use constant NS_SOAP => 'http://schemas.xmlsoap.org/soap/envelope/';
use constant NS_WSSE => 'http://schemas.xmlsoap.org/ws/2002/07/secext';
use constant NS_WSU => 'http://schemas.xmlsoap.org/ws/2002/07/utility';


our $VERSION = "0.04";

sub psgi_app {
    my $self = shift;
    return sub {
        $self->handle_psgi(@_);
    };
}

# alias
*req = \&request;
*res = \&response;

sub new {
    my $klass = shift;
    my $self  = bless {
        (@_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_),
    }, $klass;
    if (! $self->xml_parser()) {
        $self->xml_parser(XML::Atom::Server::PSGI::XMLParser->new);
    }
    if (! $self->callbacks) {
        $self->callbacks({});
    }
    return $self;
}

sub handle_psgi {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->content_type('application/x.atom+xml');

    $self->request($req);
    $self->response($res);
    # Make sure these things are all cleaned up afterwards
    my $guard = Scope::Guard->new(sub {
        $self->request(undef);
        $self->response(undef);
    });

    $env->{'xml.atom.server.request_method'} = $req->method;

    # Process parameters in path_info
    my $path_info = $req->path_info;
    my $params    = Hash::MultiValue->new;
    $path_info =~ s/^\///;
    foreach my $arg (split /\//, $path_info) {
        my ($k, $v) = split /=/, $arg, 2;
        $params->add($k, $v);
    }
    $env->{'xml.atom.server.request_params'} = $params;

    if (my $action = $req->header('SOAPAction')) {
        $env->{'xml.atom.server.is_soap'} = 1;
        $action =~ s/"//g;
        my ($method) = $action =~ m!/([^/]+)$!;
        $env->{'xml.atom.server.request_method'} = $method;
    }

    eval {
        $self->_call('handle_request');
        if ($self->is_soap) {
            my $body = $res->body;
            if (defined $body) {
                $body =~ s!^(<\?xml.*?\?>)!!;
                $body = <<SOAP;
$1
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>$body</soap:Body>
</soap:Envelope>
SOAP
                $res->body($body);
            }
        }
    };
    if (my $E = $@) {
        # Escape 
        $E =~ s/</&lt;/g;
        $E =~ s/>/&gt;/g;
        $res->code(500);
        $res->body(<<EOXML);
<?xml version="1.0" encoding="UTF-8"?>
<error>$E</error>
EOXML
    }

    return $res->finalize;
}

# for compat
sub request_param {
    shift->request_params->get(@_);
}

sub request_params {
    return $_[0]->req->env->{'xml.atom.server.request_params'};
}

# for compat
sub request_content {
    shift->req->content;
}

# for compat
sub uri {
    return $_[0]->req->uri;
}

# for compat
sub request_method {
    return $_[0]->req->env->{'xml.atom.server.request_method'};
}

# for compat
sub request_header {
    return $_[0]->req->header($_[1]);
}

# for compat
sub response_header {
    return shift->res->header(@_);
}

# for compat
sub response_content_type {
    return shift->res->content_type(@_);
}

# for compat
sub response_code {
    return shift->res->code(@_);
}

# for compat
sub is_soap {
    return $_[0]->req->env->{'xml.atom.server.is_soap'};
}

sub _call {
    my ($self, $name, @args) = @_;

    my $cb = $self->callbacks->{"on_$name"} ||
        $self->can($name);
    if (! $cb) {
        Carp::croak("no callback nor overridden method $name found");
    }
    return $cb->($self, @args);
}

sub get_auth_info {
    my $self = shift;

    my $req = $self->req;
    my %param; # XXX Hash::MultiValue?
    if ($self->is_soap) {
        my $xml = $self->xml_body;
        my $auth = XML::Atom::Util::first($xml, NS_WSSE, 'UsernameToken');
        $param{Username} = XML::Atom::Util::textValue($auth, NS_WSSE, 'Username');
        $param{PasswordDigest} = XML::Atom::Util::textValue($auth, NS_WSSE, 'Password');
        $param{Nonce} = XML::Atom::Util::textValue($auth, NS_WSSE, 'Nonce');
        $param{Created} = 
            # Using XML::Atom::Client, Created comes with WSU namespace,
            # but some the original code in XML::Atom::Server only looks
            # at WSSE
            XML::Atom::Util::textValue($auth, NS_WSSE, 'Created') ||
            XML::Atom::Util::textValue($auth, NS_WSU, 'Created');
    } else {
        my $wsse = $req->header('X-WSSE');
        if (! $wsse) {
            $self->auth_failure(401, 'X-WSSE authentication required');
            return;
        }

        $wsse =~ s/^(?:WSSE|UsernameToken) //;
        for my $i (split /,\s*/, $wsse) {
            my($k, $v) = split /=/, $i, 2;
            $v =~ s/^"//;
            $v =~ s/"$//;
            $param{$k} = $v;
        }
    }
    return \%param;
}

sub authenticate {
    my $self = shift;
    my $auth = $self->get_auth_info;
    if (! $auth) {
        return;
    }

    for my $f (qw( Username PasswordDigest Nonce Created )) {
        if (! $auth->{$f}) {
            $self->auth_failure(400, "X-WSSE requires $f");
            return;
        }
    }
    my $password = $self->_call('password_for_user', $auth->{Username});
    if (! defined $password) {
        $self->auth_failure(403, 'Invalid login');
        return;
    }

    my $expected = MIME::Base64::encode_base64(
        Digest::SHA1::sha1(
            MIME::Base64::decode_base64($auth->{Nonce}) .
            $auth->{Created} .
            $password
        ),
    '');
    if ($expected ne $auth->{PasswordDigest}) {
        $self->auth_failure(403, 'Invalid login');
        return;
    }
    return 1;
}

sub auth_failure {
    my ($self, $code, $reason) = @_;
    my $res = $self->res;
    $res->header('WWW-Authenticate', 'WSSE profile="UsernameToken"');
    $self->error($code, $reason);
}

sub error {
    my ($self, $code, $reason) = @_;
    my $res = $self->res;
    $res->code($code);
    # XXX PSGI doesn't really give us a way to override the
    # message portion of response status line, so shove it in
    # X-Reason header
    $res->header('X-Reason', $reason);
}

sub xml_body {
    my $self = shift;

    my $req = $self->req;
    my $env = $req->env;
    my $body = $env->{'xml.server.xml_body'};
    if (defined $body) {
        return $body;
    }

    $body = $self->xml_parser->parse_string($req->content);
    if (defined $body) {
        $env->{'xml.server.xml_body'} = $body;
    }
    return $body;
}

sub atom_body {
    my $self = shift;

    my $req = $self->req;
    my $env = $req->env;
    my $atom;
    if ($self->is_soap) {
        my $xml = $self->xml_body;
        $atom = XML::Atom::Entry->new(Doc => XML::Atom::Util::first($xml, NS_SOAP, 'Body'));
    } else {
        $atom = XML::Atom::Entry->new(Stream => \$req->content);
    }
    return $atom;
}

package
    XML::Atom::Server::PSGI::XMLParser;
use strict;
use Class::Accessor::Lite
    new => 1,
    rw  => [ qw(parser) ]
;
BEGIN {
    if (! XML::Atom::LIBXML) {
        require XML::XPath;
        XML::XPath->import;
    }
}

sub parse_string {
    my ($self, $string) = @_;

    if (XML::Atom::LIBXML) {
        my $parser = $self->parser;
        if (! $parser) {
            $parser = XML::Atom->libxml_parser;
            $self->parser($parser);
        }
        return $parser->parse_string($string);
    } else {
        return XML::XPath->new(xml => $string);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

XML::Atom::Server::PSGI - XML::Atom::Server for PSGI

=head1 SYNOPSIS

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

=head1 DESCRIPTION

XML::Atom::Server::PSGI is a drop in replacement for XML::Atom::Server, which assumes either mod_perl or CGI environment. This module assumes, you guessed it, that you use it from a PSGI compatible app.

=head1 LICENSE

Copyright (C) Daisuke Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Maki E<lt>lestrrat+github@gmail.comE<gt>

=cut

