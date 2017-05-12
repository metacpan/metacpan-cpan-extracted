package Test::Whitespaces;
{
  $Test::Whitespaces::VERSION = '1.2.1';
}

# ABSTRACT: test source code for errors in whitespaces

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use Carp;
use Cwd qw(realpath);
use File::Find;
use FindBin qw($Bin);
use Getopt::Long;
use List::Util qw(max);
use Pod::Usage;
use Term::ANSIColor qw(colored);



my $true = 1;
my $false = '';

$| = 1;

my $current_test = 0;
my $verbose = $false;
my $print_ok_files = $true;
my @ignore;

sub import {
    my ($class, $args) = @_;

    if (defined $args and ref $args ne "HASH") {
        croak "Test::Whitespaces expected to recieve hashref with params. Stopped";
    }

    if (defined $args->{ignore}) {
        croak "Parameter 'ignore' shoud contain ARRAY. Stopped" if ref $args->{ignore} ne "ARRAY";

        foreach (@{$args->{ignore}}) {
            croak "Parameter 'ignore' shoud contain ARRAY with Regexp-es. Stopped" if ref $_ ne "Regexp";
            push @ignore, $_;
        }
    }

    if (not defined $args->{dirs}) {
        $args->{dirs} = [],
    }

    if (not defined $args->{files}) {
        $args->{files} = [];
    }

    if (not $args->{_only_load}) {
        _check_dir($_) foreach @{$args->{dirs}};
        _check_file($_) foreach @{$args->{files}};
        _done_testing();
    }
}

sub _run_script {
    my (%args) = @_;

    if (not defined $args{dir}) {
        croak "_run_script expected to recieve param 'dir'. Stopped";
    }

    if (not defined $args{file}) {
        croak "_run_script expected to recieve param 'file'. Stopped";
    }

    if (not defined $args{script}) {
        croak "_run_script expected to recieve param 'script'. Stopped";
    }

    my $opt;

    GetOptions (
        "only_errors" => \$opt->{only_errors},
        "help" => \$opt->{help},
        "version" => \$opt->{version},
        "verbose" => \$opt->{verbose},
    );

    if ($opt->{help}) {
        pod2usage({
            -exitval => 0,
        });
    }

    if ($opt->{version}) {
        print "$args{script} $Test::Whitespaces::VERSION\n";
        exit 0;
    }

    if ($args{script} eq 'test_whitespaces' and $opt->{only_errors}) {
        $print_ok_files = $false;
    }

    if ($args{script} eq 'whiter' and $opt->{verbose}) {
        $verbose = $true;
    }

    unless (@ARGV) {
        print "No. Run me with some parameters, please.\n";
        exit 1;
    }

    foreach my $argv (@ARGV) {
        if (-d $argv) {
            $args{dir}->($argv);
        } elsif (-T $argv) {
            $args{file}->($argv);
        } else {
            print _colored(
                "Fatal error. '$argv' is not a directory and it is not a text file.\n",
                "red"
            );
            exit 1;
        }
    }
}

# writing custom _is() because Test::More::is() output ugly additional info
sub _is {
    my ($got, $expected, $text) = @_;

    $current_test++;

    if ($got eq $expected) {
        if ($print_ok_files) {
            print "ok $current_test - $text\n";
        }
    } else {
        print _colored("not ok", "red");
        print " $current_test - $text\n";
        my $diff =
            "# \n"
            . "# ## Failed check on file '$text':\n"
            . "# \n"
            . _get_diff($got, $expected)
            . "# \n"
            . "# \n"
            ;

        if ($ENV{HARNESS_ACTIVE}) {
            print STDERR "\n";
            print STDERR $diff;
        } else {
            print $diff;
        }
    }
}

sub _done_testing {
    print "1..$current_test\n";
};

sub _colored {
    my ($text, $color) = @_;

    if (-t STDOUT) {
        return colored($text, $color);
    } else {
        return $text;
    }
}

