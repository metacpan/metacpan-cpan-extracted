# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat;

require 5.006;
use strict;
use warnings;

our $VERSION = '0.7.1';

1;
__END__

=pod

=head1 NAME

Wombat - a Perl servlet container

=head1 SYNOPSIS

=head1 DESCRIPTION

Wombat is a servlet container for Perl. It is not an executable
program itself; rather, it is a library that can be used by programs
to embed a servlet container. Embedding programs must provide
implementations of Connector API classes that adapt Wombat to the
surrounding environment. One such connector is B<Apache::Wombat> which
embeds a Wombat servlet container within an Apache httpd built with
mod_perl.

Currently no developer documentation for Wombat itself is provided
beyond the contents of this document and the POD for each Wombat
class.

=head1 CONTAINER CONFIGURATION

=head2 CONTAINER DIRECTORIES

Web application directories are generally located beneath a single
I<application base> directory which in turn is usually located beneath
the container's home directory. Each Host configured in the container
can use the same application base directory (called C<webapps> by
default) or provide its own, possibly located outside the container's
home directory. As well, each Application configured in the container
has the option of locating its webapp directory outside its Host's
application base directory.

A typical directory structure for Wombat embedded within
Apache/mod_perl might be:

  # container's home dir
  /usr/local/apache
  # default hosts's appbase dir
  /usr/local/apache/webapps
  # examples app's webapp dir
  /usr/local/apache/webapps/examples
  # another host's appbase dir
  /home/bcm/maz.org/webapps
  # another app's webapp dir
  /home/bcm/maz.org/webapps/comics

=head2 CONTAINER DEPLOYMENT DESCRIPTOR

The behavior and attributes of the Wombat servlet container are
controlled by a I<container deployment descriptor> (usually named
C<server.xml>). This file is modeled after the Tomcat 4 equivalent,
but it does have slight differences. A full Configuration Guide will
be published; until then, the definitions included below are the only
documentation:

Elements supported in C<server.xml> (named with XPath paths, example
attribute settings included inline):

=over

=item Server

Represents the entire perl interpreter, into which one or more
Services are deployed. Only one Server may be specified.

=item Server/Service

Represents a collection of one or more Connectors that share a single
Engine (and therefore the web applications visible within that
Engine). A display name for the Service (C<name="HTTP Service">) may
be specified. Many Services may be specified for the single Server.

=item Server/Service/Connector

Represents an endpoint by which requests are received and responses
are returned. Each Connector passes requests on to its associated
Container for processing. The name of a class that implements the
B<Wombat::Connector> interface B<MUST> be specified
(C<className="Apache::Wombat::Connector">), as well as a scheme
(C<scheme="http"> attribute) and any attributes needed by the
implementation. A secure flag (C<secure="1">) may also be set to
indicated that the request was transported using SSL. Many Connectors
may theoretically be specified for a particular Service, but at this
time, the Wombat internals need some refactoring before they can
support Connectors for protocols other than HTTP.

=item Server/Service/Engine

Represents the highest level Container associated with a set of
Connectors. The Engine discriminates between virtual hosts as
necessary and passes the request along to the appropriate Host. A
display name for the Engine (C<name="Apache-Wombat">) may be
specified, as well as the name of a default host
(C<defaultHost="localhost"> attribute) to receive requests that are
not mapped to other specifically configured Hosts. Only one Engine may
be specified for a particular Service.

=item Server/Service/Engine/Logger

Unless overridden in a lower level Container, all log messages will be
handled by this Logger. The name of a class that implements the
B<Wombat::Logger> interface B<MUST> be specified
(C<className="Apache::Wombat::Logger">), as well as any attributes
needed by the implementation. A minimum log level (C<level="DEBUG">)
may also be specified. If no Logger is specified, logging will be
disabled for the Container. Only one Logger may be specified for a
particular Container.

=item Server/Service/Engine/Realm

Unless overridden in a lower level Container, all web applications
will be subject to this security Realm. The name of a class that
implements the B<Wombat::Realm> interface B<MUST> be specified
(C<className="Wombat::Realm::DBIRealm">), as well as any attributes
needed by the implementation. If no Realm is specified, security will
be disabled for the Container. Only one Realm may be specified for a
particular Container.

