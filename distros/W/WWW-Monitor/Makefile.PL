  # Load the Module::Install bundled in ./inc/
  use inc::Module::Install;
    
  # Define metadata
  name            'WWW-Monitor';
  all_from        'lib/WWW/Monitor.pm';
  license         'perl';

  @programs_to_install=qw(bin/webmon.pl);

  install_script($_) foreach @programs_to_install;
    
  # Specific dependencies
  requires        'Carp'                 => 0;
  requires        'File::HomeDir'        => '0.63';
  requires        'WWW::Mechanize'       => '1.20';
  requires        'HTML::FormatText'     => '2.04';
  requires        'HTML::TreeBuilder'    => '3.23';
  requires        'Cache::File'          => '2.04';
  requires        'Text::WordDiff'       => '0.02';
  requires        'Schedule::Cron'       => '0.97';
  build_requires  'Test::More'           => '0.66';
  no_index        'directory'            => 'example';
    
  auto_install;
  WriteAll;
