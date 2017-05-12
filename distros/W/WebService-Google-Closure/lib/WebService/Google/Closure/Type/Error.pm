package WebService::Google::Closure::Type::Error;

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
    init_arg   => 'error',
    required   => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

WebService::Google::Closure::Type::Error - Error generated in compilation

=head1 ATTRIBUTES

=head2 $error->type

Returns a string with the compiled javascript code.

See L<http://code.google.com/closure/compiler/docs/api-ref.html#errors> for further information.

=head2 $error->file

Filename of the file that caused the error

=head2 $error->lineno

Line number that caused the error

=head2 $error->charno

Char number that caused the error

=head2 $error->text

The error text

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Magnus Erixzon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
