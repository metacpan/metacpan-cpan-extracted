package Import::Datasource;

use DBI;

use vars qw (@ISA @EXPORT);
require Exporter;
@ISA = 'Exporter';

my $auth_db_hostname = "localhost";
my $auth_db_port = "3306";
my $auth_db_basename = "blog";
my $auth_db_username = "blog";
my $auth_db_password = "blog";

$handler = 0;

$handler = DBI->connect ("dbi:mysql:$auth_db_basename:$auth_db_hostname:$auth_db_port",
                        "$auth_db_username", "$auth_db_password");

END{
   $handler->disconnect() if $handler;
}

1;
