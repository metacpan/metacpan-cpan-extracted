=head1 NAME

XAO::DO::Web::Footer - simple HTML footer

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Displays "/bits/page-footer" template (can be overriden with "path"
argument) giving it the following arguments:

=over

=item COPYRIGHT

Copyright information for XAO::Web.

=item COPYRIGHT.HTML

Copyright information for XAO::Web suitable for HTML, with '&copy;' for
(C).

=item TITLE

Content of the 'title' argument if there is any or empty string
otherwise.

=item VERSION

Current XAO::Web package version.

=back

In most cases you would want to extend or override this object or at
least its default template with something site specific.

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

=cut

###############################################################################
package XAO::DO::Web::Footer;
use strict;
use XAO::Web;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Footer.pm,v 2.2 2005/09/14 22:05:43 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my %a=(
        path            => '/bits/page-footer',
        VERSION         => $XAO::Web::VERSION,
        COPYRIGHT       => 'Copyright (C) 2000-2002 XAO, Inc.; (C) 2003-2005 Ejelta LLC',
        'COPYRIGHT.HTML'=> 'Copyright &copy; 2000-2002 XAO, Inc.; &copy; 2003-2005 Ejelta LLC',
        TITLE           => $args->{'title'} || '',
    );

    $self->SUPER::display(merge_refs(\%a,$args));
}

###############################################################################
1;
