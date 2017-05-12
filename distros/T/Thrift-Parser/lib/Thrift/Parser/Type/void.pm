package Thrift::Parser::Type::void;

=head1 NAME

Thrift::Parser::Type::void - void type

=head1 DESCRIPTION

This type class doesn't really hold a value, but is will represent a void type nonetheless.

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type);

sub read {
    my ($self, $parser, $input, $meta) = @_;
    # do nothing
}

sub write {
    # do nothing; it's a void for crying out loud
}

sub value_plain {
    return undef;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
