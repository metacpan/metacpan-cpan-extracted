package WebService::EveOnline::API::Character;

use base qw/ WebService::EveOnline::Base /;

our $VERSION = "0.61";

=head4 new

This is called under the hood when an $eve->character object is requested.

It returns an array of character objects for each characters available via
your API key. You probably won't need to call this directly.

=cut

sub new {
    my ($self, $c, $name) = @_;

    my $character_data = $self->call_api('character', {}, $c);

    # XML::Simple is a big pile of shit:
    $character_data = ($character_data->{name}) ? { $character_data->{name} => $character_data } : $character_data;

    my $characters = [];
    foreach my $character (sort keys %{$character_data}) {
        next if $character =~ /^_/; # skip meta keys
        
        my $char_obj = bless({ 
                 _character_name => $character, 
                 _corporation_name => $character_data->{$character}->{corporationName},
                 _corporation_id => $character_data->{$character}->{corporationID},
                 _character_id => $character_data->{$character}->{characterID},
                 _api_key => $c->{_api_key},
                 _user_id => $c->{_user_id},
                 _evecache => $c->{_evecache},
            }, __PACKAGE__ );
        
        if ($name) {
            return $char_obj if $char_obj->name eq $name;
        } else {
            push(@{$characters}, $char_obj);
        }
    }
    
    return @{$characters};
}

=head2 $character->hashref

Returns a character hashref on a character object containing the following keys:

   character_id
   character_name
   character_race
   character_gender
   character_bloodline
   corporation_name
   corporation_id

=cut

sub hashref {
    my ($self) = @_;
    return {
        character_name => $self->{_character_name},
        corporation_name => $self->{_corporation_name},
        character_id => $self->{_character_id},
        corporation_id => $self->{_corporation_id},
        character_race => $self->character_race,
        character_gender => $self->character_gender,
        character_bloodline => $self->character_bloodline,
    };
}

=head2 assets

Placeholder

=cut

sub assets {
    my ($self, $params) = @_;
    my $assets = $self->call_api('assets', { characterID => $self->{_character_id} }, $self);
    return $assets;   
}

=head2 kills

Placeholder

=cut

sub kills {
    my ($self, $params) = @_;
    my $kills = $self->call_api('kills', { characterID => $self->{_character_id} }, $self);
    return $kills;   
}

=head2 orders

Placeholder

=cut

sub orders {
    my ($self, $params) = @_;
    my $orders = $self->call_api('orders', { characterID => $self->{_character_id} }, $self);
    return $orders;   
}

=head2 $character->name

Returns the name of the current character based on the character object.

=cut

sub name {
    my ($self) = @_;
    return $self->{_character_name};
}

=head2 $character->id

Returns a character object based on the character id you provide, assuming
your API key allows it.

=cut

sub id {
    my ($self) = @_;
    return $self->{_character_id};      
}

=head2 $character->race

The race of the selected character.

=cut

sub race {
    my ($self, $params) = @_;
    my $race = $self->call_api('race', { characterID => $self->{_character_id} }, $self);
    return $race->{race};   
}

=head2 $character->bloodline

The bloodline of the selected character.

=cut

sub bloodline {
    my ($self, $params) = @_;
    my $bloodline = $self->call_api('bloodline', { characterID => $self->{_character_id} }, $self);
    return $bloodline->{bloodLine}; 
}

=head2 $character->gender, sex

The gender of the selected character.

=cut

sub gender {
    my ($self, $params) = @_;
    my $gender = $self->call_api('gender', { characterID => $self->{_character_id} }, $self);
    return $gender->{gender};   
}

sub sex {
    my ($self, $params) = @_;
    my $gender = $self->call_api('gender', { characterID => $self->{_character_id} }, $self);
    return $gender->{gender};   
}

=head2 $character->attributes

Sets the base attributes held by the selected character.

=cut

sub attributes {
    my ($self, $params) = @_;
    my $attributes = $self->call_api('attributes', { characterID => $self->{_character_id} }, $self);

    $self->{_attributes} = {
        _memory => $attributes->{memory},
        _intelligence => $attributes->{intelligence},
        _charisma => $attributes->{charisma},
        _perception => $attributes->{perception},
        _willpower => $attributes->{willpower},
    };

    return bless($self, __PACKAGE__);    
}

=head2 $character->attributes->memory, $attributes->memory

Returns the base memory attribute of the current character

=cut

sub memory {
    my ($self) = @_;
    return $self->{_attributes}->{_memory};
}

=head2 $character->attributes->intelligence, $attributes->intelligence

Returns the base intelligence attribute of the current character

=cut

sub intelligence {
    my ($self) = @_;
    return $self->{_attributes}->{_intelligence};
}

=head2 $character->attributes->charisma, $attributes->charisma

Returns the base charisma attribute of the current character

=cut

sub charisma {
    my ($self) = @_;
    return $self->{_attributes}->{_charisma};
}

=head2 $character->attributes->perception, $attributes->perception

Returns the base perception attribute of the current character

=cut

sub perception {
    my ($self) = @_;
    return $self->{_attributes}->{_perception};
}

=head2 $character->attributes->willpower, $attributes->willpower

Returns the base willpower attribute of the current character

=cut

sub willpower {
    my ($self) = @_;
    return $self->{_attributes}->{_willpower};
}

=head2 $character->attributes->attr_hashref, $attributes->attr_hashref

Returns a hashref containing the base attributes of the
current character with the following keys:
    
    memory
    intelligence
    charisma
    perception
    willpower

=cut

sub attr_hashref {
    my ($self) = @_;
    return {
        memory => $self->{_attributes}->{_memory},  
        intelligence => $self->{_attributes}->{_intelligence},  
        charisma => $self->{_attributes}->{_charisma},  
        perception => $self->{_attributes}->{_perception},  
        willpower => $self->{_attributes}->{_willpower},  
    };
}

=head2 $character->attribute_enhancers

Returns a hash of hashes of the attribute enhancers held by the selected character.
The interface to this is highly likely to change to be more consistent with the rest of the
interface, so use with caution.

=cut

sub attribute_enhancers {
    my ($self, $params) = @_;
    my $enhancers = $self->call_api('enhancers', { characterID => $self->{_character_id} }, $self);
    return $enhancers;  
}

1;
