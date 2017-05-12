package Test::Mojibake;
# ABSTRACT: check your source for encoding misbehavior.


use strict;
use warnings qw(all);

our $VERSION = '1.3'; # VERSION

use File::Spec::Functions;
use Test::Builder;

my %ignore_dirs = (
    '.bzr'  => 'Bazaar',
    '.git'  => 'Git',
    '.hg'   => 'Mercurial',
    '.pc'   => 'quilt',
    '.svn'  => 'Subversion',
    CVS     => 'CVS',
    RCS     => 'RCS',
    SCCS    => 'SCCS',
    _darcs  => 'darcs',
    _sgbak  => 'Vault/Fortress',
);

my $Test = Test::Builder->new;

# Use a faster/safer XS alternative, if present

## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval, ProhibitPackageVars)
our ($use_xs, $use_pp) = (0, 0);
if ( eval 'require Unicode::CheckUTF8' ) {
    $use_xs = 1;
}
elsif ( eval 'require Unicode::CheckUTF8::PP' ) {
    $use_pp = 1;
}

sub import {
    my ($self, @args) = @_;
    my $caller = caller;

    for my $func (qw(file_encoding_ok all_files all_files_encoding_ok)) {
        ## no critic (ProhibitNoStrict)
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $Test->exported_to($caller);
    $Test->plan(@args);

    return;
}


## no critic (ProhibitCascadingIfElse, ProhibitExcessComplexity)
sub file_encoding_ok {
    my ($file, $name) = @_;
    $name = defined($name) ? $name : "Mojibake test for $file";

    ## no critic (ProhibitFiletest_f)
    unless (-f $file) {
        $Test->ok(0, $name);
        $Test->diag("$file does not exist");
        return;
    }

    my $fh;
    unless (open($fh, '<:raw', $file)) {
        close $fh;
        $Test->ok(0, $name);
        $Test->diag("Can't open $file: $!");
        return;
    }

    my $use_utf8    = 0;
    my $pod         = 0;
    my $pod_utf8    = 0;
    my $n           = 1;
    my %pod         = ();
    while (my $line = <$fh>) {
        if (($n == 1) && $line =~ /^\x{EF}\x{BB}\x{BF}/x) {
            $Test->ok(0, $name);
            $Test->diag("UTF-8 BOM (Byte Order Mark) found in $file");
            return;
        } elsif ($line =~ /^=+cut\s*$/x) {
            $pod = 0;
        } elsif ($line =~ /^=+encoding\s+([\w\-]+)/x) {
            my $pod_encoding = lc $1;
            $pod_encoding =~ y/-//d;

            # perlpod states:
            # =encoding affects the whole document, and must occur only once.
            ++$pod{$pod_encoding};
            if (1 < scalar keys %pod) {
                $Test->ok(0, $name);
                $Test->diag("POD =encoding redeclared in $file, line $n");
                return;
            }

            $pod_utf8 = ($pod_encoding eq 'utf8') ? 1 : 0;
            $pod = 1;
        } elsif ($line =~ /^=+\w+/x) {
            $pod = 1;
        } elsif ($pod == 0) {
            # source
            $line =~ s/^\s*\#.*$//sx;  # disclaimers placed in headers frequently contain UTF-8 *before* its usage is declared.
            foreach (split m{;}x, $line) {
                # trim
                s/^\s+|\s+$//gsx;

                my @type = qw(0 0 0);
                ++$type[_detect_utf8(\$_)];
                my ($latin1, $utf8) = @type[0, 2];

                if (/^use\s+utf8(?:::all)?$/x) {
                    $use_utf8 = 1;
                } elsif (/^use\s+common::sense$/x) {
                    $use_utf8 = 1;
                } elsif (/^no\s+utf8$/x) {
                    $use_utf8 = 0;
                }

                if (($use_utf8 == 0) && $utf8) {
                    $Test->ok(0, $name);
                    $Test->diag("UTF-8 unexpected in $file, line $n (source)");
                    return;
                } elsif (($use_utf8 == 1) && $latin1) {
                    $Test->ok(0, $name);
                    $Test->diag("Non-UTF-8 unexpected in $file, line $n (source)");
                    return;
                }
            }
        } else {
            # POD
            my @type = qw(0 0 0);
            ++$type[_detect_utf8(\$line)];
            my ($latin1, $utf8) = @type[0, 2];

            if (($pod_utf8 == 0) && $utf8) {
                $Test->ok(0, $name);
                $Test->diag("UTF-8 unexpected in $file, line $n (POD)");
                return;
            } elsif (($pod_utf8 == 1) && $latin1) {
                $Test->ok(0, $name);
                $Test->diag("Non-UTF-8 unexpected in $file, line $n (POD)");
                return;
            }
        }
    } continue {
        ++$n;
    }
    close $fh;

    $Test->ok(1, $name);
    return 1;
}


sub all_files_encoding_ok {
    my (@args) = @_;
    @args = _starting_points() unless @args;

    ## no critic (ProhibitFiletest_f)
    my @files = map { -d $_ ? all_files($_) : (-f $_ ? $_ : ()) } @args;

    unless (@files) {
        $Test->plan(skip_all => 'could not find any files to test');
        return;
    }

    $Test->plan(tests => scalar @files);

    my $ok = 1;
    foreach my $file (@files) {
        file_encoding_ok($file) or undef $ok;
    }
    return $ok;
}


sub all_files {
    my (@queue) = @_;
    @queue = _starting_points() unless @queue;
    my @mod = ();

    while (@queue) {
        my $file = shift @queue;
        if (-d $file) {
            opendir my $dh, $file or next;
            my @newfiles = readdir $dh;
            closedir $dh;

            @newfiles = no_upwards(@newfiles);
            @newfiles = grep { not exists $ignore_dirs{$_} } @newfiles;

            foreach my $newfile (@newfiles) {
                my $filename = catfile($file, $newfile);
                unless (-d $filename) {
                    push @queue, $filename;
                } else {
                    push @queue, catdir($file, $newfile);
                }
            }
        }

        ## no critic (ProhibitFiletest_f)
        if (-f $file) {
            push @mod, $file if _is_perl($file);
        }
    }
    return @mod;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub _is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/x;
    return 1 if $file =~ /\.p(?:l|m|od)$/x;
    return 1 if $file =~ /\.t$/x;

    open my $fh, '<', $file or return;
    my $first = <$fh>;
    close $fh;

    return 1 if defined $first && ($first =~ /(?:^\#!.*perl)|--\*-Perl-\*--/x);

    return;
}


sub _detect_utf8 {

    use bytes;
    use integer;

    my $str     = shift;

    if ($use_xs) {
        if (Unicode::CheckUTF8::is_utf8(${$str})) {
            return (${$str} =~ m{[\x{80}-\x{ff}]}x) ? 2 : 1
        } else {
            return 0;
        }
    } elsif ($use_pp) {
        if (Unicode::CheckUTF8::PP::is_utf8(${$str})) {
            return (${$str} =~ m{[\x{80}-\x{ff}]}x) ? 2 : 1
        } else {
            return 0;
        }
    }

    my $d       = 0;
    my $c       = 0;
    my $bv      = 0;
    my $bits    = 0;
    my $len     = length ${$str};

    for (my $i = 0; $i < $len; $i++) {
        $c = ord(substr(${$str}, $i, 1));
        if ($c >= 128) {
            $d++;

            if ($c >= 254) {
                return 0;
            } elsif ($c >= 252) {
                $bits = 6;
            } elsif ($c >= 248) {
                $bits = 5;
            } elsif ($c >= 240) {
                $bits = 4;
            } elsif ($c >= 224) {
                $bits = 3;
            } elsif ($c >= 192) {
                $bits = 2;
            } else {
                return 0;
            }

            if (($i + $bits) > $len) {
                return 0;
            }

            my @buf = ((0) x 4, $c & ((1 << (7 - $bits)) - 1));
            while ($bits > 1) {
                $i++;
                $bv = ord(substr(${$str}, $i, 1));
                if (($bv < 128) || ($bv > 191)) {
                    return 0;
                }
                $buf[7 - $bits] = $bv & 0x3f;
                $bits--;
            }
            return 0 if "\0\0\0\0\0\x2f" eq pack 'c6', @buf;
        } elsif ($c == 0) {
            return 0;
        }
    }

    return $d ? 2 : 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mojibake - check your source for encoding misbehavior.

=head1 VERSION

version 1.3

=head1 SYNOPSIS

    # Test::Mojibake lets you check for inconsistencies in source/documentation encoding, and report its results in standard Test::Simple fashion.
    no strict 'vars';

    use Test::Mojibake;
    file_encoding_ok($file, 'Valid encoding');
    done_testing($num_tests);

=head1 DESCRIPTION

Many modern text editors automatically save files using UTF-8 codification, however, L<perl> interpreter does not expects it I<by default>. Whereas this does not represent a big deal on (most) backend-oriented programs, Web framework (L<Catalyst|http://www.catalystframework.org/>, L<Mojolicious|http://mojolicio.us/>) based applications will suffer of so-called L<Mojibake|http://en.wikipedia.org/wiki/Mojibake> (lit. "unintelligible sequence of characters").

Even worse: if an editor saves BOM (Byte Order Mark, C<U+FEFF> character in Unicode) at the start of the script with executable bit set (on Unix systems), it won't execute at all, due to shebang corruption.

Avoiding codification problems is quite simple:

=over 4

=item *

Always C<use utf8>/C<use common::sense> when saving source as UTF-8;

=item *

Always specify C<=encoding UTF-8> when saving POD as UTF-8;

=item *

Do neither of above when saving as ISO-8859-1;

=item *

B<Never> save BOM (not that it's wrong; just avoid it as you'll barely notice it's presence when in trouble).

=back

However, if you find yourself upgrading old code to use UTF-8 or trying to standardize a big project with many developers each one using a different platform/editor, reviewing all files manually can be quite painful. Specially in cases when some files have multiple encodings (note: it all started when I realized that I<Gedit> & derivatives are unable to open files with character conversion tables).

Enter the L<Test::Mojibake> C<;)>

=head1 FUNCTIONS

=head2 file_encoding_ok( FILENAME[, TESTNAME ] )

Validates the codification of C<FILENAME>.

When it fails, C<file_encoding_ok()> will report the probable cause.

The optional second argument C<TESTNAME> is the name of the test.  If it is omitted, C<file_encoding_ok()> chooses a default test name "Mojibake test for FILENAME".

=head2 all_files_encoding_ok( [@entries] )

Validates codification of all the files under C<@entries>. It runs C<all_files()> on directories and assumes everything else to be a file to be tested. It calls the C<plan()> function for you (one test for each file), so you can't have already called C<plan>.

If C<@entries> is empty or not passed, the function finds all source/documentation files in files in the F<blib> directory if it exists, or the F<lib> directory if not. A source/documentation file is one that ends with F<.pod>, F<.pl> and F<.pm>, or any file where the first line looks like a shebang line.

=head2 all_files( [@dirs] )

Returns a list of all the Perl files in I<@dirs> and in directories below. If no directories are passed, it defaults to F<blib> if F<blib> exists, or else F<lib> if not. Skips any files in CVS, .svn, .git and similar directories. See C<%Test::Mojibake::ignore_dirs> for a list of them.

A Perl file is:

=over 4

=item *

Any file that ends in F<.PL>, F<.pl>, F<.pm>, F<.pod>, or F<.t>;

=item *

Any file that has a first line with a shebang and C<"perl"> on it;

=item *

Any file that ends in F<.bat> and has a first line with C<"--*-Perl-*--"> on it.

=back

The order of the files returned is machine-dependent.  If you want them sorted, you'll have to sort them yourself.

=head2 _detect_utf8( \$string )

Detects presence of UTF-8 encoded characters in a referenced octet stream.

Return codes:

=over 4

=item *

0 - 8-bit characters detected, does not validate as UTF-8;

=item *

1 - only 7-bit characters;

=item *

2 - 8-bit characters detected, validates as UTF-8.

=back

L<Unicode::CheckUTF8> is highly recommended, however, it is optional and this function will fallback to the Pure Perl implementation of the following PHP code: L<http://www.php.net/manual/en/function.utf8-encode.php#85293>

=head1 SAMPLE TEST SCRIPT

Module authors can include the following in a F<t/mojibake.t> file and have L<Test::Mojibake> automatically find and check all source files in a module distribution:

    #!perl -T
    use strict;

    BEGIN {
        unless ($ENV{RELEASE_TESTING}) {
            require Test::More;
            Test::More::plan(skip_all => 'these tests are for release candidate testing');
        }
    }

    use Test::More;

    eval 'use Test::Mojibake';
    plan skip_all => 'Test::Mojibake required for source encoding testing' if $@;

    all_files_encoding_ok();

=head1 OPERATION

L<Test::Mojibake> validates codification of both source (Perl code) and documentation (POD). Both are assumed to be encoded in ISO-8859-1 (aka latin1). Perl switches to UTF-8 through the statement:

 use utf8;

or:

 use utf8::all;

or even:

 use common::sense;

Similarly, POD encoding can be changed via:

 =encoding UTF-8

Correspondingly, C<no utf8>/C<=encoding latin1> put Perl back into ISO-8859-1 mode.

Actually, L<Test::Mojibake> only cares about UTF-8, as it is roughly safe to be detected. So, when UTF-8 characters are detected without preceding declaration, an error is reported. On the other way, non-UTF-8 characters in UTF-8 mode are wrong, either.

If present, L<Unicode::CheckUTF8> module (XS wrapper) will be used to validate UTF-8 strings, note that it is B<30 times faster> and a lot more Unicode Consortium compliant than the built-in Pure Perl implementation!

UTF-8 BOM (Byte Order Mark) is also detected as an error. While Perl is OK handling BOM, your OS probably isn't. Check out:

 ./bom.pl: line 1: $'\357\273\277#!/usr/bin/perl': command not found

=head2 Caveats

Whole-line source comments, like:

 # this is a whole-line comment...
 print "### hello world ###\n"; # ...and this os not

are not checked at all. This is mainly because many scripts/modules do contain authors' names in headers, B<before> the proper encoding specification. So, if you happen to have some acutes/umlauts in your name and your editor sign your code in the similar way, you probably won't be happy with L<Test::Mojibake> flooding you with (false) error messages.

If you are wondering why only whole-line comments are stripped, check the second line of the above example.

=head1 SEE ALSO

=over 4

=item *

L<scan_mojibake>

=item *

L<common::sense>

=item *

L<utf8::all>

=item *

L<Dist::Zilla::Plugin::MojibakeTests>

=item *

L<Test::Perl::Critic>

=item *

L<Test::Pod>

=item *

L<Test::Pod::Coverage>

=item *

L<Test::Kwalitee>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on L<Test::Pod>.

Thanks to
Andy Lester,
David Wheeler,
Paul Miller
and
Peter Edwards
for contributions and to C<brian d foy> for the original code.

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Hunter McMillen John SJ Anderson Karen Etheridge

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Hunter McMillen <mcmillhj@gmail.com>

=item *

John SJ Anderson <john@genehack.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=cut
