# $Id: Main.pm 2372 2009-02-22 18:30:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Main;

use strict;

use base qw(Video::DVDRip::GUI::Base);
use Locale::TextDomain qw (video.dvdrip);

use Gtk2;
use Gtk2::Ex::FormFactory 0.65;
use File::Basename;

use Video::DVDRip::Project;
use Video::DVDRip::Logger;
use Video::DVDRip::JobPlanner;

use Video::DVDRip::GUI::Context;
use Video::DVDRip::GUI::Project::Storage;
use Video::DVDRip::GUI::Project::Title;
use Video::DVDRip::GUI::Project::ClipZoom;
use Video::DVDRip::GUI::Project::Subtitle;
use Video::DVDRip::GUI::Project::Transcode;
use Video::DVDRip::GUI::Project::Logging;
use Video::DVDRip::GUI::Progress;
use Video::DVDRip::GUI::ExecFlow;
use Video::DVDRip::GUI::Rules;

sub get_form_factory            { shift->{form_factory}                 }
sub get_gtk_icon_factory        { shift->{gtk_icon_factory}             }

sub set_form_factory            { shift->{form_factory}         = $_[1] }
sub set_gtk_icon_factory        { shift->{gtk_icon_factory}     = $_[1] }

sub get_gui_state_file {
    return $ENV{HOME}."/.dvdrip/main-gui.state";
}

sub save_gui_state {
    my $self = shift;

    my ($win_width, $win_height) =
        $self->get_form_factory
             ->get_widget("main_window")
             ->get_gtk_parent_widget
             ->get_size;

    my $file = $self->get_gui_state_file;
    open (my $fh, "> $file") or die "can't write $file";
    print $fh $win_width."\t".
              $win_height."\n";
    close $fh;
    
    1;
}

sub load_gui_state {
    my $self = shift;

    my $file = $self->get_gui_state_file;
    if ( ! -f $file ) {
        return ( default_width => 600, default_height => 500 );
    }

    open (my $fh, $file) or die "can't read $file";
    my $line = <$fh>;
    close $fh;

    chomp $line;
    my @pos = split("\t", $line);

    return ( default_width => $pos[0], default_height => $pos[1] );
}

sub window_name {
    my $self = shift;

    my $context = $self->get_context;
    my $project = $context->get_object("project");

    if ($project) {
        return $self->config('program_name') . " - " . $project->name;
    }
    else {
        return $self->config('program_name') . " - <no project>";
    }
}

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my $logger = Video::DVDRip::Logger->new;
    $self->set_logger($logger);

    return $self;
}

sub start {
    my $self = shift;
    my %par = @_;
    my ( $filename, $open_cluster_control, $function, $select_title )
        = @par{ 'filename', 'open_cluster_control', 'function',
        'select_title' };

    Gtk2->init;

    my $context = Video::DVDRip::GUI::Context->create;
    $self->set_context($context);

    if ( !$open_cluster_control ) {
        $self->build;
    }

    $context->set_object( job_planner => Video::DVDRip::JobPlanner->new );
    $context->set_object(
        exec_flow_gui => Video::DVDRip::GUI::ExecFlow->new(
            context      => $context,
            form_factory => $self->get_form_factory,
        )
    );

    Glib->install_exception_handler(
        sub {
            my ($msg) = @_;
            if ( $msg =~ /^msg:\s*(.*?)\s+at.*?line\s+\d+/s ) {
                $self->error_window( message => $1, );

            }
            else {
                my $error = __x(
                    "An internal exception was thrown!\n"
                        . "The error message was:\n\n{msg}",
                    msg => $msg
                );
                $self->long_message_window( message => $error );
            }

            1;
        }
    );

    my $project;
    if ( $self->dependencies_ok ) {
        if ($filename) {
            $self->open_project_file( filename => $filename );
            $project = $self->get_context_object("project");
        }

        $self->log(
            __x("Detected transcode version: {version}",
                version => $self->version("transcode")
            )
        );

        # Open Cluster Control window, if requested
        $self->cluster_control( exit_on_close => 1 )
            if $open_cluster_control;

        # Error check
        if (    ( $select_title or $function )
            and not $project
            and $function ne 'preferences' ) {
            $self->error_dialog(
                message => __ "Opening project file failed. Aborting." );
            return 0;
        }

        $self->update_window_title;

        Glib::Idle->add(
            sub {
                # Select a title, if requested
                if ($select_title) {
                    $self->log("Selecting title $select_title");
                    $context->set_object_attr( "content.selected_title_nr",
                        $select_title );
                    $project->content->set_selected_title_nr($select_title);
                }

                # Execute a function, if requested
                if ( $function eq 'preferences' ) {
                    $self->edit_preferences(1);
                }
                elsif ($function) {
                    my $title = $self->selected_title;
                    $title->set_tc_exit_afterwards('dont_save');
                    $title->set_tc_split(1) if $function eq 'transcode_split';
                    $self->get_context_object("transcode")->transcode;
                }
                return 0;
            }
        );
    }

    Gtk2->main;

    1;
}

