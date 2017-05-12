=head1 NAME

XAO::Objects::Page - core object of XAO::Web rendering system

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

This is the default default (sic!) page handler. It is called when there
is no template for the given path and there is no path-to-object mapping
defined for this path.

Feel free to override it per-site to make it do something more useful
then just displaying 404 error message.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Web::Default;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Default.pm,v 2.3 2006/05/23 20:17:35 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item display (%)

Normally takes no arguments and uses /pagedesc/fullpath to pass to
/bits/errors/file-not-found template as a FILEPATH argument.

Sets up page headers to show 404 page not found message.

=cut

sub display ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $path=$self->clipboard->get('/pagedesc/fullpath') ||
        $args->{'path'} ||
        '';

    $self->siteconfig->header_args(
        -Status         => '404 File not found',
        -expires        => 'now',
        -cache_control  => 'no-cache',
    );

    $self->object->display(
        path        => '/bits/errors/file-not-found',
        FILEPATH    => $path,
    );
}

###############################################################################
1;
__END__

=over

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>.
