require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "UNIVERSAL::dump",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'add dump methods to all classes and objects',
 VERSION_FROM	=> 'lib/UNIVERSAL/dump.pm',

 PREREQ_PM	=> {qw(
                    Data::Dumper      0
                   )},
);
