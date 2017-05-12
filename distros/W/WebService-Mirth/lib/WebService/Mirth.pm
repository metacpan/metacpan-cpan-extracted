package WebService::Mirth;
{
  $WebService::Mirth::VERSION = '0.131220';
}

# ABSTRACT: Interact with a Mirth Connect server via REST

use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class::MoreCoercions qw( Dir );
use MooseX::Params::Validate qw( validated_list );

use Mojo::URL ();
use Mojo::UserAgent ();

use Path::Class ();
use Log::Minimal qw( debugf warnf croakff );

use aliased 'WebService::Mirth::GlobalScripts' => 'GlobalScripts', ();
use aliased 'WebService::Mirth::CodeTemplates' => 'CodeTemplates', ();
use aliased 'WebService::Mirth::Channel'       => 'Channel',       ();




has server => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


# "Administrator Port"
has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    #default  => 8443,
);


has version => (
    is       => 'ro',
    isa      => 'Str',
    default  => '0.0.0', # "Use 0.0.0 to ignore this property."
    required => 1,
);


has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has base_url => (
    is         => 'ro',
    isa        => 'Mojo::URL',
    lazy_build => 1,
);

sub _build_base_url {
    my ($self) = @_;

    my $base_url = Mojo::URL->new;

    $base_url->scheme('https');
    $base_url->host( $self->server );
    $base_url->port( $self->port );

    return $base_url;
}

has _ua => (
    is      => 'rw',
    isa     => 'Mojo::UserAgent',
    lazy    => 1,
    default => sub { Mojo::UserAgent->new },
);


has code_templates_dom => (
    is         => 'ro',
    isa        => 'Mojo::DOM',
    lazy_build => 1,
);

sub _build_code_templates_dom {
    my ($self) = @_;

    my $url = $self->base_url->clone->path('/codetemplates');

    my $tx = $self->_ua->post_form( $url,
        {   op           => 'getCodeTemplate',
            codeTemplate => '<null/>',
        }
    );

    # (Content-Type will probably be application/xml;charset=UTF-8)
    if ( my $response = $tx->success ) {
        _fix_response_body_xml($response);

        my $code_templates_dom = $response->dom;

        return $code_templates_dom;
    }
    else {
        $self->_handle_tx_error( [ $tx->error ] );
    }
}


has global_scripts_dom => (
    is         => 'ro',
    isa        => 'Mojo::DOM',
    lazy_build => 1,
);

sub _build_global_scripts_dom {
    my ($self) = @_;

    my $url = $self->base_url->clone->path('/configuration');

    my $tx = $self->_ua->post_form( $url, { op => 'getGlobalScripts' } );

    # (Content-Type will probably be application/xml;charset=UTF-8)
    if ( my $response = $tx->success ) {
        _fix_response_body_xml($response);

        my $global_scripts_dom = $response->dom;

        return $global_scripts_dom;
    }
    else {
        $self->_handle_tx_error( [ $tx->error ] );
    }
}


has channels_dom => (
    is         => 'ro',
    isa        => 'Mojo::DOM',
    lazy_build => 1,
);

sub _build_channels_dom {
    my ($self) = @_;

    my $url = $self->base_url->clone->path('/channels');

    my $tx = $self->_ua->post_form( $url,
        {   op      => 'getChannel',
            channel => '<null/>',
        }
    );

    # (Content-Type will probably be application/xml;charset=UTF-8)
    if ( my $response = $tx->success ) {
        _fix_response_body_xml($response);

        my $channels_dom = $response->dom;

        return $channels_dom;
    }
    else {
        $self->_handle_tx_error( [ $tx->error ] );
    }
}


has channel_list => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_channel_list {
    my ($self) = @_;

    my @channel_names = @{
        $self->channels_dom->find( 'channel > name' )
                           ->map ( sub { $_->text } )
    };

    my %channel_list;
    foreach my $name (@channel_names) {
        my $channel = $self->get_channel($name);
        my $id      = $channel->id;

        $channel_list{$name} = $id;
    }

    return \%channel_list;
}

sub BUILD {
    my ($self) = @_;

    $self->login;
}

