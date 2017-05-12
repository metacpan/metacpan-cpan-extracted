package UR::Namespace::Command::List::Objects;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

use above "UR";
use UR::Object::Command::List;

class UR::Namespace::Command::List::Objects { 
  is =>  'UR::Object::Command::List',
};

1;

#$HeadURL: svn+ssh://svn/srv/svn/gscpan/distro/ur-bundle/trunk/lib/UR/Namespace/Command/List/Objects.pm $
#$Id: Objects.pm 36327 2008-07-08 20:59:29Z ebelter $
