#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects.pm,v $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to define a hierarchy of
#           objects which have an associated status and which trigger
#           actions based on that status.
#
#          Description: This perl library contains subroutines which simplify the
#           creation of a hierarchy of objects to which a status can
#           be assigned and to which actions can be assigned based on
#           that status.  The objects support the handling of templates,
#           expiration times, actions, status upgrades based on the
#           re-occurance of specified actions, etc.  It also supports
#           the generation of html to show graphical descriptions of the
#           statuses of the objects grouped by name and supports a drill
#           down approach to viewing objects which have more than 3
#           segments in their name.
#
#           Directions:
#
#           Invoked by: vbserver
#
#           Depends on: VBTK::Common.pm, VBTK::Actions.pm, VBTK::Template.pm, Date::Manip.pm
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: Objects.pm,v $
#       Revision 1.10  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.9  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.8  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.7  2002/02/19 19:03:58  bhenry
#       Changed to accept 'SetBaselineFlag' when setting status
#
#       Revision 1.6  2002/01/28 22:28:45  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/01/25 16:42:06  bhenry
#       Changed to serialized filename to end in '.ser'
#
#       Revision 1.4  2002/01/25 07:16:33  bhenry
#       Changed to use Storable instead of Serialize
#
#       Revision 1.3  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.2  2002/01/18 19:24:50  bhenry
#       Warning Fixes
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#
#

package VBTK::Objects;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Actions;
use VBTK::Templates;
use VBTK::RmtServer;
use VBTK::File;
use VBTK::Objects::History;
use VBTK::Objects::Rrd;
use File::Basename;
use Date::Manip;
use POSIX;
use Storable qw (freeze thaw);

our $VERBOSE=$ENV{'VERBOSE'};
our $CHANGED=0;
our $NO_CHANGE=1;
our $DELETED=2;
our $ERROR=-1;

our $VB_OBJ_FILE_DIR;
our @VB_TEMPLATE_LIST;
our $VB_IMPORTING_OBJECTS_FLG = 0;
our $VBVIEW_EXT_URL;
our $DEFAULT_PREFIX;
our $FORK_RRD_UPDATE;

our %NAME_CACHE;
our @PERSISTENT_PARMS = ('StatusHistoryLimit','Description','ChangeActionObjList',
    'ExpireAfter','UpgradeRuleObjList','GraphGroupList','BaselineDiffStatus',
    'RunningFrom','ScriptName','LogFile','Interval');
