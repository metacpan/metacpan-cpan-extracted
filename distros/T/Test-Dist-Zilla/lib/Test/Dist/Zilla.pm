#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Test/Dist/Zilla.pm
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

#pod =head1 SYNOPSIS
#pod
#pod     package Test::Dist::Zilla::Build;
#pod
#pod     use namespace::autoclean;
#pod     use Test::Routine;
#pod     use Test::Deep qw{ cmp_deeply };
#pod
#pod     with 'Test::Dist::Zilla';
#pod
#pod     test 'Build' => sub {
#pod         my ( $self ) = @_;
#pod         my $expected = $self->expected;
#pod         $self->build();
#pod         cmp_deeply( $self->exception, $expected->{ exception } );
#pod         if ( exists( $expected->{ messages } ) ) {
#pod             cmp_deeply( $self->messages, $expected->{ messages } );
#pod         };
#pod     };
#pod
#pod     1;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a C<Test::Routine>-based role. It does not provide any test routines, but it establishes
#pod infrastructure for writing tests on C<Dist::Zilla> and its plugins. A test written with
#pod C<Test::Dist::Zila> does not require external source files (which are usually placed into
#pod F<corpus/> directory) — all the source files (including F<dist.ini>) for the test are generated
#pod on-the-fly in a temporary directory.
#pod
#pod The role is not intended to be used directly in tests. Instead, it serves as a base for other more
#pod specific roles, for example, C<Test::Dist::Zilla::Build>.
#pod
#pod =cut

package Test::Dist::Zilla;

use namespace::autoclean;
use strict;
use utf8;
use version 0.77;
use warnings;

# ABSTRACT: Test your Dist::Zilla plugin
our $VERSION = 'v0.4.4'; # VERSION

use Dist::Zilla::Tester::DieHard v0.6.0;    # `Survivor` should have `tempdir_obj` attribute.
use File::Temp qw{ tempdir };
use Test::DZil qw{ dist_ini };
use Test::More;
use Test::Routine;
use Try::Tiny;

## REQUIRE: Software::License::Perl_5
## REQUIRE: Moose 2.0800
    # ^ Test will likely fail with older Moose.
    #   Starting from 2.0800 "Roles can now override methods from other roles…".

# --------------------------------------------------------------------------------------------------

#pod =variable $Cleanup
#pod
#pod C<Dist::Zilla::Tester> creates distribution source and build directories in a temporary directory,
#pod and then unconditionally cleans it up. Sometimes (especially in case of test failure) such behavior
#pod may be not desirable — you may want to look at source or built files for troubleshooting purposes.
#pod
#pod C<Test::Dist::Zilla> provides control over temporary directory via C<$Test::Dist::Zilla::Cleanup>
#pod package variable:
#pod
#pod =over
#pod
#pod =item C<0>
#pod
#pod Never clean up temporary directory.
#pod
#pod =item C<1>
#pod
#pod Clean up temporary directory only if the test is passed (it is default).
#pod
#pod =item C<2>
#pod
#pod Always clean up temporary directory.
#pod
#pod =back
#pod
#pod If temporary directory is going to remain, the test output will contain diagnostic message like
#pod this one:
#pod
#pod     # tempdir: tmp/AKrvBhhM4M
#pod
#pod to help you identify the temporary directory created for the test.
#pod
#pod Note: Controlling temporary directory requires C<Dist::Zilla> 5.021 or newer.
#pod
#pod =cut

our $Cleanup = 1;                       ## no critic ( ProhibitPackageVars )

# --------------------------------------------------------------------------------------------------

#pod =attr C<dist>
#pod
#pod Hash of distribution options: C<name>, C<version> C<abstract>, etc. to write to the test's
#pod F<dist.ini>. This attribute is passed to C<dist_ini> as C<\%root_config> argument, see
#pod L<Test::DZil/"dist_ini">.
#pod
#pod C<HashRef>. Default value can be overridden by defining C<_build_dist> builder.
#pod
#pod Examples:
#pod
#pod     sub _build_dist { {
#pod         name     => 'Assa',
#pod         version  => '0.007',
#pod         author   => 'John Doe',
#pod         ...
#pod     } };
#pod
#pod     run_me {
#pod         dist => {
#pod             name     => 'Shooba',
#pod             version  => 'v0.7.0',
#pod             author   => 'John Doe, Jr.',
#pod             ...
#pod         },
#pod         ...
#pod     };
#pod
#pod TODO: Merge specified keys into default?
#pod
#pod =cut

