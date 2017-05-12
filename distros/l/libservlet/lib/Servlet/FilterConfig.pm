# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::FilterConfig;

use base qw(Servlet::Config);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::FilterConfig - filter configuration interface

=head1 SYNOPSIS

  my $name = $config->getFilterName();

  my @params = $config->getInitParameterNames();

  for my $p (@params) {
      print sprintf "%s: %s\n", $p, $config->getInitParameter($p);
  }

  my $context = $config->getServletContext();

=head1 DESCRIPTION

This is the interface for an object used by a servlet container to
pass configuration information to a B<Servlet::Filter> during
initialization. The interface extends B<Servlet::Config>.

=head1 METHODS

=over

=item getFilterName()

Returns the name of the filter as defined in the deployment
descriptor.

=back

=head1 SEE ALSO

L<Servlet::Config>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