our %PERSISTENT_PARMS_HASH = map { $_ => 1 } @PERSISTENT_PARMS;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    # Load in the passed parms
    $self->set(@_);

    my $defaultParms = {
        Name          => $::REQUIRED,
        SegmentName   => $::REQUIRED,
        ObjectDir     => undef,
        ExternalURL   => undef,
        DefaultPrefix => undef,
        ForkRrdUpdate => undef,
    };

    # Validate passed parms
    $self->validateParms($defaultParms) || return undef;

    # Set global variables based on passed parms
    $VB_OBJ_FILE_DIR = $self->{ObjectDir}     if ($self->{ObjectDir});
    $VBVIEW_EXT_URL  = $self->{ExternalURL}   if ($self->{ExternalURL});
    $DEFAULT_PREFIX  = $self->{DefaultPrefix} if ($self->{DefaultPrefix});
    $FORK_RRD_UPDATE = $self->{ForkRrdUpdate} if ($self->{ForkRrdUpdate});

    my $name = $self->{Name};

    # If the object name starts with a '.' then prepend the default prefix
    $self->{Name} = $name = $DEFAULT_PREFIX . $name if ($name =~ /^\./);

    &log("Creating new object '$name'") if ($VERBOSE > 1);

    # Setup some internal lists and hashes
    $self->{historyObjList} = [];
    $self->{historyObjIndex} = {};
    $self->{childObjList} = {};
    $self->{grandchildObjectNames} = {};
    $self->{Status} = '';
    $self->{type} = '';

    # Choose the template for this object.  Template values are used if
    # corresponding values were not directly set by the process setting the
    # status.
    $self->selectTemplate();

    # Load our name into the NAME_CACHE hash
    $NAME_CACHE{$name} = $self;

    # Setup a place to store object data which needs to be persistent and then
    # try to load in data from that file if it exists.
    my $metaFileName     = "$VB_OBJ_FILE_DIR/$name/Object.ser";
    $self->{metaFileObj} = new VBTK::File($metaFileName);
    $self->loadMetaData;

    # Setup a place to store the baseline text.
    my $baselineFileName     = "$VB_OBJ_FILE_DIR/$name/Baseline.txt";
    $self->{baselineFileObj} = new VBTK::File($baselineFileName);

    # Load up any history which may exist for the object
    $self->loadAllHistory;

    # Initialize an Rrd object for us
    $self->{rrdObj} = new VBTK::Rrd(
        RrdDbPath => "$VB_OBJ_FILE_DIR/$name");

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     setStatus
# Description:  Do a quick-lookup of the specified object.  If it already exists
#               then check it's status.  If it's status isn't different than
#               the specified status, then there is no need to recurse through
#               the tree, and so we can jump directly to the object.
# Input Parms:  Object Name, Status, Status File Text, Recursion Depth
# Output Parms:
#-------------------------------------------------------------------------------
sub setStatus
{
    my $self = shift;
    my %args = @_;
    my ($key,$value);

    # If the ObjStruct parm was passed, then unload it into the args hash and
    # then delete it from the hash.
    if(defined $args{ObjStruct})
    {
        &log("Attempting to thaw obj struct") if ($VERBOSE > 2);
        my $objStruct = &thaw($args{ObjStruct});
        while(($key,$value) = each(%{$objStruct}))
        {
            &log("Unloading '$key=$value' from ObjStruct") if ($VERBOSE > 3);
            $args{$key} = $value if (! defined $args{$key});
        }
    }
    delete $args{ObjStruct};

    # Now setup the list of allowed parms
    my $defaultParms = {
        Name                => $::REQUIRED,
        Status              => $::REQUIRED,
        Text                => undef,
        HeaderMsg           => undef,
        FooterMsg           => undef,
        GraphStruct         => undef,
        StatusHistoryLimit  => undef,
        ChangeActionObjList => undef,
        UpgradeRuleObjList  => undef,
        ExpireAfter         => undef,
        Description         => undef,
        GraphGroupList      => undef,
        BaselineDiffStatus  => undef,
        RunningFrom         => undef,
        ScriptName          => undef,
        LogFile             => undef,
        Interval            => undef,
        SetBaselineFlag     => undef,
    };

    # Validate the passed paramters
    &validateParms(\%args,$defaultParms) || return $ERROR;

    my $time = time;
    my $newStatus = &map_status($args{Status});
    my $name = $args{Name};

    # Return with an error if we can't map the status passed
    return $ERROR if ($newStatus eq '');

    # Store the mapped status
    $args{Status} = $newStatus;

    # If the object name starts with a '.' then prepend the default prefix    
    if ($name =~ /^\./)
    {
        $name = $DEFAULT_PREFIX . $name;
        $args{Name} = $name;
    }

    # Make sure no invalid characters were passed in
    if ($name =~ /[^\w\@\.-]/)
    {
        &error("Invalid object name '$name', ignoring");
        return $ERROR;
    }

    # Lookup the passed object name
    my $destObj = $NAME_CACHE{$name};
    my ($destTemplate,$ruleList,$retval);

    # Lookup the status upgrade rules for this object as well.  If there are
    # any upgrade rules for this object which correspond to the new status, then
    # we can't use the quick-set, because the status might get upgraded, which
    # would require a re-build of the status tree.  At this point, determining
    # this has become complicated enough that I'm not sure it's really helping
    # performance, but it's working so I'll leave it in.
    if ($destObj)
    {
        $ruleList = $destObj->getUpgradeRuleObjList($newStatus);
    }

    # If we found the target object, it's status isn't going to change,
    # there aren't any current upgrade rules, and we're not adding any,
    # then jump directly to it.
    if (($destObj ne '')&&($newStatus eq $destObj->{Status})&&
        (@{$ruleList} == 0)&&(! defined $args{UpgradeRuleObjList}))
    {
        &log("No status change, using quick-set") if ($VERBOSE > 2);
        $retval = $destObj->recurseSetStatus(%args, Time=>$time, Depth=>0);
    }
    # Otherwise, we have to drill down from the top, so that we can recurse back
    # up, setting group statuses as we go.
    else
    {
        $retval = $self->recurseSetStatus(%args, Time=>$time, Depth=>0);
    }

    # Now that we're sure the object has been created, look it up again and pass 
    # any graphing data to it.
    $destObj = $NAME_CACHE{$name} if (! defined $destObj);
    $destObj->addGraphDbData($args{GraphStruct}) if (defined $args{GraphStruct});

    ($retval);
}

