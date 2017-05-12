# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::SingleThreadModel;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::SingleThreadModel - serialized servlet access interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This tagging interface ensures that servlets handle only one request
at a time. This interface has no methods.

If a servlet implements this interface, you are I<guaranteed> that no
two threads will execute concurrently in the servlet's C<service()>
method. The servlet container can make this guarantee by synchronizing
access to a single instance of the servlet, or by maintaining a pool
of servlet instances and dispatching each new request to a free
servlet.

This interface does not prevent synchronization problems that result
from servlets accessing shared resources such as class variables or
classes outside the scope of the servlet.

B<NOTE>: No provisions have been made for usage of the Servlet API in
a threaded environment. This interface is only provided for
completeness.

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
