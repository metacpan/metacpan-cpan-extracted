# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::FilterChain;

1;
__END__

=pod

=head1 NAME

Servlet::FilterChain - filter chain interface

=head1 SYNOPSIS

  $chain->doFilter($request, $response);

=head1 DESCRIPTION

This is the interface for an object provided by the servlet container
to the developer giving a view into the invocation chain of a filtered
request for a resource. B<Servlet::Filter> objects use it to invoke
the next filter in the chain, or if the calling filter is the last
filter in the chain, to invoke the resource at the end of the chain.

=head1 METHODS

=over

=item doFilter($request, $response)

Causes the next filter in the chain to be invoked, or if the calling
filter is the last filter in the chain, causes the resource at the end
of the chain to be invoked.

B<Parameters:>

=over

$request
$request
=item I<$request>

the B<Servlet::ServletRequest> object that contains the client's
request

$response
$response
=item I<$response>

the B<Servlet::ServletResponse> object that contains the servlet's
response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if an exception occurs while performing the filtering task

=back

=back

=head1 SEE ALSO

L<Servlet::Filter>,
L<Servlet::ServletException>,
L<Servlet::ServletRequest>,
L<Servlet::ServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
