package Ast;

#-----------------------------------------------------------------------------
# This package is used  to create a simple Abstract Syntax tree. Each node
# in the AST is an associative array and supports two kinds of properties -
# scalars and lists of scalars.
#-----------------------------------------------------------------------------

use strict;
my $curr_level = 0;
my $indent     = "   ";

# Constructor 
# e.g AST->new ("personnel")
# Stores the argument in a property called astNodeName whose sole purpose
# is to support print()
sub new {
    my ($pkg, $name) = @_;
    bless {'ast_node_name' => $name}, $pkg;
}

# Add a property to this object
# $ast_node->add_prop("className", "Employee");
sub add_prop {
    $_[0]->{$_[1]} = $_[2];
}
# Equivalent to add_prop, except the property name is associated
# with a list of values
# $class_ast_node->add_prop_list("attr_list", $attr_ast_node);
sub add_prop_list {
    my ($this, $prop_name, $node_ref) = @_;
    if (! exists $this->{$prop_name}) {
        $this->{$prop_name} = [];
    }
    push (@{$this->{$prop_name}}, $node_ref);
}

# Returns a list of all the property names of this object
sub get_props {
    my ($this) = $_[0];
    return keys %{$this};
}
sub get_prop_value {
    my ($this, $prop_name) = $_[0];
    return $this->{$prop_name};
}
my @saved_values_stack;
sub visit {
    no strict 'refs';
    my $this = shift;
    package main;
    my ($var, $val, $old_val, %saved_values);
    while (($var,$val) = each %{$this}) {
        if (defined ($old_val = $$var)) {
           $saved_values{$var} = $old_val;
        }
        $$var = $val;
    }
    push (@saved_values_stack, \%saved_values);
}

sub bye {
    my $rh_saved_values = pop(@saved_values_stack);
    no strict 'refs';
    package main;
    my ($var,$val);
    while (($var,$val) = each %$rh_saved_values) {
        $$var = $val;
    }
}

# Recursively prints the entire AST tree.
sub print {
    my $this = shift;
    my($curr_indent);
    my($i,$o,$prop);
    $curr_indent = $indent x $curr_level;
    print "${curr_indent}name :", $this->{"ast_node_name"}, "\n";
    $curr_indent .= $indent ;
    ++$curr_level;
    foreach $prop (keys %$this) {
        next if ($prop eq "ast_node_name");
        $o = $this->{"$prop"};
        if (ref($o) eq "Ast") {
            $o->print();
        } elsif (ref($o) eq "ARRAY") {
            foreach $i (@{$o}) {
                $i->print() if (ref($i) eq "Ast");
            }
        } else {
            print "${curr_indent}$prop: $o \n";
        }
    }
    --$curr_level;
}
1;
