package UR::Namespace::Command::Update::Pod;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;
use IO::File;

class UR::Namespace::Command::Update::Pod {
    is => 'Command::V2',
    has => [
        executable_name => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'the name of the executable to document'
        },
        class_name => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'the command class which maps to the executable'
        },
        targets => {
            is => 'Text',
            shell_args_position => 3,
            is_many => 1,
            doc => 'specific classes to document (documents all unless specified)',
        },
        input_path => {
            is => 'Path',
            is_optional => 1,
            doc => 'optional location of the modules to document',
        },
        output_path => {
            is => 'Text',
            is_optional => 1,
            doc => 'optional location to output .pod files',
        },        
    ],
    doc => "generate man-page-like POD for a commands"
};

sub help_synopsis {
    return <<"EOS"
ur update pod -i ./lib -o ./pod ur UR::Namespace::Command
EOS
}

sub help_detail {
    return join("\n", 
        'This tool generates POD documentation for each all of the commands in a tree for a given executable.',
        'This command must be run from within the namespace directory.');
}

sub execute {
    my $self = shift;
    #$DB::single = 1;

    local $ENV{ANSI_COLORS_DISABLED}    = 1;
    my $entry_point_bin     = $self->executable_name;
    my $entry_point_class   = $self->class_name;

    my @targets = $self->targets;
    unless (@targets) {
        @targets = ($entry_point_class);
    }

    local @INC = @INC;
    if ($self->input_path) {
        unshift @INC, $self->input_path;
        $self->status_message("using modules at " . $self->input_path);
    }

    my $errors = 0;
    for my $target (@targets) {
        eval "use $target";
        if ($@) {
            $self->error_message("Failed to use $target: $@");
            $errors++;
        }
    }
    return if $errors;

    my @commands = map( $self->get_all_subcommands($_), @targets);
    push @commands, @targets;

    if ($self->output_path) {
        unless (-d $self->output_path) {
            if (-e $self->output_path) {
                $self->status_message("output path is not a directory!: " . $self->output_path);
            }
            else {
                mkdir $self->output_path;
                if (-d $self->output_path) {
                    $self->status_message("using output directory " . $self->output_path);
                }
                else {
                    $self->status_message("error creating directory: $! for " . $self->output_path);
                }
            }
        }
    }

    local $Command::V1::entry_point_bin = $entry_point_bin;
    local $Command::V2::entry_point_bin = $entry_point_bin;
    local $Command::V1::entry_point_class = $entry_point_class;
    local $Command::V2::entry_point_class = $entry_point_class;

    for my $command (@commands) {
        my $pod;
        eval {
            $pod = $command->help_usage_command_pod();
        };

        if($@) {
            $self->warning_message('Could not generate POD for ' . $command . '. ' . $@);
            next;
        }

        unless($pod) {
            $self->warning_message('No POD generated for ' . $command);
            next;
        }

        my $pod_path;
        if (defined $self->output_path) {
          my $filename = $command->command_name . '.pod';
          $filename =~ s/ /-/g;
          my $output_path = $self->output_path;
          $output_path =~ s|/+$||m;          
          $pod_path = join('/', $output_path, $filename);
        } else {
          $pod_path = $command->__meta__->module_path;
          $pod_path =~ s/.pm/.pod/;
        }

        $self->status_message("Writing $pod_path");

        my $fh;
        $fh = IO::File->new('>' . $pod_path) || die "Cannot create file at " . $pod_path . "\n";
        print $fh $pod;
        close($fh);
    }

    return 1;
}

sub get_all_subcommands {
    my $self = shift;
    my $command = shift;
    my $src = "use $command";
    eval $src;

    if ($@) {
        $self->error_message("Failed to load class $command: $@");
    }
    else {
        my $module_name = $command;
        $module_name =~ s|::|/|g;
        $module_name .= '.pm';
        $self->status_message("Loaded $command from $module_name at $INC{$module_name}\n");
    }

    my @subcommands;
    eval {
        if ($command->can('sub_command_classes')) {
            @subcommands = $command->sub_command_classes;
        }
    };

    if($@) {
        $self->warning_message("Error getting subclasses for module $command: " . $@);
    }

    return unless @subcommands and $subcommands[0]; #Sometimes sub_command_classes returns 0 instead of the empty list

    return map($self->get_all_subcommands($_), @subcommands), @subcommands;
}

1;
