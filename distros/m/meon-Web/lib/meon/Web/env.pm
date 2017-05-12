package meon::Web::env;

use strict;
use warnings;
use 5.010;

use Carp 'confess';
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::LibXSLT;
use Scalar::Util 'weaken';
use meon::Web::Config;
use meon::Web::SPc;
use Path::Class 'dir';
use URI::Escape 'uri_escape_utf8';
use meon::Web::Member;
use File::Find::Age;

my $env = {};
sub get { return $env; }
sub clear { $env = {}; return $env; }

XML::LibXSLT->register_function(
    'http://web.meon.eu/',
    'uri_escape',
    sub { uri_escape_utf8($_[0]) }
);

sub xpc {
    my $self = shift;
    my $xpc = XML::LibXML::XPathContext->new($env->{xml});
    $xpc->registerNs('x', 'http://www.w3.org/1999/xhtml');
    $xpc->registerNs('w', 'http://web.meon.eu/');
    $xpc->registerNs('u', 'http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML');
    return $xpc;
}

sub hostname {
    my $self = shift;
    $env->{hostname} = shift
        if @_;
    return $env->{hostname} // confess('unset');
}

sub current_dir {
    my $self = shift;
    return $self->xml_file->dir;
}

sub current_path {
    my $self = shift;
    $env->{current_path} = shift
        if @_;
    return $env->{current_path} // confess('unset');
}

sub hostname_dir_name {
    my $self = shift;
    $env->{hostname_dir_name} = shift
        if @_;

    unless (defined($env->{hostname_dir_name})) {
        $env->{hostname_dir_name} = meon::Web::Config->hostname_to_folder($self->hostname);
    }
    return $env->{hostname_dir_name};
}

sub hostname_dir {
    my $self = shift;
    $env->{hostname_dir} = shift
        if @_;

    unless (defined($env->{hostname_dir})) {
        my $hostname_dir_name = meon::Web::Config->hostname_to_folder($self->hostname);
        $env->{hostname_dir} = dir(meon::Web::SPc->srvdir, 'www', 'meon-web', $hostname_dir_name)->absolute->resolve;
    }
    return $env->{hostname_dir};
}

sub hostname_subdir {
    my $self = shift;
    my $sub  = shift;

    my $subdir = $self->hostname_dir->subdir($sub)->absolute;
    die 'forbidden'.(Run::Env->dev ? ' '.$self->hostname_dir.' vs '.$subdir : ())
        unless $self->hostname_dir->subsumes($subdir);
    return $subdir;
}

sub content_dir {
    my $self = shift;
    $env->{content_dir} = shift
        if @_;

    $env->{content_dir} //= dir($self->hostname_dir,'content');
    return $env->{content_dir};
}

sub include_dir {
    my $self = shift;
    $env->{include_dir} = shift
        if @_;

    $env->{include_dir} //= dir($self->hostname_dir,'include');
    return $env->{include_dir};
}

sub www_dir {
    my $self = shift;
    $env->{www_dir} = shift
        if @_;

    $env->{www_dir} //= dir($self->hostname_dir,'www');
    return $env->{www_dir};
}

sub static_dir {
    my $self = shift;
    $env->{static_dir} = shift
        if @_;

    $env->{static_dir} //= $self->www_dir->subdir('static');
    return $env->{static_dir};
}

sub profiles_dir {
    my $self = shift;
    $env->{profiles_dir} //= dir($self->content_dir, 'members', 'profile');
    return $env->{profiles_dir};
}

sub xml_file {
    my $self = shift;
    $env->{xml_file} = shift
        if @_;
    return $env->{xml_file} // confess('unset');
}

sub xml {
    my $self = shift;
    $env->{xml} = shift(@_) if @_;
    $env->{xml} //= XML::LibXML->load_xml(location => $self->xml_file);
    return $env->{xml};
}

sub stash {
    my $self = shift;
    if (@_) {
        $env->{stash} = shift @_;
        weaken($env->{stash});
    }

    return $env->{stash} // confess('unset');
}

sub user {
    my $self = shift;
    if (@_) {
        $env->{user} = shift @_;
        weaken($env->{user});
    }
    return $env->{user};
}

sub all_members {
    my $self = shift;

    my @members;
    my $profiles_dir = $self->profiles_dir;
    return unless -d $profiles_dir;
    foreach my $username_dir ($profiles_dir->children(no_hidden => 1)) {
        next unless $username_dir->is_dir;

        my $username = $username_dir->basename;
        my $member = meon::Web::Member->new(
            members_folder => $profiles_dir,
            username       => $username,
        );

        push(@members, $member)
            if (eval { $member->xml });
    }
    return @members;
}

sub hostname_config {
    my $self = shift;
    return meon::Web::Config->get->{$self->hostname_dir_name} // {};
}

sub static_dir_mtime {
    my $self = shift;
    $env->{static_dir_mtime} = shift
        if @_;

    # ignore generated files
    my $ages = File::Find::Age->in($self->static_dir);
    while ($ages->[-1]->{file} =~ m{/meon-Web-merged\.(js|css)$}) {
        pop(@$ages);
    }

    $env->{static_dir_mtime} //= $ages->[-1]->{mtime} // '-';
    return $env->{static_dir_mtime};
}

sub session {
    my $self = shift;
    $env->{session} = shift
        if @_;

    return $env->{session};
}

1;
