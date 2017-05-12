#!/usr/bin/perl
package JMX::Jmx4Perl::Product::JBoss;

use JMX::Jmx4Perl::Product::BaseHandler;
use strict;
use base "JMX::Jmx4Perl::Product::BaseHandler";

use Carp qw(croak);

=head1 NAME

JMX::Jmx4Perl::Product::JBoss - Handler for JBoss

=head1 DESCRIPTION

This is the product handler support JBoss 4.x and JBoss 5.x (L<http://www.jboss.org/jbossas/>)

=cut

sub id {
    return "jboss";
}

sub name {
    return "JBoss AS";
}

sub order { 
    return -2;
}

sub jsr77 {
    return 1;
}

sub version {
    return shift->_version_or_vendor("version",qr/^(.*?)\s+/);
}

sub autodetect_pattern {
    return ("vendor",qr/JBoss/i);
}

sub init_aliases {
    return 
    {
     attributes => 
   {
    SERVER_ADDRESS => [ "jboss.system:type=ServerInfo", "HostAddress"],
    SERVER_HOSTNAME => [ "jboss.system:type=ServerInfo", "HostName"],
   },
     operations => 
   {
    THREAD_DUMP => [ "jboss.system:type=ServerInfo", "listThreadDump"]
   }
     # Alias => [ "mbean", "attribute", "path" ]
    };
}


=head1 LICENSE

This file is part of jmx4perl.

Jmx4perl is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

jmx4perl is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with jmx4perl.  If not, see <http://www.gnu.org/licenses/>.

A commercial license is available as well. Please contact roland@cpan.org for
further details.

=head1 AUTHOR

roland@cpan.org

=cut

1;
