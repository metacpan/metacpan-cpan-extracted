package WebService::EveOnline::API::Skills;

use strict;
use warnings;

use base qw/ WebService::EveOnline::Base /;

our $VERSION = "0.62";

=head2 new

This is called under the hood when an $eve->character->skill(s) object is requested.

It returns an array of character skill objects for each skill currently trained/
partially trained by the character.

You probably won't need to call this method directly.

=cut

sub new {
    my ($self, $c) = @_;

    return bless({
                     _skill_name => undef,
                     _skill_description => undef,
                     _skill_id => undef,
                     _skill_level => undef,
                     _skill_points => undef,
                     _evecache => $c->{_evecache},
                     _api_key => $c->{_api_key},
                     _user_id => $c->{_user_id},
                     _character_id => $c->id,
                 }, __PACKAGE__) unless $c->id;


    my $skills = $self->call_api('skills', { characterID => $c->id }, $c)->{skills};

    my @skillobjs;

    foreach my $skill (@{$skills}) {
        my $gs = $c->{_evecache}->get_skill($skill->{typeID});
        $skill->{name} = $gs->{typeName};
        $skill->{description} = $gs->{description};
        push(@skillobjs, bless({ 
            _skill_name => $gs->{typeName},
            _skill_description => $gs->{description},
            _skill_id => $skill->{typeID},
            _skill_level => $skill->{level},
            _skill_points => $skill->{skillpoints},
            _evecache => $c->{_evecache},
            _api_key => $c->{_api_key},
            _user_id => $c->{_user_id},
            _character_id => $c->id,
        }, __PACKAGE__));
    }

    if (wantarray) {
        return @skillobjs;
    } else {
        return $skillobjs[0];
    }

}

=head2 $character->in_training

Returns the skill currently in training for the selected character.

=cut

sub in_training {
    my ($self) = @_;
    my $raw_training = $self->call_api('training', { characterID => $self->{_character_id} }, $self);
    my $training = {};
    
    my $trainref = { _skill_id => undef, _skill_name => undef, _skill_description => undef, _skill_in_training => undef,
                     _skill_in_training_level => undef, _skill_in_training_start_time => undef, _skill_in_training_finish_time => undef,
                     _skill_in_training_start_sp => undef, _skill_in_training_finish_sp => undef, 
    };

    foreach my $tdetail (keys %{$raw_training}) {
        next if $tdetail =~ /^_/;
        next if ref($raw_training->{$tdetail}) eq "HASH";
        $training->{$tdetail} = $raw_training->{$tdetail};
    }

    return undef unless $training->{skillInTraining} == 1;

    my $gs = $self->{_evecache}->get_skill($training->{trainingTypeID});
    
    $trainref->{_skill_id} = $training->{trainingTypeID};
    $trainref->{_skill_name} = $gs->{typeName};
    $trainref->{_skill_description} = $gs->{description};
    $trainref->{_skill_level} = $training->{trainingToLevel};
    $trainref->{_skill_in_training} = $training->{skillInTraining};
    $trainref->{_skill_in_training_start_time} = &WebService::EveOnline::Cache::_evedate_to_epoch($training->{trainingStartTime}) if $training->{trainingStartTime};
    $trainref->{_skill_in_training_finish_time} = &WebService::EveOnline::Cache::_evedate_to_epoch($training->{trainingEndTime}) if $training->{trainingEndTime};
    $trainref->{_skill_in_training_start_sp} = $training->{trainingStartSP};
    $trainref->{_skill_in_training_finish_sp} = $training->{trainingDestinationSP};
    $trainref->{_evecache} = $self->{_evecache};
    $trainref->{_api_key} = $self->{_api_key};
    $trainref->{_user_id} = $self->{_user_id};
    $trainref->{_character_id} = $self->{_character_id};

    return bless($trainref, __PACKAGE__);
}

=head2 $character->in_training->seconds_remaining, $skill_in_training->seconds_remaining

If a skill is in training, returns the number of seconds left to go before it it finished.

=cut

sub seconds_remaining {
    my ($self) = @_;
    return ($self->in_training) ? ($self->finish_time - time) : undef;
}

=head2 $character->in_training->finished_training, $skill_in_training->finished_training

If a skill was in training, but has now finished, this will return true.

The EVE API has been a bit inconsistant with how it deals with skills that have finished/
are no longer in training, so use with caution.

=cut

sub finished_training {
    my ($self) = @_;
    return ($self->seconds_remaining <= 0) ? 1 : undef;
}

=head2 $character->in_training->time_remaining, $skill_in_training->time_remaining

The same as seconds_remaining, but returns in days-hours-minutes-seconds format, making it
easier for humans to read when dealing with large numbers of seconds.

=cut

sub time_remaining {
    my ($self) = @_;
    return undef unless $self->in_training;

    my @t = map { $_ = ($_ < 10) ? "0" . $_ : $_ } (gmtime($self->seconds_remaining));
    $t[7] += 0;

    return "$t[7]d $t[2]h $t[1]m $t[0]s";
}

=head2 $character->in_training->start_time, $skill_in_training->start_time

Start time (epoch seconds) of skill currently training

=cut

sub start_time {
    my ($self) = @_;
    return $self->{_skill_in_training_start_time} || 0;
}

=head2 $character->in_training->start_sp, $skill_in_training->start_sp

Start SP of skill currently training

=cut

sub start_sp {
    my ($self) = @_;
    return $self->{_skill_in_training_start_sp} || 0;
}


=head2 $character->in_training->finish_time, $skill_in_training->finish_time

Finish time (epoch seconds) of skill currently training

=cut

sub finish_time {
    my ($self) = @_;
    return $self->{_skill_in_training_finish_time} || 0;
}

=head2 $character->in_training->finish_sp, $skill_in_training->finish_sp

Finish SP of skill currently training

=cut

sub finish_sp {
    my ($self) = @_;
    return $self->{_skill_in_training_finish_sp} || 0;
}

=head2 $skill->description

Returns a skill description from a skill object.

=cut

sub description {
    my ($self) = @_;
    return $self->{_skill_description} ? $self->{_skill_description} : undef;
}

=head2 $skill->id

Returns a skill id from a skill object.

=cut

sub id {
    my ($self) = @_;
    return $self->{_skill_id} ? $self->{_skill_id} : undef;
}

=head2 $skill->level

Returns a skill level from a skill object.

=cut

sub level {
    my ($self) = @_;
    return $self->{_skill_level} ? $self->{_skill_level} : undef;
}

=head2 $skill->points

Returns the number of skill points from a skill object.

=cut

sub points {
    my ($self) = @_;
    return $self->{_skill_points} ? $self->{_skill_points} : undef;
}

=head2 $skill->name

Returns a skill name from a skill object.

=cut

sub name {
    my ($self) = @_;
    return $self->{_skill_name} ? $self->{_skill_name} : undef;
}

=head2 $skill->hashref

Returns a hashref from a skill object containing the following keys:

    skill_description
    skill_id
    skill_level
    skill_points
    skill_name

=cut

sub hashref {
    my ($self) = @_;
    
    return { 
        description => $self->{_skill_description} || undef,
        id =>  $self->{_skill_id} || undef,
        level => $self->{_skill_level} || undef,
        points => $self->{_skill_points} || undef,
        name => $self->{_skill_name} || undef,
    };
}

=head2 $character->all_eve_skills

Returns a big datastructure containing all currently available skills in EVE.
Used to build the skill cache.

=cut

sub all_eve_skills {
    my ($self, $c) = @_;
    return $self->call_api('all_skills', {}, $self);
}

1;

