package WebService::Google::Closure::Type::Warning;

use Moose;
use MooseX::Types::Moose qw( Str Int );

has type => (
    is         => 'ro',
    isa        => Str,
    required   => 1,
);

has file => (
    is         => 'ro',
    isa        => Str,
    required   => 1,
);

has lineno => (
    is         => 'ro',
    isa        => Int,
    required   => 1,
);

has charno => (
    is         => 'ro',
    isa        => Int,
    required   => 1,
);

has line => (
    is         => 'ro',
    isa        => Str,
    required   => 1,
);

has text => (
    is         => 'ro',
    isa        => Str,
    init_arg   => 'warning',
    required   => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

WebService::Google::Closure::Type::Warning - Warning generated in compilation

=head1 ATTRIBUTES

=head2 $warning->type

Returns a string with the compiled javascript code.

=head2 $warning->file

Filename of the file that caused the warning

=head2 $warning->lineno

Line number that caused the warning

=head2 $warning->charno

Char number that caused the warning

=head2 $warning->text

The warning text

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Magnus Erixzon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
