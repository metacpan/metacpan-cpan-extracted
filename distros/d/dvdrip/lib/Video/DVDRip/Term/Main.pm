# $Id: Main.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Term::Main;

use base qw( Video::DVDRip::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

use Video::DVDRip::Project;
use Video::DVDRip::Logger;
use Video::DVDRip::Term::Progress;
use Video::DVDRip::GUI::Pipe;
use Video::DVDRip::Term::ExitTask;

sub filename            { shift->{filename}                         }
sub select_title        { shift->{select_title}                     }
sub project             { shift->{project}                          }
sub progress            { shift->{progress}                         }
sub glib_main_loop      { shift->{glib_main_loop}                   }
sub fullscreen          { shift->{fullscreen}                       }
sub quiet               { shift->{quiet}                            }

sub set_filename        { shift->{filename}       = $_[1]           }
sub set_select_title    { shift->{select_title}   = $_[1]           }
sub set_project         { shift->{project}        = $_[1]           }
sub set_progress        { shift->{progress}       = $_[1]           }
sub set_glib_main_loop  { shift->{glib_main_loop} = $_[1]           }
sub set_fullscreen      { shift->{fullscreen}     = $_[1]           }
sub set_quiet           { shift->{quiet}          = $_[1]           }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $filename, $select_title, $fullscreen, $quiet )
        = @par{ 'filename', 'select_title', 'fullscreen', 'quiet' };

    $fullscreen = 0 if $quiet;

    my $self = bless {
        filename     => $filename,
        select_title => $select_title,
        fullscreen   => $fullscreen,
        quiet        => $quiet,
        progress     =>
            Video::DVDRip::Term::Progress->new( quiet => !$fullscreen, ),
    }, $class;

    return $self;
}

sub clear_screen {
    my $self = shift;

    $self->print_screen( chr(27) . "[2J" );
    $self->print_screen( chr(27) . "[0;0H" );

    my $col   = chr(27) . "[1;33m";
    my $reset = chr(27) . "[0m";

    $self->print_screen( "[ ${col}dvd::rip $Video::DVDRip::VERSION - "
            . "(c) 2002-2005 Jörn Reder - "
            . "Task Execution Terminal$reset ]\n\n" );

    1;
}

sub print_screen {
    my $self = shift;
    return unless $self->fullscreen;
    print @_;
    1;
}

sub open_project {
    my $self = shift;

    my $project
        = Video::DVDRip::Project->new_from_file( filename => $self->filename,
        );

    $self->set_project($project);

    $self->print_screen( "> Open project file " . $self->filename . "\n" );

    my $logger = Video::DVDRip::Logger->new( project => $project, );

    $logger->set_fh( \*STDOUT ) if !$self->quiet && !$self->fullscreen;

    $self->set_logger($logger);

    $project->content->set_selected_titles( [ $self->select_title - 1 ] )
        if $self->select_title;

    1;
}

sub exec_tasks {
    my $self = shift;
    my ($tasks) = @_;

    my $first_task;
    my $last_task;
    foreach my $task_name ( @{$tasks} ) {
        $self->log("Loading task module for '$task_name'");
        my $module = "Video::DVDRip::Task::$task_name";
        eval "use $module\n";
        die $@ if $@;

        my $task = $module->new(
            ui       => $self,
            project  => $self->project,
            cb_error => sub {
                $self->glib_main_loop->quit;
            },
        );
        $first_task ||= $task;
        if ($last_task) {
            $last_task = $last_task->next_task while $last_task->next_task;
            $last_task->set_next_task($task);
        }
        $last_task = $task;
    }

    $last_task->set_next_task(
        Video::DVDRip::Term::ExitTask->new( ui => $self, ),
    );

    $self->print_screen("\n");

    $first_task->configure;
    $first_task->start;

    $self->enter_mainloop;
    $self->progress->close if $last_task->reuse_progress;

    1;
}

sub long_message_window {
    my $self      = shift;
    my %par       = @_;
    my ($message) = @par{'message'};

    print $message. "\n";

    1;
}

sub message_window {
    my $self      = shift;
    my %par       = @_;
    my ($message) = @par{'message'};

    print $message. "\n";

    1;
}

sub confirm_window {
    my $self = shift;
    my %par = @_;
    my  ($message, $yes_callback, $no_callback, $position) =
    @par{'message','yes_callback','no_callback','position'};
    my  ($with_cancel) =
    @par{'with_cancel'};

    #-- For know just call the yes callback
    &$yes_callback();
    
    1;
}

sub enter_mainloop {
    my $self = shift;

    my $main_loop = Glib::MainLoop->new;
    $self->set_glib_main_loop($main_loop);

    $main_loop->run;

    1;
}
1;
