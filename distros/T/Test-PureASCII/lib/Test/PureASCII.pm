package Test::PureASCII;

our $VERSION = '0.02';

use strict;
use warnings;

use Test::Builder;
use File::Spec;

my $test = Test::Builder->new;

our @TESTED;

sub import {
    my $self = shift;
    my $caller = caller;

    for my $func ( qw( file_is_pure_ascii all_perl_files_are_pure_ascii all_files_are_pure_ascii) ) {
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $test->exported_to($caller);
    $test->plan(@_);
}

sub _skip_file_p {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';
    if (defined(my $skip = $opts{skip})) {
        my $file = shift;
        for my $s (ref $skip eq 'ARRAY' ? @$skip : $skip) {
            if (ref $s eq 'Regexp') {
                return 1 if $file =~ $s;
            }
            else {
                return 1 if $file eq $s;
            }
        }
    }
    return 0;
}

sub _make_error {
    my ($bad, $error, $ln, $file) = @_;
    my @chars = map sprintf("0x%02x", ord $_), split //, $bad;
    my $chars = join(', ', @chars);
    my $s = @chars > 1 ? ' sequence' : '';
    '  ' . sprintf($error, $s, $chars) . " at line $ln in $file";
}

sub file_is_pure_ascii {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';
    my $skip_data = $opts{skip_data};
    my $forbid_control = $opts{forbid_control};
    my $forbid_cr = $opts{forbid_cr};
    my $forbid_tab = $opts{forbid_tab};
    my $require_crlf = $opts{require_crlf};

    my $file = shift;

    _skip_file_p(\%opts, $file) and return 1;

    my $name = @_ ? shift : "Pure ASCII test for $file";

    push @TESTED, $file;
    # $test->diag("FILE: $file");

    my $fh;
    unless (open $fh, '<', $file) {
        $test->ok(0, $name);
        $test->diag("  unable to open '$file': $!");
        return 0;
    }
    binmode $fh, ':bytes';

    my $failed = 0;
    while (<$fh>) {
        # $test->diag("line $.: $_");
        next if /\bpa_test_ignore\b/;
        last if /\bpa_test_end\b/;
        if (my ($lines) = /pa_test_skip_lines\(\d+\)/) {
            <$fh> for 1..$lines;
            next;
        }

        my @errors;
        /([^\x00-\x7f]+)/ and
            push @errors, _make_error($1, "non ASCII character%s %s",
                                      $., $file);
        $forbid_control and /([\x00-\x08\x0b-\x1F])/ and
            push @errors, _make_error($1, "forbidden control character%s %s",
                                      $., $file);
        $forbid_tab and /([\x09])/ and
            push @errors, _make_error($1, "forbidden tab character%s %s",
                                      $., $file);
        $forbid_cr and /([\x0d])/ and
            push @errors, _make_error($1, "forbidden CR character%s %s",
                                      $., $file);
        $require_crlf and /(\x0d(?!\x0a)|(?<!\x0d)\x0a)/ and
            push @errors, _make_error($a, "forbidden end of line character%s %s",
                                      $., $file);

        if (@errors) {
            $test->ok(0, $name) unless $failed;
            $test->diag($_) for @errors;
            $failed = 1;
        }

        last if ($skip_data and /^__DATA__$/);
    }
    unless (close $fh) {
        $test->ok(0, $name) unless $failed;
        $test->diag("  unable to read from '$file': $!");
        return 0;
    }
    $failed ? 0 : $test->ok(1, $name);
}

sub all_perl_files_are_pure_ascii {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';

    my @files = all_perl_files(\%opts, @_);

    $test->plan( tests => scalar @files );

    my $ok = 1;
    foreach my $file (@files) {
        file_is_pure_ascii(\%opts, $file) or undef $ok;
    }
    return $ok;
}

sub all_files_are_pure_ascii {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';

    my @files = all_files(\%opts, @_);
    $test->plan( tests => scalar @files );

    my $ok = 1;
    foreach my $file (@files) {
        file_is_pure_ascii(\%opts, $file) or undef $ok;
    }
    return $ok;
}

sub all_perl_files {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';

    my @queue = @_ ? @_ : starting_points();
    my @perl = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my $dh, $file or next;
            my @newfiles = readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" and $_ ne ".svn" and !/~$/ } @newfiles;

            foreach my $newfile (@newfiles) {
                my $filename = File::Spec->catfile( $file, $newfile );
                if ( -f $filename ) {
                    push @queue, $filename;
                }
                else {
                    push @queue, File::Spec->catdir( $file, $newfile );
                }
            }
        }
        if ( -f $file ) {
            push @perl, $file if is_perl( $file );
        }
    }
    return @perl;
}

