package Test::Requires::Git;
$Test::Requires::Git::VERSION = '1.008';
use strict;
use warnings;

use Carp;
use Git::Version::Compare ();

use base 'Test::Builder::Module';

our $GIT = 'git';

my %check = (
    version_eq => \&Git::Version::Compare::eq_git,
    version_ne => \&Git::Version::Compare::ne_git,
    version_gt => \&Git::Version::Compare::gt_git,
    version_le => \&Git::Version::Compare::le_git,
    version_lt => \&Git::Version::Compare::lt_git,
    version_ge => \&Git::Version::Compare::ge_git,
);

# aliases
$check{'=='} = $check{eq} = $check{version} = $check{version_eq};
$check{'!='} = $check{ne} = $check{version_ne};
$check{'>'}  = $check{gt} = $check{version_gt};
$check{'<='} = $check{le} = $check{version_le};
$check{'<'}  = $check{lt} = $check{version_lt};
$check{'>='} = $check{ge} = $check{version_ge};

my $quiet = 0;
my $lock  = '.test.requires.git.lock';

sub import {
    my $class = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::test_requires_git"} = \&test_requires_git;
    }

    return if @_ == 1 && $_[0] eq '-nocheck';

    # reset the global $GIT value
    my $args = _extract_arguments(@_);
    $GIT = $args->{git} if exists $args->{git};

    # test arguments
    test_requires_git(@_);
}

sub _extract_arguments {
    my (@args) = @_;

    my ( %args, @spec );
    while (@args) {

        # assume a lone parameter is a minimum git version
        unshift @args, 'version_ge' if @args == 1;

        my ( $key, $val ) = splice @args, 0, 2;
        if ( $key =~ /^(?:git|skip)/ ) {
            croak "Duplicate '$key' argument" if exists $args{$key};
            $args{$key} = $val;
        }
        elsif ( !exists $check{$key} ) {
            if ( @args % 2 ) {    # odd number of arguments (see above)
                unshift @args, version_ge => $key, $val;
                redo;
            }
            croak "Unknown git specification '$key'";
        }
        else {
            push @spec, $key, $val;
        }
    }
    return wantarray ? ( \%args, @spec ) : \%args;
}

sub _git_version { qx{$GIT --version} }

sub test_requires_git {
    my ( $args, @spec ) = _extract_arguments(@_);
    my $skip = $args->{skip};
    local $GIT = $args->{git} if exists $args->{git};

    # get the git version
    my ($version) = do {
        no warnings 'uninitialized';
        __PACKAGE__->_git_version();    # tests may override this
    };

    my $builder = __PACKAGE__->builder;
    if ( !$quiet && time - ( ( stat $lock )[9] || 0 ) > 60 ) {
        $builder->diag($version);
        $quiet++;
        open my $fh, '>', $lock if !-e $lock;
        utime( undef, undef, $lock );
    }

    # perform the check
    my ( $ok, $why ) = ( 1, '' );
    if ( defined $version && Git::Version::Compare::looks_like_git($version) ) {
        while ( my ( $spec, $arg ) = splice @spec, 0, 2 ) {
            if ( !$check{$spec}->( $version, $arg ) ) {
                $ok = 0;
                $version =~ s/^git version|[\012\015]+$//g;
                $why = "$version $spec $arg";
                last;
            }
        }
    }
    else {
        $ok  = 0;
        $why = "`$GIT` binary not available or broken";
    }

    # skip if needed
    if ( !$ok ) {

        # skip a specified number of tests
        if ( $skip ) {
            $builder->skip($why) for 1 .. $skip;
            no warnings 'exiting';
            last SKIP;
        }

        # no plan declared yet
        elsif ( !defined $builder->has_plan ) {
            if ( $builder->summary ) {
                $builder->skip($why);
                $builder->done_testing;
                exit 0;
            }
            else {
                $builder->skip_all($why);
            }
        }

        # the plan is no_plan
        elsif ( $builder->has_plan eq 'no_plan' ) {
            $builder->skip($why);
            exit 0;
        }

        # some plan was declared, skip all tests one by one
        else {
            $builder->skip($why) for 1 + $builder->summary .. $builder->has_plan;
            exit 0;
        }
    }
}

'git';

__END__

=encoding utf-8

=head1 NAME

Test::Requires::Git - Check your test requirements against the available version of Git

