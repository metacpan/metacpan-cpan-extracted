package Test::Pod::Links;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.003';

use Carp ();
use HTTP::Tiny 0.014 ();
use Pod::Simple::Search     ();
use Pod::Simple::SimpleTree ();
use Scalar::Util            ();
use Test::Builder           ();
use Test::XTFiles           ();

my $TEST = Test::Builder->new();

# - Do not use subtests because subtests cannot be tested with
#   Test::Builder:Tester.
# - Do not use a plan because a method that sets a plan cannot be tested
#   with Test::Builder:Tester.
# - Do not call done_testing in a method that should be tested by
#   Test::Builder::Tester because TBT cannot test them.

sub all_pod_files_ok {
    my $self = shift;

    my @files = Test::XTFiles->new->all_files();
    if ( !@files ) {
        $TEST->skip_all("No files found\n");
        return 1;
    }

    my @pod_files = grep { Pod::Simple::Search->new->contains_pod($_) } @files;
    if ( !@pod_files ) {
        $TEST->skip_all("No files with Pod found\n");
        return 1;
    }

    my $rc = 1;
    for my $file (@pod_files) {
        if ( !$self->pod_file_ok($file) ) {
            $rc = 0;
        }
    }

    $TEST->done_testing;

    return 1 if $rc;
    return;
}

sub new {
    my $class = shift;

    Carp::croak 'Odd number of arguments' if @_ % 2;
    my %args = @_;

    my $self = bless {}, $class;

    #
    $self->{_cache} = {};

    #
    $self->_ua( $args{ua} || HTTP::Tiny->new );

    #
    my @ignores;
    if ( exists $args{ignore} ) {
        my $ignore = $args{ignore};
        if ( ref $ignore eq ref [] ) {
            @ignores = @{$ignore};
        }
        else {
            @ignores = $ignore;
        }
    }

    #
    my @ignores_match;
    if ( exists $args{ignore_match} ) {
        my $ignore_match = $args{ignore_match};
        if ( ref $ignore_match eq ref [] ) {
            @ignores_match = @{$ignore_match};
        }
        else {
            @ignores_match = $ignore_match;
        }
    }

    ## no critic (RegularExpressions::RequireDotMatchAnything)
    ## no critic (RegularExpressions::RequireExtendedFormatting)
    ## no critic (RegularExpressions::RequireLineBoundaryMatching)
    my $ignore_regex = join q{|}, @ignores_match, map { qr{^\Q$_\E$} } @ignores;
    $self->_ignore_regex( $ignore_regex ne q{} ? qr{$ignore_regex} : undef );
    ## use critic

  KEY:
    for my $key ( keys %args ) {
        next KEY if $key eq 'ignore';
        next KEY if $key eq 'ignore_match';
        next KEY if $key eq 'ua';

        Carp::croak "new() knows nothing about argument '$key'";
    }

    return $self;
}

