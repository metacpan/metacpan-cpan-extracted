# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile::DirHandle;

use strict;
use warnings;

our $VERSION = '0.032';

=head1 NAME

Test::MockFile::DirHandle - Provides a class object for
L<Test::MockFile> to give out for opendir calls.

=head1 VERSION

Version 0.032

=cut

=head1 SYNOPSIS

This is a helper class for L<Test::MockFile> its only purpose is to
provide a object to recognize that a the passed handle is a mocked
handle. L<Test::MockFile> has to mock the other calls since there is no
tie for B<opendir> handles.

    # This is what Test::MockFile does. You really shouldn't be doing it directly.
    use Test::MockFile::DirHandle;
    my $handle = Test::MockFile::DirHandle->new("/fake/path", [qw/. .. a bbb ccc dd/]);

=head1 EXPORT

No exports are provided by this module.

=head1 SUBROUTINES/METHODS

=head2 new

Args: ($class, $dir, $files_array_ref)

Returns a blessed object for Test::MockFile::DirHandle. There are no
error conditions handled here.

B<NOTE:> the permanent directory contents are stored in a hash in
Test::MockFile. However when opendir is called, a copy is stored here.
This is because through experimentation, we've determined that adding
files in a dir during a opendir/readdir does not affect the return of
readdir.

See L<Test::MockFile>.

=cut

sub new {
    my ( $class, $dir, $files_in_readdir ) = @_;

    return bless {
        files_in_readdir => $files_in_readdir,
        'dir'            => $dir,
        'tell'           => 0,
    }, $class;
}

=head1 AUTHOR

Todd Rinaldo, C<< <toddr at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/CpanelInc/Test-MockFile>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::MockFile::DirHandle

You can also look for information at:

=over 4

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-MockFile>

=item * Search CPAN

L<https://metacpan.org/release/Test-MockFile>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 cPanel L.L.C.

All rights reserved.

L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;
