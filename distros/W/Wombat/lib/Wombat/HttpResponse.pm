# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::HttpResponse;

use base qw(Servlet::Http::HttpServletResponse Wombat::Response);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::HttpResponse - internal http response interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface extends B<Servlet::Http::HttpServletResponse> and
B<Wombat::Response> to provide fields and methods accessible only to
the container.

=head1 PUBLIC METHODS

=over

=item getCookies()

Return the list of Cookies for this Response.

=cut

=item getHeader($name)

Return the value for the first occurrence of the named response
header. For all values, use C<getHeaderValues()>.

B<Parameters:>

=over

=item $name

the header name

=back

=item getHeaderNames()

Return a list of all the header names set for this Response.

=item getHeaderValues($name)

Return the list of values for the named response header.

B<Parameters:>

=over

=item $name

the header name

=back

=item getMessage()

Return the status message for this Response.

=item getStatus()

Return the HTTP status code for this Response.

=back

=head1 SEE ALSO

L<Wombat::Response>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
