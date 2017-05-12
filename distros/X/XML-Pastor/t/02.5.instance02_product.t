
use Test::More tests=>20;
use utf8;
use strict;

use_ok ('XML::Pastor');


my $pastor = XML::Pastor->new();
	
$pastor->generate(	mode =>'eval',
					schema=>['./test/source/mathworks/schema/product.xsd'], 
					class_prefix=>"XML::Pastor::Test::MathWorks::",
					destination=>'./test/out/lib/', 					
					verbose =>0
				);
				
my $product = XML::Pastor::Test::MathWorks::product->from_xml(URI::file->new_abs('./test/source/mathworks/xml/mProduct.xml'));
	
is($product->_name, 'myProduct', "Product - attribute _name");		
is($product->name, 'myProduct', "Product - attribute alias name");

my $owner = $product->owner;

is($owner->owningTeam, 'IAT', 'Owning team');
is($owner->contactName, 'Robert Schweikert', 'Contact name');

is($product->productName, 'Test Special Edition', "productName");
is($product->productVersion, '0.1.3', "productVersion");
is($product->licenseName, 'tse', "licenseName");
is($product->externalProductIdentifier, '88', "externalProductIdentifier");


is ($product->released, 'false', "Product released - STRING");
ok(!$product->released, "Product released - BOOLEAN");

my $platforms = $product->releasePlatforms->platform;

is ($platforms->[0], 'glnx86', "platforms[0]");
is ($platforms->[1], 'glnxa64', "platforms[1]");
is ($platforms->[2], 'maci', "platforms[2]");

my $componentDeps = $product->dependsOn->componentDep;
my $componentDep_h = $componentDeps->hash(sub {shift->name;});

ok (exists($componentDep_h->{ola}), "ola");
ok (exists($componentDep_h->{bola}), "bola");
ok (exists($componentDep_h->{pablo}), "pablo");

is($product->requiredProducts->productDep->name, 'tester', "Required products");
is($product->recommendedProducts->productDep->name, 'testerExtension', "Recommended products");

#	print STDERR "\nTest OVER baby!\n";			
ok(1);	# survived everything
  

1;

