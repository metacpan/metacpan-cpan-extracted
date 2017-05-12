# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet;

require 5.006;
use strict;
use warnings;

our $VERSION = '0.9.2';

1;
__END__

=pod

=head1 NAME

Servlet - Perl Servlet API v2.3

=head1 DESCRIPTION

The Servlet API for Perl (libservlet) is a formulation of the Java
Servlet API in Perl. The current version of the API is B<2.3>.

While the servlet concept originated with Java, its component model is
quite natural for Perl as well. By writing servlet applications and
deploying them in a servlet engine, application authors can spare
themselves the effort of writing commonly needed web application
infrastructure components for each new project. Furthermore, servlet
applications are portable between deployment environments; they can be
executed in any servlet engine using any process model with only a
few configuration changes and no application code changes. Servlet
applications are insulated from changes in vendor or platform and are
able to portably take advantage of standard web infrastructure
services offered by any servlet engine.

=head1 SEE ALSO

B<Exception::Class>

The C<libservlet> web site at http://www.maz.org/libservlet/

=head1 AUTHORS

Brian Moseley, bcm@maz.org

Documentation for Servlet API classes is inspired by (read copied with
modifications from) the Java Servlet Specification and the J2SE, J2EE
and jakarta-servlet-4 API docs. Thanks!

=cut
