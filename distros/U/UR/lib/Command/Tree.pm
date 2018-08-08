package Command::Tree;

use strict;
use warnings;
use UR;
use File::Basename qw/basename/;

our $VERSION = "0.47"; # UR $VERSION;

class Command::Tree {
    is => 'Command::V2',
    is_abstract => 1,
    doc => 'base class for commands which delegate to sub-commands',
};

sub resolve_class_and_params_for_argv {
    # This is used by execute_with_shell_params_and_exit, but might be used within an application.
    my $self = shift;
    my @argv = @_;

    if ( $argv[0] and $argv[0] !~ /^\-/
            and my $class_for_sub_command = $self->class_for_sub_command($argv[0]) ) {
        # delegate
        shift @argv;
        return $class_for_sub_command->resolve_class_and_params_for_argv(@argv);
    }
    elsif ( @argv == 1 and $argv[0] =~ /^(\-)?\-h(elp)?$/ ) { # HELP ME!
        return ($self, { help => 1 });
    }
    else {
        # error
        return ($self,undef);
    }
}

sub resolve_option_completion_spec {
    my $class = shift;
    my @completion_spec;

    my @sub = eval { $class->sub_command_names };
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
            if (defined $sub_class) {
                print "WARNING: $sub has sub_class $sub_class of ($class) but could not resolve option completion spec for it.\n".
                        "Setting $sub to non-delegating command, investigate to correct tab completion.\n";
            } else {
                print "WARNING: $sub has no sub_class so could not resolve option completion spec for it.\n".
                        "Setting $sub to non-delegating command, investigate to correct tab completion.\n";
            }
            push @completion_spec, $sub => undef;
        }
    }
    push @completion_spec, "help!" => undef;

    return \@completion_spec
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
        return "";
    }
}

sub doc_help {
    my $self = shift;

    my $command_name = $self->command_name;
    my $text;

    # show the list of sub-commands
    $text = sprintf(
        "Sub-commands for %s:\n%s",
        Term::ANSIColor::colored($command_name, 'bold'),
        $self->help_sub_commands,
    );

    return $text;
}


sub doc_manual {
    my $self = shift;
    my $pod = $self->_doc_name_version;

    my $manual = $self->_doc_manual_body;
    my $help = $self->help_detail;
    if ($manual or $help) {
        $pod .= "=head1 DESCRIPTION:\n\n";

        my $txt = $manual || $help;
        if ($txt =~ /^\=/) {
            # pure POD
            $pod .= $manual;
        }
        else {
            $txt =~ s/\n/\n\n/g;
            $pod .= $txt;
            #$pod .= join('', map { "  $_\n" } split ("\n",$txt)) . "\n";
        }
    }


    my $sub_commands = $self->help_sub_commands(brief => 1);
    $pod .= "=head1 SUB-COMMANDS\n\n" . $sub_commands . "\n\n";

    $pod .= $self->_doc_footer();
    $pod .= "\n\n=cut\n\n";
    return "\n$pod";
}