has dist => (
    isa         => 'HashRef',
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_dist',
);

sub _build_dist {
    return {
        name                => 'Dummy',
        version             => '0.003',
        abstract            => 'Dummy abstract',
        author              => 'John Doe',
        license             => 'Perl_5',
        copyright_holder    => 'John Doe',
        copyright_year      => '2007',
    };
};

# --------------------------------------------------------------------------------------------------

#pod =attr C<plugins>
#pod
#pod Plugin configuration to write to the test's F<dist.ini>. Attribute is passed to C<dist_ini> as
#pod C<@plugins> argument, see L<Test::DZil/"dist_ini">.
#pod
#pod C<ArrayRef>, optional. Default value is empty array (i. e. no plugins), it can be overridden by
#pod defining C<_build_plugins> builder.
#pod
#pod Examples:
#pod
#pod     sub _build_plugin { [
#pod         'GatherDir',
#pod         'Manifest',
#pod         'MetaJSON',
#pod     ] };
#pod
#pod     run_me {
#pod         plugins => [
#pod             'GatherDir',
#pod             [ 'PodWeaver' => {
#pod                 'replacer' => 'replace_with_comment',
#pod             } ],
#pod         ],
#pod         ...
#pod     };
#pod
#pod =cut

has plugins => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy        => 1,
    builder     => '_build_plugins',
);

sub _build_plugins {
    return [];
};

# --------------------------------------------------------------------------------------------------

#pod =attr C<files>
#pod
#pod Hash of source files to add to the test's distribution source. Keys are file names, values are file
#pod contents. A file content may be specified by a (possibly multi-line) string or by array of lines
#pod (newlines are optional and will be appended if missed).
#pod
#pod Note: Explicitly specified F<dist.ini> file overrides C<dist> and C<plugins> attributes.
#pod
#pod C<HashRef>, optional, default value is empty hash (i. e. no files).
#pod
#pod Examples:
#pod
#pod     sub _build_files { {
#pod         'lib/Assa.pm' => [
#pod             'package Assa;',
#pod             '# VERSION',
#pod             '1;',
#pod         ],
#pod         'Changes'  => "Release history for Dist-Zilla-Plugin-Assa\n\n",
#pod         'MANIFEST' => [ qw{ lib/Assa.pm Changes MANIFEST } ],
#pod     } };
#pod
#pod     run_me {
#pod         files => {
#pod             'lib/Assa.pod' => [ ... ],
#pod             ...
#pod         },
#pod         ...
#pod     };
#pod
#pod =cut

has files => (
    is          => 'ro',
    isa         => 'HashRef[Str|ArrayRef]',
    lazy        => 1,
    builder     => '_build_files',
);

sub _build_files {
    return {};
};

# --------------------------------------------------------------------------------------------------

#pod =attr C<tzil>
#pod
#pod Test-enabled C<Dist::Zilla> instance (or C<DieHard> "survivor" object, if C<Dist::Zilla>
#pod constructing fails).
#pod
#pod By default C<Dist::Zilla> instance is created by calling C<< Builder->from_config( ... ) >> with
#pod appropriate arguments. Thanks to C<Dist::Zilla::Tester::DieHard>, it is never dies even if
#pod constructing fails, so C<< $self->tzil->log_message >> returns the log messages anyway.
#pod
#pod Note: Avoid calling C<build> and C<release> on C<tzil>:
#pod
#pod     $self->tzil->build();       # NOT recommended
#pod     $self->tzil->release();     # NOT recommended
#pod
#pod Call C<build> and C<release> directly on C<$self> instead:
#pod
#pod     $self->build();             # recommended
#pod     $self->release();           # recommended
#pod
#pod See C<build> and C<release> method descriptions for difference.
#pod
#pod Examples:
#pod
#pod     use Path::Tiny;
#pod     test 'Check META.json' => sub {
#pod         my ( $self ) = @_;
#pod         $self->skip_if_exception();
#pod         my $built_in = path( $self->tzil->built_in );
#pod         my $json = $built_in->child( 'META.json' )->slurp_utf8;
#pod         cmp_deeply( $json, $self->expected->{ json } );
#pod     };
#pod
#pod =cut

has tzil => (
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    builder     => '_build_tzil',
    init_arg    => undef,
    handles     => [ qw{ build release } ],
);

