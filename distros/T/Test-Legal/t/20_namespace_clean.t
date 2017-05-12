
use Test::More 'no_plan';
use Test::Legal::Util();



#my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

can_ok 'Test::Legal::Util',$_ for @Test::Legal::Util::EXPORT_OK;

my @private =  qw/ 
    is_license_type    	license_text      		is_annotated     		find_authors     
	find_license 		is_license_type 		check_LICENSE_file 		check_META_file 
    _annotate_copyright _deannotate_copyright 	default_copyright_notice    
/; 


#ok ! (Test::Legal::Util->can( $_)), $_  for @private ;


