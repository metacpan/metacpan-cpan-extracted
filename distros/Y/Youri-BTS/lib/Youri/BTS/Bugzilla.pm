# $Id: /mirror/youri/soft/BTS/trunk/lib/Youri/BTS/Bugzilla.pm 2347 2007-04-10T14:55:21.041566Z guillomovitch  $
package Youri::BTS::Bugzilla;

=head1 NAME

Youri::BTS::Bugzilla - Youri Bugzilla interface

=head1 SYNOPSIS

    use Youri::BTS::Bugzilla;

    my $bugzilla = Youri::BTS::Bugzilla->new();

    print $bugzilla->get_maintainer('foobar');

=head1 DESCRIPTION

This module implement a Bugzilla interface for managing packages.

The legacy Bugzilla database model is mapped this way:

=over

=item *

a maintainer is a user

=item *

a package is a product

=item *

each package has two pseudo components "program" and "package", owned by the
package maintainer

=back

=cut

use Carp;
use strict;
use warnings;
use version; our $VERSION = qv('0.1.1');

my %queries = (
    get_package_id    => 'SELECT id FROM products WHERE name = ?',
    get_maintainer_id => 'SELECT userid FROM profiles WHERE login_name = ?',
    get_versions      => 'SELECT value FROM versions WHERE product_id = ?',
    get_components    => 'SELECT name FROM components WHERE product_id = ?',
    add_package       => 'INSERT INTO products (name, description, defaultmilestone) VALUES (?, ?, ?)',
    add_component     => 'INSERT INTO components (product_id, name, description,initialowner, initialqacontact) VALUES (?, ?, ?, ?, ?)',
    add_version       => 'INSERT INTO versions (product_id, value) VALUES (?, ?)',
    add_milestone     => 'INSERT INTO milestones (product_id, value) VALUES (?, ?)',
    del_package       => 'DELETE FROM products WHERE product = ?',
    del_maintainer    => 'DELETE FROM profiles WHERE login_name = ?',
    del_components    => 'DELETE FROM components WHERE program = ?',
    del_versions      => 'DELETE FROM versions WHERE program = ?',
    browse_packages => <<EOF,
SELECT products.name, max(versions.value), login_name
FROM products, versions, profiles, components
WHERE versions.product_id = products.id
    AND components.product_id = products.id
    AND profiles.userid = components.initialowner
    AND components.name = 'package'
GROUP BY name
EOF
    get_maintainer => <<EOF
SELECT login_name
FROM profiles, components, products
WHERE profiles.userid = components.initialowner
    AND components.name = 'package' 
    AND components.product_id = products.id
    AND products.name = ?
EOF
);

=head1 CLASS METHODS

Except stated otherwise, maintainers are specified by their login, and packages
are specified by their name.

=head2 new(%args)

Creates a new Youri::Bugzilla object.

Parameters:

=over

=item lib $lib

Bugzilla library directory (default: /usr/share/bugzilla/lib).

=item project $project

Bugzilla project.

=back

=cut

sub new {
    my $class   = shift;
    my %options = (
        lib     => '/usr/share/buzilla/lib',
        project => undef,
        @_
    );

    # protect ENV against bugzilla cleanup
    local %ENV = %ENV;

    $ENV{PROJECT} = $options{project} if $options{project};
    push(@INC, $options{lib});
     
    # require main module for configuration
    require Bugzilla;

    # require database module to shortcut caching in main module
    require Bugzilla::DB;
 
    my $self = bless {
	_dbh => Bugzilla::DB::connect_main()
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 has_package($package)

Return true if bugzilla contains given package.

=cut

sub has_package {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_package_id($package);
}

=head2 has_maintainer($maintainer)

Return true if bugzilla contains given maintainer.

=cut

sub has_maintainer {
    my ($self, $maintainer) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_maintainer_id($maintainer);
}

=head2 get_maintainer($package)

Return maintainer of given package.

=cut

sub get_maintainer {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_single('get_maintainer', $package);
}

=head2 get_versions($package)

Return versions from given package.

=cut

sub get_versions {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_multiple(
        'get_versions',
        $self->_get_package_id($package)
    );
}

=head2 get_components($package)

Return components from given package.

=cut

sub get_components {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_multiple(
        'get_components',
        $self->_get_package_id($package)
    );
}

=head2 get_packages()

Return all packages from the database.

=cut

sub get_packages {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->_get_multiple('get_packages');
}

sub _get_package_id {
    my ($self, $package) = @_;
    return $self->_get_single('get_package_id', $package);
}

sub _get_maintainer_id {
    my ($self, $maintainer) = @_;
    return $self->_get_single('get_maintainer_id', $maintainer);
}

sub _get_single {
    my ($self, $type, $value) = @_;

    my $query = $self->{_queries}->{$type};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{$type});
        $self->{_queries}->{$type} = $query;
    }

    $query->execute($value);

    my @row = $query->fetchrow_array();
    return @row ? $row[0]: undef;
}