sub _build_tzil {
    my ( $self ) = @_;
    my $files = $self->files;
    my $tzil = Builder->from_config(
        {
            dist_root => tempdir( CLEANUP => 1 ),
                #   `Dist::Zilla::Tester::_Builder` copies all the files from `dist_root` directory
                #   to the source directory. We do not have any prepared files, but have to specify
                #   `dist_root` option because `Dist::Zilla::Tester::_Builder` requires it. Let us
                #   specify a temporary empty directory.
        },
        {
            add_files => {
                'source/dist.ini' => dist_ini(
                    $self->dist,
                    @{ $self->plugins },
                ),
                map(
                    { (
                        "source/$_" =>
                            ref ( $files->{ $_ } ) ? (
                                join(
                                    '',
                                    map(
                                        { ( my $r = $_ ) =~ s{(?<!\n)\z}{\n}x; $r }
                                        @{ $files->{ $_ } }
                                    )
                                )
                            ) : (
                                $files->{ $_ }
                            )
                    ) }
                    keys( %$files ),
                ),
            },
        },
    );
    return $tzil;
};

# --------------------------------------------------------------------------------------------------

#pod =method C<build>
#pod
#pod =method C<release>
#pod
#pod The methods call same-name method on C<tzil>, catch exception if any thrown, and save the caught
#pod exception in the C<exception> attribute for further analysis.
#pod
#pod Avoid calling these methods on C<tzil> — some tests may rely on method modifiers, which are
#pod applicable to C<< $self->I<method>() >> but not to C<< $self->tzil->I<method>() >>.
#pod
#pod Examples:
#pod
#pod     test Build => sub {
#pod         my ( $self ) = @_;
#pod         $self->build();     # == dzil build
#pod         ...
#pod     };
#pod
#pod     test Release => sub {
#pod         my ( $self ) = @_;
#pod         $self->release();   # == dzil release
#pod         ...
#pod     };
#pod
#pod =cut

around [ qw{ build release } ] => sub {
    my ( $orig, $self, @args ) = @_;
    my $ret;
    try {
        $ret = $self->$orig( @args );
    } catch {
        $self->_set_exception( $_ );
    };
    return $ret;
};

# --------------------------------------------------------------------------------------------------

#pod =attr C<exception>
#pod
#pod Exception occurred, or C<undef> is no exception was occurred.
#pod
#pod     test 'Post-build' => sub {
#pod         my ( $self ) = @_;
#pod         cmp_deeply( $self->exception, $self->expected->{ exception } );
#pod         ...
#pod     };
#pod
#pod =cut

has exception => (
    is          => 'ro',
    writer      => '_set_exception',
    init_arg    => undef,
);

# --------------------------------------------------------------------------------------------------

#pod =attr C<expected>
#pod
#pod A hash of expected outcomes. C<Test::Dist::Zilla> itself does not use this attribute, but more
#pod specific roles may do. For example, C<Test::Dizt::Zilla::Build> uses C<exception> and C<messages>
#pod keys, C<Test::Dizt::Zilla::BuiltFiles> uses C<files> key.
#pod
#pod C<HashRef>, required.
#pod
#pod Examples:
#pod
#pod     run_me {
#pod         ...,
#pod         expected => {
#pod             exception => "Aborting...\n",
#pod             messages  => [
#pod                 '[Plugin] Oops, something goes wrong...',
#pod             ],
#pod         },
#pod     };
#pod
#pod =cut

has expected => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

# --------------------------------------------------------------------------------------------------

#pod =method C<messages>
#pod
#pod This method is assumed to return C<ArrayRef> of C<Dist::Zilla> log messages. It may be complete log
#pod as it is or not — the method may filter out and/or edit actual messages to make them more suitable
#pod for comparing with expected messages.
#pod
#pod Default implementation filters the actual messages with the C<message_filter> (if it is defined).
#pod If default behaviour is not suitable, the method can be overridden.
#pod
#pod Examples:
#pod
#pod     cmp_deeply( $self->messages, $self->expected->{ messages } );
#pod
#pod =cut

sub messages {
    my ( $self ) = @_;
    my @messages = @{ $self->tzil->log_messages };
    if ( my $filter = $self->message_filter ) {
        @messages = $filter->( @messages );
    };
    return \@messages;
};

# --------------------------------------------------------------------------------------------------

