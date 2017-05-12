use strict;
use Test;

 # use a BEGIN block so we print our plan before MyModule is loaded
  BEGIN { plan tests => 3 }

use Verilog::CodeGen;
mkdir 'Objects', 0755;
chdir 'Objects';
&create_code_template('test_CodeGen','Verilog');
if(-e "test_CodeGen.pl"){ok(1)} else {ok(0)}
&make_module('test_CodeGen','Verilog');
if(-e "DeviceLibs/Verilog.pm"){ok(1)} else {ok(0)}
&make_module('','Verilog');
if(-e "../Verilog.pm"){ok(1)} else {ok(0)}
unlink  "../Verilog.pm";
unlink  "DeviceLibs/Verilog.pm";
unlink "test_CodeGen.pl";
