#!perl -T

use strict;
use warnings;

use Data::Dumper;
use Data::Validate::Type;
use Test::Exception;
use Test::Most 'bail';
use WebService::DataDog;


eval 'use DataDogConfig';
$@
	? plan( skip_all => 'Local connection information for DataDog required to run tests.' )
	: plan( tests => 12 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $dashboard_obj = $datadog->build('Dashboard');
ok(
	defined( $dashboard_obj ),
	'Create a new WebService::DataDog::Dashboard object.',
);

my $response;

throws_ok(
	sub
	{
		$response = $dashboard_obj->create();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);



throws_ok(
	sub
	{
		$response = $dashboard_obj->create(
			title       => "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABC",
			description => "blah",
			graphs      => [
				{
					title => "Sum of Memory Free",
					definition =>
					{
						events   =>[],
						requests => [
							{ q => "sum:system.mem.free{*}" }
						]
					},
					viz => "timeseries"
				},
			],
		);
	},
	qr/nvalid 'title'.*80/,
	'Dies with title too long.',
);

throws_ok(
	sub
	{
		$response = $dashboard_obj->create(
			title       => "title goes here",
			graphs      => [
				{
					title => "Sum of Memory Free",
					definition =>
					{
						events   =>[],
						requests => [
							{ q => "sum:system.mem.free{*}" }
						]
					},
					viz => "timeseries"
				},
			],
			description => "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam eget convallis lorem. Curabitur eget neque turpis. Curabitur gravida ligula et tortor facilisis placerat. Duis convallis justo eget lorem consectetur eleifend. Quisque lacinia ligula sit amet orci rhoncus condimentum. Curabitur facilisis velit eu urna dictum viverra. Cras accumsan magna porta nisi dapibus dignissim. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Ut massa mi, luctus facilisis venenatis eget, cursus a diam. Ut massa urna, ultrices lacinia dapibus et, convallis vitae eros. Donec egestas turpis eu mauris vulputate in congue augue venenatis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Proin nec sapien vel quam dictum viverra.

Sed neque urna, fermentum quis facilisis non, tincidunt in massa. Sed pulvinar sodales aliquam. In hac habitasse platea dictumst. Nullam condimentum dignissim fermentum. Sed sollicitudin, turpis vel mollis lacinia, nunc quam vehicula tortor, sed ultricies enim nisi at urna. Curabitur sodales, magna quis sollicitudin ullamcorper, mi quam interdum ligula, ut dignissim massa urna non nisi. Suspendisse nulla quam, sodales sit amet porttitor vitae, ornare in eros. Nulla vehicula leo id lacus aliquet sagittis ullamcorper sapien blandit. Phasellus pulvinar sagittis lectus tincidunt pretium. Quisque mollis leo quis arcu sagittis condimentum. Etiam risus urna, molestie at laoreet tempus, vehicula vitae ligula. Nulla vel ipsum id justo ullamcorper pulvinar ac ac lorem. Donec ut diam sit amet lacus ultrices lobortis sit amet sed lacus. Nam vel leo vitae risus gravida pulvinar pulvinar non erat. Etiam venenatis turpis at dui egestas ut iaculis dolor venenatis. Donec aliquam nunc a nunc tempor sed vestibulum orci pellentesque.

Aliquam erat volutpat. In vulputate tortor eget nisi tincidunt posuere. Duis venenatis neque et risus dapibus sodales. Morbi laoreet neque id elit sodales congue. Maecenas lacinia pharetra faucibus. Nulla facilisi. Aliquam leo sapien, porttitor quis rhoncus ac, sodales in velit. Nulla at magna et ipsum porttitor aliquet. Suspendisse eget elit nec lorem vehicula bibendum. Proin iaculis rhoncus nisi, in blandit ipsum posuere sed. In hac habitasse platea dictumst. Quisque quis dolor eget leo aliquet aliquam. Duis mollis porta lobortis. Vestibulum vel sollicitudin neque. Proin luctus, arcu sagittis cursus molestie, lectus neque hendrerit neque, at cursus ligula augue non est. In mattis mi rhoncus justo tincidunt sed posuere arcu tincidunt.

Integer ultrices, ante nec tempus sagittis, nunc felis consequat neque, non vehicula orci lacus quis leo. Sed consectetur felis eu tortor blandit ut mollis nunc scelerisque. Curabitur arcu dolor, placerat at aliquam sit amet, pharetra ac tortor. Integer dignissim turpis ut nisi vestibulum dapibus. Morbi nulla justo, porta a lacinia eget, sodales at augue. Curabitur tincidunt tincidunt tellus, vitae condimentum libero gravida fermentum. Suspendisse aliquet, nunc vel eleifend tristique, justo arcu venenatis odio, non porta nisi magna ornare odio. Mauris quis augue auctor magna sollicitudin congue eget et ante. Curabitur id sapien ligula. Proin non dui ut massa egestas lobortis. Morbi ullamcorper purus eget ante placerat bibendum.

Sed gravida odio at risus accumsan vel consectetur ante euismod. Proin rhoncus felis vel enim commodo varius. In euismod dignissim lorem non consectetur. Nulla eu nisi risus, eget vehicula felis. Suspendisse semper accumsan justo, non elementum arcu ornare laoreet. Fusce eget tortor magna. Nam facilisis commodo blandit.

Suspendisse gravida, leo ut ornare cursus, nulla odio luctus orci, lacinia elementum risus sapien eget purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec dapibus, felis eu tempor lobortis, leo odio sagittis massa, ut dignissim felis urna at lacus. Suspendisse ut feugiat lorem. Maecenas fermentum nulla sed quam nullam."
		);
	},
	qr/nvalid 'description'/,
	'Dies with description too long.',
);


lives_ok(                                                                       
  sub                                                                           
  {                                                                             
    $response = $dashboard_obj->create(                                         
      title       => "TO BE DELETED test dash deprecated",                                 
      description => "Created by WebService::DataDog unit test script",                                  
      graphs      => [                                                          
        {                                                                       
          title => "Sum of Memory Free",                                        
          definition =>                                                         
          {                                                                     
            events   =>[],                                                      
            requests => [                                                       
              { q => "sum:system.mem.free{*}" }                                 
            ]                                                                   
          },                                                                    
          viz => "timeseries"                                                   
        }                                                                       
      ],                                                                        
    );                                                                          
  },                                                                            
  'Create new dashboard, just for deprecated delete',                                                       
)|| diag explain $response;


ok(                                                                             
  open( FILE, '>', 'webservice-datadog-dashboard-dashid-deprecated.tmp'),                  
  'Open temp file to store new dashboard id for deprecated delete'                                    
);                                                                              
                                                                                
print FILE $response;

ok(                                                                             
  close FILE,                                                                   
  'Close temp file'                                                             
);

lives_ok(
	sub
	{
		$response = $dashboard_obj->create(
			title       => "TO BE DELETED test dash",
			description => "Created by WebService::DataDog unit test script",
			graphs      => [
				{
					title => "Sum of Memory Free",
					definition =>
					{
						events   =>[],
						requests => [
							{ q => "sum:system.mem.free{*}" }
						]
					},
					viz => "timeseries"
				}
			],
		);
	},
	'Create new dashboard',
)|| diag explain $response;

ok(
	Data::Validate::Type::is_number( $response ),
	'Response is a number.',
);

# Store id for use in upcoming tests: update, delete, etc

ok(
	open( FILE, '>', 'webservice-datadog-dashboard-dashid.tmp'),
	'Open temp file to store new dashboard id'
);

print FILE $response;

ok(
	close FILE,
	'Close temp file'
);
