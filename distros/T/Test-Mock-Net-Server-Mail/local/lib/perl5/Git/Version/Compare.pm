package Git::Version::Compare;
$Git::Version::Compare::VERSION = '1.004';
use strict;
use warnings;
use Exporter;
use Carp ();

my @ops = qw( lt gt le ge eq ne );

our @ISA         = qw(Exporter);
our @EXPORT_OK   = ( looks_like_git => map "${_}_git", cmp => @ops );
our %EXPORT_TAGS = ( ops => [ map "${_}_git", @ops ], all => \@EXPORT_OK );

# A few versions have two tags, or non-standard numbering:
# - the left-hand side is what `git --version` reports
# - the right-hand side is an internal canonical name
#
# We turn versions into strings, so we can use the fast `eq` and `gt`.
# The 6 elements are integers padded with 0:
# - the 4 parts of the dotted version (padded with as many .0 as needed)
# - '.000' if not an RC, or '-xxx' if an RC (- sorts before . in ascii)
# - the number of commits since the previous tag (for dev versions)
#
# The special cases are pre-computed below, the rest is computed as needed.
my %version_alias = (
    '0.99.7a' => '00.99.07.01.00.0000',
    '0.99.7b' => '00.99.07.02.00.0000',
    '0.99.7c' => '00.99.07.03.00.0000',
    '0.99.7d' => '00.99.07.04.00.0000',
    '0.99.8a' => '00.99.08.01.00.0000',
    '0.99.8b' => '00.99.08.02.00.0000',
    '0.99.8c' => '00.99.08.03.00.0000',
    '0.99.8d' => '00.99.08.04.00.0000',
    '0.99.8e' => '00.99.08.05.00.0000',
    '0.99.8f' => '00.99.08.06.00.0000',
    '0.99.8g' => '00.99.08.07.00.0000',
    '0.99.9a' => '00.99.09.01.00.0000',
    '0.99.9b' => '00.99.09.02.00.0000',
    '0.99.9c' => '00.99.09.03.00.0000',
    '0.99.9d' => '00.99.09.04.00.0000',
    '0.99.9e' => '00.99.09.05.00.0000',
    '0.99.9f' => '00.99.09.06.00.0000',
    '0.99.9g' => '00.99.09.07.00.0000',
    '0.99.9h' => '00.99.09.08.00.0000',    # 1.0.rc1
    '1.0.rc1' => '00.99.09.08.00.0000',
    '0.99.9i' => '00.99.09.09.00.0000',    # 1.0.rc2
    '1.0.rc2' => '00.99.09.09.00.0000',
    '0.99.9j' => '00.99.09.10.00.0000',    # 1.0.rc3
    '1.0.rc3' => '00.99.09.10.00.0000',
    '0.99.9k' => '00.99.09.11.00.0000',
    '0.99.9l' => '00.99.09.12.00.0000',    # 1.0.rc4
    '1.0.rc4' => '00.99.09.12.00.0000',
    '0.99.9m' => '00.99.09.13.00.0000',    # 1.0.rc5
    '1.0.rc5' => '00.99.09.13.00.0000',
    '0.99.9n' => '00.99.09.14.00.0000',    # 1.0.rc6
    '1.0.rc6' => '00.99.09.14.00.0000',
    '1.0.0a'  => '01.00.01.00.00.0000',
    '1.0.0b'  => '01.00.02.00.00.0000',
);

sub looks_like_git {
    return scalar $_[0] =~
        /^(?:v|git\ version\ )?                               # prefix
          [0-9]+(?:[.-](?:0[ab]?|[1-9][0-9a-z]*|[a-zA-Z]+))*  # x.y.z.*
          (?:[.-]?rc[0-9]+)?                                  # rc
          (?:[.-](GIT|[1-9][0-9]*[.-]g[A-Fa-f0-9]+))?         # devel
          (?:\ .*)?                                           # comment
         $/x;
}