sub build {
    my $self = shift;

    $self->build_icon_factory;

    my $context = $self->get_context;

    $context->set_object( main => $self );

    my $rule_checker = Video::DVDRip::GUI::Rules->new;

    my $window;
    my $ff = Gtk2::Ex::FormFactory->new(
        context  => $context,
        rule_checker => $rule_checker,
        sync     => 1,
        content  => [
            $window = Gtk2::Ex::FormFactory::Window->new(
                attr           => "main.window_name",
                name           => "main_window",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        $self->load_gui_state,
                    );
                    1;
                },
                closed_hook => sub { $self->exit_program; 1 },
            ),
        ],
    );

    #-- FormFactory need to be set into the object
    #-- before building the other dependent factories
    $self->set_form_factory($ff);

    $window->set_content(
        [
            $self->build_menu_factory,
            $self->build_project_factory,
        ]
    );

    $ff->open;
    $ff->update;

    $self->set_wm_icon;

    return 1;
}

sub set_wm_icon {
    my $self = shift;

    my $gtk_window
        = $self->get_form_factory->get_widget("main_window")->get_gtk_widget;

    my $icon_file
        = $self->search_perl_inc( rel_path => "Video/DVDRip/icon.xpm" );

    if ($icon_file) {
        my ( $icon, $mask )
            = Gtk2::Gdk::Pixmap->create_from_xpm( $gtk_window->window,
            $gtk_window->style->white, $icon_file );

        $gtk_window->window->set_icon( undef, $icon, $mask );
        $gtk_window->window->set_icon_name( $self->config('program_name') );
    }

    1;
}

