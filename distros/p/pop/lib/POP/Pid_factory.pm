=head1 CLASS
Title:	POP::Pid_factory.pm
Desc:	PID factory for persistent objects.
Author:	T. Burzesi (copied from Fid_factory.pm)
=cut

package POP::Pid_factory;

$VERSION = do{my(@r)=q$Revision: 1.3 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use POP::Id_factory;
use POP::Environment qw/$POP_PID_FILE/;
use vars qw/@ISA $VERSION/;

@ISA = qw/POP::Id_factory/;

=head2 CONSTRUCTOR
Title:	POP::Pid_factory::new
Desc: 	Constructor. Sets file attribute to PID file.
Error:	YES
=cut

sub new {
  my $type = shift;
  return $type->SUPER::new($POP_PID_FILE);
}
$VERSION = $VERSION;
