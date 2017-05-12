
use Test::More tests=>2;

use_ok ('XML::Pastor');


my $pastor = XML::Pastor->new();
	
$pastor->generate(	mode =>'eval',
					schema=>['./test/source/mathworks/schema/product.xsd'], 
					class_prefix=>"XML::Pastor::Test::MathWorks::",
					destination=>'./test/out/lib/', 					
					verbose =>0
				);
				
				

#	print STDERR "\nTest OVER baby!\n";			
ok(1);	# survived everything
  

1;

