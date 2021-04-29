use 5.10.1;
use strict;
use warnings;

package Test::EOF;

our $VERSION = '0.0804';
# ABSTRACT: Check correct end of files in a project.
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY

use Cwd qw/cwd/;
use File::Find;
use File::ReadBackwards;
use Test::Builder;

my $perlstart = qr/^#!.*perl/;
my $test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    {
        no strict 'refs';
        *{ $caller.'::all_perl_files_ok'} = \&all_perl_files_ok;
    }
    $test->exported_to($caller);
    $test->plan(@_);
}

sub all_perl_files_ok {
    my $options = ref $_[0] eq 'HASH' ? shift : ref $_[-1] eq 'HASH' ? pop : {};
    my @files = _all_perl_files(@_);

    $test->expected_tests;

    # no need to check then...
    if(exists $options->{'minimum_newlines'} && $options->{'minimum_newlines'} <= 0) {
        return 1;
    }

    foreach my $file (@files) {
        _check_perl_file($file, $options);
    }
}

sub _check_perl_file {
    my $file = shift;
    my $options = shift;

    $options->{'minimum_newlines'} ||= 1;
    if(!exists $options->{'maximum_newlines'}) {
        $options->{'maximum_newlines'} = $options->{'minimum_newlines'} + 3;
    }
    elsif(exists $options->{'maximum_newlines'} && $options->{'maximum_newlines'} < $options->{'minimum_newlines'}) {
        $options->{'maximum_newlines'} = $options->{'minimum_newlines'};
    }

    if($options->{'strict'}) {
        $options->{'minimum_newlines'} = 1;
        $options->{'maximum_newlines'} = 1;
    }

    $file = _module_to_path($file);

    my $reader = File::ReadBackwards->new($file) or return;

    my $linecount = 0;

    LINE:
    while(my $line = $reader->readline) {
        ++$linecount if $line =~ m{\v$};
        next LINE if $line =~ m{^\v$};
        last LINE;
    }

    if($linecount < $options->{'minimum_newlines'}) {
        my $wanted = make_wanted($options);
        $test->ok(0, "Not enough line breaks (had $linecount, wanted $wanted) at the end of $file");
        return 0;
    }
    elsif($linecount > $options->{'maximum_newlines'}) {
        my $wanted = make_wanted($options);
        $test->ok(0, "Too many line breaks (had $linecount, wanted $wanted) at the end of $file ");
        return 0;
    }
    $test->ok(1, "Just the right number of line breaks at the end of $file");
    return 1;

}

sub make_wanted {
    my $options = shift;
    return $options->{'minimum_newlines'} if $options->{'minimum_newlines'} == $options->{'maximum_newlines'};
    return sprintf "%d to %d" => $options->{'minimum_newlines'}, $options->{'maximum_newlines'};
}

sub _all_perl_files {
    my @base_dirs = @_ ? @_ : cwd();
    my @found;

    my $wants = sub {
        return if $File::Find::dir =~ m{ [\\/]? (?:CVS|\.svn) [\\/] }x;
        return if $File::Find::dir =~ m{ [\\/]? blib [\\/] (?: libdoc | man\d) $  }x;
        return if $File::Find::dir =~ m{ [\\/]? inc }x;
        return if $File::Find::name =~ m{ Build $ }xi;
        return unless -f -r $File::Find::name;
        push @found => File::Spec->no_upwards($File::Find::name);
    };
    my $find_arg = {
        wanted => $wants,
        no_chdir => 1,
    };

    find($find_arg, @base_dirs);

    my @perls = grep { _is_perl($_) || _is_perl($_) } @found;

    return @perls;
}

sub _is_perl {
    my $file = shift;

    # module
    return 1 if $file =~ m{\.pm$}i;
    return 1 if $file =~ m{::};

    # script
    return 1 if $file =~ m{\.pl}i;
    return 1 if $file =~ m{\.t$};

    open my $fh, '<', $file or return;
    my $first = <$fh>;
    if(defined $first && $first =~ $perlstart) {
        close $fh;
        return 1;
    }

    # nope
    return;
}

sub _module_to_path {
    my $file = shift;
    return $file unless $file =~ m{::};
    my @parts = split /::/ => $file;
    my $module = File::Spec->catfile(@parts) . '.pm';

    CANDIDATE:
    foreach my $dir (@INC) {
        my $candidate = File::Spec->catfile($dir, $module);
        next CANDIDATE if !-e -f -r $candidate;
        return $candidate;
    }
    return $file;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::EOF - Check correct end of files in a project.



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<img src="https://img.shields.io/badge/coverage-65.4%25-red.svg" alt="coverage 65.4%" />
<a href="https://github.com/Csson/p5-test-eof/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-test-eof/makefile-test" alt="Build status at Github" /></a>
</p>

=end html

=head1 VERSION

Version 0.0804, released 2021-04-28.

=head1 SYNOPSIS

  use Test::EOF;

  all_perl_files_ok('lib/Test::EOF', { minimum_newlines => 2 });

  done_testing();

=head1 DESCRIPTION

This module is used to check the end of files of Perl modules and scripts. It is a way to make sure that files and with (at least) one line break.

It uses C<\v> to look for line breaks. If you want to ensure that only C<\n> are used as line break, use L<Test::EOL> for that first.

There is only one function:

=head2 all_perl_files_ok

    all_perl_files_ok(@directories, { minimum_newlines => 1, maximum_newlines => 2 });

    all_perl_files_ok(@directories, { strict => 1 });

Checks all Perl files (basically C<*.pm> and C<*.pl>) in C<@directories> and sub-directories. If C<@directories> is empty the default is the parent of the current directory.

B<C<minimum_newlines =E<gt> $minimum>>

Default: C<1>

Sets the number of consecutive newlines that files checked at least should end with.

B<C<maximum_newlines =E<gt> $maximum>>

Default: C<mininum_newlines>

Sets the number of consecutive newlines that files checked at most should end with.

If C<maximum_newlines> is B<less> than C<minimum_newlines> it gets set to C<minimum_newlines>.

B<C<strict>>

If C<strict> is given a true value, both C<minimum_newlines> and C<maximum_newlines> will be set to C<1>. This option has precedence over the other two.

=head1 ACKNOWLEDGEMENTS

L<Test::EOL> was used as an inspiration.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::Test::EOF>

=item *

L<Test::EOL>

=item *

L<Test::NoTabs>

=item *

L<Test::More>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-test-eof>

=head1 HOMEPAGE

L<https://metacpan.org/release/Test-EOF>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
