require 5.005; # Test::More doesn't support earlier
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "setenv",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'set %ENV variables at compile time',
 VERSION_FROM	=> 'lib/setenv.pm',
 PREREQ_PM	=> { qw(
                   ) },
);
