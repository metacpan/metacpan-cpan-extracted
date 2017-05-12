
package example::BookStore::Object;
use base qw(Xmldoom::Object);

use Module::Util qw/ module_fs_path /;
use File::Basename qw/ dirname /;
use File::Spec::Functions qw/ catfile /;
use Xmldoom::Definition;
use strict;

our $DATABASE;

BEGIN
{
	my $module_dir = dirname( module_fs_path(__PACKAGE__) );
	my $database_xml = catfile( $module_dir, 'database.xml' );
	my $objects_xml  = catfile( $module_dir, 'objects.xml' );

	# read the database definition
	$DATABASE = Xmldoom::Definition::parse_database_uri( $database_xml );
	$DATABASE->parse_object_uri( $objects_xml );
}

1;

