use MooseX::Declare;

class WWW::PivotalTracker::Command
{
    our $VERSION = '1.00';

    use Getopt::Long::Descriptive qw( :all      );
    use Hash::Merge               qw( merge     );
    use Pod::Usage                qw( pod2usage );
    use WWW::PivotalTracker qw(
        add_note
        add_story
        all_stories
        delete_story
        project_details
        show_story
        stories_for_filter
        update_story
    );

    use aliased 'Config::Any' => 'Config';
    use aliased 'File::HomeDir';

    has options_format => (
        is => 'ro',
        isa => 'Str',
        default => "usage: %c %o",
    );

    has options => (
        is => 'ro',
        isa => 'ArrayRef',
        default => sub { return [
            [                                                                          ],
            [ 'General options:',                                                      ],
            [ 'help'           => 'Show brief help',                                   ],
            [ 'man'            => 'Full documentation',                                ],
            [ 'verbose|v'      => 'Make noise',                                        ],
            [ 'project|p=s'    => 'Named project (from config file) to query/update',  ],
            [ 'project-id|P=i' => 'Project ID to query/update (Required unless --project is specified, or General.DefaultProject is set', ],
            [ 'story-id|i=i'   => 'Story ID to query/update',                          ],
            [                                                                          ],
            [ 'Actions',                                                               ],
            [ 'list-projects'  => 'List all named projects, and their project IDs',    ],
            [ 'show-project'   => 'Display the current settings for a project',        ],
            [ 'add-story|a'    => 'Add a new story',                                   ],
            [ 'delete-story|D' => 'Delete an existing story',                          ],
            [ 'show-story|s'   => 'Show single story',                                 ],
            [ 'all-stories|A'  => 'Show all stories for project',                      ],
            [ 'search=s'       => 'Search for stories given a filter',                 ],
            [ 'update-story|u' => 'Update the details of a story',                     ],
            [ 'comment|c'      => 'Comment on story',                                  ],
            [ 'add-note=s'     => 'Add a note to an existing story',                   ],
            [ 'deliver-all'    => 'Deliver all deliverable stories',                   ],
            [                                                                          ],
            [ ' Story Display Options:',                                               ],
            [ 'show-notes|n'   => "Show stories' notes (if any)",                      ],
            [ 'one-line|1'     => "Show stories one per line",                         ],
            [                                                                          ],
            [ 'Story Attributes:',                                                     ],
            [ 'story|S=s'        => 'Story title to create',                           ],
            [ 'description|d=s'  => 'Story description',                               ],
            [ 'requested-by|b=s' => 'Who requested the story',                         ],
            [ 'owned_by|o=s'     => 'Who is responsible for working on the story',     ],
            [ 'label|l=s@'       => 'Label to apply (May appear more than once, or be a single comma separated list', ],
            [ 'estimate|e=s'     => "Point estimate for story",                        ],
            [ 'created-at|C=s'   => "Date/Time story was created (Defaults to 'now')", ],
            [ 'deadline=s'       => "Deadline of the story (Only applicable to 'release' story type)", ],
            [                                                                          ],
            [ 'Story Type Options:',                                                   ],
            [ 'story-type=s'   => [
                    [ "feature" => "Set story type to 'feature' (Default for new stories)", ],
                    [ "release" => "Set story type to 'release'", ],
                    [ "bug"     => "Set story type to 'bug'",     ],
                    [ "chore"   => "Set story type to 'chore'",   ],
                ],
            ],
            [                                                                          ],
            [ 'Story State Options:',                                                  ],
            [ 'state=s'          => [
                    [ "unscheduled" => "Story has not been scheduled, and is in the icebox", ],
                    [ "unstarted"   => "Story is in the backlog",                            ],
                    [ "started"     => "Work has started on the story",                      ],
                    [ "finished"    => "Work has been completed on the story",               ],
                    [ "delivered"   => "The story has been delivered for review",            ],
                    [ "accepted"    => "The story has been accepted after review",           ],
                    [ "rejected"    => "The story has been rejected after review",           ],
                ],
            ],
        ]},
    );

    has cfg => (
        is         => 'ro',
        isa        => 'HashRef',
        lazy_build => 1,
    );