sub _read_file {
    my ($filename) = @_;

    open FILE, "< :encoding(UTF-8)", $filename or croak "Can't open file '$filename': $!. Stopped";
    my @lines = <FILE>;
    close FILE;

    my $content = join '', @lines;

    return $content;
}

sub _write_file {
    my ($filename, $content) = @_;

    open FILE, "> :encoding(UTF-8)", $filename or croak "Can't open file '$filename': $!. Stopped";
    print FILE $content;
    close FILE;

    return $false;
}

sub _get_fixed_text {
    my ($original_text) = @_;

    my $fixed_text;

    my @lines = split(/\n/, $original_text);

    foreach my $line (@lines) {
        $line =~ s{\t}{    }g;
        $line =~ s{\s*$}{\n};
        $fixed_text .= $line;
    }

    $fixed_text .= "\n";
    $fixed_text =~ s{\s*$}{\n};

    return $fixed_text;
}

sub _get_diff {
    my ($got, $expected) = @_;

    croak "Expected 'got'. Stopped" if not defined $got;
    croak "Expected 'expected'. Stopped" if not defined $expected;

    my $return;

    if ($got eq "") {
        $return .= "# line 1 ";
        $return .= _colored("No \\n on line", "red");
        $return .= "\n";

        return $return;
    }

    my $diff = '';

    my @got_lines = split /\n/, $got, -1;
    my @expected_lines = split /\n/, $expected, -1;

    my %error_lines;    # key - line number, value - line content

    my $lines_in_file = max(scalar @got_lines, scalar @expected_lines);
    foreach my $line_number (1 .. $lines_in_file) {
        my $i = $line_number - 1;

        if (not defined $got_lines[$i]) {
            # no \n on the last line
            $error_lines{$line_number-1} = $got_lines[$i-1];
            next;
        }

        if (not defined $expected_lines[$i] or ($got_lines[$i] ne $expected_lines[$i])) {
            # empty lines in the end of file or some problems with whitespaces
            $error_lines{$line_number} = $got_lines[$i] . "\n";
        }
    }

    my $previous_line_number = 0;
    foreach my $line_number (sort {$a <=> $b} keys %error_lines) {

        if ($previous_line_number + 1 != $line_number) {
            $return .= "# ...\n";
        }

        $return .= _get_diff_line($line_number, $error_lines{$line_number});

        $previous_line_number = $line_number;
    }

    return $return;
}

sub _get_diff_line {
    my ($line_number, $error_line) = @_;

    my $diff_line;

    if ($error_line eq "\n") {
        $diff_line .= "# line $line_number \\n ";
        $diff_line .= _colored("Empty line in the end of file", "red");
        $diff_line .= "\n";

        return $diff_line;
    }

    # array of hashes:
    # { status => 'correct', text => 'a' },
    # { status => 'error', text => '__' },
    # { status => 'correct', text => '\n' },
    my @parsed_line = _split_error_line($error_line);

    my $prefix = "# line $line_number: ";
    my $spacer = "...";
    my $max_length = 78;
    my $system_length = length($prefix . $spacer);
    my $max_text_length = $max_length - $system_length;

    my $line;
    map { $line .= $_->{text}} @parsed_line;

    my $symbols_to_skip = length($line) - $max_text_length;

    my $skipped_length = 0;

    $diff_line .= $prefix;

    if ($symbols_to_skip > 0) {
        $diff_line .= $spacer;
    }

    foreach (@parsed_line) {

        if ($skipped_length < $symbols_to_skip) {
            my $removed = substr $_->{text}, 0, ($symbols_to_skip - $skipped_length), '';
            $skipped_length += length($removed);
        }

        if ($_->{status} eq 'correct') {
            $diff_line .= $_->{text};
        } else {
            $diff_line .= _colored($_->{text}, 'red');
        }
    }
    $diff_line .= "\n";

    return $diff_line;
}

