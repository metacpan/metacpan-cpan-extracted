package Test::Format;
$Test::Format::VERSION = '1.0.0';
# ABSTRACT: test files if they match format


use strict;
use warnings FATAL => 'all';
use utf8;
use open qw(:std :utf8);

use Test::More;
use JSON::PP;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    test_format
);
our @EXPORT = @EXPORT_OK;


sub test_format {
    my (@opts) = @_;

    die 'Must specify opts' if scalar(@opts) == 0;
    die 'There must be key-value pairs' if scalar(@opts) % 2;

    my %opts = @opts;

    my $files = delete $opts{files};
    my $format = delete $opts{format};
    my $format_sub = delete $opts{format_sub};

    my @unknown_opts = keys %opts;
    die 'Unknown opts: ' . join(', ', @unknown_opts) if @unknown_opts;

    die "Must specify 'files'" if not defined $files;
    die "'files' must be an array" if ref $files ne 'ARRAY';
    die "'files' can't be an empty array" if scalar(@{$files}) == 0;

    die "Must specify 'format' or 'format_sub'" if !defined($format) && !defined($format_sub);
    die "Can't specify both 'format' and 'format_sub'" if defined($format) && defined($format_sub);

    die "Unknown value for 'format' opt: '$format'" if defined($format) && $format ne 'pretty_json';
    die "'format_sub' must be sub" if defined($format_sub) && ref($format_sub) ne 'CODE';

    my $sub = defined($format) && $format eq 'pretty_json' ? \&_pretty_json : $format_sub;

    foreach my $file (@{$files}) {
        foreach my $file_name (glob $file) {
            if (-e $file_name) {

                # $content is chars, not bytes
                my $content = _read_file($file_name);

                my $expected_content = $sub->($content);

                if ($ENV{SELF_UPDATE}) {
                    if ($content eq $expected_content) {
                        pass("File $file_name is in expected format"),
                    } else {
                        _write_file($file_name, $expected_content);
                        pass("Writing fixed file $file_name");
                    }
                } else {
                    is($content, $expected_content, "File $file_name is in expected format"),
                }
            } else {
                fail("File $file_name does not exist");
            }
        }
    }

    return 1;
}

sub _pretty_json {
    my ($content) = @_;

    my $json_coder = JSON::PP
        ->new
        ->pretty
        ->canonical
        ->indent_length(4)
        ;

    my $data = JSON::PP->new->decode($content);
    my $pretty_json = $json_coder->encode($data);

    return $pretty_json;
}

sub _read_file {
    my ($file_name) = @_;

    my $content = '';

    open FH, '<', $file_name or die "Can't open < $file_name for reading: $!";

    while (<FH>) {
        $content .= $_;
    }

    return $content;
}

sub _write_file {
    my ($file_name, $content) = @_;

    open FH, '>', $file_name or die "Can't open $file_name for writing: $!";

    print FH $content;

    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Format - test files if they match format

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

In t/format.t file:

    use strict;
    use warnings FATAL => 'all';

    use Test::More tests => 1;
    use Test::Format;

    test_format(
        files => [
            'data/countries.json',
        ],
        format => 'pretty_json',
    );

It will check file 'data/countries.json' that it is in pretty json format.

And you can prettify all the files that test checks if you run test with
SELF_UPDATE environment variable:

    SELF_UPDATE=1 prove t/format.t

You can also write custom format checker:

    test_format(
        files => [
            'data/file.asdf',
        ],
        format_sub => sub {
            my ($content) = @_;

            # Your custom code that creates pretty $expected_content from ugly $content

            return $expected_content;
        },
    );

=head2 test_format

Sub test_format checks all the files that are specified that they match
specified format.

    test_format(
        files => [
            'data/cities/*.json',
            'data/countries/*.json',
        ],
        format => 'pretty_json',
    );

or

    test_format(
        files => [
            $file_name,
        ],
        format_sub => \&prettifier,
    );

You must specify `files` option and one of two options:
`format` or `format_sub`.

Option `files` is a ARRAYREF with list of files to be checked. If you specify relative
path it it relative of how you run your test, not the position of the test. You can use
wildcard characters in file names (internaly it is implemented with the `glob` function).

The value of `format` must be string. Now the only valid value is
'pretty_json'. Maybe in the future there some other values will be added.

The value of `format_sub` must be reference to a sub. This sub gets contents of every
file the test checks and it must return the prettified version of the content. The
$content that sub gets is chars, not bytes.

	sub {
		my ($content) = @_;

		...

		return $expected_content;
	}

Sub test_format behaviour depends of the environment variable SELF_UPDATE.
If it is not set, or have a false value, the sub just cheks all the files.
If the variable SELF_UPDATE is set to a true value the sub will fix the
files that do not have expected content - it will write expected content to
the files.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<https://github.com/bessarabov/Test-Format>

=head1 BUGS

Please report any bugs or feature requests in GitHub Issues
L<https://github.com/bessarabov/Test-Format/issues>

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
