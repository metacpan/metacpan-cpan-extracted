package UV::Req;

our $VERSION = '1.906';

use strict;
use warnings;
use UV ();

# No pure-perl methods

1;

__END__

=head1 NAME

UV::Req - An outstanding request in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  my $loop = UV::Loop->default;

  # A pending getaddrinfo is represented by a UV::Req
  my $req = $loop->getaddrinfo(node => "localhost", service => "8080");

  $req->cancel;

=head1 DESCRIPTION

This module provides an interface to
L<libuv's req|http://docs.libuv.org/en/v1.x/request.html>. Objects in this
type are not directly constructed, but are returned by methods that perform
some pending action, to represent the outstanding operation before it
completes.

=head1 METHODS

L<UV::Req> makes the following methods available.

=head2 cancel

    $req->cancel

Stops the pending operation. The exact semantics will depend on the type of
operation the request represents.


=head1 AUTHOR

Paul Evans <F<leonerd@leonerd.org.uk>>

=head1 COPYRIGHT AND LICENSE

Copyright 2020, Paul Evans.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
