package base::Glob;
use vars '$VERSION'; 
$VERSION = '0.01';

use strict;
use Text::Glob qw( match_glob );
use Devel::Symdump;
use Sub::Uplevel;
require base;

sub import {
    shift;
    my @packages = Devel::Symdump->rnew->packages;
    
    uplevel 1, \&base::import, 
        ( 'base', map { match_glob $_, @packages } @_ );
}

1;

__END__

=head1 NAME

base::Glob - Establish IS-A relationships based on globbing patterns 

=head1 SYNOPSIS

  package Class::Bar; sub method {2};
  package Nomatch::Foo; sub method {3};
  package main;
  use base::Glob qw(Class::*);
  print main->method(); # prints 2

=head1 DESCRIPTION

This module allows you to extend L<base> to form IS-A relationships
with the use of globs on packages in the symbol table - in the style
of Java's 'import java.class.*;'.

=head1 DEPENDENCIES

L<Text::Glob>
L<Devel::Symdump>
L<Sub::Uplevel> 
  
=head1 BUGS

Probably.

=head1 TODO

Go all the way to Java-style by spidering to find modules to require 
and add to C<@ISA>.

=head1 AUTHOR

Chris Ball, <chris@cpan.org>.  

=head1 THANKS

Michael Schwern for L<Sub::Uplevel>, Andreas Koenig for 
L<Devel::Symdump>, Richard Clamp for both L<Text::Glob> and being 
scary enough to work out that L<Sub::Uplevel> would make this work.

=cut
