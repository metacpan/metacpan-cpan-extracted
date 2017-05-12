package Thrift::Parser::Type::i64;

=head1 NAME

Thrift::Parser::Type::i64 - i64 type

=head1 DESCRIPTION

This class inherits from L<Thrift::Parser::Type::Number>.  See the docs there for all the usage details.

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type::Number);

sub _max_value { 2 ** 63 }

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
