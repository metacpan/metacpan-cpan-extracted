package Web::Session::MariaDB;

use strict;
use Web::Session::MariaDBJSON;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::MariaDBJSON);

# populate() is also called as a function
*populate = \&Web::Session::MariaDBJSON::populate;

1;
__END__

=head1 NAME

Web::Session::MariaDB - Alias of
L<Web::Session::MariaDBJSON>

=head1 SYNOPSIS

  use Web::Session::MariaDB;

  my $args = {
       DataSource => 'dbi:MariaDB:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       Commit     => 1,
  };

  tie %session, 'Web::Session::MariaDB', $id, $args;

=head1 DESCRIPTION

This module is an alias of L<Web::Session::MariaDBJSON>:
sessions are stored as JSON in a C<json> column, and indexes are built on
generated columns. See L<Web::Session::MariaDBJSON> for the
table, the indexes and the available options.

=head1 SEE ALSO

L<Web::Session::MariaDBJSON>, L<Web::Session>

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