sub DEMOLISH {
    my ($self) = @_;

    $self->logout;
}


sub login {
    my ($self) = @_;

    my $url = $self->base_url->clone->path('/users');

    debugf( 'Logging in as "%s" at %s', $self->username, $url );
    my $tx = $self->_ua->post_form( $url,
        {   op       => 'login',
            username => $self->username,
            password => $self->password,
            version  => $self->version,
        }
    );


    if ( my $response = $tx->success ) {
    }
    else {
        $self->_handle_tx_error( [ $tx->error ] );
    }

    $tx->success ? return 1 : return 0;
}


sub get_global_scripts {
    my ($self) = @_;

    my $global_scripts = GlobalScripts->new({
        global_scripts_dom => $self->global_scripts_dom
    });

    return $global_scripts;
}


sub export_global_scripts {
    my $self = shift;
    my ($output_dir) = validated_list(
        \@_,
        to_dir => { isa => Dir, coerce => 1 },
    );

    my $global_scripts = $self->get_global_scripts;

    my $filename = 'global_scripts.xml';
    my $output_file = $output_dir->file($filename);

    my $content = $global_scripts->get_content;

    debugf(
        'Exporting global scripts: %s',
        $output_file->stringify
    );
    $output_file->spew($content);
}


sub get_code_templates {
    my ($self) = @_;

    my $code_templates = CodeTemplates->new({
        code_templates_dom => $self->code_templates_dom
    });

    return $code_templates;
}


sub export_code_templates {
    my $self = shift;
    my ($output_dir) = validated_list(
        \@_,
        to_dir => { isa => Dir, coerce => 1 },
    );

    my $code_templates = $self->get_code_templates;

    my $filename = 'code_templates.xml';
    my $output_file = $output_dir->file($filename);

    my $content = $code_templates->get_content;

    debugf(
        'Exporting code templates: %s',
        $output_file->stringify
    );
    $output_file->spew($content);
}


sub get_channel {
    my ( $self, $channel_name ) = @_;

    my $channel_dom = $self->_get_channel_dom($channel_name);

    if ( not defined $channel_dom ) {
        return undef;
    }

    my $channel = Channel->new( { channel_dom => $channel_dom } );

    return $channel;
}

sub _get_channel_dom {
    my ( $self, $channel_name ) = @_;


    my $channel_name_dom =
        $self->channels_dom
             ->find ( 'channel > name' )
             ->first( sub { $_->text eq $channel_name } );

    my $channel_dom;
    if ( defined $channel_name_dom ) {
        $channel_dom = $channel_name_dom->parent;
    }
    else {
        warnf( 'Channel "%s" does not exist', $channel_name );
        return undef;
    }

    return $channel_dom;
}


sub export_channels {
    my $self = shift;
    my ($output_dir) = validated_list(
        \@_,
        to_dir => { isa => Dir, coerce => 1 },
    );

    foreach my $channel_name ( sort keys %{ $self->channel_list } ) {
        my $channel = $self->get_channel($channel_name);

        my $filename = sprintf '%s.xml', $channel->name;
        my $output_file = $output_dir->file($filename);

        my $content = $channel->get_content;

        debugf(
            'Exporting "%s" channel: %s',
            $channel->name, $output_file->stringify
        );
        $output_file->spew($content);
    }
}


sub logout {
    my ($self) = @_;

    my $url = $self->base_url->clone->path('/users');

    debugf('Logging out');
    my $tx = $self->_ua->post_form( $url, { op => 'logout' } );

    if ( my $response = $tx->success ) {
    }
    else {
        $self->_handle_tx_error( [ $tx->error ] );
    }

    $tx->success ? return 1 : return 0;
}


