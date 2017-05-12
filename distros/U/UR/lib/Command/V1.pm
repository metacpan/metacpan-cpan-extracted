package Command::V1;

use strict;
use warnings;

use UR;
use Data::Dumper;
use File::Basename;
use Getopt::Long;
use Term::ANSIColor qw();
require Text::Wrap;

our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => ['Command', 'Command::Common'],
    is_abstract => 1,
    attributes_have => [
        is_input            => { is => 'Boolean', is_optional => 1 },
        is_output           => { is => 'Boolean', is_optional => 1 },
        is_param            => { is => 'Boolean', is_optional => 1 },
        shell_args_position => { is => 'Integer', is_optional => 1,
                                 doc => 'when set, this property is a positional argument when run from a shell' },
    ],
    has_optional => [
        debug       => { is => 'Boolean', doc => 'enable debug messages' },
        is_executed => { is => 'Boolean' },
        result      => { is => 'Scalar', is_output => 1 },
        original_command_line => { is => 'String', doc => 'null-byte separated list of command and arguments when run via execute_with_shell_params_and_exit'},
    ],
);

# This is changed with "local" where used in some places
$Text::Wrap::columns = 100;

# Required for color output
eval {
    binmode STDOUT, ":utf8";
    binmode STDERR, ":utf8";
};

sub _init_subclass {
    # Each Command subclass has an automatic wrapper around execute().
    # This ensures it can be called as a class or instance method,
    # and that proper handling occurs around it.
    my $subclass_name = $_[0];
    no strict;
    no warnings;
    if ($subclass_name->can('execute')) {
        # NOTE: manipulating %{ $subclass_name . '::' } directly causes ptkdb to segfault perl
        my $new_symbol = "${subclass_name}::_execute_body";
        my $old_symbol = "${subclass_name}::execute";
        *$new_symbol = *$old_symbol;
        undef *$old_symbol;
    }
    else {
        #print "no execute in $subclass_name\n";
    }

    if($subclass_name->can('shortcut')) {
        my $new_symbol = "${subclass_name}::_shortcut_body";
        my $old_symbol = "${subclass_name}::shortcut";
        *$new_symbol = *$old_symbol;
        undef *$old_symbol;
    }

    return 1;
}

#
# Standard external interface for shell dispatchers
#

# TODO: abstract out all dispatchers for commands into a given API
sub execute_with_shell_params_and_exit {
    # This automatically parses command-line options and "does the right thing":
    my $class = shift;

    if (@_) {
        die
qq|
No params expected for execute_with_shell_params_and_exit().
Usage:

#!/usr/bin/env perl
use My::Command;
My::Command->execute_with_shell_params_and_exit;
|;
    }

    $Command::entry_point_class ||= $class;
    $Command::entry_point_bin ||= File::Basename::basename($0);

    if ($ENV{COMP_CWORD}) {
        require Getopt::Complete;
        my @spec = $class->resolve_option_completion_spec();
        my $options = Getopt::Complete::Options->new(@spec);
        $options->handle_shell_completion;
        die "error: failed to exit after handling shell completion!";
    }

    my @argv = @ARGV;
    @ARGV = ();
    my $exit_code;
    eval {
        $exit_code = $class->_execute_with_shell_params_and_return_exit_code(@argv);
        UR::Context->commit or die "Failed to commit!: " . UR::Context->error_message();
    };
    if ($@) {
        $class->error_message($@);
        UR::Context->rollback or die "Failed to rollback changes after failed commit!!!\n";
        $exit_code = 255 unless ($exit_code);
    }
    exit $exit_code;
}

sub _execute_with_shell_params_and_return_exit_code {
    my $class = shift;
    my @argv = @_;

    my $original_cmdline = join("\0",$0,@argv);

    # make --foo=bar equivalent to --foo bar
    @argv = map { ($_ =~ /^(--\w+?)\=(.*)/) ? ($1,$2) : ($_) } @argv;
    my ($delegate_class, $params,$error_tag_list) = $class->resolve_class_and_params_for_argv(@argv);
    my $rv;
    if ($error_tag_list and @$error_tag_list) {
        $class->error_message("There were problems resolving some command-line parameters:\n\t"
                             . join("\n\t",
                                    map { my($props,$type,$desc) = @$_{'properties','type','desc'};
                                          "Property '" . join("','",@$props) . "' ($type): $desc" }
                                    @$error_tag_list));
    } else {
        $rv = $class->_execute_delegate_class_with_params($delegate_class,$params,$original_cmdline);
    }

    my $exit_code = $delegate_class->exit_code_for_return_value($rv);
    return $exit_code;
}

# this is called by both the shell dispatcher and http dispatcher for now
sub _execute_delegate_class_with_params {
    my ($class, $delegate_class, $params, $original_cmdline) = @_;

    unless ($delegate_class) {
        $class->usage_message($class->help_usage_complete_text);
        return;
    }

    $delegate_class->dump_status_messages(1);
    $delegate_class->dump_warning_messages(1);
    $delegate_class->dump_error_messages(1);
    $delegate_class->dump_usage_messages(1);
    $delegate_class->dump_debug_messages(0);

    if ( $delegate_class->is_sub_command_delegator && !defined($params) ) {
        my $command_name = $delegate_class->command_name;
        $delegate_class->status_message($delegate_class->help_usage_complete_text);
        $delegate_class->error_message("Please specify a valid sub-command for '$command_name'.");
        return;
    }
    if ( $params->{help} ) {
        $delegate_class->usage_message($delegate_class->help_usage_complete_text);
        return 1;
    }

    $params->{'original_command_line'} = $original_cmdline if (defined $original_cmdline);
    my $command_object = $delegate_class->create(%$params);

    unless ($command_object) {
        # The delegate class should have emitted an error message.
        # This is just in case the developer is sloppy, and the user will think the task did not fail.
        print STDERR "Exiting.\n";
        return;
    }

    $command_object->dump_status_messages(1);
    $command_object->dump_warning_messages(1);
    $command_object->dump_error_messages(1);
    $command_object->dump_debug_messages($command_object->debug);
    if ($command_object->debug) {
        UR::ModuleBase->dump_debug_messages($command_object->debug);
    }

    my $rv = $command_object->execute($params);

    if ($command_object->__errors__) {
        $command_object->delete;
    }

    return $rv;
}

