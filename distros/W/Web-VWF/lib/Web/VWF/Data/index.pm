package Web::VWF::Data::index;

# The database associated with the index template file

use strict;
use warnings;

use Database::Abstraction;

use version; our $VERSION = version->declare('0.004.1');

our @ISA = ('Database::Abstraction');

1;

=encoding utf8

=head1 NAME

Web::VWF::Data::index - The database behind the index page

=head1 VERSION

Version 0.004.1

=head1 DESCRIPTION

A L<Database::Abstraction> for the table C<index>: a file called F<index.csv>
(or F<.sql>, F<.xml>, ...) in the database directory, see C<databases> in
L<Web::VWF/CONFIGURATION>.  It has Database::Abstraction's defaults, so a CSV
file is separated by C<!> and keyed on the column C<entry>.  The example site's
is F<example/databases/index.csv>:

	entry!email
	bob!bob@example.com

L<Web::VWF::Display::index> reads the address of the person named by C<?person=>
with C<$index-E<gt>email({ entry =E<gt> $person })>.  A page is given this handle
as C<index>, see L<Web::VWF/CONFIGURATION>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
