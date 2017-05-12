package VM::EC2::DB::Engine::Defaults;

=head1 NAME

VM::EC2::DB::Engine::Defaults - An RDS Database Engine Parameter Defaults

=head1 SYNOPSIS

 use VM::EC2;
 $ec2 = VM::EC2->new(...);
 my $defaults = $ec2->describe_engine_default_parameters(-db_parameter_group_family => 'MySQL5.1')
 my @params = $defaults->Parameters;
 print $_,"\n" foreach grep { $_->IsModifiable } @params;

=head1 DESCRIPTION

This object represents database engine parameter defaults.  It is returned
by a VM::EC2->describe_engine_default_parameters() call.

=head1 STRING OVERLOADING

none

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
use VM::EC2::DB::Parameter;

sub valid_fields {
    my $self = shift;
    return qw(DBParameterGroupFamily Parameters);
}

sub Parameters {
    my $self = shift;
    my $params = $self->SUPER::Parameters;
    return unless $params;
    $params = $params->{Parameter};
    return ref $params eq 'HASH' ?
        (VM::EC2::DB::Parameter->new($params,$self->aws)) :
        map { VM::EC2::DB::Parameter->new($_,$self->aws) } @$params;
}

1;
