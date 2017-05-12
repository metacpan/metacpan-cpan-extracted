#!/usr/bin/perl -w
 use lib qw(../lib);
 use warnings;
 use strict; 
 use File::Path;
 use perfSONAR_PS::SimpleConfig;
 
 
 
 BEGIN {
    use Log::Log4perl qw(get_logger);   
    Log::Log4perl->init("../bin/logger.conf"); 
 };
 use   version;
     
 use   perfSONAR_PS::DataModels::PingER_Model 2.0 qw($message);
 use   perfSONAR_PS::DataModels::APIBuilder   2.0 qw(&buildAPI  $API_ROOT $TOP_DIR $SCHEMA_VERSION $DATATYPES_ROOT $TEST_DIR);
    
   
   my $logger = get_logger("pinger_schema");
  
   my %CONF_PROMPTS = (   "METADATA_DB_TYPE" => "type of the internal metaData DB ( file| xmldb | sql ) ", 
                          "METADATA_DB_NAME" => " name of the internal   metaData  DB ", 
			  'DB_USER' =>    '  username to connect to the data SQL DB ',
                          'DB_PASS' =>    ' password to connect to the data SQL DB ',
			  'TOP_DIR' =>    '  top directory   where to build API ',
			  'API_ROOT'=>   ' root package name for the API', 
			  'TEST_DIR' => ' top directory  where to build tests files ', 
			  'DATATYPES_ROOT' => ' top directory name where to place versioned datatypes API',  
			  'DB_DRIVER' =>  '  perl driver name of the  data SQL DB ',
			  'CONFIGURE_DB' => ' by answering yes you will load yor DB configuration and create all object files ',
			  'DB_CLASSNAME' => ' class prefix for database packages',
		      );

		# Read in configuration information
 
#
#   pinger configuration part is here
# 
  my $pingerMA_conf = perfSONAR_PS::SimpleConfig->new( -FILE => 'pingerMA_model.conf', 
                                                     -PROMPTS => \%CONF_PROMPTS, 
						     -DIALOG => '1');
  $pingerMA_conf->parse();  
  $pingerMA_conf->store;
  my $configh =$pingerMA_conf->getNormalizedData;
   
  #####  API root dir and root package name 
  $API_ROOT = $configh->{API_ROOT};
  #####  API root dir and root package name 
  $DATATYPES_ROOT =  $configh->{DATATYPES_ROOT};
  
  ##### schema version will be set as part of the built API pathname
  #
  $SCHEMA_VERSION =     perfSONAR_PS::DataModels::DataModel->VERSION; 
  #   to   format version as vX_XX 
  $SCHEMA_VERSION  =~ s/\./_/g;
  
  $TOP_DIR = $configh->{"TOP_DIR"}; 
  #   $TOP_DIR = "/tmp/API/"; 
  $TEST_DIR = $configh->{"TEST_DIR"};
  if($configh->{"CONFIGURE_DB"} && $configh->{"CONFIGURE_DB"} eq 'yes') {  
      require   Rose::DB::Object::Loader;
    
      my $dbloader =  undef;
      eval {
         $dbloader =   Rose::DB::Object::Loader->new(
                    
		    db_dsn =>      "DBI:" . $configh->{"SQL_DB_DRIVER"} .":dbname=".$configh->{"SQL_DB_NAME"} ,
                    db_username =>   $configh->{SQL_DB_USER},
                    db_password =>   $configh->{SQL_DB_PASS},
 	            class_prefix =>  $configh->{DB_CLASSNAME},
		    include_tables => '^(metaData|data\_\d+|host)$',
		    module_dir =>    $configh->{TOP_DIR},
		    db_options => { AutoCommit =>1, ChopBlanks => 1, 
                            RaiseError => 0, PrintError => 1},  
                );
      };
      if($@) {
         $logger->fatal("Failed to load DB : " . $@);
         exit(1);
      }
    
      my @dbhooks =  $dbloader->make_modules(); 
  } 
   
  mkpath ([ "$TOP_DIR"  ], 1, 0755) ; 
  $TOP_DIR .=  $API_ROOT;  
  eval {
      buildAPI('message', $message,  '', '' )
  };
  if($@) {
       $logger->fatal(" Building API failed " . $@);
  }
