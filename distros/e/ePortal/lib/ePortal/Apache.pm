#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

BEGIN {
    $| = 1;
}

package ePortal::Apache;
    our $VERSION = '4.5';

    # --------------------------------------------------------------------
    # Packages of ePortal itself
    # --------------------------------------------------------------------
    use ePortal::Global;
    use ePortal::Utils;
    use ePortal::Server;

    # Packages for use under Apache
    use ePortal::HTML::Calendar;
    use ePortal::HTML::Dialog;
    use ePortal::HTML::List;
    use ePortal::HTML::Tree;

    # --------------------------------------------------------------------
    # Other Perl modules used in some components of ePortal

    # --------------------------------------------------------------------
    # System modules.
    #
    use HTML::Mason;
    eval "use HTML::Mason::ApacheHandler;";
    use Apache;
    use Apache::Request;
    use Apache::Constants qw/OK DECLINED/;


{   # --------------------------------------------------------------------
    # Modules used in native Mason components. Load them in
    # HTML::Mason::Commands in order to use right namespace
    #
    package HTML::Mason::Commands;
    use Carp;                           # import carp, warn
                                        #
    use ePortal::Global;                # import global variables
    use ePortal::Utils;                 # import global functions (logline)
    use ePortal::Exception;
    use Error qw/:try/;
    use Params::Validate qw/:types/;

    use Apache::Util qw/escape_html escape_uri/;    # Apache is faster then CGI
    use Apache::Cookie;
    use Apache::Constants qw/OK DECLINED/;
    use Apache::File;

    1;
}


# ------------------------------------------------------------------------
# Main entrance
#
#
sub handler
{
    my $r = shift;
    my $result = undef;
    return DECLINED unless ($r->is_main);


    # ----------------------------------------------------------------
    # I serve only some types of MIME
    #
    if ($r->content_type
            && $r->content_type !~ m|^text/|io
            && $r->content_type ne 'application/x-javascript'
            && $r->content_type ne 'httpd/unix-directory'
            && $r->uri !~ m|^/catalog/|o
            && $r->uri !~ m|^/attachment/|o
    ) {
        #logline('debug', 'Request denied: ' . $r->uri . ' served as ' . $r->content_type);
        return DECLINED;
    }

    return HTML::Mason::ApacheHandler->handler($r);
}   ## end of handler




1;


__END__

