use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "as",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'load OO module under another name',
 VERSION_FROM	=> 'lib/as.pm',

 PREREQ_PM	=> {qw(
                    warnings::register    0
                   )},
);
