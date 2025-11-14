use v5.42;

package Test2::Tools::Pod v0.1.0;

use Exporter 'import';
use Path::Iterator::Rule;
use Path::Tiny;
use Pod::Simple;
use Test2::API 'context';

our @EXPORT = qw/ pod_ok all_pod_ok /;
our @Ignore = qw/ .git .hg /;

sub pod_ok ($file, $name = undef, $should_skip = true)
{
    my $ctx = context;
    $name = "POD syntax ok for $file" unless defined $name;

    unless (-f $file) {
        $ctx->fail_and_release($name);
        return false;
    }

    my $parser = Pod::Simple->new;
    $parser->output_string( \ my $null );
    $parser->parse_file($file);

    unless ($parser->content_seen) {
        # no POD in this file
        $ctx->skip($name, 'no POD found') if $should_skip;
        $ctx->release;
        return;
    }

    if ($parser->any_errata_seen) {
        # problems
        my %errors = $parser->errata_seen->%*;

        # %errors:
        #   <line-number> => [
        #           "<problem>",
        #           ...
        #       ],
        #       ...
        # We need it flattened:
        #   "$file:<line-number>: <problem1>"
        #   "$file:<line-number>: <problem2>"
        #   ...
        $ctx->fail_and_release(
            $name,
            map {
                my $line = $_;
                map { "$file:$line: $_" } $errors{$_}->@*
            }
            sort { $a <=> $b } keys %errors
        );
        return false;
    } else {
        # syntax OK
        $ctx->pass_and_release($name);
        return true;
    }
}

sub all_pod_ok (@locations)
{
    @locations = -d 'blib' ? 'blib' : 'lib' unless @locations;

    my @candidates = _POD_candidates(@locations);
    my $tested = 0;
    my $ctx = context;

    for my $file (@candidates) {
        my $result = pod_ok($file, undef, false);
        ++$tested if defined $result;
    }

    unless ($tested) {
        # no file with POD was found, emit a skip event
        $ctx->skip('POD syntax ok', 'no POD files found');
    }

    $ctx->release;
    return $tested;
}

sub _POD_candidates (@locations)
{
    return () unless @locations;

    my $r = Path::Iterator::Rule->new;
    $r->skip_dirs(@Ignore) if @Ignore;
    $r->file;
    $r->or(
            $r->new->name(qr/\.(?:pl|pm|pod|psgi|t)$/i),
            $r->new->shebang(qr/#!.*\bperl\b/),
        );

    my %seen;
    grep { not $seen{$_}++ } $r->all(@locations);
}

1;

__END__

=head1 NAME

Test2::Tools::Pod -- check that POD syntax is valid

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::Pod;

    # Check a single file
    pod_ok 'lib/Module.pm';

    # Check all modules in distribution
    all_pod_ok;

    done_testing;

=head1 DESCRIPTION

C<Test2::Tools::Pod> performs simple POD syntax checks on one or more
Perl source files, reporting any parsing errors as test failures. It is
built directly on top of L<Test2::API>, making it suitable for projects
that use modern Test2-based tooling.

Parsing and validation are performed using L<Pod::Simple>. Each file is
read, parsed, and reported as a separate test.

The tool is suitable for author tests, continuous integration, or any
situation where POD syntax correctness is required without additional
diagnostics or formatting checks.

=head1 SUBROUTINES

=head2 pod_ok

    sub pod_ok ( $file, $name = undef )

Parses the given file and runs a single test asserting that its POD
syntax is valid. The optional C<$name> argument specifies the test name.
If omitted, the default name is C<"POD syntax ok for $file">.

If no POD content is found in the file, the test is skipped.

Returns C<true> if the syntax is OK, C<false> otherwise. If no POD was
found and the test was skipped, returns undef;

=head2 all_pod_ok

    sub all_pod_ok ( @locations )

Recursively searches for Perl files containing POD under C<@locations>,
which may include both directories and files. If no locations are
provided, it searches the F<blib> directory if it exists, or otherwise
F<lib>.

Files tested include those with extensions F<.pl>, F<.pm>, F<.pod>,
F<.psgi>, and F<.t>, as well as any file that begins with a Perl shebang
line.

When scanning directories, C<all_pod_ok> automatically skips
version-control directories for Git and Mercurial. This list is stored
in C<@Test2::Tools::Pod::Ignore>, which you may modify before calling
C<all_pod_ok> to adjust which directories are ignored.

Returns the number of files tested.

=head1 SEE ALSO

L<Test2>, L<Test2::V0>.

=head1 AUTHOR

Cesar Tessarin, E<lt>cesar@tessarin.com.brE<gt>.

Written in November 2025.