#pod =attr C<message_filter>
#pod
#pod If C<message_filter> is defined, it is used by default C<messages> implementation to filter the
#pod actual log messages. C<message_filter> function is called once with list of all the log messages.
#pod The function is expected to return a list of messages (possibly, grepped and/or edited).
#pod
#pod Note: C<message_filter> value is a function, not method — C<messages> method does not pass C<$self>
#pod reference to the C<message_filter>.
#pod
#pod If C<messages> method is overridden, the attribute may be used or ignored — it depends on new
#pod C<messages> implementation.
#pod
#pod C<Maybe[CodeRef]>, optional. There is no default message filter — C<messages> method returns all
#pod the messages intact. Default message filter may be set by defining C<_build_message_filter>
#pod builder.
#pod
#pod Examples:
#pod
#pod Pass messages only from C<Manifest> plugin and filter out all other messages:
#pod
#pod     sub _build_message_filter {
#pod         sub { grep( { $_ =~ m{^\[Manifest\] } ) @_ ) };
#pod     };
#pod
#pod Drop plugin names from messages:
#pod
#pod     run_me {
#pod         message_filter => sub { map( { $_ =~ s{^\[.*?\] }{}r ) @_ ) },
#pod         ...
#pod     };
#pod
#pod =cut

has message_filter => (
    is          => 'ro',
    isa         => 'Maybe[CodeRef]',
    lazy        => 1,
    builder     => '_build_message_filter',
);

sub _build_message_filter {
    return undef;                       ## no critic ( ProhibitExplicitReturnUndef )
};

# --------------------------------------------------------------------------------------------------

#pod =method skip_if_exception
#pod
#pod This convenience method makes test routines a bit shorter. Instead of writing
#pod
#pod     if ( defined( $self->exception ) ) {
#pod         plan skip_all => 'exception occurred';
#pod     };
#pod
#pod you can write just
#pod
#pod     $self->skip_if_exception;
#pod
#pod =cut

sub skip_if_exception {
    my ( $self ) = @_;
    if ( defined( $self->exception ) ) {
        plan skip_all => 'exception occurred';
    };
    return;
};

# --------------------------------------------------------------------------------------------------

# This stuff is not settled down yet.

has _annotation => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

after run_test => sub {
    my ( $self ) = @_;
    require Test::Builder;
    my $tb = Test::Builder->new();
    if ( not $tb->is_passing and $self->_annotation ne '' ) {
        ( my $annotation = $self->_annotation ) =~ s{^}{| }gmx;
        $tb->diag( $annotation );
        $self->{ _annotation } = '';
    };
    # Manage temporary directory:
    if ( $Cleanup < 2 ) {
        if ( $self->tzil->can( 'tempdir_obj' ) ) {
            if ( my $tempdir = $self->tzil->tempdir_obj ) {
                # `tzil` could be `Survivor` which does not have temp dir (`tempdir_obj` returns
                # `undef`).
                my $cleanup = $Cleanup;
                if ( $cleanup == 1 ) {
                    $cleanup = $tb->is_passing;
                };
                if ( not $cleanup ) {
                    diag( "tempdir: $tempdir" );
                    $tempdir->unlink_on_destroy( $cleanup );
                };
            };
        } else {
            require Dist::Zilla;
            diag(
                "You are running Dist::Zilla $Dist::Zilla::VERSION. Temporary directory will be " .
                "unconditionally cleaned up, because Test::Zilla::Tester::_Builder does not have " .
                "tempdir_obj attribute. " .
                "(tempdir_obj attribute appeared in Dist::Zilla::Tester::_Builder 5.021.)"
            );
            $Cleanup = 2;   # Avoid printing the message again and again.
        };
    };
};

# --------------------------------------------------------------------------------------------------

sub _anno_line {
    my ( $self, $line ) = @_;
    $line =~ s{(?<!\n)\z}{\n}x;
    $self->{ _annotation } .= $line;
    return;
};

# --------------------------------------------------------------------------------------------------