Note that security B<MUST> be also enabled in a particular web
application's deployment descriptor in order for the Realm to be
relevant to that web application. Therefore a Realm may be configured
for an entire Container but only in use for a single Application.

=item Server/Service/Engine/SessionManager

Unless overridden in a lower level Container, all sessions will be
managed by this SessionManager. The name of a class that implements
the B<Wombat::SessionManager> interface B<MUST> be specified
(C<className="Wombat::SessionManager::StandardSessionManager">), as
well as any attributes needed by the implementation. A maximum
inactivity interval/idle out time may also be specified
(C<maxInactiveInterval="300">). If no SessionManager element is
specified, sessions will be disabled for the Container. Only one
SessionManager may be specified for a particular Container.

The type of SessionManager used will depend heavily on the environment
provided by the embedding program. For instance, a multiprocess
Apache/mod_perl server embedding Wombat will require a SessionManager
that caches sessions in shared memory, on disk or in some other
location that all processes can access, whereas a multithreaded daemon
embedding Wombat might use a simple memory-based SessionManager.

=item Server/Service/Engine/Valve

Represents a request-processing component that "wraps" around the
Servlet that is ultimately responsible for processing the request. The
name of a class that implements the B<Wombat::Valve> interface B<MUST>
be specified (C<className="Wombat::Valve::RequestDumperValve">), as
well as any attributes needed by the implementation. Many Valves may
be specified for a single Container.

Valves are used to add container functionality for specific
Containers, much like Filters are used to add application
functionality for specific Servlets. An example of a commonly-used
Valve might be a one that logs information about each request (an
AccessLogValve perhaps).

=item Server/Service/Engine/Host

