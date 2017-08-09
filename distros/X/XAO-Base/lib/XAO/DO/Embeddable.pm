=head1 NAME

XAO::DO::Embeddable - recommended base object for XAO embeddable configs

=head1 SYNOPSIS

 package XAO::DO::Foo::Config;
 use strict;
 use XAO::Objects;
 use base XAO::Objects->load(objname => 'Embeddable');

=head1 DESCRIPTION

Provides set_base_config() and base_config() methods to embeddable
configs based on it.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Embeddable;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Embeddable.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item set_base_config ($)

Called automatically with one argument -- reference to the configuration
object it is being embedded into.

=cut

sub set_base_config ($%) {
    my ($self,$base)=@_;
    $self->{_embedding_base_config}=$base;
}

###############################################################################

=item base_config ($)

Returns previously stored base config reference. Reason to have this
method is the following: methods of embedded configs are called in the
namespace of their own and common configuration object is not available
from them through normal @ISA relations.

=cut

sub base_config ($%) {
    my $self=shift;
    return $self->{_embedding_base_config};
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2003 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

L<XAO::DO::Config>
