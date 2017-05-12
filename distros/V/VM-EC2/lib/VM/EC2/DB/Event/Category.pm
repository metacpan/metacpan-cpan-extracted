package VM::EC2::DB::Event::Category;

=head1 NAME

VM::EC2::DB::Event::Category - An RDS Database Event Category

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  $db_cat = $ec2->describe_event_categories(-source_type => 'db-instance');
  print $_,"\n" foreach $db_cat->EventCategories;

=head1 DESCRIPTION

This object represents an RDS Event Category.  It is the resultant output of 
the VM::EC2->describe_event_categories() function.

=head1 STRING OVERLOADING

When used in a string context, this object will output the source type
followed by a comma delimited list of event categories.

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
    return qw(SourceType EventCategories);
}

sub EventCategories {
    my $self = shift;
    my $cats = $self->SUPER::EventCategories;
    return unless $cats;
    $cats = $cats->{EventCategory};
    return ref $cats eq 'ARRAY' ? @$cats : ($cats);
}

sub as_string {
	my $self = shift;
	$self->SourceType . ' : ' . join(',',$self->EventCategories)
}

1;
