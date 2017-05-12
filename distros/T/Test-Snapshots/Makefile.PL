use 5.008005;
use strict;
use inc::Module::Install 0.77;





#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name           'Test-Snapshots';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Test/Snapshots.pm';

requires       'perl'                     => '5.008005';
requires       'Exporter'                 => 0;
requires       'Carp'                     => 0;
requires       'File::Basename'           => 0;
requires       'File::Find::Rule'         => '0.30';
requires       'File::Temp'               => '0';
requires       'File::Spec'               => '3.2701';
requires       'File::Spec::Functions'    => '3.2701';
requires       'FindBin'                  => 0;
requires       'List::Util'               => 0;
requires       'Test::Builder'            => '0.47';
requires       'Test::Builder::Module'    => '0.47';
requires       'Text::Diff'               => 0;

test_requires  'Test::More'               => '0.47';


#homepage       
#bugtracker     
repository     'http://github.com/szabgab/test-snapshots';
#MailingList    

WriteAll;
