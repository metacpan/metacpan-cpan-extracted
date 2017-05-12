package WoW::Armory::Class::Character;

use strict;
use warnings;

use WoW::Armory::Class::Guild;

########################################################################
package WoW::Armory::Class::Character::Titles;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'id', 'name', 'selected'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents::Talents::Spell;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'castTime', 'cooldown', 'description', 'icon', 'id', 'name', 'powerCost',
    'range', 'subtext'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents::Talents;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'column', 'tier'
];

use constant BLESSED_FIELDS =>
{
    'spell' => 'WoW::Armory::Class::Character::Talents::Talents::Spell',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents::Spec;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'backgroundImage', 'description', 'icon', 'name', 'order', 'role'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents::Glyphs::Glyph;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'glyph', 'icon', 'item', 'name'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents::Glyphs;

use base 'WoW::Armory::Class';

use constant LIST_FIELDS =>
{
    'major' => 'WoW::Armory::Class::Character::Talents::Glyphs::Glyph',
    'minor' => 'WoW::Armory::Class::Character::Talents::Glyphs::Glyph',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Talents;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'calcGlyph', 'calcSpec', 'calcTalent', 'selected'
];

use constant BLESSED_FIELDS =>
{
    'glyphs'    => 'WoW::Armory::Class::Character::Talents::Glyphs',
    'spec'      => 'WoW::Armory::Class::Character::Talents::Spec',
};

use constant LIST_FIELDS =>
{
    'talents'   => 'WoW::Armory::Class::Character::Talents::Talents',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Stats;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'agi', 'armor', 'attackPower', 'block', 'blockRating', 'crit', 'critRating',
    'dodge', 'dodgeRating', 'expertiseRating', 'hasteRating', 'health', 'hitPercent',
    'hitRating', 'int', 'mainHandDmgMax', 'mainHandDmgMin', 'mainHandDps',
    'mainHandExpertise', 'mainHandSpeed', 'mana5', 'mana5Combat', 'mastery',
    'masteryRating', 'offHandDmgMax', 'offHandDmgMin', 'offHandDps', 'offHandExpertise',
    'offHandSpeed', 'parry', 'parryRating', 'power', 'powerType', 'pvpPower',
    'pvpPowerRating', 'pvpResilience', 'pvpResilienceRating', 'rangedAttackPower',
    'rangedCrit', 'rangedCritRating', 'rangedDmgMax', 'rangedDmgMin', 'rangedDps',
    'rangedExpertise', 'rangedHitPercent', 'rangedHitRating', 'rangedSpeed',
    'spellCrit', 'spellCritRating', 'spellHitPercent', 'spellHitRating', 'spellPen',
    'spellPower', 'spr', 'sta', 'str'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Reputation;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'id', 'max', 'name', 'standing', 'value'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pvp::RatedBattlegrounds::Battlegrounds;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'name', 'played', 'won'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pvp::RatedBattlegrounds;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'personalRating'
];

use constant LIST_FIELDS =>
{
    'battlegrounds' => 'WoW::Armory::Class::Character::Pvp::RatedBattlegrounds::Battlegrounds',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pvp;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'arenaTeams', 'totalHonorableKills'
];

use constant BLESSED_FIELDS =>
{
    'ratedBattlegrounds'    => 'WoW::Armory::Class::Character::Pvp::RatedBattlegrounds',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Progression::Raids::Bosses;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'heroicKills', 'id', 'name', 'normalKills'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Progression::Raids;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'heroic', 'id', 'name', 'normal'
];

use constant LIST_FIELDS =>
{
    'bosses'    => 'WoW::Armory::Class::Character::Progression::Raids::Bosses',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Progression;

use base 'WoW::Armory::Class';

use constant LIST_FIELDS =>
{
    'raids' => 'WoW::Armory::Class::Character::Progression::Raids',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Professions::Profession;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'icon', 'id', 'max', 'name', 'rank', 'recipes'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Professions;

use base 'WoW::Armory::Class';

use constant LIST_FIELDS =>
{
    'primary'   => 'WoW::Armory::Class::Character::Professions::Profession',
    'secondary' => 'WoW::Armory::Class::Character::Professions::Profession',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pets::Collected::Stats;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'breedId', 'health', 'level', 'petQualityId', 'power', 'speciesId', 'speed'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pets::Collected;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'battlePetId', 'canBattle', 'creatureId', 'creatureName', 'icon', 'isFavorite',
    'itemId', 'name', 'qualityId', 'spellId'
];

use constant BLESSED_FIELDS =>
{
    'stats' => 'WoW::Armory::Class::Character::Pets::Collected::Stats',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Pets;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'numCollected', 'numNotCollected'
];

use constant LIST_FIELDS =>
{
    'collected' => 'WoW::Armory::Class::Character::Pets::Collected',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::PetSlots;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'abilities', 'battlePetId', 'isEmpty', 'isLocked', 'slot'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Mounts::Collected;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'creatureId', 'icon', 'isAquatic', 'isFlying', 'isGround', 'isJumping',
    'itemId', 'name', 'qualityId', 'spellId'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Mounts;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'numCollected', 'numNotCollected'
];

use constant LIST_FIELDS =>
{
    'collected' => 'WoW::Armory::Class::Character::Mounts::Collected',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Items::Item::TooltipParams;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'enchant', 'reforge'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Items::Item;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'icon', 'id', 'name', 'quality'
];

use constant BLESSED_FIELDS =>
{
    'tooltipParams' => 'WoW::Armory::Class::Character::Items::Item::TooltipParams',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Items;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'averageItemLevel', 'averageItemLevelEquipped'
];

use constant BLESSED_FIELDS =>
{
    'back'      => 'WoW::Armory::Class::Character::Items::Item',
    'chest'     => 'WoW::Armory::Class::Character::Items::Item',
    'feet'      => 'WoW::Armory::Class::Character::Items::Item',
    'finger1'   => 'WoW::Armory::Class::Character::Items::Item',
    'finger2'   => 'WoW::Armory::Class::Character::Items::Item',
    'hands'     => 'WoW::Armory::Class::Character::Items::Item',
    'head'      => 'WoW::Armory::Class::Character::Items::Item',
    'legs'      => 'WoW::Armory::Class::Character::Items::Item',
    'mainHand'  => 'WoW::Armory::Class::Character::Items::Item',
    'neck'      => 'WoW::Armory::Class::Character::Items::Item',
    'shirt'     => 'WoW::Armory::Class::Character::Items::Item',
    'shoulder'  => 'WoW::Armory::Class::Character::Items::Item',
    'trinket1'  => 'WoW::Armory::Class::Character::Items::Item',
    'trinket2'  => 'WoW::Armory::Class::Character::Items::Item',
    'waist'     => 'WoW::Armory::Class::Character::Items::Item',
    'wrist'     => 'WoW::Armory::Class::Character::Items::Item',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::HunterPets;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'calcSpec', 'creature', 'familyId', 'familyName', 'name', 'selected', 'slot'
];

use constant BLESSED_FIELDS =>
{
    'spec'  => 'WoW::Armory::Class::Character::Talents::Spec',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Guild;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'achievementPoints', 'battlegroup', 'level', 'members', 'name', 'realm'
];

use constant BLESSED_FIELDS =>
{
    'emblem'    => 'WoW::Armory::Class::Guild::Emblem',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Feed::Criteria;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'description', 'id', 'max', 'orderIndex'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Feed::Achievement;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'accountWide', 'description', 'factionId', 'icon', 'id', 'points', 'reward',
    'title'
];

use constant LIST_FIELDS =>
{
    'criteria'      => 'WoW::Armory::Class::Character::Feed::Criteria',
    'rewardItems'   => 'WoW::Armory::Class::Character::Items::Item',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Feed;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'featOfStrength', 'itemId', 'name', 'quantity', 'timestamp', 'type'
];

use constant BLESSED_FIELDS =>
{
    'achievement'   => 'WoW::Armory::Class::Character::Feed::Achievement',
    'criteria'      => 'WoW::Armory::Class::Character::Feed::Criteria',
};

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Appearance;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'faceVariation', 'featureVariation', 'hairColor', 'hairVariation', 'showCloak',
    'showHelm', 'skinColor'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character::Achievements;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'achievementsCompleted', 'achievementsCompletedTimestamp', 'criteria',
    'criteriaCreated', 'criteriaQuantity', 'criteriaTimestamp'
];

__PACKAGE__->mk_accessors;

########################################################################
package WoW::Armory::Class::Character;

use base 'WoW::Armory::Class';

use constant FIELDS => [
    'achievementPoints', 'battlegroup', 'calcClass', 'class', 'gender', 'lastModified',
    'level', 'name', 'quests', 'race', 'realm', 'thumbnail'
];

use constant BLESSED_FIELDS =>
{
    'achievements'  => 'WoW::Armory::Class::Character::Achievements',
    'appearance'    => 'WoW::Armory::Class::Character::Appearance',
    'guild'         => 'WoW::Armory::Class::Character::Guild',
    'items'         => 'WoW::Armory::Class::Character::Items',
    'mounts'        => 'WoW::Armory::Class::Character::Mounts',
    'pets'          => 'WoW::Armory::Class::Character::Pets',
    'professions'   => 'WoW::Armory::Class::Character::Professions',
    'progression'   => 'WoW::Armory::Class::Character::Progression',
    'pvp'           => 'WoW::Armory::Class::Character::Pvp',
    'stats'         => 'WoW::Armory::Class::Character::Stats',
};

use constant LIST_FIELDS =>
{
    'feed'          => 'WoW::Armory::Class::Character::Feed',
    'hunterPets'    => 'WoW::Armory::Class::Character::HunterPets',
    'petSlots'      => 'WoW::Armory::Class::Character::PetSlots',
    'reputation'    => 'WoW::Armory::Class::Character::Reputation',
    'talents'       => 'WoW::Armory::Class::Character::Talents',
    'titles'        => 'WoW::Armory::Class::Character::Titles',
};

__PACKAGE__->mk_accessors;

1;
