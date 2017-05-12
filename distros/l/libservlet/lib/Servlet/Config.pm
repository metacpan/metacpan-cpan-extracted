# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Config;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Config - configuration super interface

=head1 SYNOPSIS

  my @params = $config->getInitParameterNames();

  for my $p (@params) {
      print sprintf "%s: %s\n", $p, $config->getInitParameter($p);
  }

  my $context = $config->getServletContext();

=head1 DESCRIPTION

This is the super interface for objects in the Servlet API that pass
configuration information to Servlets or Filters during
initialization. The configuration information contains initialization
parameters, which are a set of name/value pairs, and a
B<Servlet::ServletContext> object, which gives the calling object
information about the web container.

=head1 METHODS

=over

=item getInitParameter($name)

Returns the value of the named initialization parameter, or I<undef>
if the parameter does not exist.

B<Parameters:>

=over

=item I<$name>

The name of the initialization parameter

=back

=item getInitParameterNames()

Returns an array containing the names of the servlet's initialization
parameters, or an empty array if the servlet has no initialization
parameters.

=item getServletContext()

Returns the B<Servlet::ServletContext> object representing the web
context in which the caller is executing.

=back

=head1 SEE ALSO

L<Servlet::ServletContext>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