    method _build_cfg()
    {
        my $cfg = Config->load_files({
            files           => [HomeDir->my_home() . '/.pivotal_tracker.yml'],
            flatten_to_hash => 1,
            use_ext         => 1,
        });

        my $config = {};
        foreach my $file (keys %$cfg) {
            $config = merge($config, $cfg->{$file});
        }

        return $config;
    }


    method _named_projects_string()
    {
        return "No named projects found." unless scalar keys %{$self->cfg()->{'Projects'}};

        my ($max_project_name) = sort { $b <=> $a } map { length($_) } keys %{$self->cfg()->{'Projects'}};

        my @projects = ();
        foreach my $project (keys %{$self->cfg()->{'Projects'}}) {
            my $default_marker = $self->cfg()->{'General'}->{'DefaultProject'} eq $project ? '*' : ' ';
            push @projects, sprintf("%s%-" . $max_project_name . "s %s", $default_marker, $project, $self->cfg()->{'Projects'}->{$project});
        }

        my $projects_text = "Configured Projects:\n\n"
            . join("\n", @projects) . "\n";

        return $projects_text;
    }

    method _api_key()
    {
        return $self->cfg()->{'General'}->{'APIKey'};
    }

    method _get_project_details($project_id)
    {
        my $response = project_details($self->_api_key(), $project_id);

        return $response;
    }

    method _get_all_stories($project_id)
    {
        return all_stories($self->_api_key(), $project_id);
    }

    method _get_story($project_id, $story_id)
    {
        return show_story($self->_api_key(), $project_id, $story_id);
    }

    method _stories_for_filter($project_id, $filter)
    {
        return stories_for_filter($self->_api_key(), $project_id, $filter);
    }

    method _create_story($project_id, $story_opts)
    {
        return add_story($self->_api_key(), $project_id, $story_opts);
    }

    method _update_story($project_id, $story_id, $story_opts)
    {
        return update_story($self->_api_key(), $project_id, $story_id, $story_opts);
    }

    method _delete_story($project_id, $story_id)
    {
        return delete_story($self->_api_key(), $project_id, $story_id);
    }

    method _add_note($project_id, $story_id, $note)
    {
        return add_note($self->_api_key(), $project_id, $story_id, $note);
    }

    method _display_error($result)
    {
        print STDERR "Unable to process request:\n";
        printf STDERR ("  %s\n", $_) foreach @{$result->{'errors'}};
    }

    method _display_project($project)
    {
        my $project_text =
              sprintf("               Name: %s\n", $project->{'name'})
            . sprintf("        Point Scale: %s\n", $project->{'point_scale'});
        $project_text .=
              sprintf("   Iterations Start: %s\n", $project->{'week_start_day'})
                if defined $project->{'week_start_day'};
        $project_text .=
              sprintf("Weeks per Iteration: %s\n", $project->{'iteration_weeks'})
            . "\n";

        print $project_text;
    }

    method _display_story($story, $options?)
    {
        my $story_text;
        if (exists($options->{'one_line'}) && $options->{'one_line'}) {
            $story_text = $self->_display_story_one_line($story, $options);
        }
        else {
            $story_text = $self->_display_story_long($story, $options);
        }
        print $story_text;
    }

    method _display_story_long($story, $options?)
    {
        $options->{'show_notes'} ||= 0;

        my $story_text =
              sprintf("Story %s (%s) < %s >:\n", $story->{'id'}, $story->{'story_type'}, $story->{'url'})
            . sprintf("           Name: %s\n", $story->{'name'})
            . sprintf("       Estimate: %s\n", (defined $story->{'estimate'} ? $story->{'estimate'} : ''))
            . sprintf("          State: %s\n", $story->{'current_state'});

        if (defined $story->{'description'}) {
            my @description_lines = split("\n", $story->{'description'});

            $story_text .= sprintf("    Description: %s\n", shift @description_lines);
            $story_text .= sprintf("                 %s\n", $_) foreach @description_lines;
            $story_text .= "\n" if @description_lines;
        }
        $story_text .=
              sprintf("   Requested By: %s\n", $story->{'requested_by'});
        $story_text .=
              sprintf("       Owned By: %s\n", $story->{'owned_by'})
                if defined $story->{'owned_by'};
        $story_text .=
              sprintf("        Created: %s\n", $story->{'created_at'});
        $story_text .=
              sprintf("       Deadline: %s\n", $story->{'deadline'})
                if defined $story->{'deadline'};
        $story_text .=
              sprintf("       Label(s): %s\n", join(", ", @{$story->{'labels'}}))
                if defined $story->{'labels'};

        if ($options->{'show_notes'} eq '1' && defined $story->{'notes'}) {
            $story_text .= "          Notes:\n";

            my $notes = 0;
            foreach my $note (@{$story->{'notes'}}) {
                $notes++;

                $story_text .= sprintf("            %s (%s):\n", $note->{'author'}, $note->{'date'});
                foreach my $note_line (split("\n", $note->{'text'})) {
                    $story_text .= sprintf("                 %s\n", $note_line);
                }

                $story_text .= "\n" if $notes < @{$story->{'notes'}};
            }
        }

        $story_text .= "\n";

        return $story_text;
    }

