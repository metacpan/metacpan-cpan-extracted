# pod and pod_coverage pod_spelling test

use strict ;
use warnings ;

use Test::Pod::Coverage;

#~ pod_coverage_ok
	#~ (
	#~ "Config::Hierarchical",
	#~ {
	#~ also_private => 
		#~ [
		#~ qr/^[A-Z_]+$/ 
		#~ ],
	#~ },	
	#~ "private",
	#~ );
    
all_pod_coverage_ok() ;