package Test::DirectoryLayout;
$Test::DirectoryLayout::VERSION = '0.001';

#ABSTRACT: Test directory layout for standard compliance

use strict;
use warnings;

use base qw(Test::Builder::Module);
our @EXPORT = qw(directory_layout_ok get_allowed_dirs set_allowed_dirs);

my @diags;
my $CLASS  = __PACKAGE__;
my $Tester = $CLASS->builder;

{
    my @allowed_dirs = qw(bin blib lib config doc t);

    sub get_allowed_dirs {
        return \@allowed_dirs;
    }

    sub set_allowed_dirs {
        my ($dirs) = @_;
        @allowed_dirs = @$dirs;
    }
}

sub directory_layout_ok {
    my ($dir) = @_;
    $dir = '.' unless $dir;

    # clean up diagnostics from prior tests
    undef @diags;

    my $description    = 'directory layout';
    my $directories_ok = _directories_ok($dir);

    $Tester->ok( $directories_ok, $description );
    unless ($directories_ok) {
        unshift @diags, "Found the following problems:";
        $Tester->diag( join( "\n  ", @diags ) );
    }

    return $directories_ok;
}

sub _directories_ok {
    my ($dir) = @_;

    my $ok           = 1;
    my $allowed_dirs = get_allowed_dirs;

    opendir( my $dh, $dir ) || die "Can't opendir $dir: $!";
    my @dirs = grep { !/^\./ && -d "$dir/$_" } readdir($dh);
    closedir $dh;
    for my $dir (@dirs) {
        my $allowed = grep ( /^$dir$/, @$allowed_dirs );
        unless ($allowed) {
            $ok = 0;
            push @diags, qq{Directory '$dir' is not allowed};
        }
    }
    return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DirectoryLayout - Test directory layout for standard compliance

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Test::DirectoryLayout;

    directory_layout_ok();

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 get_allowed_dirs

Returns reference to the list of allowed directories.

=head2 set_allowed_dirs($dirs)

Set list of allowed directories to the provided list. The contents
of the list are copied.

=head2 directory_layout_ok ($dir)

Tests if the provided directory contains only allowed directories.

If no name is provided the current directory is assumed.

=over 4

=item B<directory_layout_ok>

=back

=head1 SEE ALSO

=over 4

=item L<Test::Dir> for testing several attributes of a single directory.

=item L<Test::Dirs> for comparing a directory with an existing directory.

=item L<Test::Directory> for testing if creating and deleting
files and directories was performed as expected.

=back

=head1 AUTHOR

Gregor Goldbach <grg@perlservices.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
