package Command::V2;  # additional methods to dispatch from a command-line
use strict;
use warnings;

sub sorted_sub_command_classes {
    no warnings;

    my @c = shift->sub_command_classes;
    my @commands_with_position = map { [ $_->sub_command_sort_position, $_ ] } @c;

    return map { $_->[1] }
           sort { ($a->[0] <=> $b->[0])
                    ||
                  ($a->[0] cmp $b->[0])
                }
           @commands_with_position;
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
    #$DB::single = 1;        
    return $text;
}

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

sub _build_sub_command_mapping {
    my $class = shift;
    $class = ref($class) || $class;
    
    my $mapping;
    do {
        no strict 'refs';
        $mapping = ${ $class . '::SUB_COMMAND_MAPPING'};
    };
    
    unless (defined $mapping) {
        my $subdir = $class; 
        $subdir =~ s|::|\/|g;

        for my $lib (@INC) {
            my $subdir_full_path = $lib . '/' . $subdir;
            next unless -d $subdir_full_path;
            my @files = glob("\Q${subdir_full_path}\E/*");
            next unless @files;
            for my $file (@files) {
                my $basename = basename($file);
                $basename =~ s/.pm$//;
                my $sub_command_class_name = $class . '::' . $basename;
                my $sub_command_class_meta = UR::Object::Type->get($sub_command_class_name);
                unless ($sub_command_class_meta) {
                    local $SIG{__DIE__};
                    local $SIG{__WARN__};
                    eval "use $sub_command_class_name";
                }
                $sub_command_class_meta = UR::Object::Type->get($sub_command_class_name);
                next unless $sub_command_class_name->isa("Command");
                next if $sub_command_class_meta->is_abstract;
                my $name = $class->_command_name_for_class_word($basename); 
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

sub class_for_sub_command
{
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


1;


1;