    method _display_story_one_line($story, $options?)
    {
        my $story_text = sprintf("Story %s (%s): %s\n", $story->{'id'}, $story->{'story_type'}, $story->{'name'});

        return $story_text;
    }

    method _display_stories($stories, $options?)
    {
        my $num_stories = 0;
        foreach my $story (@$stories) {
            print "=" x 50 . "\n\n" if $num_stories++ >= 1 && (!$options->{'one_line'});
            $self->_display_story($story, $options);
        }
    }

    method _display_note($note)
    {
        my $note_text = sprintf("Note (%s) %s @ %s:\n", $note->{'id'}, $note->{'author'}, $note->{'date'});
        $note_text .= sprintf("    %s\n", $_) foreach split("\n", $note->{'text'});

        print $note_text;
    }

    method _response_was_successful($response)
    {
        return $response->{'success'} eq "true";
    }

    method run()
    {
        $Getopt::Long::Descriptive::MungeOptions = 1;
        my ($opts, $usage) = describe_options(
            $self->options_format(),
            @{$self->options()},
            {
                getopt_conf => [
                    'gnu_getopt',
                    'auto_abbrev',
                    'auto_version',
                ],
            }
        );

        pod2usage(1) if $opts->{'help'};
        pod2usage(-exitstatus => 0, -verbose => 2) if $opts->{'man'};


        my $project_id;
        if (defined(my $project_name = $opts->{'project'})) {
            $project_id = $self->cfg()->{'Projects'}->{$project_name};

            unless ($project_id) {
                print STDERR "Invalid Project Name.\n";
                exit 1;
            }
        }
        elsif (exists $opts->{'project_id'}) {
            $project_id = $opts->{'project_id'};
        }
        else {
            $project_id = $self->cfg()->{'Projects'}->{$self->cfg()->{'General'}->{'DefaultProject'}};
        }

        if (exists $opts->{'list_projects'}) {
            print $self->_named_projects_string();
        }
        elsif (exists $opts->{'show_project'}) {
            my $result = $self->_get_project_details($project_id);

            if ($self->_response_was_successful($result)) {
                $self->_display_project($result);
                exit 0;
            }
            else {
                $self->_display_error($result);
                exit 1;
            }
        }
        elsif (exists $opts->{'show_story'}) {
            unless (exists $opts->{'story_id'} || exists $opts->{'all_stories'}) {
                print STDERR "Missing --story-id <id> or --all-stories.\n";
                exit 1;
            }

            my $result;
            if (exists $opts->{'all_stories'}) {
                $result = $self->_get_all_stories($project_id);

                if ($self->_response_was_successful($result)) {
                    $self->_display_stories(
                        $result->{'stories'},
                        {
                            show_notes => $opts->{'show_notes'},
                            one_line   => $opts->{'one_line'},
                        }
                    );

                    exit 0;
                }
            }
            else {
                $result = $self->_get_story($project_id, $opts->{'story_id'});

                if ($self->_response_was_successful($result)) {
                    $self->_display_story(
                        $result,
                        {
                            show_notes => $opts->{'show_notes'},
                            one_line   => $opts->{'one_line'},
                        }
                    );

                    exit 0;
                }
            }

            $self->_display_error($result);
            exit 1;
        }
        elsif (exists $opts->{'search'}) {
            my $result = $self->_stories_for_filter($project_id, $opts->{'search'});

            if ($self->_response_was_successful($result)) {
                print $result->{'message'} . ":\n\n";
                $self->_display_stories($result->{'stories'}, { show_notes => $opts->{'show_notes'} });
                exit 0;
            }

            $self->_display_error($result);
            exit 1;
        }
        elsif (exists $opts->{'add_story'}) {
            my $result = $self->_create_story(
                $project_id,
                {
                    name          => $opts->{'story'},
                    description   => $opts->{'description'},
                    requested_by  => ($opts->{'requested_by'} || $self->cfg()->{'General'}->{'Me'}),
                    labels        => (exists $opts->{'label'} ? join(",", @{$opts->{'label'}}) : undef),
                    estimate      => $opts->{'estimate'},
                    created_at    => $opts->{'created_at'},
                    deadline      => $opts->{'deadline'},
                    story_type    => $opts->{'story_type'},
                    current_state => $opts->{'state'},
                }
            );

            if ($self->_response_was_successful($result)) {
                $self->_display_story($result);
                exit 0;
            }
            else {
                $self->_display_error($result);
                exit 1;
            }
        }
        elsif (exists $opts->{'update_story'}) {
            unless (exists $opts->{'story_id'}) {
                print STDERR "Must specify a Story ID to update.\n";
                exit 1;
            }

            my %story_details = ();

            %story_details = map { $_ => $opts->{$_} }
                grep { exists $opts->{$_} } qw/
                    created_at
                    deadline
                    description
                    estimate
                    owned_by
                    requested_by
                    story_type
                /;
            $story_details{'name'} = $opts->{'story'} if exists $opts->{'story'};
            $story_details{'labels'} = join(",", @{$opts->{'label'}}) if exists $opts->{'label'};
            $story_details{'current_state'} = $opts->{'state'} if exists $opts->{'state'};

            unless (scalar keys %story_details) {
                print STDERR "Cannot update a story, without specifying what to update.\n";
                exit 1;
            }

            my $result = $self->_update_story(
                $project_id,
                $opts->{'story_id'},
                { %story_details },
            );

            if ($self->_response_was_successful($result)) {
                $self->_display_story($result);
                exit 0;
            }
            else {
                $self->_display_error($result);
                exit 1;
            }
        }
        elsif (exists $opts->{'delete_story'}) {
            unless (exists $opts->{'story_id'}) {
                print STDERR "Must specify a Story ID to update.\n";
                exit 1;
            }

            my $result = $self->_delete_story($project_id, $opts->{'story_id'});

            if ($self->_response_was_successful($result)) {
                print $result->{'message'} . "\n";
                exit 0;
            }
            else {
                $self->_display_error($result);
                exit 1;
            }
        }
        elsif (exists $opts->{'add_note'}) {
            unless (exists $opts->{'story_id'}) {
                print STDERR "Must specify a Story ID to add a note.\n";
                exit 1;
            }

            my $result = $self->_add_note($project_id, $opts->{'story_id'}, $opts->{'add_note'});

            if ($self->_response_was_successful($result)) {
                $self->_display_note($result);
                exit 0;
            }
            else {
                $self->_display_error($result);
                exit 1;
            }
        }
    }
}

1;
__END__

=head1 NAME

WWW::PivotalTracker::Command - Command-line interface to Pivotal Tracker L<http://www.pivotaltracker.com/>

=head1 VERSION

1.00

=cut

=head1 SYNOPSIS

This module provides a command-line interface to interact with the Pivotal
Tracker API.

    #!/usr/bin/perl

    use WWW::PivotalTracker::Command;
    my $cmd = WWW::PivotalTracker::Command->new();
    $cmd->run();

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pivotaltracker at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PivotalTracker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PivotalTracker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PivotalTracker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PivotalTracker>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PivotalTracker/>

=item * Source code

L<git://github.com/jhelwig/www-pivotaltracker.git>

=item * Webpage

L<http://github.com/jhelwig/www-pivotaltracker>

=back

=head1 ACKNOWLEDGEMENTS

Chris Hellmuth

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Jacob Helwig.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: set tabstop=4 shiftwidth=4: 