#-------------------------------------------------------------------------------
# Function:     recurseSetStatus
# Description:  Set the status of the passed object to the value specified and store
#               the text.  This subroutine is called starting at the head node of
#               the tree and it recurses down it's child nodes until it find the
#               actual object specified.
# Input Parms:  Object Name, Status, Status File Text, Recursion Depth
# Output Parms:
#-------------------------------------------------------------------------------
sub recurseSetStatus
{
    my $self = shift;
    my %args = @_;

    # Unload some of the values from the passed structure
    my $name   = $args{Name};
    my $status = $args{Status};
    my $time   = $args{Time};
    my $depth  = $args{Depth} || 0;
    my $text   = $args{Text};

    # Unload some object values
    my $currName        = $self->{Name};
    my $currStatus      = $self->{Status};
    my $type            = $self->{type};
    my $historyObjList  = $self->{historyObjList};
    my $historyObjIndex = $self->{historyObjIndex};

    my ($retval,$newStatus,$first_char,$ptr,$temp_time,$histObj,$subName);
    my ($histFileName);

    &log("recurseSetStatus - Entering object '$currName'") if ($VERBOSE > 2);

    # If this is the lowest level object, then set the status and return.
    if ($name eq $currName)
    {
        # Can't directly set the status of a object which has sub-objects
        if((defined $type)&&($type eq 'group'))
        {
            &error("Cannot directly set the status of a group object - '$name'");
            return $ERROR;
        }

        # If no status was passed then we must be doing the initial import, so 
        # return the NO_CHANGE value so we don't bother re-calculating group 
        # statuses, etc.
        return $NO_CHANGE if(! defined $status);

        &log("Setting status of '$currName' to '$status'") if ($VERBOSE > 1);

        # Map the status based on the first character of the passed status
        $newStatus = &map_status($status);
        return $ERROR if($newStatus eq '');

        &log("Storing text\n$text") if (($text ne '')&&($VERBOSE > 2));

        # Set the status, text, and timestamp.  The rawStatus is the original
        # status of the object, before any upgrades were applied.
        $self->{Status}    = $newStatus;
        $self->{Timestamp} = $time;
        $self->{type}      = "object";

        # Construct the file path for the history file.  Remove any ':' in the 
        # file name.
        $self->{histFile} = $histFileName = $time;

        # Unload other passed parms into the object, if any of these parms are
        # specified, then we need to re-write the metadata file so mark a flag.
        my $metaDataChangedFlg = 0;
        foreach my $key (keys %args)
        {
            if ($PERSISTENT_PARMS_HASH{$key})
            {
                $self->set($key => $args{$key});
                $metaDataChangedFlg = 1;
            }
        }

        # Validate the status change actions if passed in
        $self->validateActions if (defined $args{'StatusChangeActions'});

        # If the status is EXPIRED, then don't bother recalculating
        # the expiration time.
        $self->updateExpirTime() if ($newStatus ne $::EXPIRED);

        # Create the directory where object info will be saved
        mkdir "$VB_OBJ_FILE_DIR/$name",0775 if (! -d "$VB_OBJ_FILE_DIR/$name");

        # Store the latest time, status, and text into the history queue.
        $histObj = new VBTK::Objects::History(
            ObjPath      => $VB_OBJ_FILE_DIR,
            ObjName      => $name,
            FileName     => $histFileName,
            Timestamp    => $time,
            RepeatStart  => $time,
            Status       => $newStatus,
            RawStatus    => $newStatus,
            Text         => $text,
            HeaderMsg    => $args{HeaderMsg},
            FooterMsg    => $args{FooterMsg},
            ExpireTime   => $self->{expireTime},
            Repeated     => 1);

        return $ERROR if (! defined $histObj);
        $historyObjIndex->{$histFileName} = $histObj;
        unshift(@{$historyObjList},$histObj);

        # Check to see if the object qualifies for a status upgrade
        $newStatus = $self->checkForStatusUpgrade();

        # Remove duplicates in the history, incrementing the 'repeated' counter
        # and removing entries older than the 'StatusHistoryLimit' parm.
        $self->cleanHistory();

        # Now tell the history object to write itself.
        $histObj->store;

        # Store any passed parameters which need to be persistent
        $self->storeMetaData if ($metaDataChangedFlg);
        
        # Store the baseline, if the setBaselineFlag was passed
        $self->{baselineFileObj}->put($text) if ($args{SetBaselineFlag});

        # If the status didn't change, then return NO_CHANGE, skipping all the
        # work of checking for status change actions.
        return $NO_CHANGE if ($currStatus eq $newStatus);

        # If the status did change, then check for actions to be performed.
        $self->checkForStatusChangeAction();
    }

    # If this isn't the lowest level object, then check to see if the next level down
    # exists.  If not then create it.  Recurse into the next object down.
    else
    {
        # Split object name up into segments and determine current segment
        my @objSegments = split(/[.]/, $name);
        my $currSegment = $objSegments[$depth];

        # If the node has already been declared as an object, can't give it children
        if($type eq 'object')
        {
           &error("Attempt to make '$name' a group when it's already an object");
           return $ERROR;
        }

        $self->{type} = "group" if ($type eq '');

        &log("Searching for sub-object '$currSegment'") if ($VERBOSE > 2);

        # Locate the pointer to the sub object referenced by the current name segment
        my $ptr = $self->{childObjList}->{$currSegment};

        # If the sub object doesn't exist yet, then allocate one
        unless ($ptr)
        {
            $subName = join('.',@objSegments[0..$depth]);

            $ptr = $self->{childObjList}->{$currSegment} = new VBTK::Objects(
                Name        => $subName,
                SegmentName => $currSegment);

            # Select a template to inherit defaults from 
            $ptr->selectTemplate;
        }

        # Increment the depth counter and recurse into the child object
        $args{Depth}++;
        $retval = $ptr->recurseSetStatus(%args);

        # A negative return value indicates an error, so just pass the error back.
        return $retval if ($retval < 0);

        # If no change was made to the status, there is no need to update the group
        return($NO_CHANGE) if ($retval == $NO_CHANGE);

        # Update the group status value
        $self->updateGroup();
    }
    ($CHANGED);
}

#-------------------------------------------------------------------------------
# Function:     addGraphDbData
# Description:  Use the passed data structure to update the corresponding 
#               graphing database.
# Input Parms:  Graph data structure
# Output Parms: None
#-------------------------------------------------------------------------------
sub addGraphDbData
{
    my $self = shift;
    my $rrdObj = $self->{rrdObj};
    my ($GraphStruct) = (@_);

    $rrdObj->addGraphDbData(%{$GraphStruct});

    (0);
}

#-------------------------------------------------------------------------------
# Function:     generateGraph
# Description:  Generate and return a .png file graph with the specified attributes.
# Input Parms:  Graph Attributes
# Output Parms: Png Graph Stream
#-------------------------------------------------------------------------------
sub generateGraph
{
    my $self = shift;
    my $name = $self->{Name};
    my $rrdObj = $self->{rrdObj};

    if (! defined $rrdObj)
    {
        &error("Can't find Rrd Object for VBObject '$name'");
        return undef;
    }

    &log("Generating graph for '$name'") if ($VERBOSE > 1);    
    $rrdObj->generateGraph(@_);
}

