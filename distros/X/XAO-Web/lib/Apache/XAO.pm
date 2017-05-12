=head1 NAME

Apache::XAO - Apache XAO handler

=head1 SYNOPSIS

In httpd.conf or <VirtualHost ..> section:

 PerlFreshRestart   On
 PerlSetVar         SiteName        testsite
 SetHandler         perl-script
 PerlTransHandler   Apache::XAO

=head1 DESCRIPTION

Apache::XAO is provides a clean way to integrate XAO::Web based web
sites into mod_perl for maximum performance. The same site can still be
used in CGI mode (see L<XAO::Web::Intro> for configuration samples).

Apache::XAO must be installed as PerlTransHandler, not as a
PerlHandler.

If some areas of the tree need to be excluded from XAO::Web (as it
usually happens with images -- /images or something similar) these
areas need to be configured in the site's configuration. This is
described in details below.

As a convenience, there is also simple way to exclude certain locations
using Apache configuration only. Most common is ExtFilesMap:

 PerlSetVar         ExtFilesMap     /images

This tells Apache::XAO to map everything under /images location in
URI to physical files in 'images' directory off the project home
directory. For a site named 'testsite' this is roughly the same as the
following, only you do not have to worry about exact path to site's home
directory:

 Alias              /images         /usr/local/xao/projects/testsite/images

To achieve the same effect from the site configuration you need:

 path_mapping_table => {
     '/images' => {
         type        => 'maptodir',
     },
 },

More generic way is to just disable Apache::XAO from handling some area
altogether:

 PerlSetVar         ExtFiles        /images

In this case no mapping is performed and generally Apache::XAO does
nothing and lets Apache handle the files.

Site configuration equivalent is:

 path_mapping_table => {
     '/images' => {
         type        => 'external',
     },
 },

More then one prefix can be listed using ':' as separator:

 PerlSetVar         ExtFilesMap     /images:/icons:/ftp

=head2 PERFORMANCE

Using Apache::XAO gives of course incomparable with CGI mode
performance, but even in comparision with mod_rewrite/mod_perl
combination we got 5 to 10 percent boost in performance in tests.

Not to mention clearer looking config files and reduced server memory
footprint -- no need to load mod_rewrite.

For additional improvement in memory size it is recommended to add
the following line into the main Apache httpd.conf (not into any
VirtualHost):

 PerlModule XAO::PreLoad

This way most of XAO modules will be pre-compiled and shared between all
apache child thus saving memory and child startup time:

=cut

###############################################################################
package Apache::XAO;
use strict;
use warnings;
use XAO::Utils;
use XAO::Web;

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: XAO.pm,v 2.10 2008/07/30 03:47:46 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

use vars qw($MP2);
use vars qw($HAVE_SIZE_LIMIT);

BEGIN {
    eval {
        require mod_perl2;
        require Apache2::Const;
        Apache2::Const->import(qw(:common));
        require Apache2::ServerRec;
        require Apache2::ServerUtil;
        require Apache2::Log;
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::RequestIO;
        $MP2=2;
    };
    if($@) {
        eval {
            require Apache2;
            require mod_perl;
            require Apache::Const;
            Apache::Const->import(qw(:common));
            require Apache::Server;
            require Apache::ServerUtil;
            require Apache::Log;
            require Apache::RequestRec;
            require Apache::RequestUtil;
            require Apache::RequestIO;
            $MP2=1;
        };
    }
    if($@) {
        eval {
            require Apache::Constants;
            Apache::Constants->import(qw(:common));
            $MP2=0;
        };
    }
    if($@) {
        die "Error setting up Apache::XAO: $@";
    }
}

###############################################################################

sub handler_content ($);
sub server_error ($$;$);

###############################################################################

