package WoW::Armory::API;

use strict;
use warnings;

our $VERSION = '1.031';

use base 'Exporter';

our @EXPORT = qw(
    WOW_CHARACTER_FIELDS WOW_GUILD_FIELDS
    WOW_ARENA_TEAM_2 WOW_ARENA_TEAM_3 WOW_ARENA_TEAM_5
);

use URI::Escape;
use LWP::UserAgent;
use JSON::XS;

use constant WOW_REGIONS =>
{
    us  => { api_host => 'us.battle.net'       , locales => [qw(en_US es_MX pt_BR)] },
    eu  => { api_host => 'eu.battle.net'       , locales => [qw(en_GB es_ES fr_FR ru_RU de_DE pt_PT it_IT)] },
    kr  => { api_host => 'kr.battle.net'       , locales => [qw(ko_KR)] },
    tw  => { api_host => 'tw.battle.net'       , locales => [qw(zh_TW)] },
    cn  => { api_host => 'www.battlenet.com.cn', locales => [qw(zh_CN)] },
};

use constant WOW_API_METHODS =>
[
    ['achievement'                 , 1],
    ['auction/data'                , 1],
    ['battlePet/ability'           , 1],
    ['battlePet/species'           , 1],
    ['battlePet/stats'             , 1, [qw(level breedId qualityId)]],
    ['challenge'                   , 1],
    ['challenge/region'            , 0],
    ['character'                   , 2, [qw(fields)]],
    ['item'                        , 1],
    ['item/set'                    , 1],
    ['guild'                       , 2, [qw(fields)]],
    ['arena'                       , 3],
    ['pvp/arena'                   , 2, [qw(page size asc)]],
    ['pvp/ratedbg/ladder'          , 0, [qw(page size asc)]],
    ['quest'                       , 1],
    ['realm/status'                , 0],
    ['recipe'                      , 1],
    ['spell'                       , 1],
    ['data/battlegroups'           , 0],
    ['data/character/races'        , 0],
    ['data/character/classes'      , 0],
    ['data/character/achievements' , 0],
    ['data/guild/rewards'          , 0],
    ['data/guild/perks'            , 0],
    ['data/guild/achievements'     , 0],
    ['data/item/classes'           , 0],
    ['data/talents'                , 0],
    ['data/pet/types'              , 0],
];

use constant WOW_CHARACTER_FIELDS => [qw(achievements appearance feed guild hunterPets items mounts pets petSlots
    professions progression pvp quests reputation stats talents titles)];

use constant WOW_GUILD_FIELDS => [qw(members achievements news challenge)];

use constant WOW_ARENA_TEAM_2 => '2v2';
use constant WOW_ARENA_TEAM_3 => '3v3';
use constant WOW_ARENA_TEAM_5 => '5v5';

sub _init_package {
    my $class = shift;

    for my $def (@{WOW_API_METHODS()}) {
        no strict 'refs';
        *{$class.'::Get'.join('', map { ucfirst $_ } split('/', $def->[0]))} = sub {
            return shift->DoApiCall(
                join('/', $def->[0], splice(@_, 0, $def->[1])),
                map { my $t = shift; defined $t ? ($_ => $t) : () } @{$def->[2]||[]},
            );
        };
    }
}

sub new {
    my $proto = shift;

    my $class = ref $proto || $proto;
    my $self = bless {}, $class;

    return $self->_init(@_);
}

sub _init {
    my ($self, %opts) = @_;

    $self->{ua} = LWP::UserAgent->new;

    $self->SetRegion('us');

    $self->SetRegion($opts{Region}) if exists $opts{Region};
    $self->SetLocale($opts{Locale}) if exists $opts{Locale};

    return $self;
}

sub GetRegions {
    return {regions => [
        map {{region => $_, %{WOW_REGIONS()->{$_}}}} keys %{WOW_REGIONS()}
    ]};
}

sub SetRegion {
    my ($self, $region, $locale) = @_;
    return if !WOW_REGIONS()->{$region};
    $self->{region} = $region;
    $self->SetLocale($locale);
}

sub HasLocale {
    my ($self, $locale) = @_;
    return !!grep {$_ eq $locale}
        @{WOW_REGIONS()->{$self->{region}}{locales}}
}

sub SetLocale {
    my ($self, $locale) = @_;
    if (!defined $locale) {
        $self->{locale} = undef;
        return;
    }
    return if !$self->HasLocale($locale);
    $self->{locale} = $locale;
}

sub GetApiHost {
    my ($self) = @_;
    return WOW_REGIONS()->{$self->{region}}{api_host};
}

sub DoApiCall {
    my ($self, $method, @opts) = @_;

    push @opts, (locale => $self->{locale}) if $self->{locale};
    push @opts, (rand => rand);

    my $query = join('&', map {
        uri_escape_utf8(shift @opts).'='.uri_escape_utf8(shift @opts)
    } (1..scalar(@opts)/2));

    my $url = 'http://'.$self->GetApiHost."/api/wow/${method}?${query}";
    my $res = $self->{ua}->get($url);

    #return undef if !$res->is_success;

    my $data = eval { decode_json $res->decoded_content };

    return $@ ? undef : $data;
}

__PACKAGE__->_init_package;

1;

=head1 NAME

WoW::Armory::API - Perl interface to WoW API