sub _split_error_line {
    my ($error_line) = @_;

    my @parsed_line;

    my $correct_part = '';
    my $error_part = '';

    # Value of $prev_status can be 'correct' or 'error'
    my $prev_status = '';

    my $was_change = $false;

    foreach my $i (0..(length($error_line)-1)) {
        my $symbol = substr($error_line, $i, 1);
        my $rest = substr($error_line, $i+1);

        if ($symbol eq "\t" or $symbol eq "\r") {
            $symbol =~ s{\t}{\\t}g;
            $symbol =~ s{\r}{\\r}g;

            $error_part .= $symbol;
            if ($prev_status eq 'correct') {
                $was_change = $true
            }
            $prev_status = 'error';
        } elsif ($symbol =~ / / and $rest =~ /^\s*$/) {
            $error_part .= "_";

            if ($prev_status eq 'correct') {
                $was_change = $true
            }
            $prev_status = 'error';
        } else {
            $symbol =~ s{\n}{\\n}g;
            $correct_part .= $symbol;

            if ($prev_status eq 'error') {
                $was_change = $true
            }
            $prev_status = 'correct';
        }

        if ($was_change) {
            if ($prev_status eq 'error') {
                push @parsed_line, { status => 'correct', text => $correct_part };
                $correct_part = '';
            } elsif ($prev_status eq 'correct') {
                push @parsed_line, { status => 'error', text => $error_part };
                $error_part = '';
            }
            $was_change = $false;
        }
    }

    if ($prev_status eq 'correct') {
        push @parsed_line, { status => 'correct', text => $correct_part };
    } elsif ($prev_status eq 'error') {
        push @parsed_line, { status => 'error', text => $error_part };
        $error_part = '';
    }

    return @parsed_line;
}

sub _file_is_in_vcs_index {
    my ($filename) = @_;

    if (-d $filename) {
        croak "Internal error. $filename is dir. It can't happen. Stopped";
    }

    if (not -T $filename) {
        croak "Internal error. $filename is not a text file. It can't happen. Stopped";
    }

    my @vcs_dirs = qw(
        .git
        .hg
        .svn
    );

    my @parts = split "/", $filename;
    pop @parts; # last element is filename, but we need only directories

    foreach my $part (@parts) {
        foreach my $vcs (@vcs_dirs) {
            return $true if $part eq $vcs;
        }
    }

    return $false;
}

sub _check_file {
    my ($filename) = @_;

    return if not defined $filename;

    $filename = realpath($filename);

    if (-T $filename) {
        return if _file_is_in_vcs_index($filename);

        foreach my $regexp (@ignore) {
            return if $filename =~ $regexp;
        }

        my $content = _read_file($filename);
        my $fixed_content = _get_fixed_text($content);

        my $module_path = realpath("$Bin/..") . "/";
        my $relative_filename = $filename;
        $relative_filename =~ s{^$module_path}{};

        _is($content, $fixed_content, "$relative_filename");
    }

}

sub _check_dir {
    my ($dir) = @_;

    find(
        {
            wanted => sub { _check_file($File::Find::fullname) },
            follow => 1,
        },
        $dir,
    );
}

sub _fix_file {
    my ($filename) = @_;

    return if not defined $filename;

    if (-T $filename) {
        return if _file_is_in_vcs_index($filename);

        my $content = _read_file($filename);
        my $fixed_content = _get_fixed_text($content);

        if ($content ne $fixed_content) {
            _write_file($filename, $fixed_content);
            print "Repairing $filename\n" if $verbose;
        } else {
            print "File is correct $filename\n" if $verbose;
        }
    }
}

sub _fix_dir {
    my ($dir) = @_;

    find(
        {
            wanted => sub { _fix_file($File::Find::fullname) },
            follow => 1,
        },
        $dir,
    );
}

1;

__END__

=pod

=head1 NAME

Test::Whitespaces - test source code for errors in whitespaces

=head1 VERSION

version 1.2.1

=head1 SYNOPSIS