#
# Methods to override in concrete subclasses.
#

# Override "execute" or "_execute_body" to implement the body of the command.
# See above for details of internal implementation.

# By default, there are no bare arguments.
sub _bare_shell_argument_names {
    my $self = shift;
    my $meta = $self->__meta__;
    my @ordered_names =
        map { $_->property_name }
        sort { $a->{shell_args_position} <=> $b->{shell_args_position} }
        grep { $_->{shell_args_position} }
        $self->_shell_args_property_meta();
    return @ordered_names;
}

sub help_brief {
    my $self = shift;
    if (my $doc = $self->__meta__->doc) {
        return $doc;
    }
    else {
        my @parents = $self->__meta__->ancestry_class_metas;
        for my $parent (@parents) {
            if (my $doc = $parent->doc) {
                return $doc;
            }
        }
        if ($self->is_sub_command_delegator) {
            return "";
        }
        else {
            return "no description!!!: define 'doc' in $self";
        }
    }
}


sub help_synopsis {
    my $self = shift;
    return '';
}

sub help_detail {
    my $self = shift;
    return "!!! define help_detail() in module " . ref($self) || $self . "!";
}

sub sub_command_category {
    return;
}

sub sub_command_sort_position {
    # override to do something besides alpha sorting by name
    return '9999999999 ' . $_[0]->command_name_brief;
}


#
# Self reflection
#

sub is_abstract {
    # Override when writing an subclass which is also abstract.
    my $self = shift;
    my $class_meta = $self->__meta__;
    return $class_meta->is_abstract;
}

sub is_executable {
    my $self = shift;
    if ($self->can("_execute_body") eq __PACKAGE__->can("_execute_body")) {
        return;
    }
    elsif ($self->is_abstract) {
        return;
    }
    else {
        return 1;
    }
}

sub is_sub_command_delegator {
    my $self = shift;
    if (scalar($self->sub_command_dirs)) {
        return 1;
    }
    else {
        return;
    }
}

sub _time_now {
    # return the current time in context
    # this may not be the real time in selected cases
    shift->__context__->now;
}

sub color_command_name {
    my $text = shift;

    my $colored_text = [];

    my @COLOR_TEMPLATES = ('red', 'bold red', 'magenta', 'bold magenta');
    my @parts = split(/\s+/, $text);
    for(my $i = 0 ; $i < @parts ; $i++ ){
        push @$colored_text, ($i < @COLOR_TEMPLATES) ? Term::ANSIColor::colored($parts[$i], $COLOR_TEMPLATES[$i]) : $parts[$i];
    }

    return join(' ', @$colored_text);
}

sub _base_command_class_and_extension {
    my $self = shift;
    my $class = ref($self) || $self;
    return ($class =~ /^(.*)::([^\:]+)$/);
}

sub _command_name_for_class_word {
    my $self = shift;
    my $s = shift;
    $s =~ s/_/-/g;
    $s =~ s/^([A-Z])/\L$1/; # ignore first capital because that is assumed
    $s =~ s/([A-Z])/-$1/g; # all other capitals prepend a dash
    $s =~ s/([a-zA-Z])([0-9])/$1$2/g; # treat number as begining word
    $s = lc($s);
    return $s;
}

sub command_name {
    my $self = shift;
    my $class = ref($self) || $self;
    my $prepend = '';
    if (defined($Command::entry_point_class) and $class =~ /^($Command::entry_point_class)(::.+|)$/) {
        $prepend = $Command::entry_point_bin;
        $class = $2;
        if ($class =~ s/^:://) {
            $prepend .= ' ';
        }
    }
    my @words = grep { $_ ne 'Command' } split(/::/,$class);
    my $n = join(' ', map { $self->_command_name_for_class_word($_) }  @words);
    return $prepend . $n;
}

sub command_name_brief {
    my $self = shift;
    my $class = ref($self) || $self;
    my @words = grep { $_ ne 'Command' } split(/::/,$class);
    my $n = join(' ', map { $self->_command_name_for_class_word($_) } $words[-1]);
    return $n;
}
#
# Methods to transform shell args into command properties
#

my $_resolved_params_from_get_options = {};
sub _resolved_params_from_get_options {
    return $_resolved_params_from_get_options;
}

