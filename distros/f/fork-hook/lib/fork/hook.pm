package fork::hook;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('fork::hook', $VERSION);

1;
__END__
=encoding UTF-8

=head1 NAME

fork::hook - implements functions that called after fork, in child process.

fork::hook - отпределяет функции, которые будут вызваны после форка в дочерних процессах.

=head1 SYNOPSIS
  
  package Test;

  sub AFTER_FORK { warn "Hello World!" }  # <<< Function executed after call 'fork'

  package main;
  use fork::hook;
  fork;

or

  package Test;

  sub AFTER_FORK_OBJ { warn "Hello World! " . shift }; # <<< Function executed after call 'fork', for each object

  package main;
  use fork::hook;
  my $a = bless {}, 'Test';
  fork;

=head1 DESCRIPTION

fork::hook replace origin PL_ppaddr[OP_FORK] on my own fork handler.
In 'handler', i iterate over perl arena, and call AFTER_FORK for packages stash, or AFTER_FORK_OBJ blessed ref. 

=head1 AUTHOR

Evgeniy Vansevich, E<lt>hammer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Evgeniy Vnasevich
=cut