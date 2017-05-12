#!/usr/bin/perl
##
#
#
# copyright 2001 D. Scott Barninger <barninger@fairfieldcomputers.com>
# licensed under the GNU General Public License ver. 2.0
# see the accompaning LICENSE file
##
require 5.000; use strict 'vars', 'refs', 'subs';
use DBI;
my($table,$dbh,$sql,$database,$host,$user,$password);

#-------------------------------------------------------------------------------
# configuration section
$database = "";
$host = "localhost";
$user = "";
$password = "";
$table = "auth_users";
# end configuration section
#-------------------------------------------------------------------------------

# opening message and warning
print "\nTable creation script for User Database\n";
print "(C)opyright D. Scott Barninger 2001 <barninger\@fairfieldcomputers.com>\n\n";
print "Press any key to continue or Ctrl-C to abort.\n\n";
my $junk = <STDIN>;

# connect to the database
$dbh = DBI->connect("DBI:mysql:database=$database;host=$host","$user","$password",{'RaiseError' => 1}) || die("Unable to connect to database.");

# now do it
&create($table);

$dbh->disconnect();

exit;

#---------------------------------------------------------------------------------
sub create {
	# usage create($table_to_create)
	my ($table_to_create) = @_;
	$sql = "CREATE TABLE $table_to_create (
		id INT(11) DEFAULT '0' NOT NULL AUTO_INCREMENT PRIMARY KEY,
		user_name CHAR(10),
		password CHAR(10),
		session TEXT,
		email CHAR(40))";
	$dbh->do($sql);
	print "Table $table_to_create has been created.\n";
}
return;

# end of sub create
#--------------------------------------------------------------------------------
