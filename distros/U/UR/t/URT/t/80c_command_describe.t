use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 3;


my $cmd = UR::Namespace::Command::Show::Properties->create(classes_or_modules => ['URT::Thingy'], namespace_name => 'URT');
ok($cmd, 'Create UR::Namespace::Command::Show::Properties');

my $output = '';
close STDOUT;
open(STDOUT, '>', \$output) || die "Can't open STDOUT: $!";

ok($cmd->execute(), 'Execute()');
my $expected_output = <<EOS;
URT Thingy Type URT::Thingy
  namespace: URT
  table name: 
  data source id: 
  is abstract: 0
  is final: 0
  is singleton: 0
  is transactional: 1
  schema name: 
  meta class name: URT::Thingy::Type
  Inherits from: UR::Object
  Properties: 
                                enz_id (no column)                                              NUMBER(10)  
     ID                             id (no column)                                                  Scalar  
     ID                         pcr_id (no column)                                              NUMBER(15)  
                              pcr_name (no column)                                            VARCHAR2(64)  
                              pri_id_1 (no column)                                              NUMBER(10)  
                              pri_id_2 (no column)                                              NUMBER(10)  
  References: -
  Referents: -

EOS

is($output, $expected_output, 'Output is as expected');

