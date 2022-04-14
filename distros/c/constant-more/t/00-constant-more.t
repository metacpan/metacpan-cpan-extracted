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




done_testing;
