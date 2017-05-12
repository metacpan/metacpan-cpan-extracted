#!/usr/bin/perl -w
# 
# $Id: Recordset.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Recordset;

# Auto-inserted by build scripts
$VERSION = "1.00";

use strict;
use Carp;

require WDDX;

my @Data_Types = qw( boolean number string datetime binary null );

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Recordset::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $names, $types, $data ) = @_;
    my( @names, @types, $value ) = ();
    
    unless ( defined $names and eval { $#$names || 1 } and
             defined $types and eval { $#$types || 1 }     ) {
        croak "You must supply array refs for names and data types " .
              "when creating a new $class object";
    }
    
    croak "Name and type arrays must contain the same number of elements"
        unless @$names == @$types;
    
    my $type;
    foreach $type ( @$types ) {
        next unless defined $type; # supports deserializing empty recordsets
        $type = lc $type;
        die "Unsupported data type: '$type'" unless
            grep $type eq $_, @Data_Types;
    }
    
    my $row;
    my $i = 0;
    foreach $row ( @$data ) {
        $i++;
        unless ( ref( $row ) =~ /ARRAY/ ) {
            croak "Third argument must be a ref to an array of array " .
                  "refs (i.e. a table)";
        }
        unless ( @$row == @$names ) {
            croak "The number of fields in row $i does not match the " .
                  "number of declared names";
        }
    }
    
    my @invalid = grep ! /^[_A-Za-z][_.0-9A-Za-z]*$/, @$names;
    croak "Invalid field names in recordset: @invalid" if @invalid;
    
    my $self = {
        names   => $names,
        types   => $types,
        value   => $data,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "recordset";
}


sub as_packet {
    my( $self ) = @_;
    my $output = $WDDX::PACKET_HEADER .
                 $self->_serialize .
                 $WDDX::PACKET_FOOTER;
}


sub as_arrayref {
    my( $self ) = @_;
    return $self->_deserialize;
}


sub as_javascript {
    my( $self, $js_var ) = @_;
    my $output = "$js_var=new WddxRecordset();";
    my $types  = $self->types;
    
    for ( my $col = 0; $col < $self->num_columns; $col++ ) {
        my $name = $self->names()->[$col];
        $output .= "$js_var.$name=new Array();";
        for ( my $row = 0; $row < $self->num_rows; $row++ ) {
            my $field = $self->get_element( $col, $row );
            my $var = eval "WDDX::\u$types->[$col]\->new( \$field )";
            die "$@\n" if $@;
            $output .= $var->as_javascript( "$js_var.$name\[$row\]" );
        }
    }
    return $output;
}


#/-----------------------------------------------------------------------
# Other Public Methods
# 


sub num_rows {
    my( $self ) = @_;
    return scalar @{ $self->table };
}

sub num_columns {
    my( $self ) = @_;
    return scalar @{ $self->{'names'} };
}

# Returns an array of the field names
sub names {
    my( $self, $new_names ) = @_;
    
    if ( defined $new_names ) {
        croak "You must supply an array ref when setting names"
            unless ref $new_names;
        $self->{'names'} = $new_names;
    }
    
    return $self->{'names'};
}

sub types {
    my( $self, $new_types ) = @_;
    
    if ( defined $new_types ) {
        croak "You must supply an array ref when setting types"
            unless ref $new_types;
        $self->{'types'} = $new_types;
    }
    
    return $self->{'types'};
}

sub table {
    my( $self, $new_value ) = @_;
    
    if ( defined $new_value ) {
        croak "You must supply an array ref when setting the table data"
            unless ref $new_value;
        $self->{'value'} = $new_value;
    }
    
    return $self->{value};
}

# Takes field name or number and returns array ref for that field
sub get_column {
    my( $self, $label ) = @_;
    my $data = $self->table;
    my $index = ( $label =~ /^\d+$/ ? $label : $self->get_index( $label ) );
    
    croak "Invalid column name" unless defined( $index );
    croak "Column $index doesn't exist" if $index > $self->num_columns;
    
    my @result = map $_->[$index], @$data; 
    return \@result;
}

sub set_column {
    my( $self, $label, $col ) = @_;
    my $data = $self->table;
    my $index = ( $label =~ /^\d+$/ ? $label : $self->get_index( $label ) );
    
    croak "Column not an array reference" unless ref( $col ) =~ /ARRAY/;
    croak "Invalid column name: '$label'" unless defined( $index );
    croak "Column $index doesn't exist" if $index > $self->num_columns;
    
    for ( my $i = 0; $i < @$col; $i++ ) {
        $data->[$i][$index] = $col->[$i];
    }
    # This fills in the rest of the col with undef if they passed
    # fewer elements than the number the col currently has
    for ( my $i = @$col; $i < $self->num_rows; $i++ ) {
        $data->[$i][$index] = undef;
    }
} 

sub add_column {
    my( $self, $name, $type, $col ) = @_;
    my $data = $self->table;
    my $names = $self->names;
    my $types = $self->types;
    
    croak "You must supply the name and type of the column" unless @_ >= 4;
    croak "Column not an array reference" unless ref( $col ) =~ /ARRAY/;
    croak "Duplicate column name: '$name'" if 
        defined( $self->get_index( $name ) );
    
    push @$names, $name;
    push @$types, $type;
    
    for ( my $i = 0; $i < @$col; $i++ ) {
        push @{ $data->[$i] }, $col->[$i];
    }
}

sub del_column {
    my( $self, $label ) = @_;
    my $data = $self->table;
    my $index = ( $label =~ /^\d+$/ ? $label : $self->get_index( $label ) );
    
    croak "Invalid column name: '$label'" unless defined( $index );
    croak "Column $index doesn't exist" if $index > $self->num_columns;
    
    _del_from_array( $self->{'names'}, $index );
    _del_from_array( $self->{'types'}, $index );
    
    foreach ( @$data ) {
        _del_from_array( $_, $index );
    }
}

# Pass array ref and index to delete; deletes array in place
sub _del_from_array {
    my( $arrayref, $del_idx ) = @_;
    
    return if $del_idx > $#$arrayref;
    for ( my $i = 0; $i < @$arrayref; $i++ ) {
        $arrayref->[$i] = $i >= $del_idx ? $arrayref->[$i+1] : $arrayref->[$i];
    }
    $#$arrayref--;
}


sub get_row {
    my( $self, $row_num ) = @_;
    croak "Row $row_num doesn't exist" if $row_num > $self->num_rows;
    return $self->table->[$row_num];
}

sub set_row {
    my( $self, $row_num, $row ) = @_;
    
    croak "Row not an array reference" unless ref( $row ) =~ /ARRAY/;
    croak "Row $row_num doesn't exist" if $row_num > $self->num_rows;
    croak "Number of elements in row does not match number of columns in " .
        "recordset" unless @$row == $self->num_columns;
    
    $self->table->[$row_num] = $row;
}

sub add_row {
    my( $self, $row ) = @_;
    my $data = $self->table;
    
    croak "Row not an array reference" unless ref( $row ) =~ /ARRAY/;
    croak "Number of elements in row does not match number of columns in " .
        "recordset" unless @$row == $self->num_columns;
    
    push @{ $self->table }, $row;
}

sub _check_data_type {
    my( $self, $num_rows ) = @_;
    
    if ( @{ $self->types } ) {
        croak "Number of elements in row does not match number of columns in " .
            "recordset" unless $num_rows == $self->num_columns;
    }
    else {
        warn "No data types defined for this recordset; assuming 'string'.\n";
        my @types;
        for ( 1 .. $num_rows ) { push @types, "string"; }
        $self->{'types'} = \@types;
    }

}

sub del_row {
    my( $self, $row_num ) = @_;
    my $data = $self->table;
    
    croak "Row $row_num doesn't exist" if $row_num > $self->num_rows;
    
    _del_from_array( $data, $row_num );
}


# Deprecated
sub get_field {
    my( $self, $row_num, $col_num ) = @_;
    my $data = $self->table;
    
    carp "get_field is deprecated; you should use get_element instead";
    croak "Field [$row_num,$col_num] doesn't exist" if 
        $row_num > $self->num_rows or $col_num > $self->num_columns;
    
    return $data->[$row_num][$col_num];
}

# Deprecated
sub set_field {
    my( $self, $row_num, $col_num, $value ) = @_;
    my $data = $self->table;
    
    carp "set_field is deprecated; you should use set_element instead";
    croak "Field [$row_num,$col_num] doesn't exist" if 
        $row_num > $self->num_rows or $col_num > $self->num_columns;
    
    $data->[$row_num][$col_num] = $value;
}


sub get_element {
    my( $self, $label, $row_num ) = @_;
    my $data = $self->table;
    my $col_num = ( $label =~ /^\d+$/ ? $label : $self->get_index( $label ) );
    
    croak "Field [ $label, $row_num ] doesn't exist" if 
        ! defined( $col_num ) or
        $row_num >= $self->num_rows or
        $col_num >= $self->num_columns;
    
    return $data->[$row_num][$col_num];
}

sub set_element {
    my( $self, $label, $row_num, $value ) = @_;
    my $data = $self->table;
    my $col_num = ( $label =~ /^\d+$/ ? $label : $self->get_index( $label ) );
    
    croak "Field [ $label, $row_num ] doesn't exist" if 
        ! defined( $col_num ) or
        $row_num >= $self->num_rows or
        $col_num >= $self->num_columns;
    
    $data->[$row_num][$col_num] = $value;
}


sub get_index {
    my( $self, $name ) = @_;
    
    for ( my $i = 0; $i < @{ $self->{'names'} }; $i++ ) {
        return $i if lc $name eq lc $self->{'names'}[$i];
    }
    return undef;
}



#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $table = $self->table;
    my $names = $self->names;
    my $types = $self->types;
    my $rows  = $self->num_rows;
    my $names_str = join ",", @$names;
    my $type;
    
    # We don't need to worry about data types if we don't have any data    
    if ( $self->num_rows ) {
        foreach $type ( @$types ) {
            croak "No data types were defined for this recordset" unless
                defined $type;
            die "Unsupported data type: '$_'" unless
                grep $type eq $_, @Data_Types;
        }
    }
    
    my $output = "<recordset rowCount='$rows' fieldNames='$names_str'>";
    
    for ( my $col_idx = 0; $col_idx < $self->num_columns; $col_idx++ ) {
        $output .= "<field name='$names->[$col_idx]'>";
        my $column = $self->get_column( $col_idx );
        my $field;
        foreach $field ( @$column ) {
            my $var = defined( $field ) ?
                        eval "WDDX::\u$types->[$col_idx]\->new( \$field )" :
                        new WDDX::Null();
            die "$@\n" if $@;
            $output .= $var->_serialize;
        }
        $output .= "</field>";
    }
    
    $output .= "</recordset>";
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self;
}

#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Recordset::Parser;


sub new {
    my $class = shift;
    
    my $self = {
        row_count       => 0,
        names           => "",
        value           => [],
        curr_field      => -1,
        curr_row        => -1,
        parse_var       => "",
        types           => [],
        seen_recordsets => 0,
    };
    return bless $self, $class;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $element eq "recordset" and not $self->{seen_recordsets}++ ) {
        unless ( $attribs->{rowcount} =~ /^\d+$/ ) {
            die "Invalid value for rowCount attribute in <recordset> tag\n";
        }
        
        my @names = split ",", $attribs->{fieldnames};
        if ( ! @names or grep ! /^[_A-Za-z][_.0-9A-Za-z]*$/, @names ) {
            die "Invalid fieldNames attribute declared in <recordset> tag\n";
        }
        
        $self->{'names'} = \@names;
        $self->{row_count} = $attribs->{rowcount};
    }
    elsif ( $element eq "field" and $self->{seen_recordsets} == 1 ) {
        die "No name supplied for field\n" unless $attribs->{name};
        die "Cannot nest <field> elements\n" unless $self->{curr_row} < 0;
        
        my $expected = $self->{'names'}[ ++$self->{curr_field} ];
        unless ( $attribs->{name} eq $expected ) {
            die "Expected <field name='$expected'> and found " .
                "<field name='$attribs->{name}'>\n";
        }
        
        $self->{curr_row} = -1;
    }
    else {
        unless ( $parse_var ) {
            die "<$element> not allowed in Recordset element\n" unless
                grep $element eq $_, @Data_Types;
            $parse_var = WDDX::Parser->create_var( $element ) or
                die "Expecting some data element (e.g., <string>), " .
                    "found: <$element>\n"; # shouldn't happen but be safe...
            $self->{'types'}[ $self->{curr_field} ] = $element;
            $self->push( $parse_var );
        }
        $parse_var->start_tag( $element, $attribs );
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $element eq "recordset" and not --$self->{seen_recordsets} ) {
        my @data = map { [ map $_->_deserialize, @$_ ] } @{ $self->{value} };
        
        # This is kinda a kludge to allow us to deserialize empty recordsets
        # Since an empty recordset will have no data type tags, we set the
        # data type of each field to undef
        unless ( @data ) {
            $self->{'types'} = [ map undef, ( 1 .. @{ $self->{'names'} } ) ];
        }
        
        $self = new WDDX::Recordset(
                    $self->{'names'},
                    $self->{'types'},
                    \@data
                );
    }
    elsif ( $element eq "field" and $self->{seen_recordsets} == 1 ) {
        my $name = $self->{'names'}[ $self->{curr_field} ];
        if ( $self->{curr_row} != $self->{row_count} - 1 ) {
            die "Number of elements in field '$name' doesn't match declared " .
                "row count\n";
        }
        $self->{curr_row} = -1;
    }
    else {
        unless ( $parse_var ) {
            # XML::Parser should actually catch this
            die "Found </$element> before <$element>\n";
        }
        $self->parse_var( $parse_var->end_tag( $element ) );
    }
    
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $parse_var ) {
        $parse_var->append_data( $data );
    }
    elsif ( $data =~ /\S/ ) {
        die "No loose character data is allowed within <recordset> elements\n";
    }
}


sub is_parser {
    return 1;
}


sub parse_var {
    my( $self, $var ) = @_;
    my $curr_field = $self->{curr_field};
    my $curr_row = $self->{curr_row};
    
    return "" if $curr_field < 0 or $curr_row < 0;
    
    $self->{value}[$curr_row][$curr_field] = $var if defined $var;
    my $curr_var = $self->{value}[$curr_row][$curr_field];
    return ( ref $curr_var && $curr_var->is_parser ) ? $curr_var : "";
}


sub push {
    my( $self, $element ) = @_;
    my $curr_field = $self->{curr_field};
    my $curr_row = ++$self->{curr_row};
    my $name = $self->{'names'}[$curr_field];
    
    if ( $curr_field < 0 ) {
       die "Missing <field> tag in recordset\n";
    }
    if ( $self->{curr_row} >= $self->{row_count} ) {
        die "Number of elements in field '$name' exceeds declared row count\n";
    }
    
    $self->{value}[$curr_row][$curr_field] = $element;
}
