use warnings;
use strict;  
use XML::RelaxNG::Compact::PXB;  
use POD::Credentials; 
use Data::Dumper;
 
=head1 NAME 
             
    ps_schemaPXB.pl   -  example of the data model definitions and API building script utilization for perfSONAR-PS
                         project

=head1 DESCRIPTION

run this script - perl  ps_schemaPXB.pl,
it will create  temp  directory with all modules and temp/t directory with test files,
chdir to temp and run perl ./test.pl to test generated API.
See L<DataModel.pm>,L<SOnar_Model.pm> and PingER_Model.pm> for model definitions. Please note how data model modules
loaded. In order to eliminate namespace conflicts its done at the runtime.

This is the real life example and generated classes are currently utilized by perfSONAR-PS webservices.

=cut



BEGIN {
   use Log::Log4perl qw(:easy :levels);   
   Log::Log4perl->easy_init($DEBUG); 
};
 
my $logger = get_logger("pinger_schema");
 


# top dir for the generated API 
my $TOP_DIR = 'temp' ; 
 
# namespace registries for each schema

my   %NSS = ( 
        	
	  
	   	
	   'NMTOPO_DATATYPES' => {
	   
	       'xsd'=>"http://www.w3.org/2001/XMLSchema",
               'xsi' => "http://www.w3.org/2001/XMLSchema-instance",
               'SOAP-ENV' => "http://schemas.xmlsoap.org/soap/envelope/",
               'nmwg' => "http://ggf.org/ns/nmwg/base/2.0/",
               'nmwgr' => "http://ggf.org/ns/nmwg/result/2.0/" ,
	       'select'  => "http://ggf.org/ns/nmwg/ops/select/2.0/",
	      
	       'nmwgt' => "http://ggf.org/ns/nmwg/topology/2.0/",
	       'topo'=> "http://ggf.org/ns/nmwg/topology/2.0/",
	     
	       'nmtl4' => "http://ogf.org/schema/network/topology/l4/20070828",
	       'nmtl3' => "http://ogf.org/schema/network/topology/l3/20070828",
               
               'nmtl2' => "http://ogf.org/schema/network/topology/l2/20070828/",
               'nmtopo' => "http://ogf.org/schema/network/topology/base/20070828/",
	       'nmtb' => "http://ogf.org/schema/network/topology/base/20070828/",     
	       'nmtm' => "http://ggf.org/ns/nmwg/time/2.0/"	   
	   },
	   
	   ); 
	    
# mappings for data models
my %MODELS = (   'NMTOPO_DATATYPES' => { name => 'topology', element  => 'perfSONAR_PS::DataModels::Network_Topology::nmtopo'},
	      ); 
# for every model	    
 
foreach my $type (keys %MODELS) {	   
    no strict 'refs';   
    eval {   
        my $class = $MODELS{$type}->{element};
	$class =~ s/\:\:\w+$//;
	eval "require $class";
        my $api_builder =   XML::RelaxNG::Compact::PXB->new({
                                     	       top_dir =>    $TOP_DIR ,
                                     	       nsregistry =>  $NSS{$type},
					       project_root =>   'perfSONAR_PS',
                                     	       datatypes_root =>   $type,
                                     	       schema_version =>  ${"$class\:\:VERSION"},
                                     	       test_dir =>   't',
					       DEBUG => 0,
				     	       footer => POD::Credentials->new({author=> 'Maxim Grigoriev', 
				     						license=> 'You should have received a copy of the Fermitool license along with this software.',
									        copyright => 'Copyright (c) 2010, Fermi Research Alliance (FRA)'})
						             });
        $api_builder->buildAPI({ name =>  $MODELS{$type}->{name}, element  =>  ${$MODELS{$type}->{element}} })
    };
    if($@) {
        $logger->logdie(" Building API failed " . $@);
    } 
    use strict;
}

1;
