package Thrift::Parser::Type::Exception;

=head1 NAME

Thrift::Parser::Type::Exception - Exception type

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type::Struct);

=head1 METHODS

This class inherits from L<Thrift::Parser::Type>; see docs there for inherited methods.

=head2 throw

=cut

sub throw {
    my $class = shift;
    die $class->compose({ @_ });
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