sub build_menu_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::Menu->new(
        menu_tree => [
            __"_File" => {
                item_type => '<Branch>',
                children  => [
                    __"_New Project" => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-new',
                        callback    => sub { $self->new_project },
                        accelerator => '<ctrl>N',
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },
                    __"_Open Project..." => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-open',
                        callback    => sub { $self->open_project },
                        accelerator => '<ctrl>o',
                        active_cond    => sub { !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },
                    __"_Save Project" => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-save',
                        callback    => sub { $self->save_project },
                        accelerator => '<ctrl>s',
                        object      => 'project',
                    },
                    __"Save _Project as..." => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-save-as',
                        callback    => sub { $self->save_project_as },
                        accelerator => '<shift><ctrl>s',
                        object      => 'project',
                    },
                    __"_Close Project" => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-close',
                        callback    => sub { $self->close_project },
                        accelerator => '<ctrl>w',
                        object      => 'project',
                        active_cond    => sub {
                             $context->get_object("project") &&
                            !$self->progress_is_active
                        },
                        active_depends => [ "project", "progress.is_active"],
                    },

                    "sep_quit" => { item_type => '<Separator>', },

                    __"_Exit" => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-quit',
                        callback    => sub { $self->exit_program },
                        accelerator => '<ctrl>q',
                    },
                ],
            },
            __"_Edit" => {
                item_type => '<Branch>',
                children  => [
                    __ "Edit _Preferences..." => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-preferences',
                        callback    => sub { $self->edit_preferences },
                        accelerator => '<ctrl>p',
                    },
                ],
            },
            __"_Title" => {
                item_type => '<Branch>',
                children  => [
                    __"Transcode" => {
                        item_type  => '<StockItem>',
                        extra_data => 'gtk-convert',
                        callback   => sub {
                            $context->get_object("transcode")->transcode;
                        },
                        object => 'title',
                        active_cond    => sub {  $context->get_object("title") &&
                                                !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },
                    __"View target file" => {
                        item_type  => '<StockItem>',
                        extra_data => 'gtk-media-play',
                        callback   => sub {
                            $context->get_object("transcode")->view_avi;
                        },
                        object => 'title',
                        active_cond    => sub { $context->get_object("title") &&
                                                !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },
                    __"Add project to cluster" => {
                        item_type  => '<StockItem>',
                        extra_data => 'gtk-network',
                        callback   => sub {
                            $context->get_object("transcode")->add_to_cluster;
                        },
                        object => 'title',
                        active_cond    => sub {
                            my $title = $self->selected_title;
                            return 0 if not $title;
                            return $title->tc_container ne 'vcd';
                        },
                        active_depends => "title.tc_container",
                    },

                    "sep_vobsub"       => { item_type => '<Separator>', },

                    __"Create vobsub" => {
                        callback => sub {
                            $context->get_object("subtitle_gui")
                                ->create_vobsub_now;
                        },
                        object => 'subtitle',
                        active_cond    => sub { $context->get_object("title") &&
                                                !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },

                    "sep_info" => { item_type => '<Separator>', },

                    __"Create dvdrip-info file" => {
                        callback => sub {
                            my $title = $context->get_object("title");
                            return 1 if not $title;
                            require Video::DVDRip::InfoFile;
                            Video::DVDRip::InfoFile->new(
                                title    => $title,
                                filename => $title->info_file,
                            )->write;
                            1;
                        },
                        object => 'title',
                    },

                    "sep_wav" => { item_type => '<Separator>', },

                    __"Create WAV from selected audio track" => {
                        callback => sub {
                            $context->get_object("transcode")->create_wav;
                        },
                        object => 'title',
                        active_cond    => sub { $context->get_object("title") &&
                                                !$self->progress_is_active },
                        active_depends => "progress.is_active",
                    },
                ],
            },
            __"_Cluster" => {
                item_type => '<Branch>',
                children  => [
                    __ "Contro_l..." => {
                        item_type   => '<StockItem>',
                        extra_data  => 'gtk-network',
                        callback    => sub { $self->cluster_control },
                        accelerator => '<ctrl>m',
                    },
                ],
            },
            __"_Debug" => {
                item_type => '<Branch>',
                children  => [
                    __
                        "Show _Transcode commands..." => {
                        item_type   => '<Item>',
                        callback    => sub { $self->show_transcode_commands },
                        accelerator => '<ctrl>t',
                        object      => 'title',
                        },
                    __ "Check _dependencies..." => {
                        item_type   => '<Item>',
                        callback    => sub { $self->show_dependencies },
                        accelerator => '<ctrl>d',
                    },
                ],
            },
	    __"_Help" => {
		item_type => '<LastBranch>',
		children => [
		  __"_About dvd::rip" => {
		    callback    => sub { $self->show_about_dialog },
		    item_type   => '<StockItem>',
		    extra_data  => 'gtk-about',
		    accelerator => '<ctrl>A',
		  },
		]
	    },
        ],
    );
}

sub build_project_factory {
    my $self = shift;

    my $context = $self->get_context;

    my $storage = Video::DVDRip::GUI::Project::Storage->new(
        form_factory => $self->get_form_factory, );

    my $title = Video::DVDRip::GUI::Project::Title->new(
        form_factory => $self->get_form_factory, );

    my $clip_zoom = Video::DVDRip::GUI::Project::ClipZoom->new(
        form_factory => $self->get_form_factory, );

    my $subtitle = Video::DVDRip::GUI::Project::Subtitle->new(
        form_factory => $self->get_form_factory, );

    my $transcode = Video::DVDRip::GUI::Project::Transcode->new(
        form_factory => $self->get_form_factory, );

    my $logging = Video::DVDRip::GUI::Project::Logging->new(
        form_factory => $self->get_form_factory, );

    my $progress = Video::DVDRip::GUI::Progress->new(
        form_factory => $self->get_form_factory, );

    return Gtk2::Ex::FormFactory::VBox->new(
        object   => "project",
        inactive => "invisible",
        expand   => 1,
        content  => [
            Gtk2::Ex::FormFactory::Notebook->new(
                name    => "main_nb",
                attr    => "project.last_selected_nb_page",
                expand  => 1,
                $self->get_optimum_screen_size_options("notebook"),
                content => [
                    $storage->build_factory,   $title->build_factory,
                    $clip_zoom->build_factory, $subtitle->build_factory,
                    $transcode->build_factory, $logging->build_factory,
                ],
            ),
            $progress->build_factory,
        ],
    );
}