sub _handle_tx_error {
    my $self = shift;
    my ( $message, $code ) = @{ $_[0] };

    if ( defined $code ) {
        croakff(
            'Failed with HTTP code %s: %s',
            $code,
            $message
        );
    }
    else {
        my ( $server, $port ) = map { $self->$_ } qw( server port );
        croakff(
            'HTTP transaction failed: %s',
                $message =~
                    /(Couldn't connect)|(SSL connect attempt failed)/
              ? "cannot reach $server at port $port."
              : $message
        );
    }
}

sub _fix_response_body_xml {
    my ($response) = @_;

    # XXX Hack: Append XML declaration to ensure that XML semantics
    # are turned on when the Mojo::DOM object is created (via
    # Mojo::Message::dom())
    my $body = $response->body;
    $body = qq{<?xml version="1.0"?>\n$body};
    $response->body($body);
}



__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WebService::Mirth - Interact with a Mirth Connect server via REST

=head1 VERSION

version 0.131220

=head1 SYNOPSIS

    my $mirth = WebService::Mirth->new(
        server   => 'mirth.example.com',
        port     => 8443,
        username => 'admin',
        password => 'password',
    );

    $mirth->export_channels({
        to_dir => 'path/to/export/to/'
    });

    $mirth->export_global_scripts({
        to_dir => 'path/to/export/to/'
    });

    $mirth->export_code_templates({
        to_dir => 'path/to/export/to/'
    });

=head1 DESCRIPTION

Mirth Connect is an open-source Java-powered application used for
healthcare integration.  Incoming HL7 or XML feeds containing electronic
medical records can be parsed and then handled (munged, stored, sent
off, etc) by Mirth Connect.

This module provides a pure-Perl means of RESTful interaction with a
Mirth Connect server (referred to as "Mirth" going forward).  The
functionality is similar to what the "Mirth Shell" program provides
within a Mirth installation.

Parser code living in Mirth can be exported as XML files locally, for
off-site archival.

L<Mojo::DOM> objects in some of the L</ATTRIBUTES> could be used for
inspecting or altering the channels locally (ie. turn a channel off by
changing the "enabled" node from "true" to "false").

The L</login> and L</logout> methods will automatically be called as
needed.

All internal HTTP interactions are performed via L<Mojo::UserAgent>, so
the C<MOJO_USERAGENT_DEBUG> environment variable can be set to 1 to turn
on HTTP debugging.

L<Log::Minimal> is used for application logging, so the C<LM_DEBUG>
environment variable can be set to 1 for additional debugging.

=begin comment

API was construed from reading the source code at:
https://svn.mirthcorp.com/connect/tags/2.1.1/server/src/com/mirth/connect/

Java classes studied:

- server/src/com/mirth/connect/client/core/Operations.java
- server/src/com/mirth/connect/client/core/Client.java
- command/src/com/mirth/connect/cli/CommandLineInterface.java
- server/src/com/mirth/connect/client/core/ServerConnection.java
- server/src/com/mirth/connect/client/core/ServerConnectionFactory.java
- server/src/com/mirth/connect/model/converters/ObjectXMLSerializer.java
- server/src/com/mirth/connect/model/Channel.java
- command/src/com/mirth/connect/cli/Token.java

Documentation on "Mirth Shell" is at:
http://www.mirthcorp.com/community/wiki/display/mirthuserguidev1r8p0/Mirth+Shell

=end comment

=head1 ATTRIBUTES

=head2 server

A string containing the FQDN (see L</CAVEATS>) of the Mirth server to
connect to.

=head2 port

The Jetty port that Mirth is listening on for HTTP.

=head2 version

A string containing the version of Mirth that the L</server> is hosting.
This value is required by Mirth for HTTP interaction.

Defaults to "0.0.0", which should be sufficient.

=head2 username

The name of the user to connect with.  "admin" is likely a good choice:
full administrative privileges are ideal.

=head2 password

The corresponding password for the L</username> being used.

=head2 base_url

A L<Mojo::URL> object that represents the HTTP address of the Mirth
server.  The RESTful HTTP requests will be made based on this URL.

Mirth uses HTTPS, so it will be constructed into something like
C<https://mirth.example.com:8443>.

=head2 code_templates_dom

A L<Mojo::DOM> object of the XML representing the "Code Templates" in
Mirth.  Used by L</get_code_templates> to create a
L<WebService::Mirth::CodeTemplates> object.

=head2 global_scripts_dom

A L<Mojo::DOM> object of the XML representing the "Global Scripts" in
Mirth.  Used by L</get_global_scripts> to create a
L<WebService::Mirth::GlobalScripts> object.

=head2 channels_dom

A L<Mojo::DOM> object of the XML representing all of the channels in
Mirth.  Massaged by L</get_channel> to return a
L<WebService::Mirth::Channel> object.

Also used in the construction of L</channel_list>.

=head2 channel_list

Contains a hashref representing all of the channels in Mirth.  The key
is a channel name and the value is the corresponding channel ID.

=head1 METHODS

=head2 login

    $mirth->login;

Login as L</username> at the C</users> URI, via an HTTP POST.  If
authentication is successful, starts a session that persists until
L</logout> is called.

This method is automatically called upon object construction.

=begin comment

Mirth Connect version 2.1.1.5490 will return:

true

...with Content-Type text/plain;charset=ISO-8859-1 .

Mirth Connect version 2.2.1.5861 will return:

  <com.mirth.connect.model.LoginStatus>
    <status>SUCCESS</status>
    <message></message>
  </com.mirth.connect.model.LoginStatus>

...with Content-Type text/plain;charset=UTF-8 .

=end comment

=head2 get_global_scripts

    $global_scripts = $mirth->get_global_scripts;

Returns a L<WebService::Mirth::GlobalScripts> object of the "Global
Scripts" in Mirth.

=head2 export_global_scripts

    $mirth->export_global_scripts({
        to_dir => 'path/to/export/to/'
    });

Given a path to a directory in the C<to_dir> parameter, writes an XML
file named C<global_scripts.xml> to the directory.

=head2 get_code_templates

    $code_templates = $mirth->get_code_templates;

Returns a L<WebService::Mirth::CodeTemplates> object of the "Code
Templates" in Mirth.

=head2 export_code_templates

    $mirth->export_code_templates({
        to_dir => 'path/to/export/to/'
    });

Given a path to a directory in the C<to_dir> parameter, writes an XML
file named C<code_templates.xml> to the directory.

=head2 get_channel

    $channel = $mirth->get_channel('foobar');
    print $channel->name, "\n";    # "foobar"
    print $channel->id, "\n";      # "a25ea24c-d8f4-439a-9063-62f8a2b6a4b1"
    print $channel->enabled, "\n"; # "true"

Given the name of a channel in Mirth, returns a
L<WebService::Mirth::Channel> object.

=begin comment

Find the "name" node of the channel desired, then get its parent
("channel").  To find a channel named "quux", find the name node
containing "quux", then get its parent (the channel node):

  <channel>
      <id>dc444818-9b64-42db-9d59-3d478c9ea3ef</id>
      <name>quux</name>
      <description>This channel feeds.</description>
  ...
  </channel>

=end comment

=head2 export_channels

    $mirth->export_channels({
        to_dir => 'path/to/export/to/'
    });

Given a path to a directory in the C<to_dir> parameter, writes XML files
(with names like C<my_channel.xml>) to the directory.

=head2 logout

    $mirth->logout;

Ends the session initiated by L</login>.

This method is automatically called upon object destruction.

=head1 TODO

=over

=item Add feature to put channels onto a Mirth box

=back

=head1 CAVEATS

=head2 Server specification and session cookies

It seems that an FQDN (fully-qualified domain name) is required for
L</server> in order for the session started by L</login> (involving
cookies) to stick.

For example, an IP address for L</server> is not sufficient.  A
workaround could be adding an entry to C</etc/hosts> with something like
"mirth.localhost" (in which case, see hosts(1)).

=head1 SEE ALSO

=over

=item L<http://www.mirthcorp.com/products/mirth-connect>

=item L<http://www.mirthcorp.com/community/wiki/display/mirthuserguidev1r8p0/Introduction>

=item L<http://www.mirthcorp.com/community/wiki/display/mirthuserguidev1r8p0/Mirth+Shell>

=item L<Mojo::DOM>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the Informatics Corporation of America (ICA) for sponsoring the
development of this module.

=head1 AUTHOR

Tommy Stanton <tommystanton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tommy Stanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

