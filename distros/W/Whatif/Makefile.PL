use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $variant = "44BSD";
$variant = "43BSD" if $^O eq 'solaris';


WriteMakefile(
    'NAME'		=> 'Whatif',
    'VERSION_FROM'	=> 'Whatif.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More => 0 }, # e.g., Module::Name => 1.1
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Simon Wistow <simon@thegestalt.org>') : ()),
       DEFINE     => "-DVARIANT_$variant -DPERL_INTERP='\"$perl_path\"' -I.",

);
