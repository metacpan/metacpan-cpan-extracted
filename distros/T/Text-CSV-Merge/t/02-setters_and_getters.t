#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::CSV::Merge' ) || print "Bail out!\n";
}

diag( "Testing getters and setters: i.e. read/write possibilities." );


# attempt to set csv_parser
# attempt to get csv_parser

# attempt to set dbh
# attempt to get dbh

# attempt to set base_file
# attempt to get base_file

# attempt to set merge_file
# attempt to get merge_file

# attempt to set output_file
# attempt to get output_file

# attempt to set columns
# attempt to get columns

# attempt to set search_field
# attempt to get search_field