=head1 SYNOPSIS

    use WoW::Armory::API;

    $api = WoW::Armory::API->new(Region => 'eu', Locale => 'ru_RU');

    $char_data = $api->GetCharacter('realm', 'Character', 'items,pets,mounts');
    $guild_data = $api->GetGuild('realm', 'Guild');

    print $char_data->{items}{head}{name};
    print $guild_data->{name};

    use WoW::Armory::Class::Character;
    use WoW::Armory::Class::Guild;

    $char = WoW::Armory::Class::Character->new($char_data);
    $guild = WoW::Armory::Class::Guild->new($guild_data);

    print $char->items->head->name;
    print $guild->name;

=head1 METHODS

=head2 Constants

=head3 WOW_CHARACTER_FIELDS

    @fields = @{WOW_CHARACTER_FIELDS()};
    $data = $api->GetCharacter($realmId, $characterName, join(',', @fields));

=head3 WOW_GUILD_FIELDS

    @fields = @{WOW_GUILD_FIELDS()};
    $data = $api->GetGuild($realmId, $guildName, join(',', @fields));

=head3  WOW_ARENA_TEAM_2

    $data = $api->GetArena($realmId, WOW_ARENA_TEAM_2, $teamName);

=head3 WOW_ARENA_TEAM_3

    $data = $api->GetArena($realmId, WOW_ARENA_TEAM_3, $teamName);

=head3 WOW_ARENA_TEAM_5

    $data = $api->GetArena($realmId, WOW_ARENA_TEAM_5, $teamName);

=head2 Constructor

=head3 new()

    $api = WoW::Armory::API->new;
    $api = WoW::Armory::API->new(Region => $regionId, Locale => $locale);

=head2 General

=head3 GetRegions()

    $data = WoW::Armory::API->GetRegions();
    $data = $api->GetRegions();

=head3 SetRegion()

    $api->SetRegion($regionId);
    $api->SetRegion($regionId, $locale);

=head3 HasLocale()

    $hasLocale = $api->HasLocale($locale);

=head3 SetLocale()

    $api->SetLocale($locale);

=head3 GetApiHost()

    $host = $api->GetApiHost();

=head3 DoApiCall()

    $data = $api->DoApiCall($method, @params);

=head2 WoW API

All of these methods return the appropriate data structure or undef.
See L<http://blizzard.github.com/api-wow-docs/> for more details.

=head3 GetAchievement()

    $data = $api->GetAchievement($achievementId);

=head3 GetAuctionData()

    $data = $api->GetAuctionData($realmId);

=head3 GetBattlePetAbility()

    $data = $api->GetBattlePetAbility($abilityId);

=head3 GetBattlePetSpecies()

    $data = $api->GetBattlePetSpecies($speciesId);

=head3 GetBattlePetStats()

    $data = $api->GetBattlePetStats($speciesId);
    $data = $api->GetBattlePetStats($speciesId, $level, $breedId, $qualityId);

=head3 GetChallenge()

    $data = $api->GetChallenge($realmId);

=head3 GetChallengeRegion()

    $data = $api->GetChallengeRegion();

=head3 GetCharacter()

    $data = $api->GetCharacter($realmId, $characterName);
    $data = $api->GetCharacter($realmId, $characterName, $fields);

=head3 GetItem()

    $data = $api->GetItem($itemId);

=head3 GetItemSet()

    $data = $api->GetItemSet($itemSetId);

=head3 GetGuild()

    $data = $api->GetGuild($realmId, $guildName);
    $data = $api->GetGuild($realmId, $guildName, $fields);

=head3 GetArena()

    $data = $api->GetArena($realmId, $teamSize, $teamName);

=head3 GetPvpArena()

    $data = $api->GetPvpArena($battleGroup, $teamSize);
    $data = $api->GetPvpArena($battleGroup, $teamSize, $page, $pageSize, $asc);

=head3 GetPvpRatedbgLadder()

    $data = $api->GetPvpRatedbgLadder();
    $data = $api->GetPvpRatedbgLadder($page, $pageSize, $asc);

=head3 GetQuest()

    $data = $api->GetQuest($questId);

=head3 GetRealmStatus()

    $data = $api->GetRealmStatus();

=head3 GetRecipe()

    $data = $api->GetRecipe($recipeId);

=head3 GetSpell()

    $data = $api->GetSpell($spellId);

=head3 GetDataBattlegroups()

    $data = $api->GetDataBattlegroups();

=head3 GetDataCharacterRaces()

    $data = $api->GetDataCharacterRaces();

=head3 GetDataCharacterClasses()

    $data = $api->GetDataCharacterClasses();

=head3 GetDataCharacterAchievements()

    $data = $api->GetDataCharacterAchievements();

=head3 GetDataGuildRewards()

    $data = $api->GetDataGuildRewards();

=head3 GetDataGuildPerks()

    $data = $api->GetDataGuildPerks();

=head3 GetDataGuildAchievements()

    $data = $api->GetDataGuildAchievements();

=head3 GetDataItemClasses()

    $data = $api->GetDataItemClasses();

=head3 GetDataTalents()

    $data = $api->GetDataTalents();

=head3 GetDataPetTypes()

    $data = $api->GetDataPetTypes();

=head1 SEE ALSO

L<http://blizzard.github.com/api-wow-docs/>

=head1 REPOSITORY

The source code for the WoW::Armory::API is held in a public git repository
on Github: L<https://github.com/Silencer2K/perl-wow-api>

=head1 AUTHOR

Aleksandr Aleshin F<E<lt>silencer@cpan.orgE<gt>>

=head1 COPYRIGHT

This software is copyright (c) 2012 by Aleksandr Aleshin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
