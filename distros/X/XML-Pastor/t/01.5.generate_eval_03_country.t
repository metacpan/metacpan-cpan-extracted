
use Test::More tests=>2;

use_ok ('XML::Pastor');


my $pastor = XML::Pastor->new();
	
$pastor->generate(	mode =>'eval',
					schema=>['./test/source/country/schema/country_schema3.xsd'], 
					class_prefix=>"XML::Pastor::Test",
					destination=>'./test/out/lib/', 					
					verbose =>0
				);
				
				

#	print STDERR "\nTest OVER baby!\n";			
ok(1);	# survived everything
  

1;

