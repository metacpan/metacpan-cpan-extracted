package VM::EC2::DB::Option::Group::Option::Setting;

=head1 NAME

VM::EC2::DB::Option::Group::Option::Setting - An RDS Database Option Group Option Setting

=head1 SYNOPSIS

 use VM::EC2;

 $ec2 = VM::EC2->new(...);
 @options = $ec2->describe_option_group_options(-engine_name => 'mysql');
 foreach $option (@options) {
   foreach $setting ($option->OptionGroupOptionSettings) {
     print $setting->SettingName,' : ',$setting->DefaultValue,"\n";
   }
 }

=head1 DESCRIPTION

This object describes an Option Group Option Setting and is an element returned
by the VM::EC2->describe_option_group_options() call.

=head1 STRING OVERLOADING

In string context, the object returns the Setting Name.

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

use overload '""' => sub { shift->SettingName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(
        AllowedValues
        ApplyType
        DefaultValue
        IsModifiable
        SettingDescription
        SettingName
    );
}

sub IsModifiable {
    my $self = shift;
    my $is = $self->SUPER::IsModifiable;
    return $is eq 'true';
}

1;
