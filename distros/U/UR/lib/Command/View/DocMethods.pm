package Command::V2;  # additional methods to produce documentation, TODO: turn into a real view
use strict;
use warnings;

use Term::ANSIColor qw();
use Pod::Simple::Text;
require Text::Wrap;

# This is changed with "local" where used in some places
$Text::Wrap::columns = 100;

# Required for color output
eval {
    binmode STDOUT, ":utf8";
    binmode STDERR, ":utf8";
};

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
        return "no description!!!: define 'doc' in the class definition for " 
            . $self->class;
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

# LEGACY: poorly named
sub help_usage_command_pod {
    return shift->doc_manual(@_);
}

# LEGACY: poorly named
sub help_usage_complete_text {
    shift->doc_help(@_)
}

sub doc_help {
    my $self = shift;

    my $command_name = $self->command_name;
    my $text;

    my $extra_help = '';
    my @extra_help = $self->_additional_help_sections;
    while (@extra_help) {
        my $title = shift @extra_help || '';
        my $content = shift @extra_help || '';
        $extra_help .= sprintf(
            "%s\n\n%s\n",
            Term::ANSIColor::colored($title, 'underline'),
            _pod2txt($content)
        ),
    }

    # standard: update this to do the old --help format
    my $synopsis = $self->help_synopsis;
    my $required_inputs = $self->help_options(is_optional => 0, is_input => 1);
    my $required_outputs = $self->help_options(is_optional => 0, is_output => 1);
    my $required_params = $self->help_options(is_optional => 0, is_param => 1);
    my $optional_inputs = $self->help_options(is_optional => 1, is_input => 1);
    my $optional_outputs = $self->help_options(is_optional => 1, is_output => 1);
    my $optional_params = $self->help_options(is_optional => 1, is_param => 1);
    my @parts;
    
    push @parts, Term::ANSIColor::colored('USAGE', 'underline');
    push @parts, 
        Text::Wrap::wrap(
            ' ', 
            '    ', 
            Term::ANSIColor::colored($self->command_name, 'bold'),
            $self->_shell_args_usage_string || '',
        );

    push @parts, 
        ( $synopsis 
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("SYNOPSIS", 'underline'), $synopsis)
            : ''
        );
    push @parts, 
        ( $required_inputs
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("REQUIRED INPUTS", 'underline'), $required_inputs)
            : ''
        );
    push @parts, 
        ( $required_params
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("REQUIRED PARAMS", 'underline'), $required_params)
            : ''
        );
    push @parts, 
        ( $optional_inputs
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("OPTIONAL INPUTS", 'underline'), $optional_inputs)
            : ''
        );
    push @parts, 
        ( $optional_params
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("OPTIONAL PARAMS", 'underline'), $optional_params)
            : ''
        );
    push @parts, 
        ( $required_outputs
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("REQUIRED OUTPUTS", 'underline'), $required_outputs)
            : ''
        );
    push @parts, 
        ( $optional_outputs
            ? sprintf("%s\n%s\n", Term::ANSIColor::colored("OPTIONAL OUTPUTS", 'underline'), $optional_outputs)
            : ''
        );
    push @parts, 
        sprintf(
            "%s\n%s\n",
            Term::ANSIColor::colored("DESCRIPTION", 'underline'),
            _pod2txt($self->help_detail || '')
        );
    push @parts, 
        ( $extra_help ? $extra_help : '' );

    $text = sprintf(
        "\n%s\n%s\n\n%s%s%s%s%s%s%s%s%s\n",
        @parts
    );

    return $text;
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

sub doc_sections {
    my $self = shift;
    my @sections;

    my $command_name = $self->command_name;

    my $version = do { no strict; ${ $self->class . '::VERSION' } };
    my $help_brief = $self->help_brief;
    my $datetime = $self->__context__->now;
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

    my $manual = $self->_doc_manual_body || $self->help_detail;
    push(@sections, UR::Doc::Section->create(
        title => "DESCRIPTION",
        content => $manual,
        format => 'pod',
    ));

    my @extra_help = $self->_additional_help_sections;
    while (@extra_help) {
        my $title = shift @extra_help || '';
        my $content = shift @extra_help || '';
        push (@sections, UR::Doc::Section->create(
            title => $title,
            content => $content,
            format => 'pod'
        ));
    }

    if ($self->can("doc_sub_commands")) {
        my $sub_commands = $self->doc_sub_commands(brief => 1);
        if ($sub_commands) {
            push(@sections, UR::Doc::Section->create(
                title => "SUB-COMMANDS",
                content => $sub_commands,
                format => "pod",
            ));
        }
    }

    my @footer_section_methods = (
        'LICENSE'   => '_doc_license',
        'AUTHORS'   => '_doc_authors',
        'CREDITS'   => '_doc_credits',
        'BUGS'      => '_doc_bugs',
        'SEE ALSO'  => '_doc_see_also'
    );
    
    while (@footer_section_methods) {
        my $header = shift @footer_section_methods;
        my $method = shift @footer_section_methods;
        my @txt = $self->$method;
        next if (@txt == 0 or (@txt == 1 and not $txt[0]));
        my $content;
        if (@txt == 1) { 
            $content = $txt[0];
        } else {
            $content = join("\n", @txt);
        }

        push(@sections, UR::Doc::Section->create(
            title => $header,
            content => $content,
            format => "pod",
        ));
    }

    return @sections;
}

