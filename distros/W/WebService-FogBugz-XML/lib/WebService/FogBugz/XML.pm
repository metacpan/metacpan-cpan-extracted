package WebService::FogBugz::XML;

use Moose;
use v5.10;

use common::sense;
use Config::Any;
use Data::Dumper;
use HTTP::Request;
use IO::Prompt;
use LWP::UserAgent;
use WebService::FogBugz::XML::Case;
use XML::LibXML;

our $VERSION = '1.0002';

use namespace::autoclean;

has config_filename => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { (glob "~/.fb.conf")[0] } #Glob returns iterator if called in scalar context
    );
has token_filename => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { (glob "~/.fb_auth_token")[0] }
    );

has config => (
    isa         => 'HashRef',
    traits      => ['Hash'],
    lazy_build  => 1,
    handles     => {
        config  => 'accessor',
        },
    );
has url => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build => 1,
    );
has email => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build  => 1,
    );
has password => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build  => 1,
    );
has token => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
    );

sub _build_config {
    my ($self) = @_;

    unless (-r $self->config_filename){
        say STDERR "[WARNING] Could not read config file: ".$self->config_filename;
        return {};
        }

    my $cfg = Config::Any->load_files({
        files   => [$self->config_filename],
        use_ext => 1,
        });

    my %config = map {
        my ($file, $file_config) = %$_;
        %$file_config;
        } @$cfg;

    return \%config;
    }
sub _build_token {
    my ($self) = @_;

    # Glob returns iterator unless called in scalar context
    if (-r $self->token_filename) {
        open (my $file, '<', $self->token_filename);
        chomp(my $token = <$file>);
        return $token;
        }

    my $token = $self->logon;

    return $token;
    }
sub _build_url {
    my $url = shift->config('url');
    unless ($url){
        $url = "".prompt "Fogbugz API URL: ", '-t';
        }

    if ($url !~ /api.asp/){
        say STDERR "[WARNING] Fogbugz URL doesn't end with /api.asp. That doesn't seem right!";
        }
    return $url;
    }
sub _build_email {
    if (my $email = shift->config('email')){
        return $email;
        }
    return "".prompt "Fogbugz Email address: ", '-t';
    }
sub _build_password {
    if (my $password = shift->config('password')){
        return $password;
        }
    return "".prompt "Fogbugz Password: ", -te => '*';
    }

sub logon {
    my ($self) = @_;

    my $dom = $self->get_url(logon => {
        email       => $self->email,
        password    => $self->password,
        });

    my $token = $dom->findvalue('//token');

    open(my $token_file, ">", $self->token_filename) || die "Cannot open ".$self->token_filename;

    say $token_file $token;

    $self->token( $token );

    return $token;
    }

sub logout {
    my $self = shift;

    my $dom = $self->get_url(logoff => { });

    if (-r $self->token_filename){
        unlink $self->token_filename;
        }

    return 1;
    }

sub get_case {
    my ($self, $number) = @_;

    my $case = WebService::FogBugz::XML::Case->new({
        service => $self,
        number  => $number,
        });

    $case->get;

    return $case;
    }

sub get_url {
    my ($self, $cmd, $args, $tries) = @_;

    my $ua = LWP::UserAgent->new();

    my $url = $self->url;

    unless ($cmd eq 'logon'){
        $args->{token} = $self->token;
        }

    my $get_url = "$url?cmd=$cmd&".join "&", map {$_."=".$args->{$_}} keys %$args;

    my $req = HTTP::Request->new(GET => $get_url);

    my $resp = $ua->request($req);

    unless ($resp->is_success){
        say STDERR "Error talking to Fogbugz\n".$resp->content;
        }

    my $dom = XML::LibXML->load_xml(string => $resp->content);

    my $doc = $dom->documentElement;

    if (my $errors = $doc->find('/response/error')){
        foreach my $error ($errors->get_nodelist){
            if ($tries < 1 && $error->getAttribute('code') eq 3){
                # Error code 3 is not logged on. Retry login once.
                $self->logout;
                $self->logon;
                return $self->get_url($cmd, $args, 1);
                }
            say STDERR "[ERROR] ".$error->textContent;
            }
        }

    return $doc;
    }

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

WebService::FogBugz::XML

=head1 SYNOPSIS

 use WebService::FogBugz::XML;

 # Config generally read from ~/.fb.conf
 my $fb     = WebService::FogBugz::XML->new;

 my $case   = $fb->get_case(1234);

=head1 DESCRIPTION

WebService::FogBugz::XML provides an OO interface to the FogBugz XML API.
You can use this to search for cases, change what you're working on, etc.
It's particularly useful to build external reporting on development activity.

Documentation for the API itself is here:
L<FogBugz XML API Doucmentation|http://fogbugz.stackexchange.com/fogbugz-xml-api>

=head1 CONFIGURATION

Configuration is expected to be found in ~/.fb.conf.
If it's not there, you'll be prompted for url, email and password.
The password should not be stored in the file, since it's only used to generate an auth_token.

Example config file:

    url = https://www.mysite.com/fogbugz/api.asp
    email = my@email.com

The URL should probably end in api.asp.

An auth token is stored in ~/.fb_auth_token.
This is a persistent login key. Once this exists, neither email nor password are required
again.

There are attributes available for email, password and url on the object itself,
but it's a bad pattern to hard code a password ever.

=head1 ATTRIBUTES

=head2 config_filename

Where to find the configuration file.

Default: ~/.fb.conf

=head2 token_filename

Where to find and store the auth token file.

Default: ~/.fb_auth_token

=head2 url

The URL to the fogbugz API. Should include the protocol, and the full path to the api.
 e.g. https:://www.mysite.com/fogbugz/api.asp

=head2 email

The email address to logon to Fogbugz with

=head2 password

The password address to logon to Fogbugz with

=head2 token

The auth token to use when talking to fogbugz

=head1 METHODS

=head2 get_case ($number)

Fetches a case from fogbugz.

Returns a L<WebService::FogBugz::XML::Case> object.

=head1 INTERNALS

=head2 logon

Called when there's no token present.
You shouldn't ever need to call this.

=head2 Logout

Log out of the fogbugz service.

=head2 get_url ($cmd, $args)

Retrieves an arbitrary command. Accepts a hashref of arguments.

=head1 TODO

 Many more methods to wrap up for convenience.

=head1 AUTHOR

gbjk: Gareth Kirwan <gbjk@thermeon.com>

=head1 CONTRIBUTIORS

djh:  Dominic Humphries <djh@thermeon.com>

=head1 COPYRIGHT

2012 Thermeon Worldwide PLC

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