#-------------------------------------------------------------------------------
# Function:     updateGroup
# Description:  Look at the status and timestamp of sub objects and determine the
#               group status and timestamp.
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub updateGroup
{
    my $self = shift;
    my $status = $self->{Status};
    my $name = $self->{Name};
    my ($ptr,$childStatus,$grandchildObjectName,$groupStatus);
    my $grandchildObjectNames = {};

    &log("Updating group status of '$name'") if ($VERBOSE > 1);

    # Step through each sub object of the current object
    foreach $ptr (values %{$self->{childObjList}})
    {
        # Determine the status of each sub-object and see if it's rank is higher
        # than the current group status and set the group status accordingly.
        $childStatus = $ptr->{Status};

        if((! defined $groupStatus)||
           ($::VB_STATUS_RANK{$childStatus} > $::VB_STATUS_RANK{$groupStatus}))
        {
            $groupStatus = $childStatus;
        }

        # Rebuild the list of grandchild nodes, just in case something was removed
        foreach $grandchildObjectName (keys %{$ptr->{childObjList}})
        {
            $grandchildObjectNames->{$grandchildObjectName} = 1;
        }
    }

    # If the status changed, then store the new status.
    if($groupStatus ne $status)
    {
        &log("Updating group status of '$name' to '$groupStatus'")
            if ($VERBOSE > 1);
        $self->{Status} = $groupStatus;
    }

    # Store the new list of grandchildObjectNames
    $self->{grandchildObjectNames} = $grandchildObjectNames;

    (0);
}

#-------------------------------------------------------------------------------
# Function:     updateExpirTime
# Description:  Update the expiration time of the object based on the expiration
#               rule.
# Input Parms:
# Output Parms: Status
#-------------------------------------------------------------------------------
sub updateExpirTime
{
    my $self = shift;
    my $template = $self->{template};
    my $Timestamp = $self->{Timestamp};

    my $ExpireAfter = $self->{ExpireAfter} || $template->getExpireAfter;

    # If no expiration was specified, then just return
    return 0 if (! defined $ExpireAfter);

    &log("Current timestamp is '$Timestamp'") if ($VERBOSE > 2);

    # Use the Date::Manip perl library to calculate the new expiration datetime.
    my $expireAfterSec = &deltaSec($ExpireAfter) || return 0;
    my $newExpireTimestamp = $Timestamp + $expireAfterSec;
    &log("Used '$ExpireAfter' to set new expir to '$newExpireTimestamp'")
        if ($VERBOSE > 2);

    $self->{expireTime} = $newExpireTimestamp;
    (0);
}

#-------------------------------------------------------------------------------
# Function:     checkForExpiration
# Description:  Check all sub-objects to see if they have expired and if so, set
#               their status to expired, moving the current status to 'last_status'.
#               Check also to see if their object files have been deleted and if
#               so, remove them from the object tree in memory.
# Input Parms:  object_name
# Output Parms: Status
#-------------------------------------------------------------------------------
sub checkForExpiration
{
    my $self = shift;
    my $now = shift;

    my $name         = $self->{Name};
    my $type         = $self->{type};
    my $childObjList = $self->{childObjList};
    my $expireTime   = $self->{expireTime};
    my $status       = $self->{Status};

    my ($ptr,$childObj,$childObjName,$result,$recalcGroupFlg);

    $now = time unless ($now);

    # Groups don't have an expiration time, so just recurse down.
    if((defined $type)&&($type eq 'group'))
    {
        # Step through each child object.
        while(($childObjName,$childObj) = each %{$childObjList})
        {
            $result = $childObj->checkForExpiration($now);

            # If $DELETED, then remove it as a child
            if($result == $DELETED)
            {
                &log("Removing $name.$childObjName") if ($VERBOSE);
                delete($childObjList->{$childObjName});
                delete $NAME_CACHE{"$name.$childObjName"};
            }

            $recalcGroupFlg = 1 if ($result ne $NO_CHANGE);
        }

        # Check to see if all sub-objects have been deleted
        if((keys %{$childObjList}) == 0)
        {
            ($DELETED);
        }
        # Otherwise, if anything changed, then update the group.
        elsif($recalcGroupFlg)
        {
            $self->updateGroup();
            ($CHANGED);
        }
        else
        {
            ($NO_CHANGE);
        }
    }
    # Only need to check expiration/deletion of the lowest level objects
    else
    {
        &log("Checking to see if $VB_OBJ_FILE_DIR/$name has been deleted")
            if ($VERBOSE > 1);

        # Check to see if the files in vbobj have been deleted
        if( ! -d "$VB_OBJ_FILE_DIR/$name")
        {
            &log("$VB_OBJ_FILE_DIR/$name has been deleted");
            ($DELETED);
        }
        else
        {
            &log("Checking expiration date of '$name' - $expireTime")
                if(($VERBOSE > 1)&&($expireTime));
            if(($expireTime)&&($now > $expireTime)&&($status ne $::EXPIRED))
            {
                $self->recurseSetStatus(
                    Name    => $name,
                    Status  => $::EXPIRED,
                    Time    => $now);

                ($CHANGED);
            }
            else
            {
                ($NO_CHANGE);
            }
        }
    }
}

