use strict;
use warnings;

use Test::More;#tests => 1;
BEGIN { use_ok('constant::more') };


#basic constants 


use constant::more NAME=>"value";	#Set a single constant
	
use constant::more {			#Set multiple constants
		NAME2=>"value",
		ANOTHER=>"one",
};


ok NAME eq "value", "Simple ok";
ok NAME2 eq "value", "Simple ok";
ok ANOTHER eq "one", "Simple ok";

use constant::more 			#Set multiple constants via flat list (v0.3.0)
		NAME2_FLAT=>"value",
		ANOTHER_FLAT=>"one",
;

ok NAME2_FLAT eq "value", "Simple ok";
ok ANOTHER_FLAT eq "one", "Simple ok";



use constant::more {
	FEATURE_A_ENABLED=>{		#Name of the constant
		val=>0,		#default value 
		opt=>"feature1",	#Getopt::Long option specification
		env=>"MY_APP_FEATURE_A"	#Environment variable copy value from 
	},

	FEATURE_B_CONFIG=>{
		val=>"disabled",
		opt=>"feature2=s",	#Getopt::Long format
	}
};


ok FEATURE_A_ENABLED==0 , "Normal ok";
ok FEATURE_B_CONFIG eq "disabled" , "Normal ok";


# Enumeration testing

use constant::more qw<CONA=0 CONB CONC>;
ok CONA == 0;
ok CONB == 1;
ok CONC == 2;

# Prefix with globbing
use constant::more <PREFIX_{1=0,2,3=10,4}>;

ok PREFIX_1 == 0;
ok PREFIX_2 == 1;
ok PREFIX_3 == 10;
ok PREFIX_4 == 11;

# Check the single item case
#
use constant::more "SINGLE=1"; 

ok SINGLE ==1;

done_testing;