sub _anno_text {
    my ( $self, $heading, @lines ) = @_;
    my $width = length( @lines + 0 );
    if ( @lines ) {
        $self->_anno_line( sprintf( '%s:', $heading ) );
        my $n = 0;
        for my $line ( @lines ) {
            ++ $n;
            $self->_anno_line( sprintf( "    %*d: %s", $width, $n, $line ) );
        };
    } else {
        $self->_anno_line( sprintf( '%s: %s', $heading, '(empty)' ) );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Test::Dist::Zilla::Build>
#pod = L<Test::Dist::Zilla::BuiltFiles>
#pod = L<Test::Dist::Zilla::Release>
#pod = L<Test::Routine>
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Tester::DieHard>
#pod = L<Test::DZil/"dist_ini">
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

Test::Dist::Zilla - Test your Dist::Zilla plugin

=head1 VERSION

Version v0.4.4, released on 2016-12-28 19:48 UTC.

=head1 SYNOPSIS

    package Test::Dist::Zilla::Build;

    use namespace::autoclean;
    use Test::Routine;
    use Test::Deep qw{ cmp_deeply };

    with 'Test::Dist::Zilla';

    test 'Build' => sub {
        my ( $self ) = @_;
        my $expected = $self->expected;
        $self->build();
        cmp_deeply( $self->exception, $expected->{ exception } );
        if ( exists( $expected->{ messages } ) ) {
            cmp_deeply( $self->messages, $expected->{ messages } );
        };
    };

    1;

=head1 DESCRIPTION

This is a C<Test::Routine>-based role. It does not provide any test routines, but it establishes
infrastructure for writing tests on C<Dist::Zilla> and its plugins. A test written with
C<Test::Dist::Zila> does not require external source files (which are usually placed into
F<corpus/> directory) — all the source files (including F<dist.ini>) for the test are generated
on-the-fly in a temporary directory.

The role is not intended to be used directly in tests. Instead, it serves as a base for other more
specific roles, for example, C<Test::Dist::Zilla::Build>.

=head1 OBJECT ATTRIBUTES

=head2 C<dist>

Hash of distribution options: C<name>, C<version> C<abstract>, etc. to write to the test's
F<dist.ini>. This attribute is passed to C<dist_ini> as C<\%root_config> argument, see
L<Test::DZil/"dist_ini">.

C<HashRef>. Default value can be overridden by defining C<_build_dist> builder.

Examples:

    sub _build_dist { {
        name     => 'Assa',
        version  => '0.007',
        author   => 'John Doe',
        ...
    } };

    run_me {
        dist => {
            name     => 'Shooba',
            version  => 'v0.7.0',
            author   => 'John Doe, Jr.',
            ...
        },
        ...
    };

TODO: Merge specified keys into default?

=head2 C<plugins>

Plugin configuration to write to the test's F<dist.ini>. Attribute is passed to C<dist_ini> as
C<@plugins> argument, see L<Test::DZil/"dist_ini">.

C<ArrayRef>, optional. Default value is empty array (i. e. no plugins), it can be overridden by
defining C<_build_plugins> builder.

Examples:

    sub _build_plugin { [
        'GatherDir',
        'Manifest',
        'MetaJSON',
    ] };

    run_me {
        plugins => [
            'GatherDir',
            [ 'PodWeaver' => {
                'replacer' => 'replace_with_comment',
            } ],
        ],
        ...
    };

=head2 C<files>

Hash of source files to add to the test's distribution source. Keys are file names, values are file
contents. A file content may be specified by a (possibly multi-line) string or by array of lines
(newlines are optional and will be appended if missed).

Note: Explicitly specified F<dist.ini> file overrides C<dist> and C<plugins> attributes.

C<HashRef>, optional, default value is empty hash (i. e. no files).

Examples:

    sub _build_files { {
        'lib/Assa.pm' => [
            'package Assa;',
            '# VERSION',
            '1;',
        ],
        'Changes'  => "Release history for Dist-Zilla-Plugin-Assa\n\n",
        'MANIFEST' => [ qw{ lib/Assa.pm Changes MANIFEST } ],
    } };

    run_me {
        files => {
            'lib/Assa.pod' => [ ... ],
            ...
        },
        ...
    };

=head2 C<tzil>

Test-enabled C<Dist::Zilla> instance (or C<DieHard> "survivor" object, if C<Dist::Zilla>
constructing fails).

By default C<Dist::Zilla> instance is created by calling C<< Builder->from_config( ... ) >> with
appropriate arguments. Thanks to C<Dist::Zilla::Tester::DieHard>, it is never dies even if
constructing fails, so C<< $self->tzil->log_message >> returns the log messages anyway.

Note: Avoid calling C<build> and C<release> on C<tzil>:

    $self->tzil->build();       # NOT recommended
    $self->tzil->release();     # NOT recommended

Call C<build> and C<release> directly on C<$self> instead:

    $self->build();             # recommended
    $self->release();           # recommended

See C<build> and C<release> method descriptions for difference.

Examples:

    use Path::Tiny;
    test 'Check META.json' => sub {
        my ( $self ) = @_;
        $self->skip_if_exception();
        my $built_in = path( $self->tzil->built_in );
        my $json = $built_in->child( 'META.json' )->slurp_utf8;
        cmp_deeply( $json, $self->expected->{ json } );
    };

=head2 C<exception>

Exception occurred, or C<undef> is no exception was occurred.

    test 'Post-build' => sub {
        my ( $self ) = @_;
        cmp_deeply( $self->exception, $self->expected->{ exception } );
        ...
    };

=head2 C<expected>

A hash of expected outcomes. C<Test::Dist::Zilla> itself does not use this attribute, but more
specific roles may do. For example, C<Test::Dizt::Zilla::Build> uses C<exception> and C<messages>
keys, C<Test::Dizt::Zilla::BuiltFiles> uses C<files> key.

C<HashRef>, required.

Examples:

    run_me {
        ...,
        expected => {
            exception => "Aborting...\n",
            messages  => [
                '[Plugin] Oops, something goes wrong...',
            ],
        },
    };

=head2 C<message_filter>

If C<message_filter> is defined, it is used by default C<messages> implementation to filter the
actual log messages. C<message_filter> function is called once with list of all the log messages.
The function is expected to return a list of messages (possibly, grepped and/or edited).

Note: C<message_filter> value is a function, not method — C<messages> method does not pass C<$self>
reference to the C<message_filter>.

If C<messages> method is overridden, the attribute may be used or ignored — it depends on new
C<messages> implementation.

C<Maybe[CodeRef]>, optional. There is no default message filter — C<messages> method returns all
the messages intact. Default message filter may be set by defining C<_build_message_filter>
builder.

Examples:

Pass messages only from C<Manifest> plugin and filter out all other messages:

    sub _build_message_filter {
        sub { grep( { $_ =~ m{^\[Manifest\] } ) @_ ) };
    };

Drop plugin names from messages:

    run_me {
        message_filter => sub { map( { $_ =~ s{^\[.*?\] }{}r ) @_ ) },
        ...
    };

=head1 OBJECT METHODS

=head2 C<build>

=head2 C<release>

The methods call same-name method on C<tzil>, catch exception if any thrown, and save the caught
exception in the C<exception> attribute for further analysis.

Avoid calling these methods on C<tzil> — some tests may rely on method modifiers, which are
applicable to C<< $self->I<method>() >> but not to C<< $self->tzil->I<method>() >>.

Examples:

    test Build => sub {
        my ( $self ) = @_;
        $self->build();     # == dzil build
        ...
    };

    test Release => sub {
        my ( $self ) = @_;
        $self->release();   # == dzil release
        ...
    };

=head2 C<messages>

This method is assumed to return C<ArrayRef> of C<Dist::Zilla> log messages. It may be complete log
as it is or not — the method may filter out and/or edit actual messages to make them more suitable
for comparing with expected messages.

Default implementation filters the actual messages with the C<message_filter> (if it is defined).
If default behaviour is not suitable, the method can be overridden.

Examples:

    cmp_deeply( $self->messages, $self->expected->{ messages } );

=head2 skip_if_exception

This convenience method makes test routines a bit shorter. Instead of writing

    if ( defined( $self->exception ) ) {
        plan skip_all => 'exception occurred';
    };

you can write just

    $self->skip_if_exception;

=head1 VARIABLES

=head2 $Cleanup

C<Dist::Zilla::Tester> creates distribution source and build directories in a temporary directory,
and then unconditionally cleans it up. Sometimes (especially in case of test failure) such behavior
may be not desirable — you may want to look at source or built files for troubleshooting purposes.

C<Test::Dist::Zilla> provides control over temporary directory via C<$Test::Dist::Zilla::Cleanup>
package variable:

=over

=item C<0>

Never clean up temporary directory.

=item C<1>

Clean up temporary directory only if the test is passed (it is default).

=item C<2>

Always clean up temporary directory.

=back

If temporary directory is going to remain, the test output will contain diagnostic message like
this one:

    # tempdir: tmp/AKrvBhhM4M

to help you identify the temporary directory created for the test.

Note: Controlling temporary directory requires C<Dist::Zilla> 5.021 or newer.

=head1 SEE ALSO

=over 4

=item L<Test::Dist::Zilla::Build>

=item L<Test::Dist::Zilla::BuiltFiles>

=item L<Test::Dist::Zilla::Release>

=item L<Test::Routine>

=item L<Dist::Zilla>

=item L<Dist::Zilla::Tester::DieHard>

=item L<Test::DZil/"dist_ini">

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
