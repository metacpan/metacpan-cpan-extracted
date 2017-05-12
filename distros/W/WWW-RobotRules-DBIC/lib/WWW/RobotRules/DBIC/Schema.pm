package WWW::RobotRules::DBIC::Schema;

# Created by DBIx::Class::Schema::Loader v0.03007 @ 2006-10-18 11:53:27

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw(UserAgent Netloc Rule));

1;

