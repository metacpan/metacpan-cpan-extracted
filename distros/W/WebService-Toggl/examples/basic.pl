#!/usr/bin/env perl

use strict;
use warnings;

use v5.10;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use WebService::Toggl;

main: {
    die 'Need TOGGL_API_KEY envvar set!' unless ($ENV{TOGGL_API_KEY});

    my $toggl = WebService::Toggl->new({api_key => $ENV{TOGGL_API_KEY}});

    my $me = $toggl->me;
    say "Me: " . $me->fullname . " <" . $me->email . ">:";

    say "My Workspaces:";
    for my $ws ($me->workspaces->all) {
        say "  " . $ws->name . " (" . $ws->id . ")";
        say "    Users:";
        say "      " . $_->fullname . " <" . $_->email . "> " for ($ws->users->all);
        say "    Clients:";
        say "      " . $_->name . " (" . $_->id . ") " for ($ws->clients->all);
        say "    Projects:";
        say "      " . $_->name . " (" . $_->id . ") " for ($ws->projects->all);
        say "    Tags:";
        say "      " . $_->name . " (" . $_->id . ") " for ($ws->tags->all);
    }

    say "My Projects:";
    for my $project ($me->projects->all) {
        say "  " . $project->name . " (" . $project->id . ")";
        say "    ProjectUsers:";
        say "      Uid: " . $_->uid . " (" . $_->id . ") " for ($project->project_users->all);
        say "    Tasks:";
        say "    " . $_->name . " (" . $_->id . ") " for ($project->tasks->all);
    }

    say "My Time Entries:";
    for my $entry ($me->time_entries->all) {
        say "  " . $entry->description . " (" . $entry->id . ")";
    }

    say "My Tags:";
    for my $tag ($me->tags->all) {
        say "  " . $tag->name . " (" . $tag->id . ")";
    }

    say "My Clients:";
    for my $client ($me->clients->all) {
        say "  " . $client->name . " (" . $client->id . ")";
        say "    Projects:";
        say "      " . $_->name . " (" . $_->id . ") " for ($client->projects->all);

    }


}

__END__

