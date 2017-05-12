package WebService::EveOnline::API::Corporation;

use base qw/ WebService::EveOnline::Base /;

our $VERSION = "0.61";

=head2 $character->corporation

=head4 new

This is called under the hood when an $eve->character->corporation object is requested.

It returns a corporation object for the character it is called upon.

 You probably won't need to call this directly.

=cut

sub new {
    my ($self, $c, $name) = @_;

    return bless({ _character_id => $c->id, _evecache => $c->{_evecache}, _api_key => $c->{_api_key}, _user_id => $c->{_user_id} }, __PACKAGE__);

}

=head2 members

Returns an array of corporate member objects when called in list context, otherwise
it returns your own corporate details.

=cut

sub members {
    my ($self, $c, $name) = @_;

    $c ||= $self;
    
    my $cid = $c->id || $c->{_character_id};
    
    my $members = $self->call_api('corp_members', { characterID => $cid }, $c);
    return undef unless $members;

    my @member_objs;
    
    foreach my $mref (keys %{$members}) {
        my $member = $members->{$mref};
        push(@member_objs, bless({
                _id => $member->{characterID},
                _name => $mref,
                _title => $member->{title},
                _location => $member->{location},
                _location_id => $member->{locationID},
                _ship_type => $member->{shipType},
                _ship_type_id => $member->{shipTypeID},
                _start_time => &WebService::EveOnline::Cache::_evedate_to_epoch($member->{startDateTime}),
                _logon_time => &WebService::EveOnline::Cache::_evedate_to_epoch($member->{logonDateTime}),
                _logoff_time => $member->{logoffDateTime} ? &WebService::EveOnline::Cache::_evedate_to_epoch($member->{logoffDateTime}) : undef,
                _eve_logon_time => $member->{logonDateTime},
                _eve_logoff_time => $member->{logoffDateTime},
                _eve_start_time => $member->{startDateTime},
                _base => $member->{base},
                _base_id => $member->{baseID},
                _roles => $member->{roles},
                _grantable_roles => $member->{grantableRoles}, 
                _evecache => $c->{_evecache}, 
                _api_key => $c->{_api_key}, 
                _user_id => $c->{_user_id}, 
                _character_id => $cid
            }, __PACKAGE__)
        );
    }

    if (wantarray) {
        return @member_objs;
    } else {
        # try to return yourself rather than A Random Corp Member
        foreach $m (@member_objs) {
           return $m if $m->{_id} == $cid;
        }
        return $member_objs[0];
    }

}

=head2 id

Returns the id of the character/member of the corporation

=cut

sub id {
   my ($self, $c) = @_;
   return $self->{_id};
}

=head2 name

Returns the name of the character belonging to the corporation

=cut

sub name {
   my ($self, $c) = @_;
   return $self->{_name};
}

=head2 title

Returns the  of the character belonging to the corporation

=cut

sub title {
   my ($self, $c) = @_;
   return $self->{_title};
}

=head2 location

Returns the location of the character belonging to the corporation

=cut

sub location {
   my ($self, $c) = @_;
   return $self->{_location};
}

=head2 location_id

Returns the location id of the character belonging to the corporation

=cut

sub location_id {
   my ($self, $c) = @_;
   return $self->{_location_id};
}

=head2 ship_type

Returns the ship of the character belonging to the corporation

=cut

sub ship_type {
   my ($self, $c) = @_;
   return $self->{_ship_type};
}

=head2 ship_type_id

Returns the ship_type_id of the character belonging to the corporation

=cut

sub ship_type_id {
   my ($self, $c) = @_;
   return $self->{_ship_type_id};
}

=head2 joined

Returns the joining date of the character belonging to the corporation

Epoch seconds (GMT) is returned.

=cut

sub joined {
   my ($self, $c) = @_;
   return $self->{_start_time};
}

=head2 logged_on

Returns the time that the character belonging to the corporation last logged on

Epoch seconds (GMT) is returned.

=cut

sub logged_on {
   my ($self, $c) = @_;
   return $self->{_logon_time};
}

=head2 logged_off

Returns the time that the character belonging to the corporation last logged off

Epoch seconds (GMT) is returned.

=cut

sub logged_off {
   my ($self, $c) = @_;
   return $self->{_logoff_time};
}


=head2 online

Is the member online? (NB. This doesn't seem to work as the API doesn't seem to update
until a member logs off).

=cut

sub online {
    my ($self, $c) = @_;
    return ($self->logged_on > $self->logged_off) ? 1 : undef;
}

=head2 base

Returns the base where the character belonging to the corporation currently resides.

=cut

sub base {
   my ($self, $c) = @_;
   return $self->{_base};
}

=head2 base_id

Returns the base_id where the character belonging to the corporation currently resides.

=cut

sub base_id {
   my ($self, $c) = @_;
   return $self->{_base_id};
}

=head2 roles

Returns the roles the character belonging to the corporation plays.

=cut

sub roles {
   my ($self, $c) = @_;
   return $self->{_roles};
}

=head2 grantable_roles

Returns the roles grantable to the character belonging to the corporation.

=cut 

sub grantable_roles {
   my ($self, $c) = @_;
   return $self->{_grantable_roles};
}

=head2 hashref

A hashref containing all the data the EVE API returns about a particular
corporate member.

=cut

sub hashref {
    my ($self, $c) = @_;
    return {
        id => $self->{_id},
        name => $self->{_name},
        title => $self->{_title},
        location => $self->{_location},
        location_id => $self->{_location_id},
        ship_type => $self->{_ship_type},
        ship_type_id => $self->{_ship_type_id},
        start_time => $self->{_start_time},
        logon_time => $self->{_logon_time},
        logoff_time => $self->{_logoff_time},
        eve_start_time => $self->{_eve_start_time},
        eve_logon_time => $self->{_eve_logon_time},
        eve_logoff_time => $self->{_eve_logoff_time},
        base => $self->{_base},
        base_id => $self->{_base_id},
        roles => $self->{_roles},
        grantable_roles => $self->{_grantable_roles},         
    };
    
}

1;
