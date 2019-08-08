package Test::Spelling::Comment;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moo;

use Carp                  ();
use Comment::Spell::Check ();
use Pod::Wordlist         ();
use Scalar::Util          ();
use Test::Builder         ();
use Test::XTFiles         ();

has _skip => (
    is       => 'ro',
    init_arg => 'skip',
);

has _stopwords => (
    is        => 'ro',
    isa       => sub { Carp::croak q{stopwords must have method 'wordlist'} if !Scalar::Util::blessed( $_[0] ) || !$_[0]->can('wordlist'); },
    init_arg  => 'stopwords',
    lazy      => 1,
    default   => sub { Pod::Wordlist->new },
    predicate => 1,
);

my $TEST = Test::Builder->new();

# - Do not use subtests because subtests cannot be tested with
#   Test::Builder:Tester.
# - Do not use a plan because a method that sets a plan cannot be tested
#   with Test::Builder:Tester.
# - Do not call done_testing in a method that should be tested by
#   Test::Builder::Tester because TBT cannot test them.

sub add_stopwords {
    my $self = shift;

    my $wordlist = $self->_stopwords->wordlist;

  STOPWORD:
    for (@_) {

        # explicit copy
        my $stopword = $_;
        $stopword =~ s{ ^ \s* }{}xsm;
        $stopword =~ s{ \s+ $ }{}xsm;
        next STOPWORD if $stopword eq q{};

        $wordlist->{$stopword} = 1;
    }

    return $self;
}

sub all_files_ok {
    my ($self) = @_;

    my @files = Test::XTFiles->new->all_files();
    if ( !@files ) {
        $TEST->skip_all("No files found\n");
        return 1;
    }

    my $rc = 1;
    for my $file (@files) {
        if ( !$self->file_ok($file) ) {
            $rc = 0;
        }
    }

    $TEST->done_testing;

    return 1 if $rc;
    return;
}

