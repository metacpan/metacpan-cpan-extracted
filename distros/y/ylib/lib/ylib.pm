use strict;
use warnings;

package ylib;
# ABSTRACT: Add paths to @INC from a config file
our $VERSION = '0.003'; # VERSION

use File::HomeDir 0.86 ();
use Path::Tiny 0.052;

require lib;

my $name = '.mylib';

sub import {
    my $class = shift;
    my @configs = map { path( $_, $name ) } ( File::HomeDir->my_home(), '.' );
    for my $f (@configs) {
        next unless -r $f;
        for my $dir ( $f->lines( { chomp => 1 } ) ) {
            if ( -d $dir ) {
                lib->import("$dir");
            }
            else {
                warn "lib '$dir' was not found. skipping it\n";
            }
        }
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ylib - Add paths to @INC from a config file

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # in .mylib file
  /home/david/some/library/path
  
  # from the command line
  $ perl -Mylib -E 'say for @INC'
  /home/david/some/library/path
  ...

=head1 DESCRIPTION

The C<ylib> module adds paths to C<@INC> from a configuration file named C<.mylib>
in which each line represents a library path.  The C<.mylib> file can be either
in the current directory and/or in the user's home directory.  It is equivalent
to calling C<'use lib'> on each path.

Note: C<ylib> will issue a warning if a path in C<.mylib> can't be found.

=head1 USAGE

Occasionally, it's useful to customize C<@INC> on a per-directory basis without
changing the global C<PERL5LIB> environment variable.  For example, when
developing or testing code that requires uninstalled code in an adjacent
directory, one could create a C<.mylib> file that adds the necessary path.

For example, consider this directory tree with two Perl distributions, Foo-Bar
and Baz-Bam:

  ~/projects/
      Foo-Bar/
      Baz-Bam/

The code in Foo-Bar depends on code in Baz-Bam.  So in Foo-Bar, create a
C<.mylib> file with the appropriate path:

  $ cd Foo-Bar
  $ echo '../Baz-Bam/lib' > .mylib
  $ perl -Mylib Build.PL
  $ Build && Build test

That's easier and shorter than using C<PERL5LIB> on the command line, and it
scales better as the number of libraries increases.

In the example above, the C<Build> script preserve C<@INC> including the effect
of C<-Mylib> when it was created.  This is not the case with C<Makefile.PL> or
C<prove>, in which case, C<PERL5OPT> might be an alternative approach for using
C<-Mylib>:

  $ export PERL5OPT=-Mylib
  $ prove

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/ylib/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/ylib>

  git clone https://github.com/dagolden/ylib.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
