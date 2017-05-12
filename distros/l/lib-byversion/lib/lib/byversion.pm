use 5.006;
use strict;
use warnings;

package lib::byversion;

our $VERSION = '0.002002';

# ABSTRACT: add paths to @INC depending on which version of Perl is running.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use lib ();
use version 0.77;

use String::Formatter stringf => {
  -as   => path_format =>,
  codes => {
    v => "$]",
    V => do {
      my $x = version->parse("$]")->normal;
      $x =~ s{^v}{}sx;
      $x;
    },
  },
};

sub import {
  my ( undef, @args ) = @_;
  if ( @args != 1 ) {
    die 'lib::byversion->import takes exactly one argument, instead, you specified ' . scalar @args;
  }
  my $path = path_format(@args);
  return lib->import($path);
}

## no critic (ProhibitBuiltinHomonyms)
sub unimport {
  my ( undef, @args ) = @_;
  if ( @args != 1 ) {
    die 'lib::byversion->unimport takes exactly one argument, instead, you specified ' . scalar @args;
  }
  my $path = path_format(@args);
  return lib->unimport($path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::byversion - add paths to @INC depending on which version of Perl is running.

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    PERL5OPT="-Mlib::byversion='$HOME/Foo/Bar/%V/lib/...'"

or alternatively

    use lib::byversion "/some/path/%V/lib/...";

=head1 DESCRIPTION

So you have >1 Perl Installs.  You have >1 Perl installs right?
And you switch between running them how?

Let me guess, somewhere you have code that sets a different value for PERL5LIB
depending on what Perl you're using.
Oh you use L<< C<perlbrew>?|http://grep.cpan.me/?q=PERL5LIB+dist=App-perlbrew >>

This is a slightly different approach:

=over 4

=item 1. Set up your user-land PERL5LIB directories in a regular pattern
differing only by C<perl> version

    $HOME/Foo/Bar/5.16.0/lib/...
    $HOME/Foo/Bar/5.16.1/lib/...
    $HOME/Foo/Bar/5.16.2/lib/...

=item 2. Set the following in your C<%ENV>

    PERL5OPT="-Mlib::byversion='$HOME/Foo/Bar/%V/lib/...'"

=item 3. Done!

The right PERL5LIB gets loaded based on which C<perl> you use.

=back

Yes, yes, catch 22, C<lib::byversion> and its dependencies need to be in
your lib to start with.

O.k. That is a problem, slightly. But assuming you can get that in each
C<perl> install somehow, you can load each C<perl>'s user library directories
magically with this module once its loaded.

And "assuming you can get that in each C<perl> install somehow" =~ with a bit
of luck, this feature or something like it might just be added to Perl itself,
as this is just a prototype idea to prove it works ( or as the case may be,
not ).

And even if that never happens, and you like this module, you can still
install this module into all your C<perl>'s and keep a separate
C<user-PERL5LIB-per-perl> without having to use lots of scripts to hold it
together, and for System Perls, you may even be fortunate enough to get this
module shipped by your C<OS> of choice. Wouldn't that be dandy.

=head1 IMPORT

    use lib::byversion $param
    lib::byversion->import($param)
    perl -Mlib::byversion=$param

etc.

C<lib::byversion> expects one parameter, a string path containing templated
variables for versions.

Current defined parameters include:

=over 4

=item C<%V>

This is an analogue of C<$^V> except :

=over 4

=item it should work on even C<perl>s that didn't have C<$^V>, as it converts
it from C<$]> with L<version.pm|version>

=item it lacks the preceding C<v>, because this is more usually what you want
and its easier to template it in than take it out.

=back

Example:

    %V = 5.16.9

=item C<%v>

This is the same as C<$]> on your Perl.

Example:

    %v = 5.016009

=back

More may be slated at some future time, e.g.: to allow support for components
based on C<git> C<sha1>'s, but I figured to upload something that works before
I bloat it out with features nobody will ever use.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
