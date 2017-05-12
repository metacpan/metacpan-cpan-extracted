=head1 NAME

XAO::DO::Web::URL - displays base, active and secure URLs

=head1 SYNOPSIS

Given that base_url is 'http://host.com' and browser is at
'http://www.host.com/test.html?a=1' the following translations will be
performed:

 <%URL%>                    -- http://www.host.com/test.html
 <%URL active%>             -- http://www.host.com/test.html
 <%URL active top%>         -- http://www.host.com
 <%URL active full%>        -- http://www.host.com/test.html
 <%URL active secure%>      -- https://www.host.com/test.html
 <%URL active top secure%>  -- https://www.host.com
 <%URL active full secure%> -- https://www.host.com/test.html
 <%URL base%>               -- http://host.com/test.html
 <%URL base top%>           -- http://host.com
 <%URL base full%>          -- http://host.com/test.html
 <%URL base secure%>        -- https://host.com/test.html
 <%URL base top secure%>    -- https://host.com
 <%URL base full secure%>   -- https://host.com/test.html
 <%URL secure%>             -- https://www.host.com/test.html
 <%URL uri%>                -- /test.html
 <%URL x='TAG'%>            -- from /extra_urls, assumes "top"

If browser is at 'https://www.host.com/test.html' (secure protocol):

 <%URL%>                    -- https://www.host.com/test.html
 <%URL insecure%>           -- http://www.host.com/test.html
 <%URL base%>               -- https://host.com/test.html
 <%URL base top insecure%>  -- http://host.com

=head1 DESCRIPTION

Allows to display URL with some possible alterations. Default is to
display full URL of the current page using the base host name. If the
page is a secure one then the URL will also be secure.

Base URL is set as 'base_url' parameter in the initial site
configuration.

Active host name is usually the same as base host name, but may differ
if your web server is set up to serve more then one domain using the
same XAO::Web site.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Web::URL;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: URL.pm,v 2.2 2007/01/29 05:22:13 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $secure;
    if($args->{'secure'}) {
        $secure=1;
    }
    elsif($args->{'insecure'}) {
        $secure=0;
    }
    else {
        $secure=$self->is_secure;
    }

    my $url;

    my $x=$args->{'x'};

    if($x) {
        my $extra_urls=$self->siteconfig->get('extra_urls') || { };

        $url=$extra_urls->{$x.'.'.($secure ? 'secure' : 'insecure')};

        if(!$url) {
            $url=$extra_urls->{$x} ||
                 $self->base_url(active => 0, secure => $secure);

            if($secure) {
                $url=~s/^http:/https:/;
            }
        }
    }
    else {
        my $active=$args->{'active'} ? 1 : 0;
        my $full=$args->{'top'} ? 0 : 1;

        $url=$full ? $self->pageurl(active => $active, secure => $secure) :
                     $self->base_url(active => $active, secure => $secure);
    }

    if($args->{'uri'}) {
        $url=~s/^\w+:\/\/.*?\//\//;
    }

    $self->textout($url);
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
