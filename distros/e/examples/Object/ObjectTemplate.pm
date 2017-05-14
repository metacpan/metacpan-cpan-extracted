
package ObjectTemplate;
require Exporter;
@ObjectTemplate::ISA = qw(Exporter);
@ObjectTemplate::EXPORT = qw(attributes);

my $debugging = 0; # assign 1 to it to see code generated on the fly 

# Create accessor functions, and new()
sub attributes {
    my ($pkg) = caller;
    @{"${pkg}::_ATTRIBUTES_"} = @_;
    my $code = "";
    foreach my $attr (get_attribute_names($pkg)) {
        # If a field name is "color", create a global list in the
        # calling package called @color
        @{"${pkg}::_$attr"} = ();

        # Define accessor only if it is not already present
        unless ($pkg->can("$attr")) {
            $code .= _define_accessor ($pkg, $attr);
        } 
    }
    $code .= _define_constructor($pkg);
    eval $code;
    if ($@) {
       die  "ERROR defining constructor and attributes for '$pkg':" 
            . "\n\t$@\n" 
            . "-----------------------------------------------------"
            . $code;
    }
}

# $obj->set_attributes (name => 'John', age => 23);     
# Or, $obj->set_attributes (['name', 'age'], ['John', 23]);
sub set_attributes {
    my $obj = shift;
    my $attr_name;
    if (ref($_[0])) {
       my ($attr_name_list, $attr_value_list) = @_;
       my $i = 0;
       foreach $attr_name (@$attr_name_list) {
            $obj->$attr_name($attr_value_list->[$i++]);
       }
    } else {
       my ($attr_name, $attr_value);
       while (@_) {
           $attr_name = shift;
           $attr_value = shift;
           $obj->$attr_name($attr_value);
       }
    }
}


# @attrs = $obj->get_attributes (qw(name age));
sub get_attributes {
    my $obj = shift;
    my (@retval);
    map $obj->${_}(), @_;
}


sub get_attribute_names {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);
    my @result = @{"${pkg}::_ATTRIBUTES_"};
    if (defined (@{"${pkg}::ISA"})) {
        foreach my $base_pkg (@{"${pkg}::ISA"}) {
           push (@result, get_attribute_names($base_pkg));
        }
    }
    @result;
}

sub set_attribute {
    my ($obj, $attr_name, $attr_value) = @_;
    my ($pkg) = ref($obj);
    ${"${pkg}::_$attr_name"}[$$obj] = $attr_value;
}

sub get_attribute {
    my ($obj, $attr_name, $attr_value) = @_;
    my ($pkg) = ref($obj);
    return ${"${pkg}::_$attr_name"}[$$obj];
}


sub DESTROY {
    # release id back to free list
    my $obj = $_[0];
    my $pkg = ref($obj);
    local *_free = *{"${pkg}::_free"};
    my $inst_id = $$obj;
    # Release all the attributes in that row
    local(*attributes) = *{"${pkg}::_ATTRIBUTES_"};
    foreach my $attr (@attributes) {
        undef ${"${pkg}::_$attr"}[$inst_id];
    }
    $_free[$inst_id] = $_free;
    $_free = $inst_id;
}

sub initialize { }; # dummy method, if subclass doesn’t define one.

#################################################################

sub _define_constructor {
    my $pkg = shift;
    my $code = qq {
        package $pkg;
        sub new {
            my \$class = shift;
            my \$inst_id;
            if (defined(\$_free[\$_free])) {
                \$inst_id = \$_free;
                \$_free = \$_free[\$_free];
                undef \$_free[\$inst_id];
            } else {
                \$inst_id = \$_free++;
            }
            my \$obj = bless \\\$inst_id, \$class;
            \$obj->set_attributes(\@_) if \@_;
            \$obj->initialize;
            \$obj;

        }
    };
    $code;
}

sub _define_accessor {
    my ($pkg, $attr) = @_;

    # This code creates an accessor method for a given
    # attribute name. This method  returns the attribute value 
    # if given no args, and modifies it if given one arg.
    # Either way, it returns the latest value of that attribute


    # qq makes this block behave like a double-quoted string
    my $code = qq{
        package $pkg;
        sub $attr {                                      # Accessor ...
            \@_ > 1 ? \$_${attr} \[\${\$_[0]}] = \$_[1]  # set
                    : \$_${attr} \[\${\$_[0]}];          # get
        }
        if (!defined \$_free) {
            # Alias the first attribute column to _free
            \*_free = \*_$attr;
            \$_free = 0;
        };

    };
    $code;
}

1;