sub build_selected_title_factory {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new(
        object  => "title",
        title   => __ "Selected DVD title",
        content => [
            Gtk2::Ex::FormFactory::Popup->new(
                attr => "content.selected_title_nr",
                tip => __"Choose a DVD title at any time here",

            ),
            Gtk2::Ex::FormFactory::Label->new(
                attr => "title.get_title_info",
            ),
        ],
    );
}

sub build_icon_factory {
    my $self = shift;

    my $icon_factory = Gtk2::IconFactory->new;
    $icon_factory->add_default;
    $self->set_gtk_icon_factory($icon_factory);

    my $icon_dir
        = $self->search_perl_inc( rel_path => "Video/DVDRip/GUI/Icons" );

    return if not -d $icon_dir;

    my ( $pixbuf, $icon_set, $name );

    foreach my $icon_file ( glob("$icon_dir/*.png") ) {
        $pixbuf   = Gtk2::Gdk::Pixbuf->new_from_file($icon_file);
        $icon_set = Gtk2::IconSet->new_from_pixbuf($pixbuf);

        $name = basename($icon_file);
        $name =~ s/\.[^.]+$//;

        $icon_factory->add( $name, $icon_set );
    }

    1;
}

sub new_project {
    my $self = shift;

    return if not $self->dependencies_ok;

    return if $self->unsaved_project_open( wants => "new_project" );

    $self->close_project;

    my $project = Video::DVDRip::Project->new;

    $self->get_context->set_object( project    => $project );
    $self->get_context->set_object( "!project" => undef );
    $self->get_context->get_object("job_planner")->set_project($project);

    $self->update_window_title;

    my $gtk_entry
        = $self->get_form_factory->get_widget("project_name")->get_gtk_widget;
    $gtk_entry->select_region( 0, -1 );
    $gtk_entry->grab_focus;

    1;
}

sub update_window_title {
    my $self = shift;

    $self->get_context->update_object_attr_widgets("main.window_name");

    1;
}

sub open_project {
    my $self = shift;

    return if not $self->dependencies_ok;

    return if $self->unsaved_project_open( wants => "open_project" );

    $self->close_project;

    $self->show_file_dialog(
        dir      => $self->config('dvdrip_files_dir'),
        filename => "",
        cb       => sub {
            $self->open_project_file( filename => $_[0] );
        },
    );
}

sub open_project_file {
    my $self       = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    return if not $self->dependencies_ok;

    if ( not -r $filename ) {
        $self->message_window(
            message => __x(
                "File '{filename}' not found or not readable.",
                filename => $filename
            )
        );
        return 1;
    }

    my $project
        = Video::DVDRip::Project->new_from_file( filename => $filename );

    my $context = $self->get_context;

    $context->set_object( project    => $project );
    $context->set_object( "!project" => undef );

    $self->get_context->get_object("job_planner")->set_project($project);

    $self->logger->set_project($project);
    $self->logger->insert_project_logfile;

    $self->update_window_title;

    if ( $project->convert_message ) {
        $self->message_window( message => $project->convert_message );
        $project->set_convert_message("");
    }

    1;
}

sub save_project {
    my $self = shift;

    my $context = $self->get_context;
    my $project = $context->get_object("project");
    my $created = $project->created;

    if ( $project->filename ) {
        # save
        $project->save;

        # reset changed flag
        $self->get_context->get_proxy("project")->set_object_changed(0);

        # greys out "Project name" widget
        $context->update_object_attr_widgets("project.name");
        
        return 1;

    }
    else {
        $self->show_file_dialog(
            title    => __ "Save project: choose filename",
            type     => "save",
            dir      => $self->config('dvdrip_files_dir'),
            filename => $project->name . ".rip",
            confirm  => 1,
            cb       => sub {
                $project->set_filename( $_[0] );
                $self->save_project;
                unless ($created) {
                    $context->update_object_widgets("project");
                    $self->logger->set_project($project);
                    $self->log( __x "Project {name} created",
                        name => $project->name );
                }
            },
        );
        return 0;
    }
}

sub save_project_as {
    my $self = shift;

    my $context = $self->get_context;
    my $project = $context->get_object("project");
    my $created = $project->created;

    $self->show_file_dialog(
        dir      => $self->config('dvdrip_files_dir'),
        filename => $project->name . ".rip",
        confirm  => 1,
        cb       => sub {
            $project->set_filename( $_[0] );
            $project->save;
            $self->update_window_title;
            unless ($created) {
                $context->update_object_widgets("project");
                $self->logger->set_project($project);
                $self->log( __x "Project {name} created", name => $project->name );
            }
        },
    );

    return 1;
}

