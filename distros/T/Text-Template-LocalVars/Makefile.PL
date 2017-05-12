use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name     'Text-Template-LocalVars';
all_from 'lib/Text/Template/LocalVars.pm';

readme_from 'lib/Text/Template/LocalVars.pm', { format => 'md' };
readme_from 'lib/Text/Template/LocalVars.pm', { format => 'txt' };

license  'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );

author_tests( 'xt' );


resources (
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Template-LocalVars',
   repository => 'http://bitbucket.org/djerius/text-template-localvars',

);


tests_recursive('t');

cpanfile;

WriteAll;
