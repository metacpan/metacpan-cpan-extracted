package UR::Namespace::Command::Show::Subclasses;

use strict;
use warnings;
use UR;
use YAML;

my $spacing = '';

class UR::Namespace::Command::Show::Subclasses {
    is => 'Command::V2',
    has=> [
        superclass => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Only show subclasses of this class.',
        },
        color => {
            is => 'Boolean',
            is_optional => 1,
            default_value => 1,
            doc => 'Display in color.',
        },
        maximum_depth => {
            is => 'Int',
            is_optional => 1,
            default_value => -1,
            doc => 'Maximum subclass depth.  Negative means infinite.',
        },
        recalculate => {
            is => 'Boolean',
            is_optional => 1,
            default_value => 0,
            doc => 'Recreate the cache instead of using the results of a previous run.',
        },
        flat => {
            is => 'Boolean',
            is_optional => 1,
            doc => 'Simply prints the subclass names with no other formatting or coloring.',
        }
    ],
    doc => 'Display subclasses of a given class.',
};

sub help_synopsis {
    my $self = shift;
    my $result .= <<EOP;
    Displays a tree of subclasses of a given class.
EOP
    return $result;
}

sub help_detail {
    my $self = shift;
    my $result .= <<EOP;
Displays a tree containing the names (and optionally other info) of the subclasses
of a given class.

    ur show subclasses <class_name>
    ur show subclasses <class_filename>

EOP
    return $result;
}

sub _mine_tree_for_class {
    my ($tree, $name, $result) = @_;

    if(ref($tree) eq 'HASH') {
        for my $key (keys %{$tree}) {
            if($key eq $name) {
                push(@{$result}, 1);
            } else {
                _mine_tree_for_class($tree->{$key}, $name, $result);
            }
        }
    } elsif(ref($tree) eq 'ARRAY') {
        for my $item (@{$tree}) {
            if($item eq $name) {
                push(@{$result}, 1);
            }
            _mine_tree_for_class($item, $name, $result);
        }
    }
    return;
}

sub execute {
    my ($self) = @_;
    my $indexfile = '/tmp/.ur_class_index';

    my $subclass_index_ref;
    if($self->recalculate or (not -e $indexfile)) {
        my $test_use_cmd = UR::Namespace::Command::Test::Use->create();
        $test_use_cmd->execute();

        $subclass_index_ref = {};
        create_subclass_index('UR::Object', $subclass_index_ref);

        my %subclass_index = %{$subclass_index_ref};
        open(my $output_fh, '>', $indexfile);
        for my $key (keys %subclass_index) {
            print $output_fh sprintf("%s %s\n", $key,
                join("\t", @{$subclass_index{$key}}));
        }
        close($output_fh);
    } else {
        $subclass_index_ref = parse_subclass_index_file($indexfile);
    }

    # check to see if superclass is even in the subclass_index
    my @result;
    _mine_tree_for_class($subclass_index_ref, $self->superclass, \@result);
    unless(@result) {
        my $class_name = $self->color ?
                Term::ANSIColor::colored($self->superclass, 'red') :
                $self->superclass;
        printf "%s is not a valid class, check your spelling or " .
                "see --help (recalculate).\n", $class_name;
        return;
    }

    if($self->flat) {
        $self->display_subclasses_flat($subclass_index_ref, 
                $self->superclass, 0)
    } else {
        $self->display_subclasses($subclass_index_ref,
                $self->superclass, '', '  ', 0);
    }

    return 1;
}

sub create_subclass_index {
    my ($seed, $index_ref) = @_;

    my @children = $seed->__meta__->subclasses_loaded;
    for my $child (@children) {
        my @parents = @{$child->__meta__->{is}};
        for my $parent (@parents) {
            if($index_ref->{$parent}) {
                push(@{$index_ref->{$parent}}, $child);
            } else {
                $index_ref->{$parent} = [$child];
            }
        }
    }
}

sub parse_subclass_index_file {
    my ($indexfile) = @_;

    open(IN, '<', $indexfile);
    my %index;
    while(my $line = <IN>) {
        chomp($line);
        if($line) {
            my ($parent, $rest) = split(/ /, $line);
            if($rest) {
                my @children = split('\t', $rest);
                $index{$parent} = \@children;
            } else {
                $index{$parent} = [];
            }
        }
    }
    return \%index
}

sub display_subclasses_flat {
    my ($self, $index_ref, $name, $depth) = @_;
    my $maximum_depth = $self->maximum_depth;
    if($depth == $maximum_depth + 1 and $maximum_depth != -1) {
        return;
    }
    print "$name\n";

    # get the children
    my $children_ref = $index_ref->{$name};
    my @children;
    if($children_ref) {
        @children = @{$index_ref->{$name}};
    } else { # if it isn't in index it has no children.
        @children = ();
    }

    # loop over children
    for my $child (@children) {
        $self->display_subclasses_flat($index_ref, $child, $depth+1);
    }
}

sub display_subclasses {
    my ($self, $index_ref, $name, $global_prefix, $personal_prefix, $depth) = @_;
    my $maximum_depth = $self->maximum_depth;

    my ($dgp, $dpp, $dn) = ($global_prefix, $personal_prefix, $name);
    if($self->color) {
        ($dgp, $dpp, $dn) = colorize_output($global_prefix, $personal_prefix,
                $name, $self->superclass);
    }
    print join('', $dgp, $dpp, $spacing, $dn);

    my $o = ($personal_prefix =~ /^\|/ ) ? '|' : ' ';
    my $child_global_prefix = sprintf("%s%s  %s", $global_prefix, $o, $spacing);

    # get the children
    my $children_ref = $index_ref->{$name};
    my @children;
    if($children_ref) {
        @children = @{$index_ref->{$name}};
    } else { # if it isn't in index it has no children.
        @children = ();
    }

    # loop over children
    my $len_children = scalar(@children);
    if($len_children and $depth == $maximum_depth and $maximum_depth != -1) {
        print " ...\n";
        return;
    }
    print "\n";

    my $i = 1;
    for my $child (@children) {
        my $child_personal_prefix = ($len_children == $i) ? '`-' : '|-';

        $self->display_subclasses($index_ref, $child, $child_global_prefix,
                $child_personal_prefix, $depth+1);
        $i += 1;
    }
}

sub colorize_output {
    my ($global_prefix, $personal_prefix, $name, $superclass) = @_;

    my $dgp = Term::ANSIColor::colored($global_prefix, 'white');
    my $dpp = Term::ANSIColor::colored($personal_prefix, 'white');
    my $name_prefix = $name;
    if($name_prefix =~ /^($superclass)/) {
        $name_prefix = $superclass;
    } else {
        $name_prefix = '';
    }
    my $name_suffix = $name;
    $name_suffix =~ s/^($superclass)//;
    my $dn = sprintf("%s%s", Term::ANSIColor::colored($name_prefix, 'white'), $name_suffix );

    return ($dgp, $dpp, $dn);
}

1;
