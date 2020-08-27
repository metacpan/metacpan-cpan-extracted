=head1 NAME

XAO::DO::Web::Cookie - cookies manipulations

=head1 SYNOPSIS

 Hello, <%Cookie/html name="customername"%>

 <%Cookie name="customername" value={<%CgiParam/f param="cname"%>}"%>

=head1 DESCRIPTION

Displays or sets a cookie. Arguments are:

  name    => cookie name
  value   => cookie value; nothing is displayed if a value is given
  default => what to display if there is no cookie set, nothing by default
  expires => when to expire the cookie (same as in CGI->cookie)
  path    => cookie visibility path (same as in CGI->cookie)
  domain  => cookie domain (same as in CGI->cookie)
  secure  => cookie secure flag (same as in CGI->cookie)
  httponly=> cookie httpOnly flag (same as in CGI->cookie)
  samesite=> cookie SameSite flag (Strict, Lax, or None)
  received=> when retrieving only look at actually received cookies (the
             default is to return a cookie value possibly set earlier
             in the page render)

=cut

###############################################################################
package XAO::DO::Web::Cookie;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

our $VERSION='2.004';

###############################################################################

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{'name'};
    defined($name) || throw $self "- no name given";

    if(defined($args->{'value'})) {
        $self->siteconfig->add_cookie(
            -name       => $name,
            -value      => $args->{'value'},
            -path       => $args->{'path'},
            #
            ($args->{'expires'}     ? (-expires  => $args->{'expires'}) : ()),
            ($args->{'domain'}      ? (-domain   => $args->{'domain'}) : ()),
            ($args->{'secure'}      ? (-secure   => $args->{'secure'}) : ()),
            ($args->{'httponly'}    ? (-httponly => $args->{'httponly'}) : ()),
            ($args->{'samesite'}    ? (-samesite => $args->{'samesite'}) : ()),
        );
    }
    else {
        my $c=$self->siteconfig->get_cookie($name,$args->{'received'});
        defined $c || ($c=$args->{'default'});
        defined $c || ($c='');

        $self->textout($c);
    }
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
