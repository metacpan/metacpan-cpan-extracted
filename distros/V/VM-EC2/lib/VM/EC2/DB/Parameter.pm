package VM::EC2::DB::Parameter;

=head1 NAME

VM::EC2::DB::Parameter - An RDS Database Parameter

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 @params = $ec2->describe_db_parameters(-db_parameter_group_name => 'mygroup');
 print $_,"\n" foreach @params;

=head1 DESCRIPTION

This object represents a DB Parameter, used as a response element in the
VM::EC2->describe_engine_default_parameters() and 
VM::EC2->describe_db_parameters() calls.

=head1 STRING OVERLOADING

In string context, this object returns a string of Name=Value

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::DB::Instance>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2013 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

use overload '""' => sub { shift->as_string },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(
        AllowedValues
        ApplyMethod
        ApplyType
        DataType
        Description
        IsModifiable
        MinimumEngineVersion
        ParameterName
        ParameterValue
        Source
    );
}

sub name { shift->ParameterName }

sub value { shift->ParameterValue }

sub as_string {
    my $self = shift;
    return $self->ParameterName . '=' . $self->ParameterValue
}

1;
