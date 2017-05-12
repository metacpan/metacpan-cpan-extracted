=head1 NAME

XAO::DO::Web::Redirect - browser redirection object

=head1 SYNOPSIS

 <%Redirect url="/login.html"%>

=head1 DESCRIPTION

Redirector object. 
Can set cookies on the redirect.

=cut

###############################################################################
package XAO::DO::Web::Redirect;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Redirect.pm,v 2.2 2005/12/12 07:32:04 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=pod

Arguments are:

 url        => new url or short path.
 target     => target frame (optional, only works with Netscape)
 base       => if set uses base site name (optional)
 secure     => if set uses secure protocol (optional)
 permanent  => use status 301 (default is 302)

=cut

sub display {
    my $self=shift;
    my $args=get_args(\@_);
    my $config=$self->siteconfig;

    ##
    # Checking parameters.
    #
    if(! $args->{'url'}) {
        eprint "No URL or path in Redirect";
        return;
    }

    ##
    # Additional fields into standard header.
    #
    my %qa=(
        -Status => $args->{'permanent'} ? '301 Permanently Moved' : '302 Moved'
    );

    ##
    # Target window works only with Netscape, but we do not care here and
    # do our best.
    #
    if($args->{'target'}) {
        dprint ref($self),"::display - 'target=$args->{target}' does not work with MSIE!";
        $qa{'-Target'}=$args->{'target'};
    }

    ##
    # Getting redirection URL
    #
    my $url;
    if($args->{'url'} =~ /^\w+:\/\//) {
        $url=$args->{'url'};
    }
    else {
        my $base=$args->{'base'};
        my $secure=$args->{'secure'};
        my $url_path=$args->{'url'};
        if(substr($url_path,0,1) eq '/') {
            my $base_url=$self->base_url(
                active  => $base ? 0 : 1,
                secure  => $secure,
            );
            $url=$base_url . $url_path;
        }
        else {
            $url=$self->pageurl(
                active  => $base ? 0 : 1,
                secure  => $secure,
            );
            $url=~s/^(.*\/)(.*?)$/$1$url_path/;
        }
    }

    ##
    # Redirecting
    #
    $qa{-Location}=$url;
    $config->header_args(\%qa);
    $self->finaltextout(<<EOT);
The document is moved <A HREF="$url">here</A>.
EOT
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
L<XAO::Web>,
L<XAO::DO::Web::Page>.
