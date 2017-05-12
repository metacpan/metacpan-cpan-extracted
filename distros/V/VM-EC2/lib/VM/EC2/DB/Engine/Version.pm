package VM::EC2::DB::Engine::Version;

=head1 NAME

VM::EC2::DB::Engine::Version - An RDS Database Engine Version

=head1 SYNOPSIS

 use VM::EC2;
 $ec2 = VM::EC2->new(...);
 @versions = $ec2->describe_db_engine_versions;
 print $_,"\n" foreach grep { $_->Engine eq 'mysql' } @versions;

=head1 DESCRIPTION

This object represents a DB Engine Version, returned from a call to
VM::EC2->describe_db_engine_versions().

=head1 STRING OVERLOADING

In string context, this object return the DBEngineVersionDescription.

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
use VM::EC2::DB::CharacterSet;

use overload '""' => sub { shift->DBEngineVersionDescription },
    fallback => 1;


sub valid_fields {
    my $self = shift;
    return qw(DBEngineDescription DBEngineVersionDescription DBParameterGroupFamily
              DefaultCharacterSet Engine EngineVersion SupportedCharacterSets);
}

sub DefaultCharacterSet {
    my $self = shift;
    my $charset = $self->SUPER::DefaultCharacterSet;
    return VM::EC2::DB::CharacterSet->new($charset,$self->aws);
}

sub SupportedCharacterSets {
    my $self = shift;
    my $charsets = $self->SUPER::SupportedCharacterSets;
    return map { VM::EC2::DB::CharacterSet->new($_,$self->aws) } @{$charsets->{CharacterSet}};
}

sub engine_description { shift->DBEngineDescription }

sub description { shift->DBEngineVersionDescription }

sub param_group_family { shift->DBParameterGroupFamily }

sub default_charset { shift->DefaultCharacterSet }

sub supported_charsets { shift->SupportedCharacterSets }

1;
