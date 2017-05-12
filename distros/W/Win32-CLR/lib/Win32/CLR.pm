package Win32::CLR;

use strict;
use Carp;

BEGIN {
    our $VERSION = "0.03";
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);

    my @methods = qw(
        get_field       set_field
        get_property    set_property
        get_value       set_value
        add_event       remove_event
        has_member      create_instance
        create_delegate create_enum
        create_array
    );

    foreach my $method (@methods) {
        no strict "refs";
        my $call = "_" . $method;
        *{$method} = sub {
            my $self = shift;
            my $type = ref($self) ? $self->get_qualified_type() : $self->parse_type( shift(@_) );
            return $self->$call($type, @_);
        };
    }

}

use overload
    q{""}   => \&to_string,
    'bool'  => \&op_boolify,
    # '0+'    => \&op_numify,
    '=='    => \&op_equality,
    '!='    => \&op_inequality,
    '+'     => \&op_addition,
    '-'     => \&op_subtraction,
    '*'     => \&op_multiply,
    '/'     => \&op_division,
    '%'     => \&op_modulus,
    '>'     => \&op_greaterthan,
    '>='    => \&op_greaterthan_or_equal,
    '<'     => \&op_lessthan,
    '<='    => \&op_lessthan_or_equal,
    '++'    => \&op_increment,
    '--'    => \&op_decrement;

sub parse_type {
    my ($self, $type) = @_;
    return Win32::CLR::Parser->parse_type($type);
}

sub parse_method {
    my ($self, $method) = @_;
    return Win32::CLR::Parser->parse_method($method);
}

sub call_method {
    my $self = shift;
    my $type = ref($self) ? $self->get_qualified_type() : $self->parse_type( shift(@_) );
    my ($method, @generic) = $self->parse_method( shift(@_) );

    if (@generic) {
        return $self->_call_generic_method($type, $method, \@generic, @_);
    }
    else {
        return $self->_call_method($type, $method, @_);
    }

}

sub derived_from {
    my ($self, $type) = @_;
    return $self->_derived_from( $self->parse_type($type) );
}

sub AUTOLOAD {

    our $AUTOLOAD;

    my $self = $_[0];
    my ($method) = $AUTOLOAD =~ /(\w+)$/;
    my $auto_sub;

    if ( $method =~ /^(get|set)_(\w+)/ ) {

        my $type = $1;
        my $name = $2;
        $name =~ tr/_//d;

        if ( !$self->has_member($name, "Property, Field") ) {
            carp("Warning: Missing field or property: \"$name\"");
            return;
        }

        if ("get" eq $type) {

            $auto_sub = sub {
                my $self = shift;
                return $self->get_value($name, @_);
            };

        }
        elsif ("set" eq $type) {

            $auto_sub = sub {
                my $self = shift;
                $self->set_value($name, @_);
                return;
            };

        }

    }
    else {

        my $name = $method;
        $name =~ tr/_//d;

        if ( !$self->has_member($name, "Method") ) {
            carp("Warning: Missing method: \"$name\"");
            return;
        }

        $auto_sub = sub {
            my $self = shift;
            return $self->call_method($name, @_);
        };

    }

    # my $type_hash = $self->get_type_hash();
    # my $auto_type = __PACKAGE__ . '::AutoLoad::Type' . $type_hash;
    # bless $self, $auto_type;

    # {
    #     no strict "refs";
    #     push @{$auto_type . '::ISA'}, __PACKAGE__;
    #     *{$auto_type . '::' . $method} = $auto_sub;
    # }

    goto &$auto_sub;
}

package Win32::CLR::Parser;

use strict;
use Carp;

sub stack_push {
    my ($self, $key, @value) = @_;
    push @{ $self->{$key} }, @value;
}

sub stack_pop {
    my ($self, $key) = @_;
    return pop @{ $self->{$key} };
}

