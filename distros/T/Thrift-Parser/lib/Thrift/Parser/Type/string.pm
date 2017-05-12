package Thrift::Parser::Type::string;

=head1 NAME

Thrift::Parser::Type::string - string type

=cut

use strict;
use warnings;
use utf8;
use base qw(Thrift::Parser::Type);

=head1 USAGE

Aside from standard L<Thrift::Parser::Type> methods, we are overloaded to return the plain string value.

=cut

use overload '""' => sub { $_[0]->value };

sub values_equal {
    my ($class, $value_a, $value_b) = @_;
    return $value_a eq $value_b;
}

sub value_plain {
    my $self = shift;
    return $self->value;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
