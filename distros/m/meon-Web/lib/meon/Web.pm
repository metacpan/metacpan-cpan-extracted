package meon::Web;
use Moose;
use namespace::autoclean;

use Path::Class 'file', 'dir';
use meon::Web::SPc;
use meon::Web::Util;

use Catalyst::Authentication::Store::UserXML 0.03;

use Catalyst::Runtime 5.80;
use Catalyst::Plugin::Session 0.37;
use Catalyst qw(
    ConfigLoader
    Authentication
    Session
    Session::Store::File
    Session::State::Cookie
    SmartURI
    Unicode::Encoding
);
extends 'Catalyst';
use Catalyst::View::XSLT 0.10;

our $VERSION = '0.04';

__PACKAGE__->config(
    name => 'meon_web',
    using_frontend_proxy => 1,
    'Plugin::ConfigLoader' => { file => dir(meon::Web::SPc->sysconfdir, 'meon', 'web-config.pl') },
    'Plugin::SmartURI' => { disposition => 'relative', },
    'root' => dir(meon::Web::SPc->datadir, 'meon', 'web', 'www'),
    'authentication' => {
        'userxml' => {
            'folder'             => dir(meon::Web::SPc->sharedstatedir, 'meon-web', 'global-members'),
            'user_folder_file'   => 'index.xml',
            'find_user_fallback' => 'find_user_fallback',
        }
    },
    'Plugin::Authentication' => {
        default_realm => 'members',
        members => {
            credential => {
                class         => 'Password',
                password_type => 'self_check',
            },
            store => {
                class         => 'UserXML',
            }
        }
    },
    default_view => 'XSLT',
    'View::XSLT' => {
        INCLUDE_PATH => [
            dir(meon::Web::SPc->datadir, 'meon-web', 'template', 'xsl')
        ],
        TEMPLATE_EXTENSION => '.xsl',
    },
    'View::JSON' => {
        allow_callback  => 1,
        callback_param  => 'cb',
        expose_stash    => 'json',
    },
    'Plugin::Session' => { expires => 4*60*60 },
);

__PACKAGE__->setup();

sub static_include_path {
    my $c = shift;

    my $uri      = $c->req->uri;
    my $hostname = $uri->host;
    my $hostname_dir = meon::Web::Config->hostname_to_folder($hostname);

    $c->detach('/status_not_found', ['no such domain '.$hostname.' configured'])
        unless $hostname_dir;

    return [ dir(meon::Web::SPc->srvdir, 'www', 'meon-web', $hostname_dir, 'www') ];
}

sub json_reply {
    my ( $c, $json_data ) = @_;

    $c->res->header('X-Ajax-Controller',1);
    $c->stash->{json} = $json_data;
    $c->detach('View::JSON');
}

sub member {
    my $c = shift;

    my $members_folder = $c->default_auth_store->folder;
    return meon::Web::Member->new(
        members_folder => $members_folder,
        username       => $c->user->username,
        xml            => $c->user->xml,
    );
}

sub traverse_uri {
    my ($c,$path) = @_;

    $path = meon::Web::Util->path_fixup($path);

    # redirect absolute urls with hostname
    if ($path =~ m{^https?://}) {
        return URI->new($path);
    }

    # redirect absolute urls
    if ($path =~ m{^/}) {
        my $new_uri = $c->req->base->clone;
        $new_uri->path($path);
        return $new_uri;
    }

    my $new_uri = $c->req->uri->clone;
    my @segments = $new_uri->path_segments;
    pop(@segments) if length($path); # allow keeping current uri with path set to ''
    $new_uri->path_segments(
        @segments,
        URI->new($path)->path_segments
    );
    return $new_uri;
}

sub format_dt {
    my ($c, $datetime) = @_;

    my $dt = $datetime->clone;

    # FIXME $c->user preferred timezone + format
    $dt->set_time_zone('Europe/Vienna');
    return $dt->strftime('%d.%m.%Y %H:%M:%S');
}

sub find_user_fallback {
    my ($c, $authinfo) = @_;

    my $username = $authinfo->{username};
    my $storage = meon::Web::env->hostname_config->{'auth'}{'storage'} // '';
    if ($storage eq 'session') {
        my $user_xml = $c->session->{meon_Web_user_xml};
        unless ($user_xml) {
            $user_xml =
                '<page xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns="http://web.meon.eu/" xmlns:w="http://web.meon.eu/">'
                .'<meta><user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">'
                .'<username>'.$username.'</username>'
                .'</user></meta>'
                .'<w:member-profile/>'
                .'</page>';

            $c->session->{meon_Web_user_xml} = $user_xml;
        }
        my $user = Catalyst::Authentication::Store::UserXML::User->new({
            xml_filename => file('/'),
            xml          => XML::LibXML->load_xml(string => $user_xml),
        });
        return $user;
    }
    return undef;
}

1;

__END__

=head1 NAME

meon::Web - XML+XSLT file based "CMS"

=head1 SYNOPSIS

    script/run_meon-web_devel

    cpan -i meon::Web
    cd /srv/www/meon-web/localhost/
    tree

    # in apache virtual host
    <Perl>
        use Plack::Handler::Apache2;
        Plack::Handler::Apache2->preload("/usr/local/bin/meon-web.psgi");
    </Perl>
    <Location />
        SetHandler perl-script
        PerlResponseHandler Plack::Handler::Apache2
        PerlSetVar psgi_app /usr/local/bin/meon-web.psgi
    </Location>

=head1 WARNING

Highly experimental at the moment, usable only for real adventurers.

=head1 DESCRIPTION

meon-Web is CMS for designers or publishers that wants to use the whole
power of HTML for their sites, but doesn't want to bother with
programming.

Main implementation goal is be able to have sites as files and go as
far as possible with standard XML+XSLT without database usage.

Each web pages is XML files with content part of given page. Then the
rest of the page (menu + header + footer) are added via XSLT. Any advanced
dynamically generated content on the page can be easily implemented as
special tag, which will be rendered via XSLT.

=head1 FEATURES

=over 4

=item *

multiple domains/websites at once support - stored simple in different folders, switched per request based on "Host:" header.

=item *

login + members area - users + credentials are stored in XML files. Login restriction simply by adding XML tag to meta headers.

=item *

form2email - send form to email address

=back

=head1 EXAMPLES

See F<srv/www/meon-web/localhost/> inside this distribution for simple example.

=head1 SEE ALSO

L<Template::Tools::ttree>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the meon::Web by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Andrea Pavlovic

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 srv/www/meon-web/bootstrap/

Are examples from L<https://github.com/twbs/bootstrap>, check there for
license and copyright.

=cut
