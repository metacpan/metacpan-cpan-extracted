package Plack::App::XAO;
use warnings;
use strict;
use CGI::Cookie;
use CGI::PSGI;
use Plack::App::File;
use Plack::Builder;
use Plack::Util::Accessor qw(site);
use XAO::Utils;
use XAO::Web;

use parent qw(Plack::Component);

sub call {
    my ($self,$env)=@_;

    # XAO needs to have a site name.
    #
    # Builder config:
    #   builder {
    #     mount '/' => Plack::App::XAO->new(site => 'example')->to_app(),
    #   }
    #
    # Or command line:
    #   plackup -MPlack::App::XAO -e'Plack::App::XAO->new(site => 'example')->to_app()'
    #
    my $sitename=$self->site ||
        die "A 'site' parameter is required\n";

    $sitename=~/^[\w-]+$/ ||
        die "Invalid site name\n";

    # Plack does not set up HTTPS in its environment. And CGI::PSGI
    # fails to detect https environment without that.
    #
    $env->{'HTTPS'}=($env->{'psgi.url_scheme'}//'') eq 'https' ? 'on' : '';

    # Plack does not seem to be doing any URI validation or cleaning.
    #
    my $uri=$env->{'PATH_INFO'};

    $uri !~ m!(?:^|/)\.\.(?:/|$)! ||
        return $self->error_not_found('dot-dot');

    my $web=XAO::Web->new(
        sitename => $sitename,
        init_args => {
            environment => 'web',
        },
    );

    # Checking access rules
    #
    if(!$web->check_uri_access($uri)) {
        $env->{'psgi.errors'}->print("Access denied to $uri, see path_deny_table (/CVS/ and /bits/ are denied by default)");
        return $self->error_not_found(1);
    }

    # Checking if we should serve this request at all. If the URI ends
    # with / we always add index.html to the URI before checking.
    #
    my $pagedesc;
    if(substr($uri,-1,1) eq '/') {
        $pagedesc=$web->analyze($uri . 'index.html',$sitename,1);
    }
    else {
        $pagedesc=$web->analyze($uri,$sitename,1);
    }

    my $ptype=$pagedesc->{'type'} || 'xaoweb';

    # Pages of 'external' type are for Plack::App::Cascade to pick up
    # and handle to another app potentially.
    #
    if($ptype eq 'external') {
        return $self->error_not_found(2);
    }

    # Static file mapping
    #
    elsif($ptype eq 'maptodir') {
        my $dir=$pagedesc->{'directory'} || '';

        $dir!~/\.\./ ||
            return $self->error_not_found(3);

        if(!length($dir) || substr($dir,0,1) ne '/') {
            my $phdir=$XAO::Base::projectsdir . '/' . $sitename;
            if(length($dir)) {
                $dir=$phdir . '/' . $dir;
            }
            else {
                $dir=$phdir;
            }
        }

        my $file=$dir . '/' . $uri;

        -f $file ||
            return $self->error_not_found();

        my $app=Plack::App::File->new(file => $file)->to_app();
        return $app->($env);
    }

    # If needed setting up SizeLimit to possibly restart this process
    # when it gets too big. Controlled by memory_size_limit parameters
    # in the site config:
    #
    #  check_every_n_requests | every_n_requests
    #  max_process_size         (in KB)
    #  min_share_size           (in KB)
    #  max_unshared_size        (in KB)
    #
    if(my $msl=$web->config->get('memory_size_limit')) {
        eprint "Option memory_size_limit is not supported in PSGI interface";
    }

    # Substitute CGI environment
    #
    my $cgi=XAO::Objects->new(
        objname => 'CGI',
        cgi     => CGI::PSGI->new($env),
    );

    # Executing
    #
    return $web->execute(
        path        => $uri,
        psgi        => $env,
        cgi         => $cgi,
        pagedesc    => $pagedesc,
    );
}

###############################################################################

sub error_not_found {
    my $self=shift;
    return [ '404', [ 'Content-Type' => 'text/plain' ], [ 'File not found:'.(shift||'X') ] ];
}

###############################################################################
1;
__END__

=head1 NAME

Plack::App::XAO - XAO adapter for Plack

=head1 SYNOPSIS

In a psgi file with Builder:

    builder {
        mount '/' => Plack::App::XAO->new(site => 'example')->to_app(),
    }

From a command line:

    plackup -MPlack::App::XAO -e'Plack::App::XAO->new(site => 'example')->to_app()'

=head1 DESCRIPTION

B<Work in progress!> Do not use in production code yet.

This is a simple adapter allowing to run a XAO::Web web site with Plack
and the multitude of servers that support PSGI interface.

To serve static files either mount them with builder:

    builder {
        mount '/images' => Plack::App::File->new(root => '/path/to/images')->to_app;
        mount '/' => Plack::App::XAO->new(site => 'example')->to_app(),
    };

Or, better yet, just use the same 'maptodir' configuration that
L<Apache::XAO> module uses:

    path_mapping_table => {
        '/images' => {
            type        => 'maptodir',
        },
    },

That has a benefit of automatically prepending images with the site home
directory path, whatever it happens to be.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2018 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

L<XAO::Web::Intro>
L<XAO::Web>
L<XAO::DO::Config>
