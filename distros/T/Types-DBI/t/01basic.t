=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::DBI works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::Modern;
use Test::TypeTiny;

use Types::DBI -all;

import_ok(
	'Types::DBI',
	export    => [qw( Dbh )],
	export_ok => [qw( Sth is_Dbh is_Sth to_Dbh to_Sth assert_Dbh assert_Sth )],
);

my $Dbh_SQLite = object_ok(
	sub { Dbh['SQLite'] },
	'$Dbh_SQLite',
	isa => [qw( Type::Tiny )],
);

my $Dbh_PostgreSQL = object_ok(
	sub { Dbh['PostgreSQL'] },
	'$Dbh_PostgreSQL',
	isa => [qw( Type::Tiny )],
);

my $dbh = object_ok(
	sub { to_Dbh('dbi:SQLite:dbname=:memory:') },
	'$dbh',
	isa  => [qw( DBI::db )],
	can  => [qw( prepare )],
	more => sub {
		my $dbh = shift;
		should_pass($dbh, Dbh);
		should_pass($dbh, $Dbh_SQLite);
		should_fail($dbh, $Dbh_PostgreSQL);
		should_fail($dbh, Sth);
	},
);

$dbh->do('CREATE TABLE foo (id integer);');

my $sth = object_ok(
	sub { $dbh->prepare('SELECT * FROM foo') },
	'$sth',
	isa  => [qw( DBI::st )],
	can  => [qw( execute )],
	more => sub {
		my $sth = shift;
		should_fail($sth, Dbh);
		should_fail($sth, $Dbh_SQLite);
		should_fail($sth, $Dbh_PostgreSQL);
		should_pass($sth, Sth);
	},
);

done_testing;
