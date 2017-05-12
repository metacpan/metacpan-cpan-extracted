use inc::Module::Install;
  
# Define metadata
name           'ZeroMQ-Poller-Timer';
all_from       'lib/ZeroMQ/Poller/Timer.pm';
license        'perl';

# Specific dependencies
requires       'threads' => '0';
requires       'ZeroMQ'  => '0.17';

WriteAll;