sub _normalize {
    my ($v) = @_;
    return undef if !defined $v;

    # minimal consistency check
    Carp::croak "$v does not look like a Git version" if !looks_like_git($v);

    # reformat git.git tag names, output of `git --version`
    $v =~ s/^v|^git version |\.[a-zA-Z]+\..*|[\012\015]+\z//g;
    $v =~ y/-/./;
    $v =~ s/0rc/0.rc/;
    ($v) = split / /, $v;    # drop anything after the version

    # can't use exists() because the assignment in the @ops created the slot
    return $version_alias{$v} if defined $version_alias{$v};

    # split the dotted version string
    my @v = split /\./, $v;
    my ( $r, $c ) = ( 0, 0 );

    # commit count since the previous tag
    ($c) = ( 1, splice @v, -1 ) if $v[-1] eq 'GIT';           # before 1.4
    ($c) = splice @v, -2 if substr( $v[-1], 0, 1 ) eq 'g';    # after  1.4

    # release candidate number
    ($r) = splice @v, -1 if substr( $v[-1], 0, 2 ) eq 'rc';
    $r &&= do { $r =~ s/rc//; sprintf '-%02d', $r };

    # compute and cache normalized string
    return $version_alias{$v} =
        join( '.', map sprintf( '%02d', $_ ), ( @v, 0, 0, 0 )[ 0 .. 3 ] )
      . ( $r || '.00' )
      . sprintf( '.%04d', $c );
}

for my $op (@ops) {
    no strict 'refs';
    *{"${op}_git"} = eval << "OP";
    sub {
        my ( \$v1, \$v2 ) = \@_;
        \$_ = \$version_alias{\$_} ||= _normalize( \$_ ) for \$v1, \$v2;
        return \$v1 $op \$v2;
    }
OP
}

sub cmp_git ($$) {
    my ( $v1, $v2 ) = @_;
    $_ = $version_alias{$_} ||= _normalize( $_ ) for $v1, $v2;
    return $v1 cmp $v2;
}

1;

__END__

=head1 NAME

Git::Version::Compare - Functions to compare Git versions

=head1 SYNOPSIS

    use Git::Version::Compare qw( cmp_git );

    # result: 1.2.3 1.7.0.rc0 1.7.4.rc1 1.8.3.4 1.9.3 2.0.0.rc2 2.0.3 2.3.0.rc1
    my @versions = sort cmp_git qw(
      1.7.4.rc1 1.9.3 1.7.0.rc0 2.0.0.rc2 1.2.3 1.8.3.4 2.3.0.rc1 2.0.3
    );

=head1 DESCRIPTION

L<Git::Version::Compare> contains a selection of subroutines that make
dealing with Git-related things (like versions) a little bit easier.

The strings to compare can be version numbers, tags from C<git.git>
or the output of C<git version> or C<git describe>.

These routines collect the knowledge about Git versions that
was accumulated while developing L<Git::Repository>.

=head1 AVAILABLE FUNCTIONS

By default L<Git::Version::Compare> does not export any subroutines.

All the comparison version functions die when given strings that do not
look like Git version numbers (the check is done with L</looks_like_git>).

=head2 lt_git

    if ( lt_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<lt> operator.

=head2 gt_git

    if ( gt_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<gt> operator.

=head2 le_git

    if ( le_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<le> operator.

=head2 ge_git

    if ( ge_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<ge> operator.

=head2 eq_git

    if ( eq_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<eq> operator.

=head2 ne_git

    if ( ne_git( $v1, $v2 ) ) { ... }

A Git-aware version of the C<ne> operator.

=head2 cmp_git

    @versions = sort cmp_git @versions;

A Git-aware version of the C<cmp> operator.

=head2 looks_like_git

    # true
    looks_like_git(`git version`);    # duh

    # false
    looks_like_git('v1.7.3_02');      # no _ in git versions

Given a string, returns true if it looks like a Git version number
(and can therefore be parsed by C<Git::Version::Number>) and false
otherwise.

=head1 EXPORT TAGS

=head2 :ops

Exports C<lt_git>, C<gt_git>, C<le_git>, C<ge_git>, C<eq_git>, and C<ne_git>.

=head2 :all

Exports C<lt_git>, C<gt_git>, C<le_git>, C<ge_git>, C<eq_git>, C<ne_git>,
C<cmp_git>, and C<looks_like_git>.

=head1 EVERYTHING YOU EVER WANTED TO KNOW ABOUT GIT VERSION NUMBERS

=head1 Version numbers

Version numbers as returned by C<git version> are in the following
formats (since the C<1.4> series, in 2006):

    # stable version
    1.6.0
    2.7.1

    # maintenance release
    1.8.5.6

    # release candidate
    1.6.0.rc2

    # development version
    # (the last two elements come from `git describe`)
    1.7.1.209.gd60ad
    1.8.5.1.21.gb2a0afd
    2.3.0.rc0.36.g63a0e83

In the C<git.git> repository, several commits have multiple tags
(e.g. C<v1.0.1> and C<v1.0.2> point respectively to C<v1.0.0a>
and C<v1.0.0b>). Pre-1.0.0 versions also have non-standard formats
like C<0.99.9j> or C<1.0rc2>.

This explains why:

    # this is true
    eq_git( '0.99.9l', '1.0rc4' );
    eq_git( '1.0.0a',  '1.0.1' );

    # this is false
    ge_git( '1.0rc3', '0.99.9m' );

C<git version> appeared in version C<1.3.0>.
C<git --version> appeared in version C<0.99.7>. Before that, there is no
way to know which version of Git one is dealing with.

C<Git::Version::Compare> converts all version numbers to an internal
format before performing a simple string comparison.

=head2 Development versions

Prior to C<1.4.0-rc1> (June 2006), compiling a development version of Git
would lead C<git --version> to output C<1.x-GIT> (with C<x> in C<0 .. 3>),
which would make comparing versions that are very close a futile exercise.

Other issues exist when comparing development version numbers with one
another. For example, C<1.7.1.1> is greater than both C<1.7.1.1.gc8c07>
and C<1.7.1.1.g5f35a>, and C<1.7.1> is less than both. Obviously,
C<1.7.1.1.gc8c07> will compare as greater than C<1.7.1.1.g5f35a>
(asciibetically), but in fact these two version numbers cannot be
compared, as they are two siblings children of the commit tagged
C<v1.7.1>). For practical purposes, the version-comparison methods
declares them equal.

Therefore:

    # this is true
    lt_git( '1.8.5.4.8.g7c9b668', '1.8.5.4.19.g5032098' );
    gt_git( '1.3.GIT', '1.3.0' );

    # this is false
    ne_git( '1.7.1.1.gc8c07', '1.7.1.1.g5f35a' );
    gt_git( '1.3.GIT', '1.3.1' );

If one were to compute the set of all possible version numbers (as returned
by C<git --version>) for all git versions that can be compiled from each
commit in the F<git.git> repository, the result would not be a totally ordered
set. Big deal.

Also, don't be too precise when requiring the minimum version of Git that
supported a given feature. The precise commit in git.git at which a given
feature was added doesn't mean as much as the release branch in which that
commit was merged.

=head1 SEE ALSO

L<Test::Requires::Git>, for defining Git version requirements in test
scripts that need B<git>.

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
