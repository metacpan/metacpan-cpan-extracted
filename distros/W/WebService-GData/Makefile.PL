use inc::Module::Install;
use 5.008008;
  name           'WebService-GData';
  all_from       'lib/WebService/GData.pm';
  
  license     'perl';
  requires    'LWP'  => 0;
  requires    'JSON' =>'2';
  requires    'Test::More'  => 0;
  requires    'Test::Mock::LWP'  => '0.05';
  recommends  'Crypt::SSLeay'=> 0;
#  bugtracker  'http://rt.cpan.org';
  repository  'https://github.com/szabgab/WebService-GData';

  
  WriteAll;