sub resolve_option_completion_spec {
    my $class = shift;
    my @completion_spec;

    if ($class->is_sub_command_delegator) {
        my @sub = eval { $class->sub_command_names};
        if ($@) {
            $class->warning_message("Couldn't load class $class: $@\nSkipping $class...");
            return;
        }
        for my $sub (@sub) {
            my $sub_class = $class->class_for_sub_command($sub);
            my $sub_tree = $sub_class->resolve_option_completion_spec() if defined($sub_class);

            # Hack to fix several broken commands, this should be removed once commands are fixed.
            # If the commands were not broken then $sub_tree will always exist.
            # Basically if $sub_tree is undef then we need to remove '>' to not break the OPTS_SPEC
            if ($sub_tree) {
                push @completion_spec, '>' . $sub => $sub_tree;
            }
            else {
                print "WARNING: $sub has sub_class $sub_class of ($class) but could not resolve option completion spec for it.\n".
                      "Setting $sub to non-delegating command, investigate to correct tab completion.\n";
                push @completion_spec, $sub => undef;
            }
        }
        push @completion_spec, "help!" => undef;
    }
    else {
        my $params_hash;
        @completion_spec = $class->_shell_args_getopt_complete_specification;
        no warnings;
        unless (grep { /^help\W/ } @completion_spec) {
            push @completion_spec, "help!" => undef;
        }
    }

    return \@completion_spec
}

