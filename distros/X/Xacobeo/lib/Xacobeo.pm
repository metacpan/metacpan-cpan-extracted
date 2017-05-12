package Xacobeo;

=encoding utf8

=head1 NAME

Xacobeo - XPath (XML Path Language) visualizer.

=head1 SYNOPSIS

xacobeo file [xpath]

=head1 DESCRIPTION

This program provides a simple graphical user interface (GUI) for executing
XPath queries and seeing their results.

The GUI tries to provide all the elements that are needed in order to write,
test and execute XPath queries without too many troubles. It displays the
Document Object Model (DOM) and the namespaces used. The program registers the
namespaces automatically and each element is displayed with its associated
namespaces. All is performed with the idea of being able of running an XPath
query as soon as possible without having to fight with the document's namespaces
and by seeing automatically under which namespace each element is.

=head1 RATIONALE

The main idea behind this application is to provide a simple way for building
XPath queries that will be latter integrated in to a program or XSLT
transformation paths. Therefore, this program goal is to load an XML document
and to display it as an XML parser sees it. Thus each node element is prefixed
with its namespace.

=head1 IMPLEMENTATION

This program uses L<XML::LibXML> (libxml2) for all XML manipulations and L<Gtk2>
for the graphical interface.

=head1 LIMITATIONS

For the moment, the program focuses only on XPath and doesn't allow the XML
document to be edited.

=head1 PROJECT

The project is hosted on Google Code (http://xacobeo.googlecode.com/) which
provides the latest source code (SVN trunk) and a simple bug tracking.

Although Google Code provides a download facility, the project's source code
bundles will always be published through CPAN. It's easier this way for the
project and after all this is a Perl project!

=head1 BUGS

Please when possible try to submit the bugs through the Google Code Issue
Tracker (http://code.google.com/p/xacobeo/issues/list) otherwise simply create a
ticket through RT.

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;

our $VERSION = '0.15';


# A true value
1;