sub pod_file_ok {
    my ( $self, $file ) = @_;

    Carp::croak 'usage: pod_file_ok(FILE)' if @_ != 2 || !defined $file;

    my $parse_msg = "Parse Pod ($file)";

    if ( !-f $file ) {
        $TEST->ok( 0, $parse_msg );
        $TEST->diag("\n");
        $TEST->diag("File $file does not exist or is not a file");
        return;
    }

    my $pod = Pod::Simple::SimpleTree->new->parse_file($file);

    if ( $pod->any_errata_seen ) {

        # Pod contains errors
        $TEST->ok( 0, $parse_msg );
        return;
    }

    $TEST->ok( 1, $parse_msg );

    my @links =
      grep { defined && m{ ^ http(?:s)? :// }xsmi }
      map  { ${ $_->{to} }[2] }
      grep { $_->{type} eq 'url' } $self->_extract_links_from_pod( $pod->root );

    my $ignore_regex = $self->_ignore_regex;
    if ( defined $ignore_regex ) {
        @links = grep { $_ !~ $ignore_regex } @links;
    }

    my $rc = 1;
    my $ua = $self->_ua;
    my %url_checked_in_this_file;

  LINK:
    for my $link (@links) {
        next LINK if exists $url_checked_in_this_file{$link};
        $url_checked_in_this_file{$link} = 1;

        if ( !exists $self->{_cache}->{$link} ) {
            $self->{_cache}->{$link} = $ua->head($link);
        }
        my $res = $self->{_cache}->{$link};

        $TEST->ok( $res->{success}, "$link ($file)" );

        if ( !$res->{success} ) {
            $rc = 0;
            $TEST->diag("\n");
            $TEST->diag( $res->{reason} );
            $TEST->diag("\n");
        }
    }

    return 1 if $rc;
    return;
}

sub _extract_links_from_pod {
    my ( $self, $node_ref ) = @_;

    Carp::croak 'usage: _extract_links_from_pod([ elementname, \%attributes, ...subnodes... ])' if @_ != 2 || ref $node_ref ne ref [] || scalar @{$node_ref} < 2;

    my @links;
    my ( $elem_name, $attr_ref, @subnodes ) = @{$node_ref};

    if ( $elem_name eq 'L' ) {
        push @links, $attr_ref;
    }

  SUBNODE:
    for my $subnode (@subnodes) {
        next SUBNODE if ref $subnode ne ref [];

        push @links, $self->_extract_links_from_pod($subnode);
    }

    return @links;
}

sub _ignore_regex {
    my $self = shift;

    if (@_) {
        my $ignore_regex = shift;
        $self->{_ignore_regex} = $ignore_regex;
    }

    return $self->{_ignore_regex};
}

sub _ua {
    my $self = shift;

    if (@_) {
        my $ua = shift;
        Carp::croak q{ua must have method 'head'} if !Scalar::Util::blessed($ua) || !$ua->can('head');
        $self->{_ua} = $ua;
    }

    return $self->{_ua};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Pod::Links - test Pod for invalid HTTP/S links

=head1 VERSION

Version 0.003

=head1 SYNOPSIS

    use Test::Pod::Links;
    Test::Pod::Links->new->all_pod_files_ok;

=head1 DESCRIPTION

Tests that all HTTP/S links from Pod documentation are reachable by calling
the C<head> method of L<HTTP::Tiny> on them.

All non HTTP/S links are ignored. You can check them with
L<Test::Pod::LinkCheck>.

This test is an author test and should not run on end-user installations.
Recommendation is to put it into your F<xt> instead of your F<t> directory.

=head1 USAGE

=head2 new( [ ARGS ] )

Returns a new C<Test::Pod::Link> instance. C<new> takes an optional hash
with its arguments.

    Test::Pod::Links->new(
        ignore       => 'url_to_ignore',
        ignore_match => qr{url to ignore},
        ua           => HTTP::Tiny->new,
    );

The following arguments are supported:

=head3 ignore (optional)

The C<ignore> argument is either a string or an array ref of strings. URLs
that match one of these strings are not checked. The comparison is done
case-sensitive.

This can be used to exclude URLs that are known to not work like
C<http://www.example.com/>. (But if a link doesn't work it most likely
shouldn't be in an C<L> tag anyway.)

=head3 ignore_match (optional)

The C<ignore_match> argument is either a regex or an array ref of regexes.
URLs that match one of these regexes are not checked.

=head3 ua (optional)

The C<ua> argument is used to supply your own, L<HTTP::Tiny> compatible,
user agent. Use this if you need a special configured L<HTTP::Tiny> user
agent.

=head2 pod_file_ok( FILENAME )

This will run a test for parsing the Pod and another test for every web link
found in the Pod. It is therefore unlikely to know the exact number of
tests that will run in advance. Use C<done_testing> from L<Test::More> if
you call this test directly instead of a C<plan>.

C<pod_file_ok> returns something I<true> if all web links are reachable
and I<false> otherwise.

=head2 all_pod_files_ok

Calls the C<all_files> method of L<Test::XTFiles> to get all the files to
be tested. Then, C<contains_pod> from L<Pod::Simple::Search> is used to
identify files that contain Pod.

All files that contain Pod will be checked  by calling C<pod_file_ok>.

It calls C<done_testing> or C<skip_all> so you can't have already called
C<plan>.

<all_pod_files_ok> returns something I<true> if all web links are reachable
and I<false> otherwise.

Please see L<XT::Files> for how to configure the files to be checked.

WARNING: The API was changed with 0.003. Arguments to C<all_pod_files_ok>
are now silently discarded and the method is now configured with
L<XT::Files>.

=head1 EXAMPLES

=head2 Example 1 Default Usage

Check the web links in all files in the F<bin>, F<script> and F<lib>
directory.

    use 5.006;
    use strict;
    use warnings;

    use Test::Pod::Links;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Pod::Links->new->all_pod_files_ok;

=head2 Example 2 Check non-default directories or files

Use the same test file as in Example 1 and create a F<.xtfilesrc> config
file in the root directory of your distribution.

    [Dirs]
    module = lib
    module = tools
    module = corpus/hello

    [Files]
    pod = corpus/7_links.pod

=head2 Example 3 Specify a different user agent for L<HTTP::Tiny>

    use 5.006;
    use strict;
    use warnings;

    use Test::Pod::Links;
    use HTTP::Tiny;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Pod::Links->new(
        ua => HTTP::Tiny->new(
            agent => 'Mozilla/5.0',
        ),
    )->all_pod_files_ok;

=head2 Example 4 Exclude a URL

    use 5.006;
    use strict;
    use warnings;

    use Test::Pod::Links;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Pod::Links->new(
        ignore => 'http://example.com/index.html',
    )->all_pod_files_ok;

=head2 Example 5 Exclude all urls for a domain

    use 5.006;
    use strict;
    use warnings;

    use Test::Pod::Links;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    Test::Pod::Links->new(
        ignore_match => qr{
            # We are going to exclude every URL that uses a host in the
            # example.com domain.

            ^                           # begin of string
            (?: (?i) http (?:s)? )      # case-insensitive match of http
                                        # and https
            ://                         # the protocol delimiter
            (?: [^/]* [.] )?            # this matches any hostname (or none)
            example[.]com               # the domain example.com
            (?: / | $ )                 # After the domain we get either a /
                                        # or nothing
        }x,
    )->all_pod_files_ok;

=head2 Example 6 Call C<pod_file_ok> directly

    use 5.006;
    use strict;
    use warnings;

    use Test::More 0.88;
    use Test::Pod::Links;

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }

    my $tpl = Test::Pod::Links->new;
    $tpl->pod_file_ok('corpus/7_links.pod');
    $tpl->pod_file_ok('corpus/hello');

    done_testing();

=head1 RATIONALE

=head2 Why this instead of L<Test::Pod::No404s>?

This module is much like L<Test::Pod::No404s>. It checks that HTTP/S links
in your Pod are valid.

There are a few differences to L<Test::Pod::No404s>:

=over 4

=item *

L<Test::Pod::No404s> does not cache the result. If you add a link to your
github repository in every F<.pm> file it will verify the same link for
every module by connecting to the same URL again and again. That is slow,
excessive and not very nice to the web server. C<Test::Pod::Links> caches the
result of every request only issuing a head request once for every URL.

=item *

L<Test::Pod::No404s> converts the Pod to text and then checks everything
that looks like a web URL which will pick up things that look like a URL but
are not a link. C<Test::Pod::Links> only checks HTTP/S links inside an C<L>
tag.

=item *

C<Test::Pod::Links> supports a C<ua> argument with the C<new> method that
allows you to pass a custom, L<HTTP::Tiny> compatible, user agent to it. It
can also be used to configure L<HTTP::Tiny> to your liking, e.g. configuring
the user-agent string.

=item *

L<Test::Pod::No404s> uses a hard coded list of hostnames to ignore, with
C<Test::Pod::Links> you have the C<ignore> and C<ignore_match> option to
decide which URLs to skip over.

=back

=head1 SEE ALSO

L<HTTP::Tiny>, L<Test::More>, L<Test::Pod::LinkCheck>, L<Test::Pod::No404s>,
L<XT::Files>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-Pod-Links/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-Pod-Links>

  git clone https://github.com/skirmess/Test-Pod-Links.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
