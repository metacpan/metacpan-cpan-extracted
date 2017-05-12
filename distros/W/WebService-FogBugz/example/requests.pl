#!/usr/bin/perl -w
use strict;

use WebService::FogBugz;
use Data::Dumper;

my $fogbugz = WebService::FogBugz->new({
    email       => 'youremail@example.com',
    password    => 'password',
    base_url    => 'http://www.example.com/fogbugz/api.asp'
});

$fogbugz->logon;


###########################################
## Filters
# listFilters
#print $fogbugz->request_method('listFilters');

# saveFilter

###########################################
## Listing Cases
# search
my $res =  $fogbugz->request_method('search', {
    q => 'WebService',
});
print $res;

###########################################
## Editing Cases
# new
# edit
# assign
# reactivate
# reopen
# resolve
# close
# email
# reply
# forward

###########################################
## Lists
# listProjects
# listAreas
# listCategories
# listPriorities
# listPeople
# listStatuses
# listFixFors
# listMailBoxes

###########################################
## Views
# viewProject
# viewArea
# viewCategory
# viewPriority
# viewPerson
# viewStatus
# viewFixFor
# viewMainBox

###########################################
## Working Schedule
# listWorkingSchedule
# wsDateFromHours

###########################################
## Time Tracking
# startWork
# stopWork
# newInterval
# listIntervals

###########################################
## Source Control
# newCheckin
#$fogbugz->request_method('newCheckin', {
#    ixBug => 9999,
#    sFile => 'repos/trunk/Example.pm',
#    sNew  => 10,
#    sPrev => 9,
#    sRepo => '',
#});

# listCheckins
#$fogbugz->request_method('listCheckins', {ixBug => 9999});

###########################################
## Release Notes
#$fogbugz->request_method('search', {
#    q=fixfor:undecided
#    cols=ixBug,sCategory,sTitle,sReleaseNotes
#});

###########################################
## Discussion Groups
# listDiscussGroups
# listDiscussion
# listDiscussTopic

###########################################
## BugzScout
# listScoutCase

###########################################
## Subscriptions
# subscribe
# unsubscribe

###########################################
## Mark as viewed
# view

###########################################
## Settings
# viewSettings


$fogbugz->logoff;

