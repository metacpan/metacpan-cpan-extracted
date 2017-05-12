#!/usr/bin/perl
use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect
		      create_table_FILIERES
		      create_table_LOTS
		      create_table_REFIDDOC
		      create_table_SUPPORTS
		   );

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_PARAM');

create_table_FILIERES($dbh);
create_table_LOTS($dbh);
create_table_REFIDDOC($dbh);
create_table_SUPPORTS($dbh);
