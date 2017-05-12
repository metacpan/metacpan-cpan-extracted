package VUser::Google::Groups::V2_0;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;
extends 'VUser::Google::Groups';

use VUser::Google::Groups::GroupEntry;

has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/group/2.0/');

#### Methods ####
# %options
#   groupId*
#   groupName*
#   description
#   emailPermission* (Owner | Member | Domain | Anyone)
sub CreateGroup {
    my $self = shift;
    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Groups::GroupEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    my $url = $self->base_url.$self->google->domain;

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006" xmlns:gd="http://schemas.google.com/g/2005">';
    $post .= '<apps:property name="groupId" value="'
	.$options{groupId}.'"/>';
    $post .= '<apps:property name="groupName" value="'
	.$options{groupName}.'"/>';
    $post .= '<apps:property name="description" value="'
	.$options{description}.'"/>';
    $post .= '<apps:property name="emailPermission" value="'
	.$options{emailPermission}.'"/>';

    $post .= '</atom:entry>';


    if ($self->google->Request('POST', $url, $post)) {
	my $entry = $self->_build_group_entry($self->google->result);
	return $entry;
    }
    else {
	die "Unable to create group: ".$self->google->result->{'reason'}."\n";
    }
}

# Cannot be used to rename the group
# %options
#   groupId*
#   newGroupId --- no
#   groupName*
#   description
#   emailPermission*
sub UpdateGroup {
    my $self    = shift;
    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Groups::GroupEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    my $url = $self->base_url.$self->google->domain."/$options{groupId}";

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006" xmlns:gd="http://schemas.google.com/g/2005">';

    if (0 and $options{newGroupId}) {
	$post .= '<apps:property name="groupId" value="'
	    .$options{newGroupId}.'"/>';
    }

    if ($options{groupName}) {
	$post .= '<apps:property name="groupName" value="'
	    .$options{groupName}.'"/>';
    }

    if ($options{description}) {
	$post .= '<apps:property name="description" value="'
	    .$options{description}.'"/>';
    };

    if ($options{emailPermission}) {
	$post .= '<apps:property name="emailPermission" value="'
	    .$options{emailPermission}.'"/>';
    };

    $post .= '</atom:entry>';


    if ($self->google->Request('PUT', $url, $post)) {
	my $entry = $self->_build_group_entry($self->google->result);
	return $entry;
    }
    else {
	die "Unable to create group: ".$self->google->result->{'reason'}."\n";
    }
}

sub RetrieveGroup {
    my $self    = shift;
    my $groupid = shift;

    my $url = $self->base_url.$self->google->domain."/$groupid";

    if ($self->google->Request('GET', $url)) {
	return $self->_build_group_entry($self->google->result);
    }
    else {
	if ($self->google->result->{'reason'} =~ /EntityDoesNotExist/) {
	    return undef;
	}
	else {
	    die "Error retrieving group: ".$self->google->result->{'reason'}."\n";
	}
    }
}

sub RetrieveAllGroupsInDomain {
    my $self = shift;

    return $self->RetrieveAllGroupsForMember();

#     my $url = $self->base_url.$self->google->domain;

#     my @groups = ();

#     if ($self->google->Request('GET', $url)) {
# 	foreach my $entry_xml (@{ $self->google->result->{'entry'} }) {
# 	    my $entry = $self->_build_group_entry($entry_xml);
# 	    push @groups, $entry;
# 	}
#     }
#     else {
# 	die "Cannot retrieve all groups in domain: ".
# 	    $self->google->result->{'reason'};
#     }

#     return @groups;
}

sub RetrieveAllGroupsForMember {
    my $self   = shift;
    my $member = shift;

    my $url = $self->base_url.$self->google->domain;
    if ($member) {
	$url = '?member='.$member;
    }

    my @groups = ();

    if ($self->google->Request('GET', $url)) {
	foreach my $entry_xml (@{ $self->google->result->{'entry'} }) {
	    my $entry = $self->_build_group_entry($entry_xml);
	    push @groups, $entry;
	}
    }
    else {
	die "Cannot retrieve all groups in domain: ".
	    $self->google->result->{'reason'};
    }

    return @groups;

}

sub DeleteGroup {
    my $self    = shift;
    my $groupId = shift;

    die "Cannot delete group: No group specified.\n" if not $groupId;

    my $url = $self->base_url.$self->google->domain."/$groupId";

    if ($self->google->Request('DELETE', $url)) {
	return 1;
    }
    else {
	die "Cannot delete group ($groupId): ".$self->google->result->{'reason'};
    }
}

sub AddMemberToGroup {
    my $self    = shift;
    my %options = @_;

    die "Cannot add member to group: No member specified\n" if not $options{'member'};
    die "Cannot add member to group: No group specified\n" if not $options{'group'};

    my $url = $self->base_url.$self->google->domain
	.'/'.$options{group}.'/member';

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:apps="http://schemas.google.com/apps/2006"
    xmlns:gd="http://schemas.google.com/g/2005">';

    $post .= "<apps:property name=\"memberId\" value=\"$options{'member'}\"/>";
    $post .= '</atom:entry>';

    if ($self->google->Request('POST', $url, $post)) {
	return 1;
    }
    else {
	die "Cannot add member to group: ".$self->google->result->{'reason'}."\n";
    }
}

sub RetrieveAllMembersOfGroup {
}

sub RetrieveMemberOfGroup {
}

sub RemoveMemberOfGroup {
}

sub AddOwnerToGroup {
}

sub RetrieveAllOwnersOfGroup {
}

sub RemoveOwnerFromGroup {
}

sub _build_group_entry {
    my $self = shift;
    my $xml  = shift;

    my $entry = VUser::Google::Groups::GroupEntry->new();

    $entry->GroupId($xml->{'apps:property'}{'groupId'}{'value'});
    $entry->GroupName($xml->{'apps:property'}{'groupName'}{'value'});
    $entry->Description($xml->{'apps:property'}{'description'}{'value'});
    $entry->EmailPermission($xml->{'apps:property'}{'emailPermission'}{'value'});

    return $entry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
