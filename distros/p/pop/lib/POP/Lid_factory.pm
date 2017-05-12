package POP::Lid_factory;

use strict;
use POP::Id_factory;
use POP::Environment qw/$POP_LID_FILE/;
use vars qw/@ISA $VERSION/;

$VERSION = do{my(@r)=q$Revision: 1.1 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

@ISA = qw/POP::Id_factory/;

sub new {
  my $type = shift;
  return $type->SUPER::new($POP_LID_FILE)
}

$VERSION=$VERSION;