#-------------------------------------------------------------------------------
# Function:     deleteHistoryItem
# Description:  Delete an entry from the object history
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub deleteHistoryItem
{
    my $self = shift;
    my ($pos) = @_;

    my $name           = $self->{Name};
    my $historyObjList = $self->{historyObjList};

    # Get the specified history object and the one previous to it.
    my $histObj     = $historyObjList->[$pos];
    my $prevHistObj = $historyObjList->[$pos-1];

    # Return if the specified history entry doesn't exist
    return 0 if (! defined $histObj);

    # Get their timestamps
    my $histFile     = $histObj->getFileName;
    my $prevHistFile = $prevHistObj->getFileName if (defined $prevHistObj);

    &log("Removing element '$pos' from the history array") if ($VERBOSE > 2);
    splice(@{$historyObjList},$pos,1);

    # In the rare case that the status was set twice in the same second, the
    # obj file and historyObjIndex pointer have already been overwritten, so we
    # don't want to delete them again, or we'll lose data.
    if($prevHistFile ne $histFile)
    {
        $histObj->delete;
        delete $self->{historyObjIndex}->{$histFile};
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     deleteObject
# Description:  Delete an object along with all of it's history files
# Input Parms:  Object name
# Output Parms: None
#-------------------------------------------------------------------------------
sub deleteObject
{
    my $self = shift;
    my %args = @_;

    my $name  = $args{Name};
    my $depth = $args{Depth};

    my $currName       = $self->{Name};
    my $type           = $self->{type};
    my $historyObjList = $self->{historyObjList};

    my ($ptr,$child_ptr,$retval,$file,@fileList,$childName);

    $depth = 0 if ($depth < 1);
    $name = $currName if (! defined $name);

    &log("Delete - Entering object '$currName'") if ($VERBOSE > 2);

    # If this is the lowest level object, then set the status and return.
    if ($name eq $currName)
    {
        &log("Deleting object '$currName'") if ($VERBOSE);

        # If this is a group, then delete all the child objects recursively.
        if($type eq 'group')
        {
            foreach $ptr (values %{$self->{childObjList}})
            {
                $ptr->deleteObject();
            }
        }
        # Otherwise clear out the history items and unlink the vbobj
        # directory.
        else
        {
            @fileList = <$VB_OBJ_FILE_DIR/$currName/*>;
            foreach $file (@fileList)
            {
                &log("Deleting object file '$file'") if ($VERBOSE);
                unlink("$file");
            }
            unlink("$VB_OBJ_FILE_DIR/$currName");
        }
    }
    else
    {
        # Split object name up into segments and determine current segment
        my @objSegments = split(/[.]/, $name);
        my $currSegment = $objSegments[$depth];

        &log("Searching for sub-object '$currSegment'") if ($VERBOSE > 1);

        # Locate the pointer to the sub object referenced by the current name segment
        my $ptr = $self->{childObjList}->{$currSegment};

        # If the sub object doesn't exist then complain
        if ($ptr eq '')
        {
            &error("Attempt to delete non-existant node '$currName'");
            return $ERROR;
        }

        # Recurse into the sub object
        $retval = $ptr->deleteObject(Name => $name, Depth => ($depth+1));

        # If the target of the delete is the immediate child, then unlink the
        # child object.
        $childName = join('.',@objSegments[0..($depth+1)]);
        if($childName eq $name)
        {
            &log("Unlinking child object") if ($VERBOSE > 2);
            delete $self->{childObjList}->{$currSegment};
            delete $NAME_CACHE{$childName};
        }

        # A negative return value indicates an error, so just pass the error back.
        return $retval if ($retval < 0);

        # Update the group status value
        $self->updateGroup();
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     selectTemplate
# Description:  Use pattern matching to select the template for this object.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub selectTemplate
{
    my $self = shift;
    my $name = $self->{Name};
    my ($template,$Pattern);

    &log("Setting defaults for '$name'") if ($VERBOSE > 1);
    foreach $template (@VB_TEMPLATE_LIST)
    {
        $Pattern = $template->{Pattern};

        &log("Checking '$name' against pattern '$Pattern'") if ($VERBOSE > 2);
        next unless $name =~ /$Pattern/;

        &log("Using template '$Pattern' for object '$name'") if ($VERBOSE > 1);

        $self->{template} = $template;

        # Only use the first match
        last;
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     validateActions
# Description:  Check all the action names listed in the StatusChangeActions rules
#               and make sure they are all real actions.  We should only run this
#               if a client process just passed in some new action rules.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub validateActions
{
    my $self = shift;
    my $name      = $self->{Name};
    my $StatusChangeActions = $self->{StatusChangeActions};
    my $historyObjList      = $self->{historyObjList};
    my ($changeActionObj,$badActionList,$msg);

    return 0 if (! defined $StatusChangeActions);

    foreach $changeActionObj (@{$StatusChangeActions})
    {
        next if ($changeActionObj->validateActionNames);

        # If we made it this far, then one of the action names is bad
        $self->{Status} = $::FAILED;
        $badActionList = $changeActionObj->getActionList;
        $msg = "Invalid action name in list '$badActionList', setting status to " .
            $::FAILED;
        &error("$msg");
        $historyObjList->[0]->addHeaderMsg("$msg\n");
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     checkForStatusChangeAction
# Description:  Check for an action associated with a status change for the
#               current object and execute it if one is found.
# Input Parms:  Status
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkForStatusChangeAction
{
    my $self = shift;
    my $status    = $self->{Status};
    my $name      = $self->{Name};
    my $histFile  = $self->{histFile};
    my $ChangeActionObjList = $self->getChangeActionObjList($status);

    my ($action,$action_ptr,$msgText,$actionName,$changeActionObj);

    &log("Status changed to '$status', looking for status change actions")
        if ($VERBOSE > 1);

    return 0 if (@{$ChangeActionObjList} < 1);

    if ($VBVIEW_EXT_URL ne '')
    {
        $msgText = "See: ${VBVIEW_EXT_URL}?name=$name&histFile=$histFile";
    }

    foreach $changeActionObj (@{$ChangeActionObjList})
    {
        $changeActionObj->checkForActions($status,$name,$msgText);
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     checkForStatusUpgrade
# Description:  Check to see if the object qualifies for a status upgrade
# Input Parms:  None
# Output Parms: New Status
#-------------------------------------------------------------------------------
sub checkForStatusUpgrade
{
    my $self = shift;
    my $status = $self->{Status};

    my $historyObjList     = $self->{historyObjList};
    my $UpgradeRuleObjList = $self->getUpgradeRuleObjList($status);

    return $status if (@{$UpgradeRuleObjList} < 1);

    my $upgradeTo          = $::SUCCESS;
    my ($newStatus,$ruleObj);

    &log("Checking for status upgrade") if ($VERBOSE > 1);

    foreach $ruleObj (@{$UpgradeRuleObjList})
    {
        $newStatus = $ruleObj->checkForUpgrade($status,$historyObjList);
        $upgradeTo = &find_higher_status($upgradeTo,$newStatus);
    }

    # Decide which status is higher, and then store it in the current object as well
    # as in the history object
    $status = &find_higher_status($status,$upgradeTo);
    $self->{Status} = $status;
    $historyObjList->[0]->setStatus($status);

    ($status);
}

#-------------------------------------------------------------------------------
# Function:     cleanHistory
# Description:  Scan through the object history, removing duplicates and incrementing
#               the 'repeated' counter.  Also, remove any entries older than the
#               StatusHistoryLimit value.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub cleanHistory
{
    my $self = shift;

    my $h         = $self->{historyObjList};
    my $template  = $self->{template};

    my $StatusHistoryLimit = $self->{StatusHistoryLimit} ||
        $template->{StatusHistoryLimit};

    my $hLen = @{$h};
    my ($startHistory,$timestamp,$historyLimitSec);

    &log("Cleaning history") if ($VERBOSE > 1);

    # If the 1st, 2nd, and 3rd history items all have the same status
    # then consolidate the 2nd into the 1st, incrementing the 'repeated'
    # counter of the 1st.  Also, preserve the repeatStart value from the
    # 2nd history item.
    if (($hLen > 2) &&
        ($h->[0]->getStatus eq $h->[1]->getStatus) &&
        ($h->[0]->getStatus eq $h->[2]->getStatus))
    {
        &log("Consolidating 1st & 2nd entries in history") if ($VERBOSE > 2);
        $h->[0]->addToRepeated($h->[1]->getRepeated);
        $h->[0]->setRepeatStart($h->[1]->getRepeatStart);
        $self->deleteHistoryItem(1);
        $hLen--;
    }

    # Just return if there's no StatusHistoryLimit entry
    return 0 if ($StatusHistoryLimit eq '');

    &log("Checking history limit of '$StatusHistoryLimit'") if ($VERBOSE > 1);

    # If the 'StatusHistoryLimit' entry is just an integer, then it means that
    # that is the total number of allowed history entries, so just trim off
    # all the entries over that count.
    if($StatusHistoryLimit =~ /^\d+$/)
    {
        while($hLen > $StatusHistoryLimit)
        {
            &log("Removing history entry #$hLen") if ($VERBOSE > 2);
            $self->deleteHistoryItem($hLen - 1);
            $hLen--;
        }
    }
    # Otherwise it's a date string and we need to run DateCalc to find the
    # starting cutoff.
    else
    {
        $historyLimitSec = &deltaSec($StatusHistoryLimit);
        $startHistory = time - $historyLimitSec;
        $timestamp = $h->[$hLen - 1]->getTimestamp;

        &log("Searching for history timestamps prior to '$startHistory'")
           if ($VERBOSE > 2);

        while($timestamp < $startHistory)
        {
            &log("Removing history entry for $timestamp") if ($VERBOSE > 2);
            $self->deleteHistoryItem($hLen - 1);
            $hLen--;
            $timestamp = $h->[$hLen - 1]->getTimestamp;
        }
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     importObjects
# Description:  Import all objects from the object files in the VB_OBJ_FILE_DIR
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub importObjects
{
    my $self = shift;
    my ($object,$objName,$objDir);

    &log("Importing all objects in '$VB_OBJ_FILE_DIR'");

    # Get a listing of subdirectories in the vbobj directory
    my @objList = grep((-d $_),<$VB_OBJ_FILE_DIR/*>);

    # Step through each directory.
    foreach $objDir (@objList)
    {
        $objName = basename($objDir);

        # Skip '.' and '..';
        next if ($objName =~ /^\./);

        &log("Importing object dir '$objDir'") if ($VERBOSE > 1);

        # Create the object.  By passing no status value, we'll cause it to
        # load itself from it's history.
        $self->recurseSetStatus(Name => $objName);
    }

    # Step through all group objects and update the group statuses
    &log("Updating all group statuses");
    foreach $objName (reverse sort keys %NAME_CACHE)
    {
        $object=$NAME_CACHE{$objName};
        $object->updateGroup() if ((defined $object->{type}) && 
                                   ($object->{type} eq 'group'));
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     loadMetaData
# Description:  Load metat data about this object
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub loadMetaData
{
    my $self = shift;
    my $Name = $self->{Name};
    my $metaFileObj = $self->{metaFileObj};

    return 0 unless ($metaFileObj->exists);

    &log("Loading meta data for '$Name'") if ($VERBOSE > 1);

    my $struct = $metaFileObj->serGet;

    return undef if (! defined $struct);

    $self->set(%{$struct});

    (1);        
}

#-------------------------------------------------------------------------------
# Function:     storeMetaData
# Description:  Write the some parms we want to be persistent out to a file
# Input Parms:  None
# Output Parms: True | False
#-------------------------------------------------------------------------------
sub storeMetaData
{
    my $self = shift;
    my $Name        = $self->{Name};
    my $metaFileObj = $self->{metaFileObj};

    # Create a structure containing just the object members which we want to
    # be persistent.
    my $struct = { map { $_ => $self->{$_} } @PERSISTENT_PARMS };

    &log("Saving meta data for '$Name'") if ($VERBOSE > 1);
    $metaFileObj->serPut($struct) || return undef;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     loadAllHistory
# Description:  Find all history objects stored in the object's vbobj directory and
#               create objects for them, returning an array of objects.
# Input Parms:  Object Dir
# Output Parms: Array of history objects
#-------------------------------------------------------------------------------
sub loadAllHistory
{
    my $self = shift;
    my $name            = $self->{Name};
    my $historyObjList  = $self->{historyObjList};
    my $historyObjIndex = $self->{historyObjIndex};
    my $vbObjPath = $VB_OBJ_FILE_DIR;

    my ($file,$timestamp,$histObj,$count,$histFile);

    my @histFileList = reverse sort <$vbObjPath/$name/[0-9]*.ser>;
    my $cacheMode = $VBTK::Objects::History::NOTEXT;

    # Loop through the history entries from oldest to newest
    foreach $file (@histFileList)
    {
        $file =~ /([^\/]+)\.ser$/;
        $histFile = $1;
    
        # Only cache data for the first two entries, the rest will be
        # loaded on demand.
        $cacheMode = $VBTK::Objects::History::MINIMAL if (++$count > 2);

        $histObj = new VBTK::Objects::History(
            ObjPath   => $vbObjPath,
            ObjName   => $name,
            FileName  => $histFile,
            CacheMode => $cacheMode);

        next if (! defined $histObj);
        
        push(@{$historyObjList},$histObj);
        $historyObjIndex->{$histFile} = $histObj;
    }

    # Initialize a few entries in the object itself if any history entries
    # were found.
    if (defined $historyObjList->[0])
    {
        $self->{Status}     = $historyObjList->[0]->getStatus;
        $self->{Timestamp}  = $historyObjList->[0]->getTimestamp;
        $self->{expireTime} = $historyObjList->[0]->getExpireTime;
        $self->{histFile}   = $historyObjList->[0]->getFileName;
    }

    (1);    
}

#-------------------------------------------------------------------------------
# Function:     addObjectTemplate
# Description:  Add an object template to the global array of templates
# Input Parms:  Object pattern
# Output Parms: None
#-------------------------------------------------------------------------------
sub addObjectTemplate
{
    my $self = shift;
    my $template = shift;

    push(@VB_TEMPLATE_LIST,$template);
    (0);
}

#-------------------------------------------------------------------------------
# Function:     getMatrixList
# Description:  Return a list of top level objects used as the starting point
#               for each matrix to be displayed.  Note that if a name is specified,
#               then only that top-level object will be returned.
# Input Parms:  Object Name
# Output Parms: Array List of top level objects
#-------------------------------------------------------------------------------
sub getMatrixList
{
    my $self = shift;
    my $name = $self->{Name};
    my ($targetObj,$ptr,@matrixList,$child);

    &log("Retrieving matrix list for object '$name'") if ($VERBOSE > 1);

    # If no name was passed, then return a list of child objects of this object.
    if ($name eq $::MASTER_NODE)
    {
        foreach $child (sort keys %{$self->{childObjList}})
        {
            $ptr = $self->{childObjList}->{$child};
            push(@matrixList,$ptr);
        }
        (@matrixList);
    }
    # If a name was passed, then lookup the object associated with that name
    # and return it.
    else
    {
        ($self);
    }
}

#-------------------------------------------------------------------------------
# Function:     getHistoryObjList
# Description:  Retrieve a list of history objects.  If a timestamp is passed,
#               then limit the list to just the object with the matching timestamp
# Input Parms:  Optional timestamp
# Output Parms: Array of history objects
#-------------------------------------------------------------------------------
sub getHistoryObjList
{
    my $self = shift;
    my $histFile = shift;
    my $name = $self->{Name};
    my $historyObjList = $self->{historyObjList};
    my $historyObjIndex = $self->{historyObjIndex};

    if ($histFile)
    {
        &log("Retrieving history object for '$name' - '$histFile'") 
            if ($VERBOSE > 1);

        ($historyObjIndex->{$histFile});
    }
    else
    {
        &log("Retrieving all history objects for '$name'") if ($VERBOSE > 1);

        (@{$historyObjList});
    }
}

#-------------------------------------------------------------------------------
# Function:     getUpgradeRuleObjList
# Description:  Return a list of upgrade rule objects for this object.  If a status
#               is specified, then only get rules which correspond to the passed
#               status.
# Input Parms:  Status
# Output Parms: Array List of rule objects
#-------------------------------------------------------------------------------
sub getUpgradeRuleObjList 
{ 
    my $self = shift;
    my $status = shift;

    my $template = $self->{template};
    my $UpgradeRuleObjList = $self->{UpgradeRuleObjList} ||
        $template->getUpgradeRuleObjList;

    my $result = [];

    return $result if (! defined $UpgradeRuleObjList);

    my ($ruleObj,$testStatus);

    foreach $ruleObj (@{$UpgradeRuleObjList})
    {
        $testStatus = $ruleObj->getTestStatus;

        push(@{$result},$ruleObj) if (($testStatus eq $status)||(! defined $status));
    }

    ($result);
}


#-------------------------------------------------------------------------------
# Function:     getStatusChangeActionObjList
# Description:  Return a list of status change action objects for this object.  
#               If a status is specified, then only get rules which correspond 
#               to the passed status.
# Input Parms:  Status
# Output Parms: Array List of status change action objects
#-------------------------------------------------------------------------------
sub getChangeActionObjList 
{ 
    my $self = shift;
    my $status = shift;

    my $template = $self->{template};
    my $ChangeActionObjList = $self->{ChangeActionObjList} ||
        $template->getChangeActionObjList;

    my $result = [];

    return $result if (! defined $ChangeActionObjList);

    my ($ruleObj,$testStatus);

    foreach $ruleObj (@{$ChangeActionObjList})
    {
        $testStatus = $ruleObj->getTestStatus;

        push(@{$result},$ruleObj) if (($testStatus eq $status)||(! defined $status));
    }

    ($result);
}

#-------------------------------------------------------------------------------
# Function:     getGraphGroupObjList
# Description:  Retrieve the graph group definitions for the specified graph
#               group number.  Default the group number to the first on the list
#               if not specified.
# Input Parms:  Group Number
# Output Parms: Graph Group Object List
#-------------------------------------------------------------------------------
sub getGraphGroupObjList
{
    my $self = shift;
    my $groupNumber = shift;
    my $GraphGroupList = $self->{GraphGroupList};
    my @groupNumberList;

    if (! defined $groupNumber)
    {
        @groupNumberList = $self->getGraphGroupNumberList;
        $groupNumber = $groupNumberList[0];
    }

    my $graphObjList = $GraphGroupList->{$groupNumber};

    @{$graphObjList};
}

#-------------------------------------------------------------------------------
# Function:     getGraphGroupNumberList
# Description:  Retrieve a list of valid graph group numbers for this object.
# Input Parms:  Group Number
# Output Parms: Graph Group Number List
#-------------------------------------------------------------------------------
sub getGraphGroupNumberList
{
    my $self = shift;
    my $GraphGroupList = $self->{GraphGroupList};

    sub byNumber { $a <=> $b }
    sort byNumber keys %{$GraphGroupList};
}

#-------------------------------------------------------------------------------
# Function:     getUpgradeRuleObjText
# Description:  Retrieve an array of text describing the upgrade rules
# Input Parms:  None
# Output Parms: Array of text describing the upgrade rules for this object
#-------------------------------------------------------------------------------
sub getUpgradeRuleObjText  
{ 
    my $self = shift;
    my $UpgradeRuleObjList = $self->{UpgradeRuleObjList};
    return () if (! defined $UpgradeRuleObjList);

    map { $_->getRuleText } @{$UpgradeRuleObjList};
}

#-------------------------------------------------------------------------------
# Function:     getChangeActionObjText
# Description:  Retrieve an array of text describing the change actions
# Input Parms:  None
# Output Parms: Array of text describing the change actions for this object
#-------------------------------------------------------------------------------
sub getChangeActionObjText
{ 
    my $self = shift;
    my $ChangeActionObjList = $self->{ChangeActionObjList};
    return () if (! defined $ChangeActionObjList);

    map { $_->getRuleText } @{$ChangeActionObjList};
}

# Simple Get Methods
sub getObject              { $NAME_CACHE{$_[1]}; }
sub getFullName            { $_[0]->{Name}; }
sub getHistFile            { $_[0]->{histFile}; }
sub getSegName             { $_[0]->{SegmentName}; }
sub getTimestamp           { $_[0]->{Timestamp}; }
sub getTimestampText       { ($_[0]->{Timestamp}) ? &UnixDate("epoch $_[0]->{Timestamp}","%C") : "None"; }
sub getStatus              { $_[0]->{Status}; }
sub getExpiration          { $_[0]->{expireTime}; }
sub getExpirationText      { ($_[0]->{expireTime}) ? &UnixDate("epoch $_[0]->{expireTime}","%C") : "None"; }
sub getNameSegments        { split(/\./,$_[0]->{Name}); }
sub getGrandChildNames     { sort keys %{$_[0]->{grandchildObjectNames}}; }
sub getGrandChildCount     { (keys %{$_[0]->{grandchildObjectNames}}) + 0; }
sub getChildObjects        { map { $_[0]->{childObjList}->{$_} } sort keys %{$_[0]->{childObjList}}; }
sub getChildNames          { sort keys %{$_[0]->{childObjList}}; }
sub getChild               { $_[0]->{childObjList}->{$_[1]}; }
sub isGroup                { ($_[0]->{type} eq 'group'); }
sub getRrdObj              { $_[0]->{rrdObj}; }
sub getTemplate            { $_[0]->{template}; }
sub getBaselineText        { $_[0]->{baselineFileObj}->get; }
sub getRunningFrom         { $_[0]->{RunningFrom}; }
sub getScriptName          { $_[0]->{ScriptName}; }
sub getLogFile             { $_[0]->{LogFile}; }

sub getBaselineDiffStatus  { $_[0]->{BaselineDiffStatus}; }
sub getInterval            { $_[0]->{Interval}; }

# These get methods will use the template value if no direct value was specified.
sub getExpireAfter         { $_[0]->{ExpireAfter}; }
sub getDescription         { $_[0]->{Description}; }

# Simple Set Methods
sub setBaselineText        { $_[0]->{baselineFileObj}->put($_[1]); }


#-------------------------------------------------------------------------------
# Function:     FindObjByName
# Description:  Locate the specified object by name
# Input Parms:  Object name
# Output Parms: Object pointer
#-------------------------------------------------------------------------------
sub FindObjByName
{
    my ($objName) = @_;

    if ((! defined $objName)||($objName eq ''))
    {
        $objName = $::MASTER_NODE;
    }
    else
    {
        # If the object name starts with a '.' then prepend the default prefix    
        $objName = $DEFAULT_PREFIX . $objName if ($objName =~ /^\./);
    
        # Make sure no invalid characters were passed in
        if ($objName =~ /[^\w\@\.-]/)
        {
            &error("Invalid object name '$objName', ignoring");
            return $ERROR;
        }
    }

    my $targetObj = $NAME_CACHE{$objName};

    &log("Unable to find object '$objName' on this server")
        if ((! defined $targetObj)&&($VERBOSE > 1));

    ($targetObj);
}

1;
__END__

=head1 NAME

VBTK::Objects - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle server-side
VB Objects.  Do not try to access this package directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Server|VBTK::Server>

=back

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