sub file_ok {
    my ( $self, $file ) = @_;

    Carp::croak 'usage: file_ok(FILE)' if @_ != 2 || !defined $file;

    if ( !-f $file ) {
        $TEST->ok( 0, $file );
        $TEST->diag("\n");
        $TEST->diag("File $file does not exist or is not a file");

        return;
    }

    my $fh;
    if ( !open $fh, '<', $file ) {
        $TEST->ok( 0, $file );
        $TEST->diag("\n");
        $TEST->diag("Cannot read file '$file': $!");

        return;
    }

    my @lines = <$fh>;
    chomp @lines;

    if ( !close $fh ) {
        $TEST->ok( 0, $file );
        $TEST->diag("\n");
        $TEST->diag("Cannot read file '$file': $!");

        return;
    }

    my $skips_ref = $self->_skip;
    if ( defined $skips_ref ) {
        if (   ( !defined Scalar::Util::reftype($skips_ref) )
            || ( Scalar::Util::reftype($skips_ref) ne Scalar::Util::reftype( [] ) ) )
        {
            $skips_ref = [$skips_ref];
        }

        for my $line (@lines) {
            for my $skip ( @{$skips_ref} ) {
                ## no critic (RegularExpressions::RequireDotMatchAnything)
                ## no critic (RegularExpressions::RequireExtendedFormatting)
                ## no critic (RegularExpressions::RequireLineBoundaryMatching)
                $line =~ s{$skip}{}g;
                ## use critic
            }
        }
    }

    my $speller = Comment::Spell::Check->new( $self->_has_stopwords ? ( stopwords => $self->_stopwords ) : () );
    my $buf;
    $speller->set_output_string($buf);
    my $result;
    if ( !eval { $result = $speller->parse_from_string( join "\n", @lines, q{} ); 1 } ) {
        my $error_msg = $@;
        $TEST->ok( 0, $file );
        $TEST->diag("\n$error_msg\n\n");

        return;
    }

    if ( @{ $result->{fails} } == 0 ) {
        $TEST->ok( 1, $file );

        return 1;
    }

    $TEST->ok( 0, $file );
    $TEST->diag("\n$buf\n\n");

    return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Spelling::Comment - check for spelling errors in code comments

=head1 VERSION

Version 0.005

=head1 SYNOPSIS

    use Test::Spelling::Comment;
    Test::Spelling::Comment->new->add_stopwords(<DATA>)->all_files_ok;

=head1 DESCRIPTION

C<Test::Spelling::Comment> lets you check the spelling of your code
comments, and report its results in standard L<Test::More|Test::More>
fashion. This module uses L<Comment::Spell::Check|Comment::Spell::Check> to
do the checking, which requires a spellcheck program such as C<spell>,
C<aspell>, C<ispell>, or C<hunspell>.

This test is an author test and should not run on end-user installations.
Recommendation is to put it into your F<xt> instead of your F<t> directory.

=head1 USAGE

=head2 new( [ ARGS ] )

Returns a new C<Test::Spelling::Comment> instance. C<new> takes an optional
hash with its arguments.

    Test::Spelling::Comment->new(
        skip      => pattern,
        stopwords => Pod::Wordlist,
    );

The following arguments are supported:

=head3 skip (optional)

The C<skip> argument is either a string or an array ref of strings or regex
patterns. Every pattern is substituted for the empty string on every line of
the input file. This happens before passing the file over to
L<Comment::Spell::Check|Comment::Spell::Check> for spell checking.

Use this option to remove parts of the file that would otherwise require you
to add multiple C<stopwords>. An example would be lines like these:

    # vim: ts=4 sts=4 sw=4 et: syntax=perl

=head3 stopwords (optional)

The C<stopwords> argument must be a L<Pod::Wordlist|Pod::Wordlist> instance,
or something compatible. You can use that argument to configure
L<Pod::Wordlist|Pod::Wordlist> to your liking.

=head2 file_ok( FILENAME )

C<file_ok> will ok the test and return something I<true> if no spelling
error is found in the code comments. Otherwise it fails the test and returns
something I<false>.

=head2 all_files_ok

Calls the C<all_files> method of L<Test::XTFiles> to get all the files to
be tested. All files will be checked by calling C<file_ok>.

It calls C<done_testing> or C<skip_all> so you can't have already called
C<plan>.

C<all_files_ok> returns something I<true> if all files test ok and I<false>
otherwise.

Please see L<XT::Files> for how to configure the files to be checked.

WARNING: The API was changed with 0.005. Arguments to C<all_files_ok>
are now silently discarded and the method is now configured with
L<XT::Files>.

=head2 add_stopwords( @entries )

Adds the words passed in C<@entries> as stopwords. These words are not
passed to the spell checker and are therefore accepted as correct.

The C<add_stopwords> method always returns C<$self> and can therefore be
used to chain methods together.

This method can be called multiple times.

This method only adds the words as passed in C<@entries>. Unlike
C<learn_stopwords> from L<Pod::Wordlist|Pod::Wordlist> it does not add the
words plural too.

=head1 EXAMPLES

=head2 Example 1 Default Usage

Check the spelling in all files in the F<bin>, F<script> and F<lib>
directory.

    use 5.006;
    use strict;
    use warnings;

    use Test::Spelling::Comment 0.002;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Spelling::Comment->new->add_stopwords(<DATA>)->all_files_ok;

    __DATA__
    your
    stopwords
    go
    here

=head2 Example 2 Check non-default directories or files

Use the same test file as in Example 1 and create a F<.xtfilesrc> config
file in the root directory of your distribution.

    [Dirs]
    module = lib
    module = tools
    module = corpus/hello

    [Files]
    module = corpus/my.pm

=head2 Example 3 Call C<file_ok> directly

    use 5.006;
    use strict;
    use warnings;

    use Test::More 0.88;
    use Test::Spelling::Comment;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    my $comment = Test::Spelling::Comment->new;
    $comment->file_ok('corpus/hello.pl');
    $comment->file_ok('tools/update.pl');

    done_testing();

=head2 Example 4 Skip vim line

Check the spelling in all files in the F<bin>, F<script> and F<lib>
directory and remove the C<vim> comment.

    use 5.006;
    use strict;
    use warnings;

    use Test::Spelling::Comment 0.003;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Spelling::Comment->new(
        skip => '^# vim: .*'
    )->add_stopwords(<DATA>)->all_files_ok();

    __DATA__
    your
    stopwords
    go
    here

=head1 SEE ALSO

L<Comment::Spell::Check|Comment::Spell::Check>,
L<Comment::Spell|Comment::Spell>, L<Test::More|Test::More>,
L<XT::Files>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-Spelling-Comment/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-Spelling-Comment>

  git clone https://github.com/skirmess/Test-Spelling-Comment.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
