package Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2;

$Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2::VERSION   = '2.04';
$Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2::AUTHORITY = 'cpan:MANWAR';

use Moose::Role;
use Test::PostgreSQL::v2;

requires 'cleanup';

=head1 NAME

Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2 - Use Test::PostgreSQL::v2 as the database backend for Test::DBIx::Class

=head1 VERSION

Version 2.04

=head1 SYNOPSIS

In your test file:

    use Test::More;
    use Test::DBIx::Class {
        schema_class => 'MyApp::Schema',
        traits       => ['Testpostgresqlv2'],
        deploy_db    => 1,
    }, qw/:resultsets/;

    ok my $user = ResultSet('User')->create({ name => 'John' }), 'Created user';
    is $user->name, 'John', 'Name persisted correctly';

    done_testing;

=head1 DESCRIPTION

This L<Moose::Role> is a trait for L<Test::DBIx::Class::SchemaManager> that
transparently replaces the legacy C<Testpostgresql> trait. Instead of relying
on the aging L<Test::PostgreSQL> module, it spins up a temporary PostgreSQL
instance using L<Test::PostgreSQL::v2>, which is designed for modern Linux
environments (Ubuntu 22.04+, Debian Bookworm, and similar distributions) that
restrict writes to system socket directories such as C</var/run/postgresql>.

When the trait is activated via the C<traits> key in L<Test::DBIx::Class>'s
configuration hash, the schema manager calls C<get_default_connect_info>
during its own initialisation phase. This trait overrides that method to:

=over 4

=item 1.

Instantiate a L<Test::PostgreSQL::v2> object, which handles binary discovery,
temporary directory creation, C<initdb>, and process management automatically.

=item 2.

Store the live instance on the schema manager object so the PostgreSQL process
is kept alive for the entire duration of the test run.

=item 3.

Return a L<DBI>-compatible connection array-ref (DSN, username, password, and
attributes) for L<Test::DBIx::Class> to use when connecting to the schema.

=back

The temporary PostgreSQL instance, including all data files, configuration,
and logs, is automatically removed when the test process exits, because
L<Test::PostgreSQL::v2> uses L<File::Temp> with C<CLEANUP =E<gt> 1>.

=head1 INTEGRATION

=head2 Replacing the legacy Testpostgresql trait

If you are already using L<Test::DBIx::Class> with the C<Testpostgresql>
trait, migration is a one-line change:

    # Before
    traits => ['Testpostgresql'],

    # After
    traits => ['Testpostgresqlv2'],

No other changes to your test files are required.

=head2 Trait discovery

L<Test::DBIx::Class> maps trait names to packages by prepending
C<Test::DBIx::Class::SchemaManager::Trait::>. The trait name
C<Testpostgresqlv2> therefore resolves to this package. Ensure the file
is on Perl's C<@INC>, typically by placing it under C<lib/> in your
distribution or under C<t/lib/> for test-only use.

=head2 Passing extra options to Test::PostgreSQL::v2

The current implementation uses the default L<Test::PostgreSQL::v2>
constructor. If you need to customise the PostgreSQL instance (for example,
to bind to a specific port or host), subclass this trait and override
C<get_default_connect_info> accordingly.

=head1 METHODS

=head2 get_default_connect_info

    my $connect_info = $self->get_default_connect_info;

Called internally by L<Test::DBIx::Class::SchemaManager> during schema
initialisation. Starts a temporary PostgreSQL instance via
L<Test::PostgreSQL::v2> and returns a four-element array-ref suitable for
passing directly to L<DBI/connect>:

    [ $dsn, $user, $password, \%dbi_attributes ]

The C<AutoCommit> attribute is set to C<1> by default, matching the behaviour
expected by L<DBIx::Class>.

Dies with a descriptive message (including the content of
C<$Test::PostgreSQL::v2::errstr>) if the PostgreSQL instance cannot be
started.

B<Note:> This method is an extension point defined by
L<Test::DBIx::Class::SchemaManager>. It is not part of the public API of this
trait and should not be called directly from test code.

=cut

sub get_default_connect_info {
    my ($self) = @_;

    my $pg = Test::PostgreSQL::v2->new()
        or die "Could not start PostgreSQL: $Test::PostgreSQL::v2::errstr";

    # Stash on the object as a plain hash key — no Moose 'has' needed
    $self->{_pg} = $pg;

    return [ $pg->dsn, $pg->user, '', { AutoCommit => 1 } ];
};

after 'cleanup' => sub {
    my ($self) = @_;

    # Disconnect schema storage before PostgreSQL process is killed
    if ( $self->schema
      && $self->schema->storage
      && $self->schema->storage->connected ) {
        local $@;
        eval { $self->schema->storage->disconnect };
    }

    # Now safe to let the PostgreSQL instance go
    delete $self->{_pg};
};

=head1 DEPENDENCIES

=over 4

=item * L<Moose::Role>

Required to participate in the L<Test::DBIx::Class::SchemaManager> trait
composition system. L<Moose> is already a dependency of
L<Test::DBIx::Class>, so no additional installation is needed.

=item * L<Test::PostgreSQL::v2>

The modern PostgreSQL test instance manager that this trait wraps. Must be
installed separately. See L<Test::PostgreSQL::v2> for full prerequisites,
including a working PostgreSQL installation (C<initdb> and C<postgres>
binaries must be discoverable via C<$PATH> or C<POSTGRES_HOME>).

=item * L<DBD::Pg>

Required at runtime by L<DBIx::Class> to connect to the PostgreSQL instance.
Must be installed separately.

=back

=head1 SEE ALSO

=over 4

=item * L<Test::PostgreSQL::v2>

The backend module this trait wraps.

=item * L<Test::DBIx::Class>

The testing framework this trait integrates with.

=item * L<Test::DBIx::Class::SchemaManager::Trait::Testpostgresql>

The legacy trait this module replaces.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Test-PostgreSQL-v2>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Test-PostgreSQL-v2/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Test-PostgreSQL-v2/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-PostgreSQL-v2>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Test-PostgreSQL-v2/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::DBIx::Class::SchemaManager::Trait::Testpostgresqlv2
