package Web::Session::MySQL;

use strict;
use Web::Session::MySQLJSON;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::MySQLJSON);

# populate() is also called as a function
*populate = \&Web::Session::MySQLJSON::populate;

1;
__END__

=head1 NAME

Web::Session::MySQL - Alias of
L<Web::Session::MySQLJSON>

=head1 SYNOPSIS

  use Web::Session::MySQL;

  my $args = {
       DataSource => 'dbi:mysql:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       Commit     => 1,
  };

  tie %session, 'Web::Session::MySQL', $id, $args;

=head1 DESCRIPTION

This module is an alias of L<Web::Session::MySQLJSON>: sessions
are stored as JSON in a C<json> column, and indexes are built on generated
columns. See L<Web::Session::MySQLJSON> for the table, the
indexes and the available options (and L<Web::Session::MariaDBJSON>
for MariaDB).

Previous versions stored each indexed field in its own column. A table created
for them is not compatible: create a new table as described in
L<Web::Session::MySQLJSON>, then copy the sessions, for example:

  INSERT INTO new_sessions (id, a_session)
    SELECT id, a_session FROM sessions WHERE JSON_VALID(a_session);

=head1 SEE ALSO

L<Web::Session::MySQLJSON>, L<Web::Session>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
