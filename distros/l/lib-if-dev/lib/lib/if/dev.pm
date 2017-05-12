#
# This file is part of lib-if-dev
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package lib::if::dev;
{
  $lib::if::dev::VERSION = '0.002';
}

# ABSTRACT: Use lib/ if we're in a dev root

sub import {

    return unless -d 'lib';
    return unless -f 'dist.ini' || -f 'Makefile.PL' || -f 'Build.PL';

    push @INC, 'lib';
    return;
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

lib::if::dev - Use lib/ if we're in a dev root

=head1 VERSION

This document describes version 0.002 of lib::if::dev - released February 24, 2013 as part of lib-if-dev.

=head1 SYNOPSIS

    # does a 'use lib "lib/"' if exists Makefile.PL, Build.PL, or dist.ini
    use lib::if::dev;

=head1 DESCRIPTION

If you're running a script from your development root (or anything else for
that matter), it's often fun to figure out how to include lib/ in your command
both so that you don't need to remember to do a C<-Ilib> or have to remember
to remove 'use lib "lib"' statements before releasing.

This package aims to solve that (for one value of "solve").

If your current directory contains a directory "lib" and one or more of
Makefile.PL, Build.PL, or dist.ini, then this package pushes 'lib/' onto
C<@INC>.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
