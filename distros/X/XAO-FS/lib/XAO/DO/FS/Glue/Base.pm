=head1 NAME

XAO::DO::FS::Glue::Base - glue base

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

Provides a basic set of methods all drivers derive from.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::Base;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Base.pm,v 2.1 2007/05/09 21:03:09 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item connector ($)

Returns an internal connector object that is used for communicating
requests to the database.

=cut

sub connector ($) {
    my $self=shift;
    my $connector=$self->{'connector'};
    if(!$connector) {
        $self->{'connector'}=$connector=$self->connector_create;
    }
    return $connector;
}

###############################################################################

=item connector_create ($)

Pure virtual. Returns an actual implementation of a connector
(DBI/direct connect/etc). Receives no connection arguments, should wait
for sql_connect before actually connecting to the DB.

=cut

sub connector_create ($) {
    my $self=shift;
    throw $self "connector_create - pure virtual method";
}

###############################################################################

=item DESTROY ($)

Calls sql_disconnect on the connector if one was created.

=cut

sub DESTROY ($) {
    my $self=shift;
    $self->{'connector'}->sql_disconnect() if $self->{'connector'};
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2007 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>.

=cut