sub stack_increment {
    my ($self, $key) = @_;
    my $array_ref = $self->{$key};
    $array_ref->[$#$array_ref] += 1;
}

sub stack_depth {
    my ($self, $key) = @_;
    return scalar @{ $self->{$key} };
}

sub stack_append {
    my ($self, @value) = @_;
    $self->{append}->($self, @value);
}

sub parse_type {
    my $class = shift;

    my $self = bless {
        name    => [],
        generic => [],
        param   => [],
        number  => [],
        append  => sub {
            my ($self, @value) = @_;
            if ( $self->stack_depth("param") ) {
                my $param_ref = $self->{param};
                push @{ $param_ref->[$#$param_ref] }, @value;
            }
            else {
                push @{ $self->{name} }, @value;
            }
        },
    }, $class;

    $self->_parse($_[0]);
    return join "", @{ $self->{name} };
}

sub parse_method {

    my ($class, $name) = @_;

    $name =~ s/^\s+//;
    $name =~ s/\s+$//;

    if ( $name =~ /^\w+</ and $name =~ />$/ ) {
        $name =~ s/^(\w+)<//;
        my $method = $1;
        $name =~ s/>$//;

        my $self = bless {
            name    => [],
            generic => [],
            param   => [],
            number  => [],
            append  => sub {
                my ($self, @value) = @_;
                if ( $self->stack_depth("param") ) {
                    my $param_ref = $self->{param};
                    push @{ $param_ref->[$#$param_ref] }, @value;
                }
                else {
                    return if (@value == 1 and $value[0] eq ",");
                    if ($value[0] eq "[" and $value[$#value] eq "]") {
                        pop   @value;
                        shift @value;
                    }
                    push @{ $self->{name} }, join "", @value;
                }
            },
        }, $class;

        $self->_parse($name);
        return $method, @{ $self->{name} };
    }
    else {
        return $name, ();
    }

}

sub _parse {

    my $self = shift;
    $_[0] =~ /\G\s+/gc; # ignore space

    if ( $_[0] =~ /\G([\w+.\\]+)</gc  ) {
        # type<
        $self->stack_push("generic", $1);
        $self->stack_push("param", []);
        $self->stack_push("number", 1);
    }
    elsif ( $_[0] =~ /\G([\w+.\\]+`\d+ \s*,\s*[\w.]+ \s*,\s*\w+=[^\]]+ )/gcx) {
        # type`1, assem, Version=...
        $self->stack_append($1);
    }
    elsif ( $_[0] =~ /\G([\w+.\\]+`\d+\[)/gc ) {
        # type`1[
        $self->stack_push("param", []);
        $self->stack_push("number", 1);
        $self->stack_append($1);
    }
    elsif ( $_[0] =~ /\G([\w+.\\]+`\d+)/gcx) {
        # type`1
        my $type = Win32::CLR->get_qualified_type($1);

        if ( defined $type ) {
            if ( $self->stack_depth("param") ) {
                $self->stack_append("[", $type, "]");
            }
            else {
                $self->stack_append($type);
            }
        }
        else {
            carp("Warning: Missing type or method: \"$1\" not found");
            $self->stack_append($1);
        }

    }
    elsif ( $_[0] =~ /\G\[/gc ) {
        $self->stack_push("param", []);
        $self->stack_push("number", 1);
        $self->stack_append("[");
    }
    elsif ( $_[0] =~ /\G\] ( \s*,\s*[\w.]+ \s*,\s*\w+=[^\]]+ ) /gcx ) {
        # ...], assem, Version=...
        $self->stack_pop("number");
        my $param_ref = $self->stack_pop("param");
        $self->stack_append( @{$param_ref}, "]", $1 );
    }
    elsif ( $_[0] =~ /\G\]/gc ) {
        $self->stack_pop("number");
        my $param_ref = $self->stack_pop("param");
        $self->stack_append( @{$param_ref}, "]" );
    }
    elsif ( $_[0] =~ /\G>( \s*,\s*[\w.]+ \s*,\s*\w+=[^\]]+ ) /gcx ) {
        # ...>, assem, Version=...
        my $type      = $self->stack_pop("generic");
        my $number    = $self->stack_pop("number");
        my $param_ref = $self->stack_pop("param");
        $self->stack_append( $type, "`", $number, "[", @{$param_ref}, "]", $1 );
    }
    elsif ( $_[0] =~ /\G>/gc ) {

        my $type      = $self->stack_pop("generic");
        my $number    = $self->stack_pop("number");
        my $param_ref = $self->stack_pop("param");

        if ( $number == 1 and @{$param_ref} == 0 ) {
            $self->stack_append( $type, "`", $number );
        }
        else {
            $self->stack_append( $type, "`", $number, "[", @{$param_ref}, "]" );
        }

    }
    elsif ( $_[0] =~ /\G( [\w+.\\]+ (?: \[ [^\]]* \] )+ \s*,\s*[\w.]+ \s*,\s*\w+=[^\]]+ )/gcx ) {
        # type[,][*], assem, Version=...
        $self->stack_append($1);
    }
    elsif ( $_[0] =~ /\G([\w+.\\]+[*&]* \s*,\s*[\w.]+ \s*,\s*\w+=[^\]]+ )/gcx) {
        # type type* type** type&, assem, Version=...
        $self->stack_append($1);
    }
    elsif ( $_[0] =~ /\G( [\w+.\\]+ (?: \[ [^\]]* \] )+ )/gcx ) {
        # type[,][*]
        my $type = Win32::CLR->get_qualified_type($1);

        if ( defined $type ) {
            if ( $self->stack_depth("param") ) {
                $self->stack_append("[", $type, "]");
            }
            else {
                $self->stack_append($type);
            }
        }
        else {
            carp("Warning: Missing type or method: \"$1\" not found");
            $self->stack_append($1);
        }

    }
    elsif ( $_[0] =~ /\G([\w+.\\]+[*&]*)/gcx) {
        # type type* type** type&
        my $type = Win32::CLR->get_qualified_type($1);

        if ( defined $type ) {
            if ( $self->stack_depth("param") ) {
                $self->stack_append("[", $type, "]");
            }
            else {
                $self->stack_append($type);
            }
        }
        else {
            carp("Warning: Missing type or method: \"$1\" not found");
            $self->stack_append($1);
        }

    }
    elsif ( $_[0] =~ /\G,/gc ) {

        if ( $self->stack_depth("number") ) {
            $self->stack_increment("number");
        }

        $self->stack_append(",");

    }
    else {
        return;
    }

    $self->_parse($_[0]);
    return;
}

1;

__END__
=head1 NAME

Win32::CLR - Use .NET Framework facilities in Perl

=head1 SYNOPSIS

    use Win32::CLR;
    use utf8;

    # binmode STDOUT, ":encoding(Shift_JIS)"; # japanese character set

    # creating instance
    my $dt1 = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10, 11, 12);

    # getting property
    print $dt1->get_property("Year"), "\n"; # 2007

    # calling method
    my $dt2 = $dt1->call_method("AddYears", 3);
    print $dt2->get_property("Year"), "\n"; # 2010

    my $asm = "System.Windows.Forms, Version=2.0.0.0,
    Culture=neutral, PublicKeyToken=b77a5c561934e089";

    # loading assembly by name
    Win32::CLR->load($asm);

    # after loading assembly, System.Windows.Forms.* classes can be used
    Win32::CLR->call_method(
        "System.Windows.Forms.MessageBox", # type
        "Show",    # method
        "Message", # parameter
        "Title"    # parameter
    );

    # creating generic instance
    my $generic = "System.Collections.Generic.Dictionary<System.String, System.Int32>";
    my $dict = Win32::CLR->create_instance($generic);
    $dict->set_property("Item", "ABC", 4321); # dict["ABC"] = 4321;
    print $dict->get_property("Item", "ABC"), "\n"; # 4321

=head1 DESCRIPTION

Win32::CLR provides utility methods to using Microsoft .NET Framework,
also known as Common Language Runtime. It is available for creating object,
calling method, accessing field or property, converting perl subroutine
to delegate, loading assembly.

=head1 CLASS METHODS

=over

=item Win32::CLR->create_instance("TYPE", @PARAMS)

Creates .NET Framework object of TYPE. The constructor that
matches @PARAMS is used.

    my $dt = Win32::CLR->create_instance(
        "System.DateTime",
        2007, 8, 9, 10, 11, 12
    );

=item Win32::CLR->call_method("TYPE", "NAME", @PARAMS)

Calls the static method declared in TYPE. @PARAMS must be primitive
value or Win32::CLR instance. If @PARAMS contain array reference,
it is converted to System.Array.

    # in .net
    # static void MyType::Foo(String^ param);

    # in perl
    Win32::CLR->call_method("MyType", "Foo", "foo");

    # static void MyType::Foo2(String^ param1, Int32 param2);
    Win32::CLR->call_method("MyType", "Foo2", "foo", 4321);

    # static void MyType::Foo3(array<Object^>^ params);
    Win32::CLR->call_method("MyType", "Foo3", ["foo", "bar", ...]);

=item Win32::CLR->get_field("TYPE", "NAME", [$INDEX])

Returns the static field declared in TYPE. If field has index,
optional parameter $INDEX can be used.

    # in .net
    # field = MyType::Foo;

    Win32::CLR->get_field("MyType", "Foo");

    # MyType::Foo[0]
    Win32::CLR->get_field("MyType", "Foo", 0);

=item Win32::CLR->set_field("TYPE", "NAME", [$INDEX, ] $PARAM)

Sets $PARAM in the static field declared in TYPE. $PARAM must be primitive value
or Win32::CLR instance. If field has index, optional parameter $INDEX can be used.

=item Win32::CLR->get_property("TYPE", "NAME", [$INDEX])

Same as get_field, returns the static property declared in TYPE.
Optionally, $INDEX can be used.

    # in .net
    # dict["ABC"]
    $dict->get_property("Item", "ABC");

=item Win32::CLR->set_property("TYPE", "NAME", [$INDEX, ] $PARAM)

Same as set_field, sets $PARAM in the static property declared in TYPE.
Optionally, $INDEX can be used.

    # in .net
    # dict["ABC"] = 4321;
    $dict->set_property("Item", "ABC", 4321);

=item Win32::CLR->get_value("TYPE", "NAME", [$INDEX])

If property exists in TYPE, calls get_property, or otherwise calls get_field.

=item Win32::CLR->set_value("TYPE", "NAME", [$INDEX, ] $PARAM)

Same as get_value, sets $PARAM in static property or field.

=item Win32::CLR->add_event("TYPE", "NAME", $DELEG)

Sets event handler in the static event declared in TYPE.
$DELEG must be System.Delegate or subroutine reference.

    my $deleg = Win32::CLR->create_delegate(
        "System.EventHandler",
        sub {print "do something"},
    );
    $button->add_event("Click", $deleg);
    $button->remove_event("Click", $deleg);

    # directly, but addition only!
    $button->add_event("Click", sub {print "do something"});

=item Win32::CLR->remove_event("TYPE", "NAME", $DELEG)

Removes event handler $DELEG from TYPE.
$DELEG must be System.Delegate.

=item Win32::CLR->create_delegate("TYPE", $CODE)

Creates System.Delegate from perl subroutine.
$CODE can contain "sub_name" or \&sub_ref.
TYPE is delegate type (ex. System.EventHandler).

    my $deleg = Win32::CLR->create_delegate(
        "System.EventHandler",
        sub {
            my ($obj, $event_args) = @_;
            # do something ...
        }
    );

=item Win32::CLR->create_array("TYPE", @PARAMS)

Creates TYPE of System.Array. @PARAMS is setted.

    my $array = Win32::CLR->create_array("System.String", "A", "B", "C");
    $array->call_method("GetValue", 0); # A
    $array->call_method("GetValue", 1); # B
    $array->call_method("GetValue", 2); # C

=item Win32::CLR->create_enum("TYPE", "VALUE1, VALUE2, ...")

Creates System.Enum value. TYPE is enum type, VALUES contain list of named
constants delimited by commas.

    my $binding_flags = Win32::CLR->create_enum(
        "System.Reflection.BindingFlags",
        "InvokeMethod, NonPublic"
    );

=item Win32::CLR->load("NAME")

Loads assembly by AssemblyQualifiedName. If assembly loaded once, it comes
to be able to use the type in assembly. Loaded assembly is cached in
memory, so reloading assembly is not required. NAME must be long form of
the assembly name. It returns loaded System.Reflection.Assembly object.

    my $name =
        "System.Windows.Forms, Version=2.0.0.0,
        Culture=neutral, PublicKeyToken=b77a5c561934e089";
    # $asm can be ignored
    my $asm = Win32::CLR->load($name);
    my $button = Win32::CLR->create_instance("System.Windows.Forms.Button");

=item Win32::CLR->load_from("PATH")

Loads assembly from file. PATH is path to assembly file.
It returns loaded System.Reflection.Assembly object.

=item Win32::CLR->has_member("TYPE", "NAME", [$MEMBER_TYPE])

Checks TYPE has member NAME. $MEMBER_TYPE is System.Reflection.MemberTypes constants
delimited by commas. Default is Method, Field, Property, Event.

    if ( Win32::CLR->has_member("System.String", "Length", "Field, Property") ) {
        print "System.String has Length\n";
    }

=item Win32::CLR->get_type_name($OBJ)

Returns type name in CLR.

=item Win32::CLR->get_qualified_type($OBJ)

Returns full qualified type name in CLR.

=back

=head1 INSTANCE METHODS

Win32::CLR instance has similar methods to class methods.

    $obj->call_method("NAME", @PARAMS)
    $obj->get_field("NAME", [$INDEX])
    $obj->set_field("NAME", [$INDEX, ] $PARAM)
    $obj->get_property("NAME", [$INDEX])
    $obj->set_property("NAME", [$INDEX, ] $PARAM)
    $obj->get_value("NAME", [$INDEX])
    $obj->set_value("NAME", [$INDEX, ] $PARAM)
    $obj->add_event("NAME", $DELEG)
    $obj->remove_event("NAME", $DELEG)
    $obj->has_member("NAME", [$MEMBER_TYPE])
    $obj->get_type_name()
    $obj->get_qualified_type()

=over

=item $obj->get_addr()

Returns object address. Can be used for Inside-out class.

=item $obj->derived_from("TYPE")

Like UNIVERSAL::isa, returns $obj is derived from TYPE.

=item $obj->to_string()

Converts $obj to perl primitive string.

=back

=head1 CREATING GENERIC INSTANCE

If you want to create generic instance, use optional parameter type enclosed by "<>".

    my $name = "System.Collections.Generic.Dictionary<System.String, System.Int32>";
    my $dict = Win32::CLR->create_instance($name);

Also System.Type.GetType form can be used.

    my $name = "System.Collections.Generic.Dictionary`2[System.String, System.Int32]";
    my $dict = Win32::CLR->create_instance($name);

=head2 GENERIC TYPE EXAMPLE

    "Generic< Generic<Type1, Type2>, Type3 >"   # recursive
    "Generic< Generic`2[Type1, Type2], Type3 >" # mixing

    my $type = <<"TYPE"; # assembly qualified form
    System.Collections.Generic.Dictionary<
        [
            System.String, mscorlib, Version=2.0.0.0,
            Culture=neutral, PublicKeyToken=b77a5c561934e089
        ],
        System.Int32
    >, mscorlib, Version=2.0.0.0, Culture=neutral,
    PublicKeyToken=b77a5c561934e089
    TYPE

    # creating generic delegate
    my $deleg = Win32::CLR->create_delegate(
        "System.Action<System.String>",
        sub { print $_[0] }
    );

=head1 CALLING GENERIC METHOD

Like creating generic type, generic method can be used.

    $obj->call_method("method<System.String>", @params);

=head1 TYPE CONVERSION

Win32::CLR automatically converts primitive value between .net and perl.

    .net -> perl
        Boolean                      -> perl bool
        SByte, Int16, Int32, Int64   -> perl int
        Byte, UInt16, UInt32, UInt64 -> perl unsigned int
        Single, Double               -> perl double
        Char, String, Decimal        -> perl string(utf8 flag on)
        null(nullptr)                -> perl undef
        other                        -> perl Win32::CLR instance

    perl -> .net
        Win32::CLR instance -> Object
        perl int            -> Int32  -> cast target
        perl unsigned int   -> UInt32 -> cast target
        perl string         -> Char, String, Decimal
        perl double         -> Double -> cast target
        perl undef          -> null(nullptr)

=head1 EXCEPTION HANDLING

When error occurred, System.Exception object is setted in $@. If you want to
catch the exception, use eval-block statement. Note that exception message is
utf8 encoded.

    use Win32::CLR;

    binmode STDERR, ":encoding(sjis)"; # if japanese windows

    eval {
        # Invalid arguments!
        my $dt1 = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10);
    };

    print STDERR $@->get_property("Message"), "\n";
    print STDERR $@->get_type_name(), "\n"; # System.MissingMethodException

=head1 OVERLOAD

Following operators are overloaded.

    "" bool == != + - * / % > >= < <= ++ --

    my $dt1 = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10, 11, 12);
    my $dt2 = Win32::CLR->create_instance("System.DateTime", 2008, 8, 9, 10, 11, 12);
    print "$dt1";
    $dt1 == $dt1;
    $dt1 != $dt2;
    $dt > $dt2;
    $dt < $dt2;

If you want compare instance equality, use get_addr method.

    $dt->get_addr() == $dt->get_addr()

=head1 AUTOLOAD

When calling method named /^(get|set)_\w+/, it is converted to get_value or set_value.
If not /^(get|set)_/, converted to call_method. Underscore is ignored and name is ignorecase.

    $obj->get_year()    -> $obj->get_value("Year")
    $obj->get_y_e_Ar()  -> $obj->get_value("Year")
    $obj->set_year(1)   -> $obj->set_value("Year", 1)
    $obj->add_years(2)  -> $obj->call_method("AddYears", 2)
    $obj->AddYears(2)   -> $obj->call_method("AddYears", 2)
    $obj->aDd__yEaRs(2) -> $obj->call_method("AddYears", 2)

=head1 BUGS AND WARNINGS

More tests and documents are required.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 Toshiyuki Yamato, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
