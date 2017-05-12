package WSST::Schema::Return;

use strict;
use base qw(WSST::Schema::Node);
__PACKAGE__->mk_accessors(qw(options page_total_entries page_current_page
                             page_entries_per_page));

use constant BOOL_FIELDS => qw(multiple nullable page_total_entries
                               page_current_page page_entries_per_page);

our $VERSION = '0.1.1';

=head1 NAME

WSST::Schema::Return - Schema::Return class of WSST

=head1 DESCRIPTION

This class represents the return element of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 options

Accessor for the options.

=head2 page_total_entries

Accessor for the page_total_entries.

=head2 page_current_page

Accessor for the page_current_page.

=head2 page_entries_per_page

Accessor for the page_entries_per_page.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