sub doc_sub_commands {
    my $self = shift;
    return;
}

sub doc_manual {
    my $self = shift;
    my $pod = $self->_doc_name_version;

    my $synopsis = $self->command_name . ' ' . $self->_shell_args_usage_string . "\n\n" . $self->help_synopsis;
    my $required_args = $self->help_options(is_optional => 0, format => "pod");
    my $optional_args = $self->help_options(is_optional => 1, format => "pod");
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
            );

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

    $pod .= $self->_doc_footer();    
    $pod .= "\n\n=cut\n\n";
    return "\n$pod";
}


sub _doc_name_version {
    my $self = shift;

    my $command_name = $self->command_name;
    my $pod;

    # standard: update this to do the old --help format
    my $synopsis = $self->command_name . ' ' . $self->_shell_args_usage_string . "\n\n" . $self->help_synopsis;
    my $help_brief = $self->help_brief;
    my $version = do { no strict; ${ $self->class . '::VERSION' } };
    my $datetime = $self->__context__->now;
    my ($date,$time) = split(' ',$datetime);

    $pod =
        "\n=pod"
        . "\n\n=head1 NAME"
        .  "\n\n"
        .   $self->command_name 
        . ($help_brief ? " - " . $self->help_brief : '') 
        . "\n\n";

    $pod .=
        "\n\n=head1 VERSION"
        . "\n\n"
        . "This document " # separated to trick the version updater 
        . "describes " . $self->command_name;

    if ($version) {
        $pod .= " version " . $version . " ($date at $time).\n\n";
    }
    else {
        $pod .= " ($date at $time)\n\n";
    }

    return $pod;
}

sub _doc_manual_body {
    return '';
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
                Term::ANSIColor::colored($row->[0], 'bold'), # . "   " . $row->[1],
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


sub _doc_footer {
    my $self = shift;
    my $pod = '';

    my @method_header_map = (
        'LICENSE'   => '_doc_license',
        'AUTHORS'   => '_doc_authors',
        'CREDITS'   => '_doc_credits',
        'BUGS'      => '_doc_bugs',
        'SEE ALSO'  => '_doc_see_also'
    );
    
    while (@method_header_map) {
        my $header = shift @method_header_map;
        my $method = shift @method_header_map;
        my @txt = $self->$method;
        next if (@txt == 0 or (@txt == 1 and not $txt[0]));
        if (@txt == 1) { 
            my @lines = split("\n",$txt[0]);
            $pod .= "=head1 $header\n\n"
                . join("  \n", @lines)
                . "\n\n";        
        }
        else {
            $pod .= "=head1 $header\n\n"
                . join("\n  ",@txt);
            $pod .= "\n\n";
        }
    }
    
    return $pod;
}

sub _doc_license {
    return '';
}

sub _doc_authors {
    return ();
}

sub _doc_credits {
    return '';    
}

sub _doc_bugs {
    return '';
}

sub _doc_see_also {
    return ();
}


sub _shell_args_usage_string {
    my $self = shift;

    return eval {
        if ( $self->isa('Command::Tree') ) { 
            return '...';
        }
        elsif ($self->can("_execute_body") eq __PACKAGE__->can("_execute_body")) {
            return '(no execute!)';
        }
        elsif ($self->__meta__->is_abstract) {
            return '(no sub commands!)';
        }
        else {
            return join(
                " ", 
                map { 
                    $self->_shell_arg_usage_string_from_property_meta($_) 
                } $self->_shell_args_property_meta()

            );
        }
    };
}

sub _shell_args_usage_string_abbreviated {
    my $self = shift;
    my $detailed = $self->_shell_args_usage_string;
    if (length($detailed) <= 20) {
        return $detailed;
    }
    else {
        return substr($detailed,0,17) . '...';
    }
}

sub sub_command_mapping {
    my ($self, $class) = @_;
    return if !$class;
    no strict 'refs';
    my $mapping = ${ $class . '::SUB_COMMAND_MAPPING'};
    if (ref($mapping) eq 'HASH') {
        return $mapping;
    } else {
        return;
    }
};

sub command_name {
    my $self = shift;
    my $class = ref($self) || $self;
    my $prepend = '';


    # There can be a hash in the command entry point class that maps
    # root level tools to classes so they can be in a different location
    # ...this bit of code considers that misdirection:
    my $entry_point_class = $Command::entry_point_class;
    my $mapping = $self->sub_command_mapping($entry_point_class);
    for my $k (%$mapping) {
        my $v = $mapping->{$k};
        if ($v && $v eq $class) {
            my @words = grep { $_ ne 'Command' } split(/::/,$class);
            return join(' ', $self->_command_name_for_class_word($words[0]), $k);
        }
    }


    if (defined($entry_point_class) and $class =~ /^($entry_point_class)(::.+|)$/) {
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

sub _pod2txt {
    my $txt = shift;
    my $output = '';
    my $parser = Pod::Simple::Text->new;
    $parser->no_errata_section(1);
    $parser->output_string($output);
    $parser->parse_string_document("=pod\n\n$txt");
    return $output;
}

sub _additional_help_sections {
    return;
}

1;
