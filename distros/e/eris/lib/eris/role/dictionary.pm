package eris::role::dictionary;
# ABSTRACT: Interface for implementing a dictionary object

use Moo::Role;
use Types::Standard qw(Int Str);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


requires qw(lookup fields);
with qw(
    eris::role::plugin
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::dictionary - Interface for implementing a dictionary object

=head1 VERSION

version 0.008

=head1 INTERFACE

=head2 lookup()

Takes a field name, returns undef for not found or
a HashRef with the following keys:

    {
        field => 'field_name',
        description => 'This is what this field means to users',
    }

=head2 fields()

Returns the list of all fields in the dictionary.

=head1 SEE ALSO

L<eris::dictionary>, L<eris::role::plugin>, L<eris::dictionary::cee>,
L<eris::dictionary::eris>, L<eris::dictionary::syslog>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
