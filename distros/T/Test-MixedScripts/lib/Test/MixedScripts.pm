package Test::MixedScripts;

use utf8;

# ABSTRACT: test text for mixed and potentially confusable Unicode scripts

use v5.16;
use warnings;

use Carp          qw( croak );
use Exporter 5.57 qw( import );
use File::Basename qw( basename );
use File::Spec;
use IO            qw( File );
use List::Util    qw( first );
use Unicode::UCD  qw( charinfo charscripts );

use Test2::API 1.302200 qw( context );
use Test2::Util::DistFiles v0.2.0 qw( manifest_files is_perl_file );

our @EXPORT_OK = qw( all_perl_files_scripts_ok file_scripts_ok );

our $VERSION = 'v0.6.2';


sub file_scripts_ok {
    my ( $file, @args ) = @_;

    my $options = @args == 1 && ref( $args[0] ) eq "HASH" ? $args[0] : { scripts => \@args };
    $options->{scripts} //= [];
    push @{ $options->{scripts} }, qw( Latin Common ) unless defined $options->{scripts}[0];

    my $ctx = context();

    if ( my $error = _check_file_scripts( $file, $options ) ) {

        my ( $lino, $pre, $char ) = @{$error};

        # Ideally we would use charprop instead of charscript, since that supports Script_Extensions, but Unicode::UCD
        # is not dual life and charprop is only available after v5.22.0.

        my $info    = charinfo( ord($char) );
        my $message = sprintf(
            'Unexpected %s character %s on line %u character %u in %s',
            $info->{script},               #
            $info->{name} || "NO NAME",    #
            $lino,                         #
            length($pre) + 1,              #
            "$file"
        );

        $ctx->fail( $file, $message );

    }
    else {
        $ctx->pass( $file );
    }

    $ctx->release;
}

sub _check_file_scripts {
    my ( $file, $options ) = @_;

    my @scripts = @{ $options->{scripts} };
    my $default = _make_regex(@scripts);

    my $fh = IO::File->new( $file, "r" ) or croak "Cannot open ${file}: $!";

    $fh->binmode(":utf8");

    my $current = $default;

    while ( my $line = $fh->getline ) {
        my $re = $current;
        # TODO custom comment prefix based on the file type
        if ( $line =~ s/\s*##\s+Test::MixedScripts\s+(\w+(?:,\w+)*).*$// ) {
            $re = _make_regex( split /,\s*/, $1 );
        }
        elsif ( $line =~ /^=for\s+Test::MixedScripts\s+(\w+(?:,\w+)*)$/ ) {
            $current = $1 eq "default" ? $default : _make_regex( split /,\s*/, $1 );
            next;
        }

        unless ( $line =~ $re ) {
            my $fail = _make_negative_regex(@scripts);
            $line =~ $fail;
            return [ $fh->input_line_number, ${^PREMATCH}, ${^MATCH} ];
        }
    }

    $fh->close;

    return 0;
}

sub _make_regex_set {
    state $scripts = { ASCII => undef, map { $_ => 1 } keys %{ charscripts() } };
    if ( my $err = first { !exists $scripts->{$_} } @_ ) {
        croak "Unknown script ${err}";
    }
    return join( "", map { $_ eq "ASCII" ? '\x00-\x7f' : sprintf( '\p{scx=%s}', $_ ) } @_ );
}

sub _make_regex {
    my $set = _make_regex_set(@_);
    return qr/^[${set}]*$/u;
}

sub _make_negative_regex {
    my $set = _make_regex_set(@_);
    return qr/([^${set}])/up;
}


sub all_perl_files_scripts_ok {
    my $options = { };
    $options = shift if ref $_[0] eq 'HASH';
    my @files = manifest_files( \&is_perl_file);
    foreach my $file (@files) {
        file_scripts_ok( $file, $options );
    }
}

sub _is_perl_file {
    my ($file) = @_;
    return is_perl_file($file) || _is_pod_file($file) || _is_perl_config($file) || _is_xs_file($file) || _is_template($file);
}

sub _is_pod_file {
    $_[0] =~ /\.pod$/i;
}

sub _is_perl_config {
    my ($file) = @_;
    my $name = basename($file);
    return 1 if $name =~ /^(?:Rexfile|cpanfile)$/;
    return;
}

sub _is_xs_file {
    $_[0] =~ /\.(c|h|xs)$/i;
}

