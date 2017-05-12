use v5.10;
#use ExtUtils::MakeMaker;
use inc::Module::Install;

name           'Test-Legal'                          ;
license        'perl'                                ;
all_from       'lib/Test/Legal.pm'                   ;
install_script 'script/copyright-injector.pl'        ;
install_script 'script/license-injector.pl'          ;
no_index       'directory'   => 'examples'           ;
author         'Ioannis Tambouras <ioannis@cpan.org>';

requires 
#        'Moose'               => '2.0007',
#        'namespace::autoclean'=> '0.12',
	     'Log::Log4perl'         => '1.33',
         'Getopt::Compact'       => '0.04',
	     'List::MoreUtils'       => '0.32',
	     'List::Util'            => '1.23',
	     'File::Slurp'           => '9999.18',
	     'List::Compare'         => '0.37',
	     'CPAN::Meta'            => '2.112621',
	     'Test::Builder::Module' => '0.98',
	     'File::Find::Rule'      => '0.33',
	     'IO::Prompter'          => '0.001001',
	     'Sub::Exporter'         => '0.982',
	     'Software::License'     => '0.103002',
;
test_requires 'Test::Pod::Coverage' => '1.08',
              'Test::Pod'           => '1.45',
              'namespace::clean'    => '0.21',
	          'Expect'              => '1.21',
              'Test::HasVersion'    => '0.012',
              'Test::CPAN::Meta'    => '0.18',
              'Test::Exception'     => '0.31',
              'Test::Dependencies'  => '0.12',
              'Test::MinimumVersion'=> '0.101080',
              'Test::Strict'        => '0.14', 
              'File::Copy'          => '2.18', 
              'Test::Spelling'      => '0.15',
              'Test::Script'        => '1.07',
              'Test::t'             => '0.0031',
;
auto_install;
WriteAll;