sub sorted_sub_command_classes {
    no warnings;
    my @c = map { [ $_->sub_command_sort_position, $_ ] } shift->sub_command_classes;
    return map { $_->[1] }
           sort {
            ($a->[0] <=> $b->[0])
            ||
            ($a->[0] cmp $b->[0])
        }
        @c;
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

sub _categorize_sub_commands {
    my $class = shift;

    my @sub_command_classes = $class->sorted_sub_command_classes;
    my %categories;
    my @order;
    for my $sub_command_class (@sub_command_classes) {
        next if $sub_command_class->_is_hidden_in_docs();
        my $category = $sub_command_class->sub_command_category || '';
        unless (exists $categories{$category}) {
            if ($category) {
                push(@order, $category)
            } else {
                unshift(@order, '');
            }
            $categories{$category} = [];
        }
        push(@{$categories{$category}}, $sub_command_class);
    }

    return (\@order, \%categories);
}

sub help_sub_commands {
    my ($self, %params) = @_;
    my ($order, $categories) = $self->_categorize_sub_commands(@_);
    my $command_name_method = 'command_name_brief';

    no warnings;
    local $Text::Wrap::columns = 60;

    my @full_data;
    for my $category (@$order) {
        my $sub_commands_within_this_category = $categories->{$category};
        my @data = map {
                my @rows = split("\n",Text::Wrap::wrap('', ' ', $_->help_brief));
                chomp @rows;
                (
                    [
                        $_->$command_name_method,
                        ($_->isa('Command::Tree') ? '...' : ''), #$_->_shell_args_usage_string_abbreviated,
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
            $text .= $colors[$c] ? Term::ANSIColor::colored($row->[$c], $colors[$c]) : $row->[$c];
            $text .= ' ';
            $text .= ' ' x ($max_width_found[$c]-length($row->[$c]));
        }
        $text .= "\n";
    }
    return $text;
}

sub doc_sub_commands {
    my $self = shift;
    my ($order, $categories) = $self->_categorize_sub_commands(@_);
    my $text = "";
    my $indent_lvl = 4;
    for my $category (@$order) {
        my $category_name = ($category ? uc $category : "GENERAL");
        $text .= "=head2 $category_name\n\n";
        for my $cmd (@{$categories->{$category}}) {
            $text .= "=over $indent_lvl\n\n";
            my $name = $cmd->command_name_brief;
            my $link = $cmd->command_name;
            $link =~ s/ /-/g;
            my $description = $cmd->help_brief;
            $text .= "=item B<L<$name|$link>>\n\n=over 2\n\n=item $description\n\n=back\n\n";
            $text .= "=back\n\nE<10>\n\n";
        }
    }

    return $text;
}

#
# The following methods build allow a command to determine its
# sub-commands, if there are any.
#

# This is for cases in which the Foo::Bar command delegates to
# Foo::Bar::Baz, Foo::Bar::Buz or Foo::Bar::Doh, depending on its paramters.

sub sub_command_dirs {
    my $class = shift;
    my $subdir = ref($class) || $class;
    $subdir =~ s|::|\/|g;
    my @dirs = grep { -d $_ } map { $_ . '/' . $subdir  } @INC;
    return @dirs;
}

sub sub_command_classes {
    my $class = shift;
    my $mapping = $class->_build_sub_command_mapping;
    return values %$mapping;
}

# For compatability with Command::V1-based callers
sub is_sub_command_delegator {
    return scalar(shift->sub_command_classes);
}

sub command_tree_source_classes {
    # override in subclass if you want different sources
    my $class = shift;
    return $class;
}

sub _build_sub_command_mapping {
    my $class = shift;
    $class = ref($class) || $class;

    my @source_classes = $class->command_tree_source_classes;

    my $mapping;
    do {
        no strict 'refs';
        $mapping = ${ $class . '::SUB_COMMAND_MAPPING'};
        if (ref($mapping) eq 'HASH') {
            return $mapping;
        }
    };

    for my $source_class (@source_classes) {
        # check if this class is valid
        eval{ $source_class->class; };
        if ( $@ ) {
            warn $@;
        }

        # for My::Foo::Command::* commands and sub-trees
        my $subdir = $source_class;
        $subdir =~ s|::|\/|g;

        # for My::Foo::*::Command sub-trees
        my $source_class_above = $source_class;
        $source_class_above =~ s/::Command//;
        my $subdir2 = $source_class_above;
        $subdir2 =~ s|::|/|g;

        # check everywhere
        for my $lib (@INC) {
            my $subdir_full_path = $lib . '/' . $subdir;

            # find My::Foo::Command::*
            if (-d $subdir_full_path) {
                my @files = glob("\Q${subdir_full_path}/*");
                for my $file (@files) {
                    my $basename = basename($file);
                    $basename =~ s/.pm$// or next;
                    my $sub_command_class_name = $source_class . '::' . $basename;
                    my $sub_command_class_meta = UR::Object::Type->get($sub_command_class_name);
                    unless ($sub_command_class_meta) {
                        local $SIG{__DIE__};
                        local $SIG{__WARN__};
                        # until _use_safe is refactored to be permissive, use directly...
                        print ">> $sub_command_class_name\n";
                        eval "use $sub_command_class_name";
                    }
                    $sub_command_class_meta = UR::Object::Type->get($sub_command_class_name);
                    next unless $sub_command_class_name->isa("Command");
                    next if $sub_command_class_meta->is_abstract;
                    next if $sub_command_class_name eq $class;
                    my $name = $source_class->_command_name_for_class_word($basename);
                    $mapping->{$name} = $sub_command_class_name;
                }
            }

            # find My::Foo::*::Command
            $subdir_full_path = $lib . '/' . $subdir2;
            my $pattern = $subdir_full_path . '/*/Command.pm';
            my @paths = glob("\Q$pattern\E");
            for my $file (@paths) {
                next unless defined $file;
                next unless length $file;
                next unless -f $file;
                my $last_word = File::Basename::basename($file);
                $last_word =~ s/.pm$// or next;
                my $dir = File::Basename::dirname($file);
                my $second_to_last_word = File::Basename::basename($dir);
                my $sub_command_class_name = $source_class_above . '::' . $second_to_last_word . '::' . $last_word;
                next unless $sub_command_class_name->isa('Command');
                next if $sub_command_class_name->__meta__->is_abstract;
                next if $sub_command_class_name eq $class;
                my $basename = $second_to_last_word;
                $basename =~ s/.pm$//;
                my $name = $source_class->_command_name_for_class_word($basename);
                $mapping->{$name} = $sub_command_class_name;
            }
        }
    }
    return $mapping;
}

sub sub_command_names {
    my $class = shift;
    my $mapping = $class->_build_sub_command_mapping;
    return keys %$mapping;
}



sub _try_command_class_named {
    my $self = shift;

    my $sub_class = join('::', @_);

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


sub class_for_sub_command {
    my $self = shift;
    my $class = ref($self) || $self;
    my $sub_command = shift;

    return if $sub_command =~ /^\-/;  # If it starts with a "-", then it's a command-line option

    # First attempt is to convert $sub_command into a camel-case module name
    # and just try loading it

    my $name_for_sub_command = join("", map { ucfirst($_) } split(/-/, $sub_command));
    my @class_name_parts = (split(/::/,$class), $name_for_sub_command);
    my $sub_command_class = $self->_try_command_class_named(@class_name_parts);
    return $sub_command_class if $sub_command_class;

    # Remove "Command" if it's embedded in the middle and try inserting it in other places, starting at the end
    @class_name_parts = ( ( map { $_ eq 'Command' ? () : $_ } @class_name_parts) , 'Command');
    for(my $i = $#class_name_parts; $i > 0; $i--) {
        $sub_command_class = $self->_try_command_class_named(@class_name_parts);
        return $sub_command_class if $sub_command_class;
        $class_name_parts[$i] = $class_name_parts[$i-1];
        $class_name_parts[$i-1] = 'Command';
    }

    # Didn't find it yet.  Try exhaustively loading all the command modules under $class
    my $mapping = $class->_build_sub_command_mapping;
    if (my $sub_command_class = $mapping->{$sub_command}) {
        return $sub_command_class;
    } else {
        return;
    }
}

my $depth = 0;
sub __extend_namespace__ {
    my ($self,$ext) = @_;

    my $meta = $self->SUPER::__extend_namespace__($ext);
    return $meta if $meta;

    $depth++;
    if ($depth>1) {
        $depth--;
        return;
    }

    my $class = Command::Tree::class_for_sub_command((ref $self || $self), $self->_command_name_for_class_word($ext));
    return $class->__meta__ if $class;
    return;
}

1;

__END__

=pod

=head1 NAME

Command::Tree -base class for commands which delegate to a list of sub-commands

=head1 DESCRIPTION

# in Foo.pm
class Foo { is => 'Command::Tree' };

# in Foo/Cmd1.pm
class Foo::Cmd1 { is => 'Command' };

# in Foo/Cmd2.pm
class Foo::Cmd2 { is => 'Command' };

# in the shell
$ foo
cmd1
cmd2
$ foo cmd1
$ foo cmd2

=cut

