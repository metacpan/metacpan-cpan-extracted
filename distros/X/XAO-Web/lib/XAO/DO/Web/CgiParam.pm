=head1 NAME

XAO::DO::Web::CgiParam - Retrieves parameter from CGI environment

=head1 SYNOPSIS

 <%CgiParam param="username" default="test"%>

=head1 DESCRIPTION

Displays CGI parameter. Arguments are:

 name => parameter name
 default => default text

=cut

###############################################################################
package XAO::DO::Web::CgiParam;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::CgiParam);
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION='2.2';
### $VERSION=(0+sprintf('%u.%03u',(q$Id: CgiParam.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{'name'} || $args->{'param'} ||
        throw $self "- no 'param' and no 'name' given";

    my $text;
    $text=$self->cgi->param($name);
    $text=$args->{'default'} unless defined $text;

    return unless defined $text;

    # Preventing XSS attacks. Unless we have a 'dont_sanitize' parameter
    # angle brackets are removed from the output.
    #
    if(!$args->{'dont_sanitize'}) {
        $text=~s/[<>]/ /sg;
    }

    # Trimming spaces
    #
    if(!$args->{'keep_spaces'}) {
        $text=~s/^\s*|\s*$//sg;
    }

    $self->textout($text);
}

###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

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
