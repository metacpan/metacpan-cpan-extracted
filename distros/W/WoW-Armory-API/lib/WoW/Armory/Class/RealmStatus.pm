package WoW::Armory::Class::RealmStatus;

use strict;
use warnings;

########################################################################
package WoW::Armory::Class::RealmStatus::Realms::Battlegrounds;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'area', 'controlling-faction', 'next', 'status'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::RealmStatus::Realms;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'battlegroup', 'locale', 'name', 'population', 'queue', 'slug', 'status',
    'timezone', 'type'
];

use constant BLESSED_FIELDS =>
{
    'tol-barad'     => 'WoW::Armory::Class::RealmStatus::Realms::Battlegrounds',
    'wintergrasp'   => 'WoW::Armory::Class::RealmStatus::Realms::Battlegrounds',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::RealmStatus;

use base 'WoW::Armory::Class';

use constant LIST_FIELDS =>
{
    'realms'    => 'WoW::Armory::Class::RealmStatus::Realms',
};

__PACKAGE__->mk_accessors;

1;