sub _get_multiple {
    my ($self, $type, $value) = @_;

    my $query = $self->{_queries}->{$type};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{$type});
        $self->{_queries}->{$type} = $query;
    }

    $query->execute($value);

    my @results;
    while (my @row = $query->fetchrow_array()) {
        push @results, $row[0];
    }
    return @results;
}

=head2 add_package($name, $summary, $version, $maintainer, $contact)

Adds a new package in the database, with given name, summary, version,
maintainer and initial QA contact.

=cut

sub add_package {
    my ($self, $name, $summary, $version, $maintainer, $contact) = @_;
    croak "Not a class method" unless ref $self;

    my $maintainer_id  = $self->_get_maintainer_id($maintainer);
    unless ($maintainer_id) {
        carp "Unknown maintainer $maintainer, aborting";
        return;
    }

    my $contact_id  = $self->_get_maintainer_id($contact);
    unless ($contact_id) {
        carp "Unknown QA contact $contact, aborting";
        return;
    }

    my $milestone = '---';

    my $query = $self->{_queries}->{add_package};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{add_package});
        $self->{_queries}->{add_package} = $query;
    }

    $query->execute($name, $summary, $milestone);

    my $package_id  = $self->_get_package_id($name);

    $self->_add_version($package_id, $version);
    $self->_add_milestone($package_id, $milestone);
    $self->_add_component(
        $package_id,
        'package',
        'problem related to the package',
        $maintainer_id,
        $contact_id
    );
    $self->_add_component(
        $package_id,
        'program',
        'problem related to the program',
        $maintainer_id,
        $contact_id
    );
}

=head2 add_version($package, $version)

Adds a new version to given package.

=cut

sub add_version {
    my ($self, $package, $version) = @_;
    croak "Not a class method" unless ref $self;

    my $package_id  = $self->_get_package_id($package);
    $self->_add_version($package_id, $version);
}

sub _add_version {
    my ($self, $package_id, $version) = @_;

    my $query = $self->{_queries}->{add_version};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{add_version});
        $self->{_queries}->{add_version} = $query;
    }

    $query->execute($package_id, $version);
}

sub _add_milestone {
    my ($self, $package_id, $milestone) = @_;

    my $query = $self->{_queries}->{add_milestone};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{add_milestone});
        $self->{_queries}->{add_milestone} = $query;
    }

    $query->execute($package_id, $milestone);
}


=head2 add_maintainer($name, $login)

Adds a new maintainer in the database, with given name, login and password.

=cut

sub add_maintainer {
    my ($self, $name, $login) = @_;
    croak "Not a class method" unless ref $self;

    Bugzilla::User->create({
        login_name => $login, 
        realname   => $name,
        cryptpassword => '*'
    });
}

sub _add_component {
    my ($self, $package_id, $name, $description, $maintainer_id, $contact_id) = @_;

    my $query = $self->{_queries}->{add_component};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{add_component});
        $self->{_queries}->{add_component} = $query;
    }

    $query->execute($package_id, $name, $description, $maintainer_id, $contact_id);
}

=head2 del_package($package)

Delete given package from database.

=cut

sub del_package {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    $self->_delete('del_package', $package);
    $self->_delete('del_versions', $package);
    $self->_delete('del_components', $package);
}

=head2 del_maintainer($maintainer)

Delete given maintainer from database.

=cut

sub del_maintainer {
    my ($self, $maintainer) = @_;
    croak "Not a class method" unless ref $self;
    $self->_delete('del_maintainer', $maintainer);
}

sub _delete {
    my ($self, $type, $value) = @_;

    my $query = $self->{_queries}->{$type};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{$type});
        $self->{_queries}->{$type} = $query;
    }

    $query->execute($value);
}

=head2 browse_packages($callback)

Browse all packages from bugzilla, and execute given callback with name and
maintainer as argument for each of them.

=cut

sub browse_packages {
    my ($self, $callback) = @_;
    croak "Not a class method" unless ref $self;

    my $query = $self->{_queries}->{browse_packages};
    unless ($query) {
        $query = $self->{_dbh}->prepare($queries{browse_packages});
        $self->{_queries}->{browse_packages} = $query;
    }

    $query->execute();

    while (my @row = $query->fetchrow_array()) {
        $callback->(@row);
    }
}

# close database connection
sub DESTROY {
    my ($self) = @_;

    foreach my $query (values %{$self->{_queries}}) {
        $query->finish() if $query;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