sub close_project {
    my $self       = shift;
    my %par        = @_;
    my ($dont_ask) = @par{'dont_ask'};

    return if not $dont_ask and $self->unsaved_project_open;

    $self->get_context->set_object( project    => undef );
    $self->get_context->set_object( "!project" => 1 );
    $self->get_context->get_object("job_planner")->set_project();

    $self->update_window_title;

    1;
}

sub project_changed {
    return $_[0]->get_context->get_proxy("project")->get_object_changed;
}

sub unsaved_project_open {
    my $self    = shift;
    my %par     = @_;
    my ($wants) = @par{'wants'};

    return if ! $self->get_context->get_object("project");
    return if ! $self->project_changed;

    $self->confirm_window(
        message      => __ "Do you want to save this project first?",
        yes_label    => __ "Yes",
        no_label     => __ "No",
        yes_callback => sub {
            if ( $self->save_project ) {
                $self->close_project( dont_ask => 1 );
                $self->$wants() if $wants;
            }
        },
        no_callback => sub {
            $self->close_project( dont_ask => 1 );
            $self->$wants() if $wants;
        },
        with_cancel => 1,
    );

    1;
}

sub exit_program {
    my $self    = shift;
    my %par     = @_;
    my ($force) = @par{'force'};

    $self->save_gui_state;

    return 1
        if not $force
        and $self->unsaved_project_open( wants => "exit_program" );

    $self->close_project( dont_ask => $force );

    $self->get_form_factory->close;

    Gtk2->main_quit;
}

sub edit_preferences {
    my $self = shift;
    my ($init) = @_;

    require Video::DVDRip::GUI::Preferences;

    my $pref = Video::DVDRip::GUI::Preferences->new(
        form_factory => $self->get_form_factory, );

    $pref->open_window;

    $self->message_window (
        modal   => 1,
        message =>
            __"This is the first time you start dvd::rip. The Preferences ".
              "dialog was opened automatically for you. Please review the settings, ".
              "in particular the default DVD device and your data base directory. ".
              "Point it to a directory with sufficient diskspace of at least ".
              "10 GB for full DVD copies.",
    ) if $init;

    1;
}

sub cluster_control {
    my $self            = shift;
    my %par             = @_;
    my ($exit_on_close) = @par{'exit_on_close'};

    if ( $self->get_context->get_object("cluster_gui") ) {
        my $cluster = $self->get_context->get_object("cluster_gui");
        $cluster->connect_master if !$cluster->master;
        return;
    }

    return if not $self->dependencies_ok;

    require Video::DVDRip::GUI::Cluster::Control;

    my $cluster = Video::DVDRip::GUI::Cluster::Control->new(
        context      => $self->get_context,
        form_factory => $self->get_form_factory,
    );
    $cluster->set_exit_on_close($exit_on_close);
    $cluster->open_window;

    if ( !$cluster->master ) {
        return if !$cluster->connect_master;
    }

    1;
}