sub resolve_class_and_params_for_argv {
    # This is used by execute_with_shell_params_and_exit, but might be used within an application.
    my $self = shift;
    my @argv = @_;

    if ($self->is_sub_command_delegator) {
        if ( $argv[0] and $argv[0] !~ /^\-/
                and my $class_for_sub_command = $self->class_for_sub_command($argv[0]) ) {
            # delegate
            shift @argv;
            return $class_for_sub_command->resolve_class_and_params_for_argv(@argv);
        }

        if (@argv) {
            # this has sub-commands, and is also executable
            # fall through to the execution_logic...
        }
        else {
            #$self->error_message(
            #    'Bad command "' . $sub_command . '"'
            #    , "\ncommands:"
            #    , $self->help_sub_commands
            #);
            return ($self,undef);
        }
    }

    my ($params_hash,@spec) = $self->_shell_args_getopt_specification;
    unless (grep { /^help\W/ } @spec) {
        push @spec, "help!";
    }

    # Thes nasty GetOptions modules insist on working on
    # the real @ARGV, while we like a little more flexibility.
    # Not a problem in Perl. :)  (which is probably why it was never fixed)
    local @ARGV;
    @ARGV = @argv;

    do {
        # GetOptions also likes to emit warnings instead of return a list of errors :(
        my @errors;
        local $SIG{__WARN__} = sub { push @errors, @_ };

        ## Change the pattern to be '--', '-' followed by a non-digit, or '+'.
        ## This s the effect of treating a negative number as a value of an option.
        ## This means that we won't be allowed to have an option named, say, -1.
        ## But since command modules' properties have to be allowable function names,
        ## and "1" is not a valid function name, it's not really a problem
        #Getopt::Long::Configure('prefix_pattern=--|-(?!\D)|\+');
        unless (GetOptions($params_hash,@spec)) {
            Carp::croak( join("\n", @errors) );
        }
    };

    # Q: Is there a standard getopt spec for capturing non-option paramters?
    # Perhaps that's not getting "options" :)
    # A: Yes.  Use '<>'.  But we need to process this anyway, so it won't help us.

    if (my @names = $self->_bare_shell_argument_names) {
        for (my $n=0; $n < @ARGV; $n++) {
            my $name = $names[$n];
            unless ($name) {
                $self->error_message("Unexpected bare arguments: @ARGV[$n..$#ARGV]!");
                return($self, undef);
            }
            my $value = $ARGV[$n];
            my $meta = $self->__meta__->property_meta_for_name($name);
            if ($meta->is_many) {
                if ($n == $#names) {
                    # slurp the rest
                    $params_hash->{$name} = [@ARGV[$n..$#ARGV]];
                    last;
                }
                else {
                    die "has-many property $name is not last in bare_shell_argument_names for $self?!";
                }
            }
            else {
                $params_hash->{$name} = $value;
            }
        }
    } elsif (@ARGV) {
        ## argv but no names
        $self->error_message("Unexpected bare arguments: @ARGV!");
        return($self, undef);
    }

    for my $key (keys %$params_hash) {
        # handle any has-many comma-sep values
        my $value = $params_hash->{$key};
        if (ref($value)) {
            my @new_value;
            for my $v (@$value) {
                my @parts = split(/,\s*/,$v);
                push @new_value, @parts;
            }
            @$value = @new_value;

        } elsif ($value eq q('') or $value eq q("")) {
            # Handle the special values '' and "" to mean undef/NULL
            $params_hash->{$key} = '';
        }

        # turn dashes into underscores
        my $new_key = $key;

        next unless ($new_key =~ tr/-/_/);
        if (exists $params_hash->{$new_key} && exists $params_hash->{$key}) {
            # this corrects a problem where is_many properties badly interact
            # with bare args leaving two entries in the hash like:
            # a-bare-opt => [], a_bare_opt => ['with','vals']
            delete $params_hash->{$key};
            next;
        }
        $params_hash->{$new_key} = delete $params_hash->{$key};
    }

    $_resolved_params_from_get_options = $params_hash;

    return $self, $params_hash;
}

#
# Methods which let the command auto-document itself.
#

sub help_usage_complete_text {
    my $self = shift;

    my $command_name = $self->command_name;
    my $text;

    if (not $self->is_executable) {
        # no execute implemented
        if ($self->is_sub_command_delegator) {
            # show the list of sub-commands
            $text = sprintf(
                "Sub-commands for %s:\n%s",
                Term::ANSIColor::colored($command_name, 'bold'),
                $self->help_sub_commands,
            );
        }
        else {
            # developer error
            my (@sub_command_dirs) = $self->sub_command_dirs;
            if (grep { -d $_ } @sub_command_dirs) {
                $text .= "No execute() implemented in $self, and no sub-commands found!"
            }
            else {
                $text .= "No execute() implemented in $self, and no directory of sub-commands found!"
            }
        }
    }
    else {
        # standard: update this to do the old --help format
        my $synopsis = $self->help_synopsis;
        my $required_args = $self->help_options(is_optional => 0);
        my $optional_args = $self->help_options(is_optional => 1);
        my $sub_commands = $self->help_sub_commands(brief => 1) if $self->is_sub_command_delegator;
        $text = sprintf(
            "\n%s\n%s\n\n%s%s%s%s%s\n",
            Term::ANSIColor::colored('USAGE', 'underline'),
            Text::Wrap::wrap(
                ' ',
                '    ',
                Term::ANSIColor::colored($self->command_name, 'bold'),
                $self->_shell_args_usage_string || '',
            ),
            ( $synopsis
                ? sprintf("%s\n%s\n", Term::ANSIColor::colored("SYNOPSIS", 'underline'), $synopsis)
                : ''
            ),
            ( $required_args
                ? sprintf("%s\n%s\n", Term::ANSIColor::colored("REQUIRED ARGUMENTS", 'underline'), $required_args)
                : ''
            ),
            ( $optional_args
                ? sprintf("%s\n%s\n", Term::ANSIColor::colored("OPTIONAL ARGUMENTS", 'underline'), $optional_args)
                : ''
            ),
            sprintf(
                "%s\n%s\n",
                Term::ANSIColor::colored("DESCRIPTION", 'underline'),
                Text::Wrap::wrap(' ', ' ', $self->help_detail || '')
            ),
            ( $sub_commands
                ? sprintf("%s\n%s\n", Term::ANSIColor::colored("SUB-COMMANDS", 'underline'), $sub_commands)
                : ''
            ),
        );
    }

    return $text;
}

sub doc_sections {
    my $self = shift;
    my @sections;

    my $command_name = $self->command_name;
    my $version = do { no strict; ${ $self->class . '::VERSION' } };
    my $help_brief = $self->help_brief;
    my $datetime = $self->__context__->now;
    my $sub_commands = $self->help_sub_commands(brief => 1) if $self->is_sub_command_delegator;
    my ($date,$time) = split(' ',$datetime);

    push(@sections, UR::Doc::Section->create(
        title => "NAME",
        content => "$command_name" . ($help_brief ? " - $help_brief" : ""),
        format => "pod",
    ));

    push(@sections, UR::Doc::Section->create(
        title => "VERSION",
        content =>  "This document " # separated to trick the version updater
            . "describes $command_name "
            . ($version ? "version $version " : "")
            . "($date at $time)",
        format => "pod",
    ));

    if ($sub_commands) {
        push(@sections, UR::Doc::Section->create(
            title => "SUB-COMMANDS",
            content => $sub_commands,
            format => 'pod',
        ));
    } else {
        my $synopsis = $self->command_name . ' ' . $self->_shell_args_usage_string . "\n\n" . $self->help_synopsis;
        if ($synopsis) {
            push(@sections, UR::Doc::Section->create(
                title => "SYNOPSIS",
                content => $synopsis,
                format => 'pod'
            ));
        }

        my $required_args = $self->help_options(is_optional => 0, format => "pod");
        if ($required_args) {
            push(@sections, UR::Doc::Section->create(
                title => "REQUIRED ARGUMENTS",
                content => "=over\n\n$required_args\n\n=back\n\n",
                format => 'pod'
            ));
        }

        my $optional_args = $self->help_options(is_optional => 1, format => "pod");
        if ($optional_args) {
            push(@sections, UR::Doc::Section->create(
                title => "OPTIONAL ARGUMENTS",
                content => "=over\n\n$optional_args\n\n=back\n\n",
                format => 'pod'
            ));
        }

        push(@sections, UR::Doc::Section->create(
            title => "DESCRIPTION",
            content => join('', map { "  $_\n" } split ("\n",$self->help_detail)),
            format => 'pod',
        ));
    }

    return @sections;
}

sub help_usage_command_pod {
    my $self = shift;

    my $command_name = $self->command_name;
    my $pod;

    if (0) { # (not $self->is_executable)
        # no execute implemented
        if ($self->is_sub_command_delegator) {
            # show the list of sub-commands
            $pod = "Commands:\n" . $self->help_sub_commands;
        }
        else {
            # developer error
            my (@sub_command_dirs) = $self->sub_command_dirs;
            if (grep { -d $_ } @sub_command_dirs) {
                $pod .= "No execute() implemented in $self, and no sub-commands found!"
            }
            else {
                $pod .= "No execute() implemented in $self, and no directory of sub-commands found!"
            }
        }
    }
    else {
        # standard: update this to do the old --help format
        my $synopsis = $self->command_name . ' ' . $self->_shell_args_usage_string . "\n\n" . $self->help_synopsis;
        my $required_args = $self->help_options(is_optional => 0, format => "pod");
        my $optional_args = $self->help_options(is_optional => 1, format => "pod");
        my $sub_commands = $self->help_sub_commands(brief => 1) if $self->is_sub_command_delegator;
        my $help_brief = $self->help_brief;
        my $version = do { no strict; ${ $self->class . '::VERSION' } };

        $pod =
            "\n=pod"
            . "\n\n=head1 NAME"
            .  "\n\n"
            .   $self->command_name
            . ($help_brief ? " - " . $self->help_brief : '')
            . "\n\n";

        if ($version) {
            $pod .=
                "\n\n=head1 VERSION"
                . "\n\n"
                . "This document " # separated to trick the version updater
                . "describes " . $self->command_name . " version " . $version . '.'
                . "\n\n";
        }

        if ($sub_commands) {
            $pod .=
                    (
                        $sub_commands
                        ? "=head1 SUB-COMMANDS\n\n" . $sub_commands . "\n\n"
                        : ''
                    )
        }
        else {
            $pod .=
                    (
                        $synopsis
                        ? "=head1 SYNOPSIS\n\n" . $synopsis . "\n\n"
                        : ''
                    )
                .   (
                        $required_args
                        ? "=head1 REQUIRED ARGUMENTS\n\n=over\n\n" . $required_args . "\n\n=back\n\n"
                        : ''
                    )
                .   (
                        $optional_args
                        ? "=head1 OPTIONAL ARGUMENTS\n\n=over\n\n" . $optional_args . "\n\n=back\n\n"
                        : ''
                    )
                . "=head1 DESCRIPTION:\n\n"
                . join('', map { "  $_\n" } split ("\n",$self->help_detail))
                . "\n";
        }

        $pod .= "\n\n=cut\n\n";

    }
    return "\n$pod";
}

sub help_header {
    my $class = shift;
    return sprintf("%s - %-80s\n",
        $class->command_name
        ,$class->help_brief
    )
}

sub help_options {
    my $self = shift;
    my %params = @_;

    my $format = delete $params{format};
    my @property_meta = $self->_shell_args_property_meta(%params);

    my @data;
    my $max_name_length = 0;
    for my $property_meta (@property_meta) {
        my $param_name = $self->_shell_arg_name_from_property_meta($property_meta);
        if ($property_meta->{shell_args_position}) {
            $param_name = uc($param_name);
        }

        #$param_name = "--$param_name";
        my $doc = $property_meta->doc;
        my $valid_values = $property_meta->valid_values;
        my $example_values = $property_meta->example_values;
        unless ($doc) {
            # Maybe a parent class has documentation for this property
            eval {
                foreach my $ancestor_class_meta ( $property_meta->class_meta->ancestry_class_metas ) {
                    my $ancestor_property_meta = $ancestor_class_meta->property_meta_for_name($property_meta->property_name);
                    if ($ancestor_property_meta and $doc = $ancestor_property_meta->doc) {
                        last;
                    }
                }
            };
        }

        if (!$doc) {
            if (!$valid_values) {
                $doc = "(undocumented)";
            }
            else {
                $doc = '';
            }
        }
        if ($valid_values) {
            $doc .= "\nvalid values:\n";
            for my $v (@$valid_values) {
                $doc .= " " . $v . "\n";
                $max_name_length = length($v)+2 if $max_name_length < length($v)+2;
            }
            chomp $doc;
        }
        if ($example_values && @$example_values) {
            $doc .= "\nexample" . (@$example_values > 1 and 's') . ":\n";
            $doc .= join(', ',
                        map { ref($_) ? Data::Dumper->new([$_])->Terse(1)->Dump() : $_ } @$example_values
                    );
            chomp($doc);
        }
        $max_name_length = length($param_name) if $max_name_length < length($param_name);

        my $param_type = $property_meta->data_type || '';
        if (defined($param_type) and $param_type !~ m/::/) {
            $param_type = ucfirst(lc($param_type));
        }

        my $default_value;
        if (defined($default_value = $property_meta->default_value)
            || defined(my $calculated_default = $property_meta->calculated_default)
        ) {
            unless (defined $default_value) {
                $default_value = $calculated_default->()
            }

            if ($param_type eq 'Boolean') {
                $default_value = $default_value ? "'true'" : "'false' (--no$param_name)";
            } elsif ($property_meta->is_many && ref($default_value) eq 'ARRAY') {
                if (@$default_value) {
                    $default_value = "('" . join("','",@$default_value) . "')";
                } else {
                    $default_value = "()";
                }
            } else {
                $default_value = "'$default_value'";
            }
            $default_value = "\nDefault value $default_value if not specified";
        }

        push @data, [$param_name, $param_type, $doc, $default_value];
        if ($param_type eq 'Boolean') {
            push @data, ['no'.$param_name, $param_type, "Make $param_name 'false'" ];
        }
    }
    my $text = '';
    for my $row (@data) {
        if (defined($format) and $format eq 'pod') {
            $text .= "\n=item " . $row->[0] . ($row->[1]? '  I<' . $row->[1] . '>' : '') . "\n\n" . $row->[2] . "\n". ($row->[3]? $row->[3] . "\n" : '');
        }
        elsif (defined($format) and $format eq 'html') {
            $text .= "\n\t<br>" . $row->[0] . ($row->[1]? ' <em>' . $row->[1] . '</em>' : '') . "<br> " . $row->[2] . ($row->[3]? "<br>" . $row->[3] : '') . "<br>\n";
        }
        else {
            $text .= sprintf(
                "  %s\n%s\n",
                Term::ANSIColor::colored($row->[0], 'bold') . "   " . $row->[1],
                Text::Wrap::wrap(
                    "    ", # 1st line indent,
                    "    ", # all other lines indent,
                    $row->[2],
                    $row->[3] || '',
                ),
            );
        }
    }

    return $text;
}

sub sorted_sub_command_classes {
    no warnings;
    my @c = shift->sub_command_classes;

    my @commands_with_position = map { [ $_->sub_command_sort_position, $_ ] } @c;
    my @sorted = sort { $a->[0] <=> $b->[0]
                         ||
                        $a->[0] cmp $b->[0]
                 }
                 @commands_with_position;
    return map { $_->[1] } @sorted;
}

sub sorted_sub_command_names {
    my $class = shift;
    my @sub_command_classes = $class->sorted_sub_command_classes;
    my @sub_command_names = map { $_->command_name_brief } @sub_command_classes;
    return @sub_command_names;
}

sub sub_commands_table {
    my $class = shift;
    my @sub_command_names = $class->sorted_sub_command_names;

    my $max_length = 0;
    for (@sub_command_names) {
        $max_length = length($_) if ($max_length < length($_));
    }
    $max_length ||= 79;
    my $col_spacer = '_'x$max_length;

    my $n_cols = floor(80/$max_length);
    my $n_rows = ceil(@sub_command_names/$n_cols);
    my @tb_rows;
    for (my $i = 0; $i < @sub_command_names; $i += $n_cols) {
        my $end = $i + $n_cols - 1;
        $end = $#sub_command_names if ($end > $#sub_command_names);
        push @tb_rows, [@sub_command_names[$i..$end]];
    }
    my @col_alignment;
    for (my $i = 0; $i < $n_cols; $i++) {
        push @col_alignment, { sample => "&$col_spacer" };
    }
    my $tb = Text::Table->new(@col_alignment);
    $tb->load(@tb_rows);
    return $tb;
}

sub help_sub_commands {
    my $class = shift;
    my %params = @_;
    my $command_name_method = 'command_name_brief';
    #my $command_name_method = ($params{brief} ? 'command_name_brief' : 'command_name');

    my @sub_command_classes = $class->sorted_sub_command_classes;

    my %categories;
    my @categories;
    for my $sub_command_class (@sub_command_classes) {
        my $category = $sub_command_class->sub_command_category;
        $category = '' if not defined $category;
        next if $sub_command_class->_is_hidden_in_docs();
        my $sub_commands_within_category = $categories{$category};
        unless ($sub_commands_within_category) {
            if (defined $category and length $category) {
                push @categories, $category;
            }
            else {
                unshift @categories,'';
            }
            $sub_commands_within_category = $categories{$category} = [];
        }
        push @$sub_commands_within_category,$sub_command_class;
    }

    no warnings;
    local  $Text::Wrap::columns = 60;

    my $full_text = '';
    my @full_data;
    for my $category (@categories) {
        my $sub_commands_within_this_category = $categories{$category};
        my @data = map {
                my @rows = split("\n",Text::Wrap::wrap('', ' ', $_->help_brief));
                chomp @rows;
                (
                    [
                        $_->$command_name_method,
                        $_->_shell_args_usage_string_abbreviated,
                        $rows[0],
                    ],
                    map {
                        [
                            '',
                            ' ',
                            $rows[$_],
                        ]
                    } (1..$#rows)
                );
            }
            @$sub_commands_within_this_category;

        if ($category) {
            # add a space between categories
            push @full_data, ['','',''] if @full_data;

            if ($category =~ /\D/) {
                # non-numeric categories show their category as a header
                $category .= ':' if $category =~ /\S/;
                push @full_data,
                    [
                        Term::ANSIColor::colored(uc($category), 'blue'),
                        '',
                        ''
                    ];

            }
            else {
                # numeric categories just sort
            }
        }

        push @full_data, @data;
    }

    my @max_width_found = (0,0,0);
    for (@full_data) {
        for my $c (0..2) {
            $max_width_found[$c] = length($_->[$c]) if $max_width_found[$c] < length($_->[$c]);
        }
    }

    my @colors = (qw/ red   bold /);
    my $text = '';
    for my $row (@full_data) {
        for my $c (0..2) {
            $text .= ' ';
            $text .= Term::ANSIColor::colored($row->[$c], $colors[$c]),
            $text .= ' ';
            $text .= ' ' x ($max_width_found[$c]-length($row->[$c]));
        }
        $text .= "\n";
    }
    return $text;
}

sub _is_hidden_in_docs { return; }

#
# Methods which transform command properties into shell args (getopt)
#

sub _shell_args_property_meta {
    my $self = shift;
    my $class_meta = $self->__meta__;

    # Find which property metas match the rules.  We have to do it this way
    # because just calling 'get_all_property_metas()' will product multiple matches
    # if a property is overridden in a child class
    my $rule = UR::Object::Property->define_boolexpr(@_);
    my %seen;
    my (@positional,@required,@optional);
    foreach my $property_meta ( $class_meta->get_all_property_metas() ) {
        my $property_name = $property_meta->property_name;

        next if $seen{$property_name}++;
        next unless $rule->evaluate($property_meta);

        next if $property_name eq 'id';
        next if $property_name eq 'result';
        next if $property_name eq 'is_executed';
        next if $property_name eq 'original_command_line';
        next if $property_name =~ /^_/;
        next if defined($property_meta->data_type) and $property_meta->data_type =~ /::/;
        next if not $property_meta->is_mutable;
        next if $property_meta->is_delegated;
        next if $property_meta->is_calculated;
#        next if $property_meta->{is_output}; # TODO: This was breaking the G::M::T::Annotate::TranscriptVariants annotator. This should probably still be here but temporarily roll back
        next if $property_meta->is_transient;
        next if $property_meta->is_constant;
        if ($property_meta->{shell_args_position}) {
            push @positional, $property_meta;
        }
        elsif ($property_meta->is_optional) {
            push @optional, $property_meta;
        }
        else {
            push @required, $property_meta;
        }
    }

    my @result;
    @required   = map { [ $_->property_name, $_ ] } @required;
    @optional   = map { [ $_->property_name, $_ ] } @optional;
    @positional = map { [ $_->{shell_args_position}, $_ ] } @positional;

    @result = (
        (sort { $a->[0] cmp $b->[0] } @required),
        (sort { $a->[0] cmp $b->[0] } @optional),
        (sort { $a->[0] <=> $b->[0] } @positional),
    );

    return map { $_->[1] } @result;
}

sub _shell_arg_name_from_property_meta {
    my ($self, $property_meta,$singularize) = @_;
    my $property_name = ($singularize ? $property_meta->singular_name : $property_meta->property_name);
    my $param_name = $property_name;
    $param_name =~ s/_/-/g;
    return $param_name;
}

sub _shell_arg_getopt_qualifier_from_property_meta {
    my ($self, $property_meta) = @_;

    my $many = ($property_meta->is_many ? '@' : '');
    if (defined($property_meta->data_type) and $property_meta->data_type =~ /Boolean/) {
        return '!' . $many;
    }
    #elsif ($property_meta->is_optional) {
    #    return ':s' . $many;
    #}
    else {
        return '=s' . $many;
    }
}

sub _shell_arg_usage_string_from_property_meta {
    my ($self, $property_meta) = @_;
    my $string = $self->_shell_arg_name_from_property_meta($property_meta);
    if ($property_meta->{shell_args_position}) {
        $string = uc($string);
    }

    if ($property_meta->{shell_args_position}) {
        if ($property_meta->is_optional) {
            $string = "[$string]";
        }
    }
    else {
        $string = "--$string";
        if (defined($property_meta->data_type) and $property_meta->data_type =~ /Boolean/) {
            $string = "[$string]";
        }
        else {
            if ($property_meta->is_many) {
                $string .= "=?[,?]";
            }
            else {
                $string .= '=?';
            }
            if ($property_meta->is_optional) {
                $string = "[$string]";
            }
        }
    }
    return $string;
}

sub _shell_arg_getopt_specification_from_property_meta {
    my ($self,$property_meta) = @_;
    my $arg_name = $self->_shell_arg_name_from_property_meta($property_meta);
    return (
        $arg_name .  $self->_shell_arg_getopt_qualifier_from_property_meta($property_meta),
        ($property_meta->is_many ? ($arg_name => []) : ())
    );
}


sub _shell_arg_getopt_complete_specification_from_property_meta {
    my ($self,$property_meta) = @_;
    my $arg_name = $self->_shell_arg_name_from_property_meta($property_meta);
    my $completions = $property_meta->valid_values;
    if ($completions) {
        if (ref($completions) eq 'ARRAY') {
            $completions = [ @$completions ];
        }
    }
    else {
        my $type = $property_meta->data_type;
        my @complete_as_files = (
            'File','FilePath','Filesystem','FileSystem','FilesystemPath','FileSystemPath',
            'Text','String',
        );
        my @complete_as_directories = (
            'Directory','DirectoryPath','Dir','DirPath',
        );
        if (!defined($type)) {
            $completions = 'files';
        }
        else {
            for my $pattern (@complete_as_files) {
                if (!$type || $type eq $pattern) {
                    $completions = 'files';
                    last;
                }
            }
            for my $pattern (@complete_as_directories) {
                if ( $type && $type eq $pattern) {
                    $completions = 'directories';
                    last;
                }
            }
        }
    }
    return (
        $arg_name .  $self->_shell_arg_getopt_qualifier_from_property_meta($property_meta),
        $completions,
#        ($property_meta->is_many ? ($arg_name => []) : ())
    );
}

sub _shell_args_getopt_specification {
    my $self = shift;
    my @getopt;
    my @params;
    for my $meta ($self->_shell_args_property_meta) {
        my ($spec, @params_addition) = $self->_shell_arg_getopt_specification_from_property_meta($meta);
        push @getopt,$spec;
        push @params, @params_addition;
    }
    @getopt = sort @getopt;
    return { @params}, @getopt;
}

sub _shell_args_getopt_complete_specification {
    my $self = shift;
    my @getopt;
    for my $meta ($self->_shell_args_property_meta) {
        my ($spec, $completions) = $self->_shell_arg_getopt_complete_specification_from_property_meta($meta);
        push @getopt, $spec, $completions;
    }
    return @getopt;
}

sub _shell_args_usage_string {
    my $self = shift;
    if ($self->is_executable) {
        return join(
            " ",
            map {
                $self->_shell_arg_usage_string_from_property_meta($_)
            } $self->_shell_args_property_meta()

        );
    }
    elsif ($self->is_sub_command_delegator) {
        my @names = $self->sub_command_names;
        return "[" . join("|",@names) . "] ..."
    }
    else {
        return "(no execute or sub commands implemented)"
    }
    return "";
}

sub _shell_args_usage_string_abbreviated {
    my $self = shift;
    if ($self->is_sub_command_delegator) {
        return "...";
    }
    else {
        my $detailed = $self->_shell_args_usage_string;
        if (length($detailed) <= 20) {
            return $detailed;
        }
        else {
            return substr($detailed,0,17) . '...';
        }
    }
}

#
# The following methods build allow a command to determine its
# sub-commands, if there are any.
#

# This is for cases in which the Foo::Bar command delegates to
# Foo::Bar::Baz, Foo::Bar::Buz or Foo::Bar::Doh, depending on its paramters.

sub sub_command_dirs {
    my $class = shift;
    my $module = ref($class) || $class;
    $module =~ s/::/\//g;

    # multiple dirs is not working quite yet
    #my @paths = grep { -d $_ } map { "$_/$module"  } @INC;
    #return @paths;

    $module .= '.pm';
    my $path = $INC{$module};
    unless ($path) {
        return;
    }
    $path =~ s/.pm$//;
    unless (-d $path) {
        return;
    }
    return $path;
}

sub sub_command_classes {
    my $class = shift;
    my @paths = $class->sub_command_dirs;
    return unless @paths;
    @paths =
        grep { s/\.pm$// }
        map { glob("$_/*") }
        grep { -d $_ }
        grep { defined($_) and length($_) }
        @paths;
    return unless @paths;
    my @classes =
        grep {
            ($_->is_sub_command_delegator or !$_->__meta__->is_abstract)
        }
        grep { $_ and $_->isa('Command') }
        map { $class->class_for_sub_command($_) }
        map { s/_/-/g; $_ }
        map { basename($_) }
        @paths;
    return @classes;
}

sub sub_command_names {
    my $class = shift;
    my @sub_command_classes = $class->sub_command_classes;
    my @sub_command_names = map { $_->command_name_brief } @sub_command_classes;
    return @sub_command_names;
}

sub class_for_sub_command {
    my $self = shift;
    my $class = ref($self) || $self;
    my $sub_command = shift;

    return if $sub_command =~ /^\-/;

    my $sub_class = join("", map { ucfirst($_) } split(/-/, $sub_command));
    $sub_class = $class . "::" . $sub_class;

    my $meta = UR::Object::Type->get($sub_class); # allow in memory classes
    unless ( $meta ) {
        eval "use $sub_class;";
        if ($@) {
            if ($@ =~ /^Can't locate .*\.pm in \@INC/) {
                #die "Failed to find $sub_class! $class_for_sub_command.pm!\n$@";
                return;
            }
            else {
                my @msg = split("\n",$@);
                pop @msg;
                pop @msg;
                $self->error_message("$sub_class failed to compile!:\n@msg\n\n");
                return;
            }
        }
    }
    elsif (my $isa = $sub_class->isa("Command")) {
        if (ref($isa)) {
            # dumb modules (Test::Class) mess with the standard isa() API
            if ($sub_class->SUPER::isa("Command")) {
                return $sub_class;
            }
            else {
                return;
            }
        }
        return $sub_class;
    }
    else {
        return;
    }
}

# Run the given command-line with stdout and stderr redirected to /dev/null
sub system_inhibit_std_out_err {
    my($self,$cmdline) = @_;

    open my $oldout, ">&STDOUT"     or die "Can't dup STDOUT: $!";
    open my $olderr, ">&", \*STDERR or die "Can't dup STDERR: $!";

    open(STDOUT,'>/dev/null');
    open(STDERR,'>/dev/null');

    my $ec = system ( $cmdline );

    open STDOUT, ">&", $oldout or die "Can't dup \$oldout: $!";
    open STDERR, ">&", $olderr or die "Can't dup \$olderr: $!";

    return $ec;
}

sub parent_command_class {
    my $class = shift;
    $class = ref($class) if ref($class);
    my @components = split("::", $class);
    return if @components == 1;
    my $parent = join("::", @components[0..$#components-1]);
    return $parent if $parent->can("command_name");
    return;
}


1;

__END__

=pod

=head1 NAME

Command - base class for modules implementing the command pattern

=head1 SYNOPSIS

  use TopLevelNamespace;

  class TopLevelNamespace::SomeObj::Command {
    is => 'Command',
    has => [
        someobj => { is => 'TopLevelNamespace::SomeObj', id_by => 'some_obj_id' },
        verbose => { is => 'Boolean', is_optional => 1 },
    ],
  };

  sub execute {
      my $self = shift;
      if ($self->verbose) {
          print "Working on id ",$self->some_obj_id,"\n";
      }
      my $result = $someobj->do_something();
      if ($self->verbose) {
          print "Result was $result\n";
      }
      return $result;
  }

  sub help_brief {
      return 'Call do_something on a SomeObj instance';
  }
  sub help_synopsis {
      return 'cmd --some_obj_id 123 --verbose';
  }
  sub help_detail {
      return 'This command performs a FooBarBaz transform on a SomObj object instance by calling its do_something method.';
  }

  # Another part of the code

  my $cmd = TopLevelNamespace::SomeObj::Command->create(some_obj_id => $some_obj->id);
  $cmd->execute();

=head1 DESCRIPTION

The Command module is a base class for creating other command modules
implementing the Command Pattern.  These modules can be easily reused in
applications or loaded and executed dynamicaly in a command-line program.

Each Command subclass represents a reusable work unit.  The bulk of the
module's code will likely be in the execute() method.  execute() will
usually take only a single argument, an instance of the Command subclass.

=head1 Command-line use

Creating a top-level Command module called, say TopLevelNamespace::Command,
and a script called tln_cmd that looks like:

  #!/usr/bin/perl
  use TopLevelNamespace;
  TopLevelNamespace::Command->execute_with_shell_params_and_exit();

gives you an instant command-line tool as an interface to the hierarchy of
command modules at TopLevelNamespace::Command.

For example:

  > tln_cmd foo bar --baz 1 --qux

will create an instance of TopLevelNamespace::Command::Foo::Bar (if that
class exists) with params baz => 1 and qux => 1, assumming qux is a boolean
property, call execute() on it, and translate the return value from execute()
into the appropriate notion of a shell return value, meaning that if
execute() returns true in the Perl sense, then the script returns 0 - true in
the shell sense.

The infrastructure takes care of turning the command line parameters into
parameters for create().  Params designated as is_optional are, of course,
optional and non-optional parameters that are missing will generate an error.

--help is an implicit param applicable to all Command modules.  It generates
some hopefully useful text based on the documentation in the class definition
(the 'doc' attributes you can attach to a class and properties), and the
strings returned by help_detail(), help_brief() and help_synopsis().

=head1 TODO

This documentation needs to be fleshed out more.  There's a lot of special
things you can do with Command modules that isn't mentioned here yet.

=cut