sub all_files {
    my %opts;
    %opts = %{shift @_} if ref $_[0] eq 'HASH';

    my @queue = @_ ? @_ : '.';
    my @all = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my $dh, $file or next;
            my @newfiles = readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" and $_ ne ".svn" and !/~$/ } @newfiles;

            foreach my $newfile (@newfiles) {
                my $filename = File::Spec->catfile( $file, $newfile );
                if ( -f $filename ) {
                    push @queue, $filename;
                }
                else {
                    push @queue, File::Spec->catdir( $file, $newfile );
                }
            }
        }
        push @all, $file if -f $file
    }
    return @all;
}

sub starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|m|od)$/;
    return 1 if $file =~ /\.t$/;

    open my $fh, $file or return;
    my $first = <$fh>;
    close $fh;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return;
}


1;

__END__

=head1 NAME

Test::PureASCII - Test that only ASCII characteres are used in your code

=head1 SYNOPSIS

  use Test::PureASCII;
  all_perl_files_are_pure_ascii();

or

  use Test::PureASCII tests => $how_many;
  file_is_pure_ascii($filename1, "only ASCII in $filaname1");
  file_is_pure_ascii({ skip_data => 1 }, $filename2, "only ASCII in $filaname2");
  ...

The usual pure-ASCII test looks like:

  use Test::More;
  eval "use Test::PureASCII";
  plan skip_all => "Test::PureASCII required" if $@;
  all_perl_files_are_pure_ascii();

=head1 DESCRIPTION

This module allows to create tests to ensure that only 7-bit ASCII
characters are used on Perl source files.

=head2 EXPORT

The functions available from this module are described next.

All of them accept as first argument a reference to a hash containing
optional parameters. The usage of those parameters is explained on the
L<Options> subchapter.

=over 4

=item file_is_pure_ascii([\%opts,] $filename [, $test_name])

checks that C<$filename> contains only ASCII characters.

The optional argument C<$test_name> will be included on the output
when reporting errors.

=item all_perl_files_are_pure_ascii([\%opts,] @dirs)

find all the Perl source files contained in directories C<@dirs>
recursively and check that they only contain ASCII characters.

C<blib> is used as the default directory if none is given.


=item all_files_are_pure_ascii([\%opts,] @dirs)

find all the files (Perl and non-Perl) contained in directories
C<@dirs> recursively and check that they only contain ASCII
characters.

The current directory is used as the default directory if none is
given.

=back

=head3 Options

All the functions from this module accept the following options:

=over 4

=item skip => \@list_of_files

@list_of_files can contain any combination of string and references to
regular expressions. Files matching any of the entries will be skipped.

For instance:

  all_files_are_pure_ascii({ skip => [qr/\.dat$/] });

=item skip_data => 1

On Perl files, skip any C<__DATA__> section found at the end.

=item forbid_control => 1

Tests fail when any control character that is not tab, CR neither LF is
found.

=item forbid_tab => 1

Tests fail when tab characters are found.

=item forbid_cr => 1

Tests fail when carriage return (CR) characters are found. That can be
useful when you want to force people working on your project to use
the Unix conventions for line endings.

=item require_crlf => 1

Test fail when any CR or LF not being part of a CRLF sequence is
found. That can be useful when you want to stick to Windows line
ending conventions.

=back

=head2 HINTS

The module recognizes some sequences or hints on the tested files that
allow to skip specific exceptions. Usually you would include them as
Perl comments.

=over 4

=item pa_test_ignore

the line where this token is found is not checked for pure-ascii

=item pa_test_skip_lines($n)

the line where this token is found and the following $n are skipped

=item pa_test_end

the test for this file ends when this token is found

=back

=head1 SEE ALSO

A nice table containing Unicode and Latin1 codes for common (at least
in Europe) non-ASCII characters is available from
L<http://www.alanwood.net/demos/ansi.html>.

=head1 AUTHOR

Salvador FaE<ntilde>dino, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Qindel Formacion y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

This module contains code copied from L<Test::Pod> Copyright (C) 2006
by Andy Lester.


=cut
