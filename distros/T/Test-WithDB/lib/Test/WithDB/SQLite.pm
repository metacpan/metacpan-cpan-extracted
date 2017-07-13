package Test::WithDB::SQLite;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'Test::WithDB';

sub _read_config {
    my $self = shift;

    my $path = $self->{config_path};
    my $cfg0;
    if (-f $path) {
        require Config::IOD::Reader;
        $cfg0 = Config::IOD::Reader->new->read_file($path);
    } else {
        $cfg0 = {};
    }
    my $profile = $self->{config_profile} // 'GLOBAL';
    my $cfg = $cfg0->{$profile} // {};

    $cfg->{admin_dsn}  //= 'dbi:SQLite:';
    $cfg->{admin_user} //= '';
    $cfg->{admin_pass} //= '';

    $cfg->{user_dsn}  //= 'dbi:SQLite:';
    $cfg->{user_user} //= '';
    $cfg->{user_pass} //= '';

    $cfg->{sqlite_db_dir} //= do {
        require File::Temp;
        File::Temp::tempdir(CLEANUP=>$ENV{TWDB_KEEP_TEMP_DBS} ? 0:1);
    };

    Test::More::note("Will be creating test SQLite databases in '$cfg->{sqlite_db_dir}'");

    $self->{_config} = $cfg;
}

1;
# ABSTRACT: A subclass of Test::WithDB that provide defaults for SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::WithDB::SQLite - A subclass of Test::WithDB that provide defaults for SQLite

=head1 VERSION

This document describes version 0.09 of Test::WithDB::SQLite (from Perl distribution Test-WithDB), released on 2017-07-10.

=head1 SYNOPSIS

In your test file:

 use Test::More;
 use Test::WithDB::SQLite;

 my $twdb = Test::WithDB::SQLite->new;

 my $dbh = $twdb->create_db; # create db with random name

 # do stuffs with dbh

 my $dbh2 = $twdb->create_db; # create another db

 # do more stuffs

 $twdb->done; # will drop all created databases, unless tests are not passing

=head1 DESCRIPTION

This subclass of L<Test::WithDB> creates a convenience for use with SQLite.
Config file is not required, and by default SQLite databases will be created in
a temporary directory.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-WithDB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-WithDB>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-WithDB>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Test::WithDB>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
