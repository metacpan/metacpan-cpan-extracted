#!/usr/bin/perl
use strict;
use warnings;
use Util::H2O::More qw/d2o ddd/;

# Define a minimal but complex nested data structure
my $data = {
    'company' => {
        'teams' => [
            {
                'name' => 'Development',
                'members' => [
                    {
                        'id' => 1,
                        'name' => 'Alice',
                        'skills' => ['Perl', 'Python'],
                        'projects' => [
                            {
                                'name' => 'Project X',
                                'tasks' => [
                                    {
                                        'title' => 'Design',
                                        'status' => 'Completed',
                                        'details' => {
                                            'deadline' => '2024-01-15',
                                            'budget'   => 2000,
                                        },
                                    },
                                    {
                                        'title' => 'Implementation',
                                        'status' => 'In Progress',
                                        'details' => {
                                            'deadline' => '2024-03-01',
                                            'budget'   => 5000,
                                        },
                                    },
                                ],
                            },
                        ],
                    },
                ],
            },
            {
                'name' => 'Marketing',
                'members' => [
                    {
                        'id' => 2,
                        'name' => 'Bob',
                        'skills' => ['SEO', 'Content Creation'],
                        'projects' => [
                            {
                                'name' => 'Campaign Y',
                                'tasks' => [
                                    {
                                        'title' => 'Planning',
                                        'status' => 'Not Started',
                                        'details' => {
                                            'deadline' => '2024-02-01',
                                            'budget'   => 1500,
                                        },
                                    },
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    },
};

# Process and print data
foreach my $team (@{$data->{'company'}{'teams'}}) {
    print "Team: " . $team->{'name'} . "\n";
    
    foreach my $member (@{$team->{'members'}}) {
        print "  Member ID: " . $member->{'id'} . "\n";
        print "  Name: " . $member->{'name'} . "\n";
        print "  Skills: " . join(', ', @{$member->{'skills'}}) . "\n";

        foreach my $project (@{$member->{'projects'}}) {
            print "    Project: " . $project->{'name'} . "\n";
            
            foreach my $task (@{$project->{'tasks'}}) {
                print "      Task: " . $task->{'title'} . "\n";
                print "      Status: " . $task->{'status'} . "\n";
                print "      Details:\n";
                print "        Deadline: " . $task->{'details'}{'deadline'} . "\n";
                print "        Budget: \$" . $task->{'details'}{'budget'} . "\n";
            }
        }
    }
    print "\n";
}

# Add a new team
push @{$data->{'company'}{'teams'}}, {
    'name' => 'Sales',
    'members' => [
        {
            'id' => 3,
            'name' => 'Carol',
            'skills' => ['Negotiation', 'Market Analysis'],
            'projects' => [
                {
                    'name' => 'Sales Drive Z',
                    'tasks' => [
                        {
                            'title' => 'Lead Generation',
                            'status' => 'Not Started',
                            'details' => {
                                'deadline' => '2024-04-01',
                                'budget'   => 3000,
                            },
                        },
                    ],
                },
            ],
        },
    ],
};

d2o $data;

# Modify an existing task's status and budget
$data->company->teams->i(0)->members->i(0)->projects->i(0)->tasks->i(1)->status('Completed');
$data->company->teams->i(0)->members->i(0)->projects->i(0)->tasks->i(1)->details->budget(6000);

# Print the updated data
print "Updated data:\n";
foreach my $team ($data->company->teams->all) {
    print "Team: " . $team->name . "\n";
    
    foreach my $member ($team->members->all) {
        print "  Member ID: " . $member->id . "\n";
        print "  Name: " . $member->name . "\n";
        print "  Skills: " . join(', ', $member->skills->all) . "\n";

        foreach my $project ($member->projects->all) {
            print "    Project: " . $project->name . "\n";
            
            foreach my $task ($project->tasks->all) {
                print "      Task: " . $task->title . "\n";
                print "      Status: " . $task->status . "\n";
                print "      Details:\n";
                print "        Deadline: " . $task->details->deadline . "\n";
                print "        Budget: \$" . $task->details->budget . "\n";
            }
        }
    }
    print "\n";
}
