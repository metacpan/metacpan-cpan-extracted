=head1 NAME

XAO::DO::Cache::Uncached - a non-caching backend

=head1 SYNOPSIS

You should not use this object directly, it is a back-end for
XAO::Cache.

=head1 DESCRIPTION

Cache::Uncached is an implementation that always calls the retrieve
method without attempting any caching. Helpful in debugging and
development.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Cache::Uncached;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Atom');

###############################################################################

sub drop ($@) {
    return undef;
}

###############################################################################

sub drop_all ($$$) {
    return undef;
}

###############################################################################

sub get ($$) {
    return undef;
}

###############################################################################

sub put ($$$) {
    return undef;
}

###############################################################################

sub setup ($%) {
    return undef;
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::DO::Cache::Memory>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