Represents a Container associated with a particular virtual host. A
Host maps the request URI to a particular web application and passes
the request along to the appropriate Application. The name of the host
B<MUST> be specified (C<name="localhost">), as well as the application
base directory (C<appBase="webapps">) which can be specified
absolutely or relative to the container's home directory. Many Hosts
(at least one, corresponding to the Engine's default host attribute)
may be specified for a single Engine.

=item Server/Service/Engine/Host/Alias

Represents an alternate name or names for the virtual host. For a Host
named 'maz.org', the Alias '*.maz.org' might be configured to catch
requests for specific hosts and subdomains in the domain. The name of
the alias B<MUST> be specified (C<name="*.maz.org">). Many Aliases may
be specified for a particular Host.

=item Server/Service/Engine/Host/Logger

A Logger configured for a Host overrides any Logger configured at the
Engine level.

=item Server/Service/Engine/Host/Realm

A Realm configured for a Host overrides any Realm configured at the
Engine level.

=item Server/Service/Engine/Host/SessionManager

A SessionManager configured for a Host overrides any SessionManager
configured at the Engine level.

=item Server/Service/Engine/Host/Valve

Any Valves configured for a Host add to (and execute after) any Valves
configured at the Engine level.

=item Server/Service/Engine/Host/Application

Represents a Container associated with a particular web
application. An Application inspects the request URI and passes the
request along to the appropriate Servlet (as configured in the web
application's deployment descriptor). The display name of the
application (C<displayName="Examples Application">) and the URI path
base for the application (C<path="/wombat-examples">) B<MUST> be
specified, as well as the webapp directory (C<docBase="examples">)
which can be specified absolutely or relative to the parent Host's
application base directory. Many Applications (at least one,
corresponding to the URI path '/') may be specified for a single Host.

=item Server/Service/Engine/Host/Application/Logger

A Logger configured for an Application overrides any Logger configured
at a higher level.

=item Server/Service/Engine/Host/Application/Realm

A Realm configured for an Application overrides any Realm configured
at a higher level.

=item Server/Service/Engine/Host/Application/SessionManager

A SessionManager configured for an Application overrides any
SessionManager configured at a higher level.

=item Server/Service/Engine/Host/Application/Valve

Any Valves configured for an Application add to (and execute after)
any Valves configured at a higher level.

=back

=head1 WEB APPLICATION CONFIGURATION

=head2 WEB APPLICATION DIRECTORIES

Each web application's resources (images, static HTML files, templates
and classes) are located in a single I<webapp directory>. This makes
it trivially easy to organize and deploy individual web applications.

Each webapp directory B<MUST> contain a directory named
C<WEB-INF>. This directory B<MUST> contain the web application
deployment descriptor, C<web.xml> (see L</WEB APPLICATION
CONFIGURATION>). Additionally it B<MAY> contain a C<lib> directory in
which application-specific modules are located. If the C<lib>
directory exists, it will be added to C<@INC> when the application is
loaded so that application classes are visible.

All contents of the webapp directory B<EXCEPT> the C<WEB-INF>
directory and everything beneath it will be visible at the path
specified for the Application in the container's deployment descriptor
(see L</CONTAINER CONFIGURATION>). For example, if an application's
path is configured as "/wombat-examples", then the file named
C<index.html> located inside the webapp directory would be visible at
the URI "/wombat-examples/index.html". The I<context-relative> path of
the file would be "/index.html".

=head2 WEB APPLICATION DEPLOYMENT DESCRIPTOR

The behavior and attributes of a particular web application are
controlled by a I<web application deployment descriptor> (C<web.xml>)
as specified in the Java (TM) servlet specification. The elements that
may be included in C<web.xml> are defined in the servlet specification
and in the DTD included in the libservlet distribution.

Web application deployment descriptor elements recognized by Wombat:

=over

=item web-app

=item web-app/context-param

=item web-app/context-param/param-name

=item web-app/context-param/param-value

=item web-app/display-name

=item web-app/login-config

=item web-app/login-config/auth-method

=item web-app/login-config/realm-name

=item web-app/security-constraint

=item web-app/security-constraint/auth-constraint

=item web-app/security-constraint/auth-constraint/role-name

=item web-app/security-constraint/display-name

=item web-app/security-constraint/user-data-constraint

=item web-app/security-constraint/user-data-constraint/transport-guarantee

=item web-app/security-constraint/web-resource-collection

=item web-app/security-constraint/web-resource-collection/http-method

=item web-app/security-constraint/web-resource-collection/url-pattern

=item web-app/security-constraint/web-resource-collection/web-resource-name

=item web-app/servlet

=item web-app/servlet/init-param

=item web-app/servlet/init-param/param-name

=item web-app/servlet/init-param/param-value

=item web-app/servlet/security-role-ref

=item web-app/servlet/security-role-ref/role-name

=item web-app/servlet/security-role-ref/role-link

=item web-app/servlet/servlet-class

=item web-app/servlet/servlet-name

=item web-app/servlet-mapping

=item web-app/servlet-mapping/url-pattern

=item web-app/servlet-mapping/servlet-name

=item web-app/session-config

=item web-app/session-timeout

=back

Elements currently not recognized by Wombat, or for which Wombat does
not currently provide feature support:

=over

=item web-app/context-param/description

=item web-app/description

=item web-app/distributable

=item web-app/ejb-local-ref/description

=item web-app/ejb-local-ref/ejb-ref-name

=item web-app/ejb-local-ref/ejb-ref-type

=item web-app/ejb-local-ref/local-home

=item web-app/ejb-local-ref/local

=item web-app/ejb-local-ref/ejb-link

=item web-app/ejb-ref/description

=item web-app/ejb-ref/ejb-ref-name

=item web-app/ejb-ref/ejb-ref-type

=item web-app/ejb-ref/home

=item web-app/ejb-ref/remote

=item web-app/ejb-ref/ejb-link

=item web-app/env-entry

=item web-app/env-entry/description

=item web-app/env-entry/env-entry-name

=item web-app/env-entry/env-entry-value

=item web-app/env-entry/env-entry-type

=item web-app/error-page

=item web-app/error-page/error-code

=item web-app/error-page/exception-type

=item web-app/error-page/location

=item web-app/filter

=item web-app/filter/icon

=item web-app/filter/icon/small-icon

=item web-app/filter/icon/large-icon

=item web-app/filter/init-param

=item web-app/filter/init-param/param-name

=item web-app/filter/init-param/param-value

=item web-app/filter/filter-name

=item web-app/filter/display-name

=item web-app/filter/description

=item web-app/filter/filter-class

=item web-app/filter/init-param

=item web-app/filter-mapping

=item web-app/filter-mapping/filter-name

=item web-app/filter-mapping/url-pattern

=item web-app/filter-mapping/servlet-name

=item web-app/icon

=item web-app/icon/small-icon

=item web-app/icon/large-icon

=item web-app/listener

=item web-app/listener-class

=item web-app/login-config/form-login-config

=item web-app/login-config/form-login-config/form-login-page

=item web-app/login-config/form-login-config/form-error-page

=item web-app/mime-mapping

=item web-app/mime-mapping/extension

=item web-app/mime-mapping/mime-type

=item web-app/resource-env-ref

=item web-app/resource-env-ref/description

=item web-app/resource-env-ref/resource-env-ref-name

=item web-app/resource-env-ref/resource-env-ref-type

=item web-app/resource-ref

=item web-app/resource-ref/description

=item web-app/resource-ref/res-auth

=item web-app/resource-ref/res-ref-name

=item web-app/resource-ref/res-sharing-scope

=item web-app/resource-ref/res-type

=item web-app/security-constraint/auth-constraint/description

=item web-app/security-constraint/user-data-constraint/description

=item web-app/security-constraint/web-resource-collection/description

=item web-app/security-role

=item web-app/security-role/description

=item web-app/security-role/role-name

=item web-app/servlet/description

=item web-app/servlet/display-name

=item web-app/servlet/icon

=item web-app/servlet/icon/small-icon

=item web-app/servlet/icon/large-icon

=item web-app/servlet/jsp-file

=item web-app/servlet/load-on-startup

=item web-app/servlet/run-as/description

=item web-app/servlet/run-as/role-name

=item web-app/servlet/security-role-ref/description

=item web-app/taglib

=item web-app/taglib/taglib-uri

=item web-app/taglib/taglib-location

=item web-app/welcome-file-list

=item web-app/welcome-file-list/welcome-file

=back

=head1 SERVLET API SUPPORT

Wombat will eventually implement the entire Java (TM) servlet
specification as adapted to Perl by B<libservlet>. Currently it
supports just enough to be classified as a 'proof of concept' servlet
container.

Features currently not supported by Wombat but likely to be supported
in the near future include:

=over

=item Application class reloading (SRV.3.7)

=item Application replacing (SRV.9.8)

=item Application events (SRV.10)

=item Auth methods: client cert, digest, form (SRV.12.5)

=item Compartmentalized class loading (SRV.9.7.2)

=item Secure connector redirection

=item Clustering/session distribution (SRV.2.2, SRV.3.4.1, SRV.7.7.2,
SRV.10.6)

=item Environment entries (SRV.9.11)

=item Environment/external resources (SRV.9.11)

=item Error handling request attributes and pages (SRV.9.9)

=item Filtering (SRV.6)

=item Internationalization (SRV.4.8, SRV.4.9, SRV.5.4)

=item MIME mappings

=item Multiple protocol support

=item Named request dispatchers (SRV.8.2)

=item Request dispatcher attributes (SRV.8.3, SRV.8.4)

=item Request path translation (SRV.4.5)

=item Security roles (SRV.12.3)

=item Servlet context resources (SRV.3.5)

=item Servlet context working directories (SRV.3.7.1)

=item Servlet load-on-startup (SRV.2.3.1)

=item Session tracking via SSL or URL rewriting (SRV.7.1)

=item Session events (SRV.7.4, SRV.7.5, SRV.10.7)

=item SSL attributes (SRV.4.7)

=item Welcome files (SRV.9.10)

=back

Features not likely to ever be supported include:

=over

=item EJB

=item Icons

=item JSP files

=item Taglibs

=back

=head1 OTHER NOTES

No consideration has been given to threading. When the threading
environment in perl has settled down, this may change.

=head1 SEE ALSO

B<Apache::Wombat>,
B<mod_perl>,
B<Servlet>

Java (TM) Servlet 2.3 Specification:
http://www.jcp.org/aboutJava/communityprocess/final/jsr053/

=head1 AUTHORS

Brian Moseley, bcm@maz.org

Largely inspired by Tomcat, the Apache Java (TM) servlet container at
http://jakarta.apache.org/tomcat/. Many thanks!

=cut
