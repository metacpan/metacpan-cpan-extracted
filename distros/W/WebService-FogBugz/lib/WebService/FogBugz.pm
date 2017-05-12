package WebService::FogBugz;

use warnings;
use strict;

our $VERSION = '0.1.2';

#----------------------------------------------------------------------------
# Library Modules

use LWP::UserAgent;
use WebService::FogBugz::Config;
use XML::Liberal;
use XML::LibXML;

#----------------------------------------------------------------------------
# Public API

sub new {
    my $class = shift;
    my $param = { @_ };
    my $atts = {};

    my $self = bless $atts, $class;
    $self->{UA} = $param->{ua} || LWP::UserAgent->new;
    $self->{UA}->agent(__PACKAGE__.'/'.$VERSION);
    $self->{PARSER} = XML::Liberal->new('LibXML');

    die 'no configuration parameters'
        unless $param;

    $self->{CONFIG} = WebService::FogBugz::Config->new( %$param );
    die 'no configuration parameters'
        unless $self->{CONFIG};

    die 'no instance of FogBugz specified '
        unless $self->{CONFIG}->base_url;
    die 'no login details of FogBugz instance specified '
        unless ($self->{CONFIG}->token || ($self->{CONFIG}->email && $self->{CONFIG}->password));

    $self->logon;
    die 'unable to log into the specified instance of FogBugz'
        unless $self->{token};

#    $self->{COMMAND} = WebService::FogBugz::Command->new(
#        base_url    => $self->{CONFIG}->base_url,
#        token       => $self->{token}
#    );

    return $self;
}

sub logon {
    my $self = shift;

    if($self->{CONFIG}->token) {
        $self->{token} = $self->{CONFIG}->token;

    } else {
        my $res = $self->{UA}->get(
            $self->{CONFIG}->base_url
            . '?cmd=logon'
            . '&email=' . $self->{CONFIG}->email
            . '&password=' . $self->{CONFIG}->password);

        return  if ($self->_is_error($res->content));
    
        my $doc = $self->{PARSER}->parse_string($res->content);
        $self->{token} = $doc->findvalue("//*[local-name()='response']/*[local-name()='token']/text()");
    }

    return $self->{token};
}

sub logoff {
    my $self = shift;
    my $res = $self->{UA}->get(
        $self->{CONFIG}->base_url
        . '?cmd=logoff'
        . '&token=' . $self->{token});

    return  if ($self->_is_error($res->content));

    delete $self->{token};
    return;
}

sub request_method {
    my ($self, $cmd, $param) = @_;
    my $query = join('', map {'&' . $_ . '=' . $param->{$_}} keys(%$param));
    my $res = $self->{UA}->get(
        $self->{CONFIG}->base_url
        . '?cmd=' . $cmd
        . '&token=' . $self->{token}
        . $query);

    return  if ($self->_is_error($res->content));

    return $res->content;
}

sub _is_error {
    my ($self, $content)  = @_;
    $content =~ s/<\?xml\s+.*?\?>//g;
    return 1    unless($content && $content =~ /</);

    my $doc  = $self->{PARSER}->parse_string($content);
    $self->{error}{code} = $doc->findvalue("//*[local-name()='response']/*[local-name()='error']/\@code");
    $self->{error}{msg}  = $doc->findvalue("//*[local-name()='response']/*[local-name()='error']/text()");
    return $self->{error}{code} ? '1' : '0';
}

1;

__END__

=head1 NAME

WebService::FogBugz - FogBugz API for Perl

=head1 SYNOPSIS

    use WebService::FogBugz;

    my $fogbugz = WebService::FogBugz->new({
        # optional
        config      => 'fbrc',

        # mandatory, if no config option
        base_url    => 'http://yourfogbugz.example.com/api.asp',

        # preprepared credentials
        token       => 'mytoken',

        # alternative credentials
        email       => 'yourmail@example.com',
        password    => 'yourpassword',
    });

    $fogbugz->logon;

    # your request.
    my $xml = $fogbugz->request_method('search', {
        q => 'WebService',
    });

    $fogbugz->logoff;

=head1 DESCRIPTION

This module provides a Perl interface for the FogBugz API. FogBugz is a 
project management system.

=head1 CONSTRUCTOR

=head2 new([%options])

This method returns an instance of this module. 

In order to process commands for the FogBugz API, certain configuration details
are required. However, there are a few ways these can be presented. 
Configuration values can be provided as options to the constructor, or via a
configuration file.

The constructor options can be one or more of the following:

=over

=item * config

The file path to a configuration file. See below for further details regarding 
the configuration file.

Note: If no configuration file is found, all credentials must be provided as 
constructor options.

=item * base_url

Your FogBugz API's URL. See below for more details regarding the base URL.

=item * token

Your personal token for accessing FogBugz.

=item * email

Your login email address used for logging in to FogBugz.

=item * password

Your login password used for logging in to FogBugz.

=back

=head1 CONFIGURATION

=head2 Configuration File

If no file is given as a configuration option, the environment variable 'FBRC'
is checked. If still no file is defined, the file '.fbrc' is looked for in the
local directory followed by your home directory.

If a file is found, and readable, it is read and its contents are extracted
into configuration variables. The file may look like the one of the following
examples.

Example 1:

  URL=https://example.com/fogbugz/api.asp
  TOKEN=mytoken

Example 2:

  URL=https://example.fogbugz.com/api.asp
  EMAIL=me@example.com
  PASSWORD=mypassword

Note that constructor options can be used to override these values if required.

=head2 Base URL

This may be a hosted instance 
(e.g. https://example.fogbugz.com/api.asp?) or a local installation
(e.g. http://www.example.com/fogbugz/api.asp).

If you're unsure about your base_url, check the url field of an XML request.
For example, if using a local installation, such as 
http://www.example.com/fogbugz, check the URL as 
http://www.example.com/fogbugz/api.xml. If you have a FogBugz On Demand account
the link will be https://example.fogbugz.com/api.xml, where example is your 
account name.

=head1 ACCESS METHODS

The following are used as convenience methods, as they are not necessarily 
required, but are used by the older version of this distribution, and are 
maintained for backwards compatibility.

=head2 logon

Retrieves an API token from Fogbugz.

=head2 logoff

Log off from FogBugz.

=head1 COMMAND METHODS

=head2 request_method($command,$hash)

The 1st argument is the name of command you wish to action, and the 2nd 
argument is the hash of parameters for the specified command.

FogBugz supports many commands, which you can find from FogBugz Online 
Documentation by using keyword of 'cmd'.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-fogbugz@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::FogBugz

You can also look for information at:

=over 4

=item * FogBugz Online Documentation

L<http://help.fogcreek.com/fogbugz>

=item * FogBugz Online Documentation - API

L<http://help.fogcreek.com/8202/xml-api>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-FogBugz>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-FogBugz>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-FogBugz>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-FogBugz>

=back

=head1 AUTHORS

Original Author: Takatsugu Shigeta  C<< <shigeta@cpan.org> >>

Current Maintainer: Barbie  C<< <barbie@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

  Copyright (c) 2007-2014, Takatsugu Shigeta C<< <shigeta@cpan.org> >>.
  Copyright (c) 2014-2015, Barbie for Miss Barbell Productions. 
  All rights reserved.

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
