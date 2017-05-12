use Test::More 'no_plan';
use Log::Log4perl qw( :levels);
use POSIX;
use Data::Dumper;
use Time::HiRes qw ( &gettimeofday );
use Scalar::Util qw(blessed);
Log::Log4perl->easy_init($DEBUG);

# configs
my $tempDB = '/tmp/pingerMA.sqlite3';

# my $config = {
#	'DB_DRIVER' => 'SQLite',
#        'DB_TYPE' => 'SQLite',
#	'DB_NAME' => $tempDB,
#	'DB_USER' => 'pinger',
#	'DB_PASS' => 'pinger',		
#};

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";


# create a blank database using sqlite for now
`rm $tempDB` if -e  $tempDB;
`sqlite3 $tempDB < util/create_pingerMA_SQLite.sql`; 
ok( -e $tempDB, "create temporary database $tempDB" );

# use class
use_ok('perfSONAR_PS::DB::SQL::PingER');

 

# instantiate
my $db_obj = perfSONAR_PS::DB::SQL::PingER->new( 
   {
    driver       => 'SQLite', 
    database     => $tempDB,
   
   });
ok( blessed $db_obj && $db_obj->can('openDB'), "new DB object created ". $db_obj->ERRORMSG );

my $result =  $db_obj->openDB();
ok(  $result == 0  && $db_obj->alive == 0 , "open db connection" . $db_obj->ERRORMSG);
print "DB connected \n";

 
###
# try using the objects directly
###

### Hosts table

my $ip_name1 = 'localhost';
my $ip_number1 = '127.0.0.1';

# select or insert
my $hostname1 =$db_obj->soi_host({  
				'ip_name' => $ip_name1, 
				'ip_number' => $ip_number1 
			        });
ok(   $hostname1 eq 'localhost', "soi  host: $hostname1 " . $db_obj->ERRORMSG);

my $ip_name2 = 'www.apple.com';
my $ip_number2 = '999.999.999.999';

# select or insert
my $hostname2 =$db_obj->soi_host({  
				'ip_name' => $ip_name2, 
				'ip_number' => $ip_number2 
			        });
ok(  $hostname2  eq 'www.apple.com', "soi  host: $hostname2 " . $db_obj->ERRORMSG);

 
 
my $transport = 'ICMP';
my $packetSize = '1008';
my $count = '10';
my $packetInterval = '1';
my $ttl = '64';

 
my $metaid =  $db_obj->soi_metadata({        
					'ip_name_src' =>  $hostname1 ,
					'ip_name_dst' => $hostname2 ,
					'transport'   => $transport,
					'packetSize'  => $packetSize,
					'count'		  => $count,
					'packetInterval' => $packetInterval,
					'ttl'		  => $ttl,
					});
					
ok( $metaid &&  $metaid > 0 , " soi metadata: $metaid " . $db_obj->ERRORMSG );

# read
my @metaIDs =  $db_obj->getMetaID( [ 	'ip_name_src' => { 'eq' =>  $hostname1 },
					'ip_name_dst' => { 'eq' =>  $hostname2  },
					'transport'	  => { 'eq' => $transport },
					'packetSize'  => { 'eq' => $packetSize },
					'count'		  => { 'eq' => $count },
					'packetInterval' => { 'eq' => $packetInterval },
					'ttl'		  => { 'eq' => $ttl },
				 ], 1);
ok( @metaIDs  , "getMetaID:  " . (join " : ",  @metaIDs )  . $db_obj->ERRORMSG );

# read
my $metadatas =  $db_obj->getMeta( [ 	'ip_name_src' => { 'eq' => $hostname1  },
					'ip_name_dst' => { 'eq' =>  $hostname2 },
					'transport'	  => { 'eq' => $transport },
					'packetSize'  => { 'eq' => $packetSize },
					'count'		  => { 'eq' => $count },
					'packetInterval' => { 'eq' => $packetInterval },
					'ttl'		  => { 'eq' => $ttl },
				 ], 1);
ok( $metadatas && ref($metadatas ) eq 'HASH' , "getMeta " . $db_obj->ERRORMSG);
				 
# change and insert new one

my $existingID = undef;
foreach my $metaID (sort {$a <=> $b} keys  %{$metadatas} ) {
      $metadatas->{$metaID}->{count} = 55;
      delete $metadatas->{$metaID}->{metaID} if defined $metadatas->{$metaID}->{metaID};
      my $meta  =  $db_obj->soi_metadata( $metadatas->{$metaID});
      ok( $meta  &&  $meta > 0 , "updated and inserted new metadata "  . $db_obj->ERRORMSG);
      $existingID =  $metaID;
}
 
 		 
# create					
use Time::HiRes qw ( &gettimeofday );
my ( $nowTime, $nowMSec ) = &gettimeofday;

 
my $data = $db_obj->insertData({
				'metaID'	=> $existingID,
				'timestamp' =>    $nowTime,
				'minRtt'	=> '0.023',
				'maxRtt'	=> '0.030',
				'meanRtt'	=> '0.026',
				'minIpd'	=> '0.0',
				'maxIpd'	=> '0.002',
				'meanIpd'	=> '0.006',
				'iqrIpd'	=> '0.0001',
				'lossPercent'	=> '0.0',
				'outOfOrder'	=> 'true',									
				'duplicates'	=> 'false',	
			    });
ok( $data && $data >0 , "create data for $existingID and  $nowTime " . $db_obj->ERRORMSG);

 
# another read
my $datas =   $db_obj->getData( [ 'timestamp' => { 'eq' => $nowTime } ] );
ok( $datas  && ref($datas) eq 'HASH' , "getData for    '$nowTime' " . $db_obj->ERRORMSG);



foreach my $metaID (keys %{$datas}) {
   foreach my $timestamp (keys %{$datas->{$metaID}}) {
       $datas->{metaID}->{$timestamp}->{lossPercent} =   '100.0';
       delete  $datas->{metaID}->{$timestamp}->{metaID} if   defined $datas->{metaID}->{$timestamp}->{metaID};
       delete  $datas->{metaID}->{$timestamp}->{timestamp} if defined   $datas->{metaID}->{$timestamp}->{timestamp};
       warn " ...updating data for $timestamp and $metaID";
       my $result = $db_obj->updateData( $datas->{metaID}->{$timestamp}, [ metaID => $metaID, timestamp => $timestamp]);
       ok(   $result  == 0 , "update data for $timestamp and $metaID " . $db_obj->ERRORMSG);
  }
}
 

 
  
# remove temp file
#`rm $tempDB`;

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
