use warnings;
use strict;    
use Test::More;
use English qw( -no_match_vars);
use FindBin qw($Bin);
  
BEGIN {
   plan tests =>  '6';
   use_ok  'XML::RelaxNG::Compact::PXB';
   unshift @INC, "$Bin/data"; 
   use Log::Log4perl qw(:easy :levels); 
   Log::Log4perl->easy_init({
                              level => ERROR,
                              layout => '%d (%P) %p> %F{1}:%L %M - %m%n',
                           });
}
 
my $element =  {  'attrs'  => {value => 'scalar', type => 'scalar', port => 'scalar',  xmlns => 'nsid'},
                   elements => [], 
		   text => 'unless:value',
		   sql      => { table1 => { field1 => { value => ['value'], if => 'name:keyword'} }},
               };
	       
my $model =    {  'attrs'  => {id => 'scalar', type => 'scalar', xmlns => 'nsid'}, 
                  elements => [ 
		                [subelement => $element]
			      ], 
	       }; 
#2
can_ok(XML::RelaxNG::Compact::PXB->new(),qw/buildAPI buildHelpers buildTests sayIt saying/);
#3
my $obj1;
eval {
    $obj1 =  XML::RelaxNG::Compact::PXB->new({ 
                                            top_dir =>   "$Bin/data", 
					    nsregistry =>  {'nsid' => 'http://URI/nsid', 'nsid2' => 'http://URI/nsid2'},
					    project_root => "MyAPI",
                                            datatypes_root =>   "Datatypes",
                                            schema_version =>   "1.0",
					    test_dir =>   "t",
				 	    footer => POD::Credentials->new({author=> 'Joe Doe', see_also => ' See this nice thing'})
					    })

};
ok($obj1 && !$EVAL_ERROR, "Create object XML::RelaxNG::Compact::PXB..." ) or  diag($EVAL_ERROR);
undef $EVAL_ERROR;

#4
eval {
   $obj1->buildAPI({name=>'mymodel', element=>$model}); 

};
ok(!$EVAL_ERROR, "buildAPI for test model...") or  diag($EVAL_ERROR);
undef $EVAL_ERROR;


#5
eval {

   my $obj2 = XML::RelaxNG::Compact::PXB->new({ 
                                            top_dir =>   "$Bin/data", 
					    nsregistry =>  {'nsid' => 'http://URI/nsid', 'nsid2' => 'http://URI/nsid2'}, 
					    project_root => "MyAPI",
                                            datatypes_root =>   "Datatypes",
                                            schema_version =>   "1.0",
					    test_dir =>   "t",
				 	    footer => POD::Credentials->new({author=> 'Joe Doe', see_also => ' See this nice thing'})
					    });
   
   $obj2->buildTests({name=>'mymodel', element=>$model}); 

};
ok(!$EVAL_ERROR, "buildTests for test model...") or  diag($EVAL_ERROR);
undef $EVAL_ERROR;

#6
eval {
  $obj1->buildHelpers(); 

};
ok(!$EVAL_ERROR, "buildHelpers for test model...") or  diag($EVAL_ERROR);
undef $EVAL_ERROR;
 
