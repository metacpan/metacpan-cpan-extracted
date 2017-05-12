# Bind8 front. 
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8 - Front end for a suite of classes for manipulating a
Bind8 conf and associated zone record files.

=head1 SYNOPSIS

    use Unix::Conf::Bind8;
    my ($conf, $ret);

    # get a new Bind8::Conf object. If one exists with the same 
    # name it is parsed.
    $conf = Unix::Conf::Bind8->new_conf (
        FILE => 'named.conf', 
        SECURE_OPEN => 1
    ) or $conf->die ('could not open \'named.conf\'');

    $db = Unix::Conf::Bind8->new_db (
        FILE	=> '/etc/namedb/db.extremix.net', 
        ORIGIN	=> 'extremix.net',
        CLASS	=> 'IN',
        SECURE_OPEN	=> 0,
    ) or $db->die ("couldn't create db");

=head1 METHODS

=cut

package Unix::Conf::Bind8;

use 5.6.0;
use strict;
use warnings;

use Unix::Conf::Bind8::Conf;
use Unix::Conf::Bind8::DB;

$Unix::Conf::Bind8::VERSION = "0.3";

=over 4

=item new_conf ()

 Arguments
 FILE        => PATHNAME,
 SECURE_OPEN => 1/0,       # default 1 (enabled)

Class Method
Read Bind8 configuration file PATHNAME or create one if none
exists.
Returns a Bind8::Conf object in case of success or an Err object 
in case of failure. Refer to docs for Bind8::Conf for further
information.

=cut

sub new_conf () 
{ 
	shift (); 
	return (Unix::Conf::Bind8::Conf->new (@_)); 
}

=item new_db ()

 Arguments
 FILE        => PATHNAME,	 # pathname of the records file
 ORIGIN      => ZONE_ORIGIN, # from the zone statement
 CLASS       => ZONE_CLASS,	 # from the zone statement
 SECURE_OPEN => 1/0,         # default 1 (enabled)

Class method.
Read a zone records file PATHNAME or create one if none exists.
Returns a Bind8::DB object in case of success or an Err object in
case of failure. Do not use this method. Use 
Unix::Conf::Bind8::Conf::Zone::get_db (), or better still, 
Unix::Conf::Bind8::Conf::get_db () instead.
Refer to docs for Bind8::DB for further information.

=cut
	
sub new_db () 
{ 
	shift (); 
	return (Unix::Conf::Bind8::DB->new (@_)); 
}

1;
__END__

=head1 STATUS

Beta. Needs extensive testing.
	
=head1 AVAILABILITY

This module is available from 
http://www.cpan.org/modules/by-authors/id/K/KA/KARTHIKK/
http://www.extremix.net/UnixConf/

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with the program; if not, write to the Free Software Foundation, Inc. :

59 Temple Place, Suite 330, Boston, MA 02111-1307

=head1 COPYRIGHT

Copyright (c) 2002, Karthik Krishnamurthy <karthik.k@extremix.net>.
