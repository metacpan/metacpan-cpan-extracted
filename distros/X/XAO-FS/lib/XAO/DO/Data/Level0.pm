=head1 NAME

XAO::DO::Data::Level0

=head1 SYNOPSIS

None

=head1 DESCRIPTION

=cut

###############################################################################
package XAO::DO::Data::Level0;
use strict;
use XAO::Objects;

use vars qw(@ISA);
@ISA=XAO::Objects->load(objname => 'FS::Hash');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Level0.pm,v 1.1 2007/01/06 18:57:52 enn Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
1;
__END__

=head1 AUTHOR
