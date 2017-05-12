# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Filter;

1;
__END__

=pod

=head1 NAME

Servlet::Filter - filter interface

=head1 SYNOPSIS

  $filter->setFilterConfig($fconfig);

  # later

  $filter->doFilter($request, $response, $chain);

  my $config = $filter->getConfig();

=head1 DESCRIPTION

This is the interface for an object that performs filtering tasks on
the request for a resource, the response, or both.

Filters perform filtering in the C<doFilter()> method. Every filter
has access to a B<Servlet::FilterConfig> object from which it can
obtain its initialization parameters and a reference to the
B<Servlet::ServletContext> which it can use, for example, to load
resources needed for filtering tasks.

Filters are configured in the deployment descriptor of a web
application.

Examples that have been identified for this design are:

=over

=item Authentication Filters

=item Logging and Auditing Filters

=item Image conversion Filters

=item Data compression Filters

=item Encryption Filters

=item Tokenizing Filters

=item Filters that trigger resource access events

=item XSL/T Filters

=item MIME-type chain Filters

=back

=head1 METHODS

=over

=item doFilter($request, $response, $chain)

This method is called by the container each time a request/response
pair is passed through the filter chain due to a client request for a
resource at the end of the chain. The filter chain passed into this
method allows the filter to passon the request and response to the
next entity in the chain.

A typical implementation of this method would follow such a pattern:

=over

=item 1

Examine the request

=item 2

Optionally wrap the request object with a custom implementation to
filter content or headers for input filtering

=item 3

Optionally wrap the response object with a custom implementation to
filter content or headers for output filtering

=item 4 a)

B<Either> invoke the next entity in the chain by calling C<doFilter()>
on I<$chain>,

=item 4 b)

B<or> block further filter processing by not passing the
request/response pair down the chain

=item 5

Directly set headers on the response after invocation of the next
entity in the filter chain.

=back

B<Parameters:>

=over

=item I<$request>

the B<Servlet::ServletRequest> object that contains the client's
request

=item I<$response>

the B<Servlet::ServletResponse> object that contains the servlet's
response

=item I<$chain>

the B<Servlet::FilterChain> through which the request and response are
passed

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if an exception occurs while performing the filtering task

=back

=item getFilterConfig()

Returns the B<Servlet::FilterConfig> object for this filter

=item setFilterConfig($config)

Set the config object for this filter

B<Parameters:>

=over

=item I<$config>

the B<Servlet::FilterConfig> object for this filter

=back

=back

=head1 SEE ALSO

L<Servlet::FilterChain>,
L<Servlet::FilterConfig>,
L<Servlet::ServletException>,
L<Servlet::ServletRequest>,
L<Servlet::ServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