In xt/whitespaces.t (read FAQ section to find out why it is recommended to
place test file in xt directory):

    use Test::Whitespaces {

        # Directories to check all the files from
        dirs => [
            'bin',
            'examples',
            'lib',
            't',
        ],

    };

The test will check all the files specified by parameters. It will pretty
print all the errors, so it is easy to undestand where is the problem.

=head1 DESCRIPTION

This module is intend to solve one simple task: to make sure that your source
code don't have problems with whitespaces.

This module checks that all the rules are followed.

=over

=item * Each line ends with "\n" (including the last line)

=item * For new lines "\n" is used (not "\r\n")

=item * There are no ending spaces on the lines

=item * 4 spaces are used instead of tabs

=item * No empty lines in the end of file

=back

This module don't export any subroutines, you only need to write a test file
and write there:

    use Test::Whitespaces { dirs => ['lib'] };

Here is the full list of all avaliable parameters:

    use Test::Whitespaces {

        # Directories to check all the files from
        dirs => [ 'lib', 'bin', 't' ],

        # Files to be checekd (if you don't need to check the whole dir)
        files => [ 'README' ],

        # Files that matches any of this regexp will not be checked
        ignore => [ qr{\.bak$} ],

    };

This module does not check the files that are stored in the version control
system directories (you remember, that .git, .svn and friends).

This module is shiped with 2 scripts. `L<test_whitespaces>` to easy check
files and directories and `L<whiter>` to fix all that errors.

And by the way, this module don't have any dependencies, but Perl. It does not
matter much, but it is nice =)

=encoding UTF-8

=head1 FAQ

=head2 Why not to use perltidy instead of this module?

Perltidy is a great thing. It fixes some whitespace problems in the Perl
source code. But sometimes you don't need the whole perltidy possibilities,
but only want to make your whitespaces accurate. Adding Test::Whitespaces
to the project affects less than adding perltidy. And with Test::Whitespaces
you can test and fix not only the Perl source code, but any texts. For
example, you can make sure that you javasript code has no problems with
whitespaces or you can fix your text files.

=head2 Why there is no default values?

The idea behind this test is to make delelopers work simplier. There are a
lot of things a developer should remember. I don't want to ask developers to
remember the default values of this module. The person writing test should
write the exact list of thing to check, but such precise writing simplifies
the work of person who reads the code.

=head2 What Perl version do I need to use Test::Whitespaces?

This module works with Perl 5.8.0 and above. In Perl 5.8.0 the better
Unicode support was implemented that is needed for this module.

=head2 What is the logic for version numbering?

Test::Whitespaces version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head2 Why it is recommended to place test file in xt directory?

I recomend create test file as xt/whitespaces.t, not t/whitespaces.t.
Directory `t` stores all the tests that will be run when the user installs
module from CPAN. If you add testing whitespaces of the module to the `t`
directory you will need to add dependency Test::Whitespaces to your module.
But checking whitespaces does matter for the module author, and does not
matter for the module user. I think that we should simplify module user life
and not to oblige the user to install Test::Whitespaces. Directory `xt` is for
extened tests. That tests are run by the module author, but are not run when
the user installs module from CPAN. So xt directory is the perfect place to
store file that checks whitespaces.

=head1 SEE ALSO

If this module is not what you need, you may try to look to these modules (but
I hope you will prefer to use Test::Whitespaces):

=over

=item * L<Test::EOL>

=item * L<Test::NoTabs>

=item * L<Test::Tabs>

=item * L<Test::TrailingSpace>

=back

=head1 CONTRIBUTORS

=over 4

=item * Rob Hoelz (RHOELZ)

=item * Michael Jemmeson (MJEMMESON)

=back

=head1 SOURCE CODE

The source code for this module and scripts is hosted on GitHub
L<https://github.com/bessarabov/Test-Whitespaces>

=head1 BUGS

Please report any bugs or feature requests in GitHub Issues
L<https://github.com/bessarabov/Test-Whitespaces/issues>

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
