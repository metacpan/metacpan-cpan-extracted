use 5.006;
use strict;
use warnings;
package Test::Filename;
# ABSTRACT: Portable filename comparison
our $VERSION = '0.03'; # VERSION

use Test::Builder::Module;
use Path::Tiny;

our @ISA = qw/Test::Builder::Module/; 
our @EXPORT = qw(
    filename_is 
    filename_isnt
); 

my $CLASS = __PACKAGE__;

#--------------------------------------------------------------------------#
# public API
#--------------------------------------------------------------------------#

sub filename_is {
    my($got, $expected, $label) = @_;
    return $CLASS->builder->is_eq(path($got), path($expected), $label);
}

sub filename_isnt {
    my($got, $expected, $label) = @_;
    return $CLASS->builder->isnt_eq(path($got), path($expected), $label);
}


1;

__END__

=pod

=head1 NAME

Test::Filename - Portable filename comparison

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Test::Filename tests => 2;
  
  filename_is  ( "some\path", "some/path", "should pass" );
  filename_isnt( "some\path", "some/path", "should fail" );

=head1 DESCRIPTION

Many cross-platform test failures -- particularly on Win32 -- are due to
hard-coded file paths being used in comparison tests.

  my $file = get_file();     # returns "foo\bar.t";
  is( $file, "foo/bar.t" );  # fails on Win32

This simple module provides some handy functions to convert all those
path separators automatically so filename tests will just DWIM.

The alternative is to write your own utility subroutine and use it everywhere
or just keep on littering your test code with calls to File::Spec -- yuck!

  is( $file, File::Spec->canonpath("some/path"), "should pass" );

Since this module is so simple, you might not think it worth including as a
dependency.  After all, it's not I<that> hard to always remember to use
L<File::Spec>, L<Path::Tiny> or some other file utility, right? But odds are
that, at some point, you'll be so busy writing tests that you'll forget and
hard-code a path in your haste to show what a clever programmer you are.

So just use this module and stop worrying about it.  You'll be happier
and so will anyone trying to install your modules on Win32.

=head1 USAGE

Just like Test::More, you have the option of providing a test plan
as arguments when you use this module. The following functions are 
imported by default.

=head2 filename_is
=head2 filename_isnt

    filename_is  ( $got, $expected, $label );
    filename_isnt( $got, $expected, $label );

These functions work just like C<is()> and C<isnt()> from Test::More, but
the first two argument will be cleaned up and normalized to Unix-style
paths using L<Path::Tiny>.  This means that C<.\foo.txt> will get normalized
to C<foo.txt> and so on.

=head1 SEE ALSO

=over 4

=item *

L<perlport>

=item *

L<File::Spec>

=item *

L<Path::Tiny>

=item *

L<Test::More>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/test-filename/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/test-filename>

  git clone git://github.com/dagolden/test-filename.git

=head1 AUTHOR

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by David A. Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
