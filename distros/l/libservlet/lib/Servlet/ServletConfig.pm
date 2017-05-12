# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletConfig;

use base qw(Servlet::Config);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletConfig - servlet configuration interface

=head1 SYNOPSIS

  my $name = $config->getServletName();

  my @params = $config->getInitParameterNames();

  for my $p (@params) {
      print sprintf "%s: %s\n", $p, $config->getInitParameter($p);
  }

  my $context = $config->getServletContext();

=head1 DESCRIPTION

This is the interface for an object used by a servlet container to
pass configuration information to a B<Servlet::Servlet> during
initialization. The interface extends B<Servlet::Config>.

=head1 METHODS

=over

=item getServletName()

Returns the name of the servlet instance. The name may be provided via
server administration, assigned in the web application deployment
descriptor, or for an unregistered (and thus unnamed) servlet instance
it will be the servlet's class name.

=back

=head1 SEE ALSO

L<Servlet::Config>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
