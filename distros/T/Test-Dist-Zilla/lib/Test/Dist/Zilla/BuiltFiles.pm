#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Test/Dist/Zilla/BuiltFiles.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Test-Dist-Zilla.
#
#   perl-Test-Dist-Zilla is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Test-Dist-Zilla is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Test-Dist-Zilla. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =head1 DESCRIPTION
#pod
#pod This is a C<Test::Routine>-based role for testing C<Dist::Zilla> and its plugins. It is intended to
#pod be used in cooperation with C<Test::Dist::Zilla::Build> role. C<Test::Dist::Zilla::Build> builds
#pod the distribution and checks exception and build messages, while C<Test::Dist::Zilla::BuiltFiles>
#pod checks built files.
#pod
#pod =cut

package Test::Dist::Zilla::BuiltFiles;

use namespace::autoclean;
use strict;
use version 0.77;
use warnings;

# ABSTRACT: Check files built by your Dist::Zilla plugin
our $VERSION = 'v0.4.4'; # VERSION

use Test::Routine;

#~ requires qw{ tzil exception expected };

use Test::Deep qw{ cmp_deeply };
use Path::Tiny;
use Test::More;

# --------------------------------------------------------------------------------------------------

#pod =method BuiltFiles
#pod
#pod It is a test routine. It checks built files. Names of files to check should be be enlisted in
#pod C<files> key of C<expected> hash. Value should be C<HashRef>, keys are filenames, values are file
#pod content. For every file the test routine checks the file exists and its actual content matches the
#pod expected content. If expected content is C<undef>, the file should not exist.
#pod
#pod File content may be specified either by C<Str> or by C<ArrayRef>:
#pod
#pod     run_me {
#pod         …
#pod         expected => {
#pod             files => {
#pod                 'filename1' => "line1\nline2\n",
#pod                 'filename2' => [
#pod                     'line1',            # Should not include newline character.
#pod                     'line2',
#pod                     re( '^#' ),         # See "Special Comparisons" in Test::Deep.
#pod                 ],
#pod                 'filename3' => undef,   # This file should not exist.
#pod             },
#pod         },
#pod     };
#pod
#pod Actual file content is compared with expected file content by C<cmp_deeply> routine from
#pod C<Test::Deep>.
#pod
#pod C<BuiltFiles> assumes successful build. If an exception occurred, C<BuiltFiles> skips all the
#pod checks.
#pod
#pod =cut

test 'BuiltFiles' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( not exists( $expected->{ files } ) ) {
        plan skip_all => 'no expected files specified';
    };
    $self->skip_if_exception();
    my @names = keys( %{ $expected->{ files } } );          # Name of files to check.
    my $built_in = path( $self->tzil->built_in );           # Build directory.
    for my $name ( @names ) {
        my $exp  = $expected->{ files }->{ $name };         # Expected content.
        my $file = $built_in->child( $name );               # Actual file.
        if ( defined( $exp ) ) {
            ok( $file->exists, "$name exists" ) and do {
                my $act = ref( $exp ) eq 'ARRAY' ? (
                    #   `$file->lines_utf8( { chomp => 1 } )` does not work as expected in
                    #   `Path::Tiny` 0.068 .. 0.072 (at least), see
                    #   <https://github.com/dagolden/Path-Tiny/issues/152>.
                    #   To workaround the problem, `chomp` lines manually.
                    [ do { my @l = $file->lines_utf8(); chomp( @l ); @l; } ]
                ) : (
                    $file->slurp_utf8()
                );
                cmp_deeply( $act, $exp, "$name content" ) or do {
                    $self->_anno_text( $name, ref( $act ) ? @$act : $act );
                };
            };
        } else {
            ok( ! $file->exists, "$name not exist" );
        };
    };
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SYNOPSIS
#pod
#pod
#pod
#pod     # Let's test Manifest Dist::Zilla plugin:
#pod
#pod     use strict;
#pod     use warnings;
#pod
#pod     use Test::Deep qw{ re };
#pod     use Test::More;
#pod     use Test::Routine;
#pod     use Test::Routine::Util;
#pod
#pod     with 'Test::Dist::Zilla::Build';
#pod     with 'Test::Dist::Zilla::BuiltFiles';
#pod
#pod     run_me 'A test' => {
#pod         plugins => [
#pod             'GatherDir',
#pod             'Manifest',
#pod             'MetaJSON',
#pod         ],
#pod         files => {
#pod             'lib/Dummy.pm' => 'package Dummy; 1;',
#pod         },
#pod         expected => {
#pod             files => {
#pod                 'MANIFEST' => [
#pod                     re( qr{^# This file was } ),
#pod                     'MANIFEST',
#pod                     'META.json',
#pod                     'dist.ini',
#pod                     'lib/Dummy.pm',
#pod                 ],
#pod             },
#pod         },
#pod     };
#pod
#pod     done_testing;
#pod
#pod
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Test::Dist::Zilla>
#pod = L<Test::Dist::Zilla::Build>
#pod = L<Test::Deep/"$ok = cmp_deeply($got, $expected, $name)">
#pod = L<Test::Routine>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Dist::Zilla::BuiltFiles - Check files built by your Dist::Zilla plugin

=head1 VERSION

Version v0.4.4, released on 2016-12-28 19:48 UTC.

=head1 SYNOPSIS

    # Let's test Manifest Dist::Zilla plugin:

    use strict;
    use warnings;

    use Test::Deep qw{ re };
    use Test::More;
    use Test::Routine;
    use Test::Routine::Util;

    with 'Test::Dist::Zilla::Build';
    with 'Test::Dist::Zilla::BuiltFiles';

    run_me 'A test' => {
        plugins => [
            'GatherDir',
            'Manifest',
            'MetaJSON',
        ],
        files => {
            'lib/Dummy.pm' => 'package Dummy; 1;',
        },
        expected => {
            files => {
                'MANIFEST' => [
                    re( qr{^# This file was } ),
                    'MANIFEST',
                    'META.json',
                    'dist.ini',
                    'lib/Dummy.pm',
                ],
            },
        },
    };

    done_testing;

=head1 DESCRIPTION

This is a C<Test::Routine>-based role for testing C<Dist::Zilla> and its plugins. It is intended to
be used in cooperation with C<Test::Dist::Zilla::Build> role. C<Test::Dist::Zilla::Build> builds
the distribution and checks exception and build messages, while C<Test::Dist::Zilla::BuiltFiles>
checks built files.

=head1 OBJECT METHODS

=head2 BuiltFiles

It is a test routine. It checks built files. Names of files to check should be be enlisted in
C<files> key of C<expected> hash. Value should be C<HashRef>, keys are filenames, values are file
content. For every file the test routine checks the file exists and its actual content matches the
expected content. If expected content is C<undef>, the file should not exist.

File content may be specified either by C<Str> or by C<ArrayRef>:

    run_me {
        …
        expected => {
            files => {
                'filename1' => "line1\nline2\n",
                'filename2' => [
                    'line1',            # Should not include newline character.
                    'line2',
                    re( '^#' ),         # See "Special Comparisons" in Test::Deep.
                ],
                'filename3' => undef,   # This file should not exist.
            },
        },
    };

Actual file content is compared with expected file content by C<cmp_deeply> routine from
C<Test::Deep>.

C<BuiltFiles> assumes successful build. If an exception occurred, C<BuiltFiles> skips all the
checks.

=head1 SEE ALSO

=over 4

=item L<Test::Dist::Zilla>

=item L<Test::Dist::Zilla::Build>

=item L<Test::Deep/"$ok = cmp_deeply($got, $expected, $name)">

=item L<Test::Routine>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