=head1 SYNOPSIS

    # will skip all if git is not available
    use Test::Requires::Git;

    # needs some git that supports `git init $dir`
    test_requires_git version_ge => '1.6.5';

=head1 DESCRIPTION

Test::Requires::Git checks if the version of Git available for testing
meets the given requirements. If the checks fail, then all tests will
be I<skipped>.

C<use Test::Requires::Git> always calls C<test_requires_git> with the
given arguments. If you don't want C<test_requires_git> to be called
at import time, write this instead:

    use Test::Requires::Git -nocheck;

Passing the C<git> parameter (see L</test_requires_git> below) to
C<use Test::Requires::Git> will override it for the rest of the program run.

=head1 EXPORTED FUNCTIONS

=head2 test_requires_git

    # skip all unless git is available as required
    test_requires_git version_ge => '1.6.5';

    # giving no operator implies 'version_ge'
    test_requires_git '1.6.5';

    # skip 2 if git is not available
  SKIP: {
        test_requires_git skip => 2;
        ...;
    }

    # skip 2 unless git is available as required
  SKIP: {
        test_requires_git
          skip       => 2,
          version_ge => '1.7.12';
        ...;
    }

    # skip all remaining tests if git is not available
    test_requires_git;

    # force which git binary to use
    test_requires_git
      git        => '/usr/local/bin/git',
      version_ge => '1.6.5';

Takes a list of version requirements (see L</GIT VERSION CHECKING>
below), and if one of them does not pass, I<skips> all remaining tests.
All conditions must be satisfied for the check to pass.

When the C<skip> parameter is given, only the specified number of tests
will be skipped.

The "current git" is obtained by running C<git --version>.
I.e. the first C<git> binary found in the current environment will
be tested. This is of course sensitive to local changes to C<PATH>,
so this will behave as expected:

    # skip 4 tests if there's no git available in the alternative PATH
  SKIP: {
        local $ENV{PATH} = $alternative_PATH;
        test_requires_git skip => 4;
        ...;
    }

When the C<git> parameter is given, C<test_requires_git> will run that
program instead of C<git>.

If no condition is given, C<test_requires_git> will simply check if C<git>
is available.

The first time it's called, C<test_require_git> will print a test diagnostic
with the output of C<git --version> (if C<git> is available, of course).
To prevent this behaviour, load the module with:

    use Test::Requires::Git -quiet;

=head1 GIT VERSION CHECKING

The actual comparison is handled by L<Git::Version::Compare>, so the
strings can be version numbers, tags from C<git.git> or the output of
C<git version> or C<git describe>.

The following version checks are currently supported:

=head2 version_eq

Aliases: C<version_eq>, C<eq>, C<==>, C<version>.

    test_requires_git version_eq => $version;

Passes if the current B<git> version is I<equal> to C<$version>.

=head2 version_ne

Aliases: C<version_ne>, C<ne>, C<!=>.

    test_requires_git version_eq => $version;

Passes if the current B<git> version is I<not equal> to C<$version>.

=head2 version_lt

Aliases: C<version_lt>, C<lt>, C<E<lt>>.

    test_requires_git version_lt => $version;

Passes if the current B<git> version is I<less than> C<$version>.

=head2 version_gt

Aliases: C<version_gt>, C<gt>, C<E<gt>>.

    test_requires_git version_gt => $version;

Passes if the current B<git> version is I<greater than> C<$version>.

=head2 version_le

Aliases: C<version_le>, C<le>, C<E<lt>=>.

    test_requires_git version_le => $version;

Passes if the current B<git> version is I<less than or equal> C<$version>.

=head2 version_ge

Aliases: C<version_ge>, C<ge>, C<E<gt>=>.

    test_requires_git version_ge => $version;

Passes if the current B<git> version is I<greater than or equal > C<$version>.

As a special shortcut for the most common case, a lone version number
is turned into a C<version_ge> check, so the following two lines are
exactly equivalent:

    test_requires_git version_ge => '1.6.5';

    # version_ge implied
    test_requires_git '1.6.5';

=head1 SEE ALSO

L<Test::Requires>, L<Git::Version::Compare>.

=head1 ACKNOWLEDGEMENTS

Thanks to Oliver Mengué (DOLMEN), who gave me the idea for this module
at the Perl QA Hackathon 2015 in Berlin, and suggested to give a look
at L<Test::Requires> for inspiration.

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2015-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