sub _is_template {
    my ($file) = @_;
    my $name = basename($file);
    return 1 if $name =~ /\.(?:epl?|inc|mc|psp|tal|tm?pl|tt)$/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::MixedScripts - test text for mixed and potentially confusable Unicode scripts

=head1 VERSION

version v0.6.2

=head1 SYNOPSIS

  use Test::V0;
  use Test::MixedScripts v0.3.0 qw( all_perl_files_scripts_ok file_scripts_ok );

  all_perl_files_scripts_ok();

  file_scripts_ok( 'assets/site.js' );

  done_testing;

=head1 DESCRIPTION

This is a module to test that Perl code and other text files do not have potentially malicious or confusing Unicode
combinations.

For example, the text for the domain names "E<0x043e>nE<0x0435>.example.com" and "one.example.com" look indistinguishable in many fonts,
but the first one has Cyrillic letters.  If your software interacted with a service on the second domain, then someone
can operate a service on the first domain and attempt to fool developers into using their domain instead.

This might be through a malicious patch submission, or even text from an email or web page that they have convinced a
developer to copy and paste into their code.

=head1 EXPORTS

=head2 file_scripts_ok

  file_scripts_ok( $filepath, @scripts );

This tests that the text file at C<$filepath> contains only characters in the specified C<@scripts>.
If no scripts are given, it defaults to C<Common> and C<Latin> characters.

You can override the defaults by adding a list of Unicode scripts, for example

  file_scripts_ok( $filepath, qw/ Common Latin Cyrillic / );

You can also pass options as a hash reference,

  file_scripts_ok( $filepath, { scripts => [qw/ Common Latin Cyrillic /] } );

A safer alternative to overriding the default scripts for a file is to specify an exception on each line using a special
comment:

   "English bŭlgarski" ## Test::MixedScripts Latin,Cyrillic,Common

You can also override the default scripts with a special POD directive, which will change the scripts for all lines
(code or POD) that follow:

    =for Test::MixedScripts Latin,Cyrillic,Common

You can reset to the default scripts using:

    =for Test::MixedScripts default

You can escape the individual characters in strings and regular expressions using hex codes, for example,

   say qq{The Cyryllic "\x{043e}" looks like an "o".};

and in POD using the C<E> formatting code. For example,

    =pod

    The Cyryllic "E<0x043e>" looks like an "o".

    =cut

See L<perlpod> for more information.

When tests fail, the diagnostic message will indicate the unexpected script and where the character was in the file:

    Unexpected Cyrillic character CYRILLIC SMALL LETTER ER on line 286 character 45 in lib/Foo/Bar.pm

You can also specify "ASCII" as a special script name for only 7-bit ASCII characters:

  file_scripts_ok( $filepath, qw/ ASCII / );

Note that "ASCII" is available in version v0.6.0 or later.

=head2 all_perl_files_scripts_ok

  all_perl_files_scripts_ok();

  all_perl_files_scripts_ok( \%options );

This applies L</file_scripts_ok> to all of the Perl scripts in the current directory, based the distribution
L<MANIFEST|ExtUtils::Manifest>.

=head1 KNOWN ISSUES

=head2 Unicode and Perl Versions

Some scripts were added to later versions of Unicode, and supported by later versions of Perl.  This means that you
cannot run tests for some scripts on older versions of Perl.
See L<Unicode Supported Scripts|https://www.unicode.org/standard/supported.html> for a list of scripts supported
by Unicode versions.

=head2 Pod::Weaver

The C<=for> directive is not consistently copied relative to the sections that occur in by L<Pod::Weaver>.

=head2 Other Limitations

This will not identify confusable characters from the same scripts.

=head1 SEE ALSO

L<Test::PureASCII> tests that only ASCII characters are used.

L<Unicode::Confuse> identifies L<Unicode Confusables|https://util.unicode.org/UnicodeJsps/confusables.jsp>.

L<Unicode::Security> implements several security mechanisms described in
L<Unicode Security Mechanisms|https://www.unicode.org/reports/tr39/>.

L<Detecting malicious Unicode|https://daniel.haxx.se/blog/2025/05/16/detecting-malicious-unicode/>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Test-MixedScripts>
and may be cloned from L<git://github.com/robrwo/perl-Test-MixedScripts.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Test-MixedScripts/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
