use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 11 }

use FileHandle;
require XML::Mini::Document;
use Data::Dumper;
use strict;

my $sample = './t/sample/vocpboxes.xml';
my $numberOfBoxes = 20;

{
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->parse($sample);

	ok($numchildren, 3);

	my $XMLhash = $miniXML->toHash();

	my $boxes = $XMLhash->{'VOCPBoxConfig'}->{'boxList'}->{'box'};
	ok($boxes);
	
	ok(ref $boxes, 'ARRAY');
	my $numBoxes = @{$boxes};
	
	ok($numBoxes, $numberOfBoxes);
	
	#print STDERR Dumper($XMLhash);
	my $attribs = {
					'attributes' => {
							'-all'	=> [ 'id', 'number', 'version'],
							'email'	=> 'type',
					},
				};

	my $newDocHash = {
			'person'	=> [
							{
								'id'	=> '001',
								'name'	=> 'Pat D',
								'type'	=> 'SuperFly SuperSpy',
								'email'	=> [
											{
												'type'	=> 'public',
												'-content'	=> 'spam-me@psychogenic.com',
											},
											'noattrib@example.com',
											{
												'type'	=> 'private',
												'-content' => 'dontspam@psychogenic.com',
											}
										],
								'address'	=> '1234 Skid Row, Irvine, CA 92618',
							},
							{
								'id'	=> '007',
								'type'	=> 'SuperSpy',
								'name'	=> 'James Bond',
								'email'	=> 'mi5@london.uk',
								'address'	=> 'Wherever he is needed most',
							},

							{
								'id'	=> '006',
								'number'	=> 6,
								'name'	=> 'Number 6',
								'email'	=> 'prisoner@aol.com',
								'comment'	=> 'I am not a man, I am a free number',
								'address'	=> '6 Prison Island Road, Prison Island, Somewhere',
							}
						],
			
	};

	$numchildren = $miniXML->fromHash($newDocHash, $attribs);
	
	ok($numchildren, 3);
	
	
	

my $xmlString = 
qq|
<people>
 <person id="007">
  <email>
   mi5\@london.uk
  </email>
  <name>
   James Bond
  </name>
  <address>
   Wherever he is needed most
  </address>
  <type>
   SuperSpy
  </type>
 </person>
 <person id="006" number="6">
  <comment>
   I am not a man, I am a free number
  </comment>
  <name>
   Number 6
  </name>
  <email type="private">prisoner\@aol.com</email>
  <address>
   6 Prison Island Road, Prison Island, Somewhere
  </address>
 </person>
</people>
|;

	$miniXML->init();
	$numchildren = $miniXML->parse($xmlString);


	ok($numchildren, 1);
	
	my $toHash = $miniXML->toHash();
	# print STDERR Dumper($toHash);
	
	ok($toHash->{'people'}->{'person'}->[0]->{'id'}, '007');
	
	ok($toHash->{'people'}->{'person'}->[1]->{'id'}, '006');
	
	
	my $options = { 
  			'attributes'	=> {
  					'spy'	=> 'id',
					'email'	=> 'type',
					'friend' => ['name', 'age'],
				}
		};


   my $h = {
	 
	 'spy'	=> {
		'id'	=> '007',
		'type'	=> 'SuperSpy',
		'name'	=> 'James Bond',
		'email'	=> {
				'type'		=> 'private',
				'-content'	=> 'mi5@london.uk',
				
			},
		'address'	=> {
				'type'	=> 'residential',
				'-content' => 'Wherever he is needed most',
		},
		
		'friend'	=> [
					{
						'name' 	=> 'claudia',
						'age'	=> 25,
						'type'	=> 'close',
					},
					
					{
						'name'	=> 'monneypenny',
						'age'	=> '40something',
						'type'	=> 'tease',
					},
					
					{
						'name'	=> 'Q',
						'age'	=> '10E4',
						'type'	=> 'pain',
					}
				],
									
	},
   };
	
	

  	$numchildren = $miniXML->fromHash($h, $options);
	
	ok($numchildren, 1);
	
	my $spyname = $miniXML->getElementByPath('spy/name');
	ok($spyname);
	
	my $name = $spyname->getValue();
	
	ok($name, 'James Bond');
	
}

