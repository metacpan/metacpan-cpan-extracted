package Twiggy::Prefork::Metabolic;
use strict;
use warnings;

our $VERSION = '0.02';

1;
__END__

=head1 NAME

C<Twiggy::Prefork::Metabolic> - Metabolic preforking AnyEvent HTTP server for PSGI

=head1 SYNOPSIS

  $ plackup -s Twiggy::Prefork::Metabolic -a app.psgi

=head1 DESCRIPTION

C<Twiggy::Prefork::Metabolic> behaves the same as L<Twiggy::Prefork>
except that a child process (a worker) won't stop listening after
reaching C<max_reqs_per_child> until all accepted requests finished.
In other words, the child process never refuses a new connection
arrived before restart.

C<Twiggy::Prefork::Metabolic> infinitely accepts new requests as
C<Twiggy> does without getting stuck even if there are more requests
than C<max_workers> x C<max_reqs_per_child>.  This is like
C<Twiggy::Prefork> with C<--max-reqs-per-child=0>.  It also restarts
child processes as C<Twiggy::Prefork> does if the process has idle
time after reaching C<max_reqs_per_child>.

=head1 SEE ALSO

L<Twiggy::Prefork>

=head1 LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
