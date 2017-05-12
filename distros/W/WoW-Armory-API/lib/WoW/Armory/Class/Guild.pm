package WoW::Armory::Class::Guild;

use strict;
use warnings;

use WoW::Armory::Class::Character;
use WoW::Armory::Class::Time;

########################################################################
package WoW::Armory::Class::Guild::News;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'character', 'itemId', 'timestamp', 'type'
];

use constant BLESSED_FIELDS =>
{
    'achievement'   => 'WoW::Armory::Class::Character::Feed::Achievement',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Members::Character;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'achievementPoints', 'battlegroup', 'class', 'gender', 'guild', 'level',
    'name', 'race', 'realm', 'thumbnail'
];

use constant BLESSED_FIELDS =>
{
    'spec'  => 'WoW::Armory::Class::Character::Talents::Spec',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Members;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'rank'
];

use constant BLESSED_FIELDS =>
{
    'character' => 'WoW::Armory::Class::Guild::Members::Character',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Emblem;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'backgroundColor', 'border', 'borderColor', 'icon', 'iconColor'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Challenge::Realm;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'battlegroup', 'locale', 'name', 'slug', 'timezone'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Challenge::Map;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'hasChallengeMode', 'id', 'name', 'slug'
];

use constant BLESSED_FIELDS =>
{
    'bronzeCriteria'    => 'WoW::Armory::Class::Time',
    'goldCriteria'      => 'WoW::Armory::Class::Time',
    'silverCriteria'    => 'WoW::Armory::Class::Time',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Challenge::Groups::Members;

use base 'WoW::Armory::Class';

use constant BLESSED_FIELDS =>
{
    'character' => 'WoW::Armory::Class::Guild::Members::Character',
    'spec'      => 'WoW::Armory::Class::Character::Talents::Spec',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Challenge::Groups;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'date', 'faction', 'isRecurring', 'medal', 'ranking'
];

use constant BLESSED_FIELDS =>
{
    'guild' => 'WoW::Armory::Class::Character::Guild',
    'time'  => 'WoW::Armory::Class::Time',
};

use constant LIST_FIELDS =>
{
    'members'   => 'WoW::Armory::Class::Guild::Challenge::Groups::Members',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild::Challenge;

use base 'WoW::Armory::Class';

use constant BLESSED_FIELDS =>
{
    'map'   => 'WoW::Armory::Class::Guild::Challenge::Map',
    'realm' => 'WoW::Armory::Class::Guild::Challenge::Realm',
};

use constant LIST_FIELDS =>
{
    'groups'    => 'WoW::Armory::Class::Guild::Challenge::Groups',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Guild;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'achievementPoints', 'battlegroup', 'lastModified', 'level', 'name', 'realm',
    'side'
];

use constant BLESSED_FIELDS =>
{
    'achievements'  => 'WoW::Armory::Class::Character::Achievements',
    'emblem'        => 'WoW::Armory::Class::Guild::Emblem',
};

use constant LIST_FIELDS =>
{
    'challenge' => 'WoW::Armory::Class::Guild::Challenge',
    'members'   => 'WoW::Armory::Class::Guild::Members',
    'news'      => 'WoW::Armory::Class::Guild::News',
};

__PACKAGE__->mk_accessors;

1;