sub handler {
    my $r=shift;

    # Request URI
    #
    my $uri=$r->uri;
    ### $r->server->log_error("HANDLER: $uri");

    ##
    # Checking if we were called as a PerlHandler and complaining
    # otherwise.
    #
    if($r->is_initial_req && exists $ENV{'REQUEST_METHOD'}) {
        return server_error($r,'Use PerlTransHandler',<<EOT);
Please use 'PerlTransHandler Apache::XAO' instead of just PerlHandler.
EOT
    }

    ##
    # Getting site name and loading the site configuration
    #
    my $sitename=$r->dir_config('sitename') || $r->dir_config('SiteName');
    if(!$sitename) {
        return server_error($r,'No Site Name',<<EOT);
Please use 'PerlSetVar sitename yoursitename' directive in the
configuration.
EOT
    }
    my $web=XAO::Web->new(sitename => $sitename);

    # Checking access rules
    #
    if(!$web->check_uri_access($uri)) {
        $r->server->log_error("Access denied to $uri, see path_deny_table (/CVS/ and /bits/ are denied by default)");
        return NOT_FOUND;
    }

    # Checking if we need to worry about ExtFilesMap or ExtFiles in the
    # apache config.
    #
    my $efm=$r->dir_config('ExtFilesMap') || '';
    my $ef=$r->dir_config('ExtFiles') || '';
    if($efm || $ef) {
        my $config=$web->config;
        my $pmt=$config->get('path_mapping_table');
        my $pmt_orig=$pmt;
        foreach my $path (split(/:+/,$efm)) {
            $path='/'.$path;
            $path=~s/\/{2,}/\//g;
            $path=~s/\/$//g;
            next if $pmt->{$path};
            $pmt->{$path}={ type => 'maptodir' };
        }
        foreach my $path (split(/:+/,$ef)) {
            $path='/'.$path;
            $path=~s/\/{2,}/\//g;
            $path=~s/\/$//g;
            next if $pmt->{$path};
            $pmt->{$path}={ type => 'external' };
        }
        if(!$pmt_orig) {
            $config->put(path_mapping_table => $pmt);
        }
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
    if($ptype eq 'external') {
        ### $r->server->log_error("EXTERNAL: uri=$uri");
        return DECLINED;
    }
    elsif($ptype eq 'maptodir') {
        my $dir=$pagedesc->{'directory'} || '';
        if(!length($dir) || substr($dir,0,1) ne '/') {
            my $phdir=$XAO::Base::projectsdir . "/" . $sitename;
            if(length($dir)) {
                $dir=$phdir . '/' . $dir;
            }
            else {
                $dir=$phdir;
            }
        }
        $dir.='/' . $uri;
        $dir=~s/\/{2,}/\//g;
        $r->filename($dir);
        ### $r->server->log_error("MAPTODIR: => $dir");
        return OK;
    }

    # We pass the knowledge along in the 'notes' table.
    #
    $r->pnotes(xaoweb   => $web);
    $r->pnotes(pagedesc => $pagedesc);
    $r->pnotes(uri      => $uri);

    # Default is to install a content handler to produce actual output.
    # It could be more optimal to have two always present handlers
    # instead of pushing/popping automatically -- in this case
    # 'HandlerType' must be set to 'static' in the server config.
    #
    # We return OK to indicate to Apache that there is no need to try
    # to map that URI to anything else, we know how to produce results
    # for it.
    #
    my $htype=lc($r->dir_config('HandlerType') || 'auto');
    if($htype eq 'auto') {
        ### $r->server->log_error("TRANS: auto (uri=$uri)");

        # In mod_perl 2.x filepath translation is done in a separate
        # phase, we need to set up a handler for it -- otherwise apache
        # will still attempt to map filename, and worse yet -- attempt
        # to redirect to language specific 'index.html.en' for example.
        #
        if($MP2) {
            $r->push_handlers(PerlMapToStorageHandler => \&handler_map_to_storage);
            $r->push_handlers(PerlResponseHandler => \&handler_content);
            return OK;
        }
        else {
            $r->push_handlers(PerlHandler => \&handler_content);
            return OK;
        }
    }
    elsif($htype eq 'static') {
        ### $r->server->log_error("TRANS: static (uri=$uri)");
        return OK;
    }
    else {
        return server_error($r,"Unknown HandlerType '$htype'");
    }
}

###############################################################################

sub handler_content ($) {
    my $r=shift;

    # Getting the data. If there is no data then trans handler was not
    # executed or has declined, so we do not need to do anything.
    #
    my $web=$r->pnotes('xaoweb') ||
        return DECLINED;
    my $pagedesc=$r->pnotes('pagedesc');

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
        if($MP2 && $MP2==2) {
            if(!$HAVE_SIZE_LIMIT) {
                require Apache2::MPM;
                require Apache2::SizeLimit;
                $HAVE_SIZE_LIMIT=1;
            }

            $Apache2::SizeLimit::CHECK_EVERY_N_REQUESTS=$msl->{'check_every_n_requests'} if $msl->{'check_every_n_requests'};
            $Apache2::SizeLimit::CHECK_EVERY_N_REQUESTS=$msl->{'every_n_requests'} if $msl->{'every_n_requests'};

            Apache2::SizeLimit::setmin($msl->{'min_share_size'}) if $msl->{'min_share_size'};
            Apache2::SizeLimit::setmin($msl->{'min_shared_size'}) if $msl->{'min_shared_size'};
            Apache2::SizeLimit::setmax($msl->{'max_process_size'},$r) if $msl->{'max_process_size'};
            Apache2::SizeLimit::setmax_unshared($msl->{'max_unshared_size'}) if $msl->{'max_unshared_size'};

            ### $r->server->log_error("$Apache2::SizeLimit::CHECK_EVERY_N_REQUESTS / $Apache2::SizeLimit::MIN_SHARE_SIZE / $Apache2::SizeLimit::MAX_UNSHARED_SIZE / $Apache2::SizeLimit::MAX_PROCESS_SIZE");
        }
        else {
            $r->server->log_error("memory_size_limit is only supported when Apache2::SizeLimit is available");
        }
    }

    # We have to get the original URI, the one in $r->uri may get mangled
    #
    my $uri=$r->pnotes('uri');
    ### $r->server->log_error("CONTENT: uri=$uri");

    # Executing
    #
    $web->execute(
        path        => $uri,
        apache      => $r,
        pagedesc    => $pagedesc,
    );

    return OK;
}

###############################################################################

sub handler_map_to_storage {
    my $r=shift;
    ### $r->server->log_error("MAPTOSTORAGE: uri=".$r->uri);
    return OK;
}

###############################################################################

sub server_error ($$;$) {
    my ($r,$name,$desc)=@_;

    $desc=$name unless $desc;

    $r->server->log_error("*ERROR: Apache::XAO - $name");
    $r->custom_response(
        SERVER_ERROR,
        "<H2>XAO::Web System Error: $name</H2>\n$desc"
    );
    return SERVER_ERROR;
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web::Intro>,
L<XAO::Web>,
L<XAO::DO::Config>,
L<Apache>.