sub show_transcode_commands {
    my $self = shift;

    my $title = $self->selected_title;
    return unless $title;

    my $commands = "";

    $commands .= __ "Probe Command:\n"
        . "==============\n"
        . $title->get_probe_command() . "\n";

    $commands .= "\n\n";

    if ( $title->project->rip_mode eq 'rip' ) {
        my $rip_method =
            $title->tc_use_chapter_mode
            ? "get_rip_command"
            : "get_rip_and_scan_command";

        $commands .= __ "Rip Command:\n"
            . "============\n"
            . $title->$rip_method() . "\n";
    }
    else {
        $commands .= __ "Scan Command:\n"
            . "============\n"
            . $title->get_scan_command() . "\n";
    }

    $commands .= "\n\n";

    $commands .= __ "Grab Preview Image Command:\n"
        . "===========================\n";

    eval {
        $commands .= $title->get_take_snapshot_command(
            frame => $title->preview_frame_nr )
            . "\n";
    };

    if ($@) {
        $commands .= __
            "You must first rip the selected title to see this command.\n";
    }

    $commands .= "\n\n";

    $commands .= __ "Transcode Command:\n" . "==================\n";

    if ( $title->tc_multipass ) {
        $commands
            .= $title->get_transcode_command( pass => 1, split => 1 ) . "\n"
            . $title->get_transcode_command( pass  => 2, split => 1 ) . "\n";
    }
    else {
        $commands .= $title->get_transcode_command( split => 1 ) . "\n";
    }

    if ( $title->tc_container eq 'vcd' ) {
        $commands .= "\n" . $title->get_mplex_command( split => 1 ), "\n";
    }

    if ( $title->is_ogg ) {
        $commands .= "\n"
            . $title->get_merge_audio_command(
            vob_nr => $title->get_first_audio_track,
            avi_nr => 0,
            ),
            "\n";
    }

    $commands .= "\n\n";

    my $add_audio_tracks = $title->get_additional_audio_tracks;

    if ( keys %{$add_audio_tracks} ) {
        $commands .= __ "Additional audio tracks commands:\n"
            . "============================\n";

        my ( $avi_nr, $vob_nr );
        while ( ( $avi_nr, $vob_nr ) = each %{$add_audio_tracks} ) {
            $commands .= "\n"
                . $title->get_transcode_audio_command(
                vob_nr    => $vob_nr,
                target_nr => $avi_nr,
                )
                . "\n";
            $commands .= "\n"
                . $title->get_merge_audio_command(
                vob_nr    => $vob_nr,
                target_nr => $avi_nr,
                );
        }

        $commands .= "\n\n";
    }

    $commands .= __ "View DVD Command:\n"
        . "=================\n"
        . $title->get_view_dvd_command(
        command_tmpl => $self->config('play_dvd_command') )
        . "\n";

    $commands .= "\n\n";

    $commands .= __ "View Files Command:\n" . "===================\n"
        . $title->get_view_avi_command(
        command_tmpl => $self->config('play_file_command'),
        file         => "movie.avi",
        )
        . "\n";

    my $create_image_command;
    eval { $create_image_command = $title->get_create_image_command; };
    $create_image_command = $self->stripped_exception if $@;

    my $burn_command;
    eval { $burn_command = $title->get_burn_command; };
    $burn_command = $self->stripped_exception if $@;

    $commands .= "\n\n";

    $commands .= __ "CD image creation command:\n"
        . "========================\n"
        . $create_image_command;

    $commands .= "\n\n";

    $commands .= __ "CD burning command:\n"
        . "==================\n"
        . $burn_command;

    $commands .= "\n\n";

    my $wav_command = eval { $title->get_create_wav_command };

    if ($wav_command) {

        $commands .= __ "WAV creation command:\n"
            . "====================\n"
            . $wav_command;

    }

    $self->long_message_window(
        title   => __ "Commands executed by dvd::rip",
        message => $commands
    );

    1;
}

sub show_dependencies {
    my $self = shift;

    require Video::DVDRip::GUI::Depend;

    my $depend = Video::DVDRip::GUI::Depend->new(
        form_factory => $self->get_form_factory );
    $depend->open_window;

    1;
}

sub dependencies_ok {
    my $self = shift;

    return 1 if $self->depend_object->ok;

    $self->show_dependencies;
    $self->message_window( message => __
            "One or several mandatory tools are\nmissing or too old. You must install them\nbefore you can proceed with dvd::rip."
    );

    return 0;
}

sub show_about_dialog {
    my $self = shift;

    my $license     = $self->read_text_file("license.txt");
    my $translators = $self->read_text_file("translators.txt");

    my $splash_lang_file = __"splash.en.png";

    my $logo_image = Gtk2::Ex::FormFactory->get_image_path (
	    "Video/DVDRip/$splash_lang_file"
    );

    my $logo_pixbuf = $logo_image ?
	    Gtk2::Gdk::Pixbuf->new_from_file($logo_image) : 
	    undef;

    my $about = Gtk2::AboutDialog->new;
    $about->set (
        name => "dvd::rip",
	version => $Video::DVDRip::VERSION,
        logo => $logo_pixbuf,
        license => $license,
        translator_credits => $translators,
    );

    $about->run;
    $about->destroy;

    1;
}

sub read_text_file {
    my $self = shift;
    my ($name) = @_;

    my $file = Gtk2::Ex::FormFactory->get_image_path("Video/DVDRip/$name");

    open (my $fh, $file) or die "can't read $file [$name]";
    my $text = do { local $/=undef; <$fh> };
    close $fh;

    return $text;
}

1;
