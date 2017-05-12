use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Time::TimeTick',
      license         => 'perl',
      dist_version_from => 'lib/Time/TimeTick.pm',
   )->create_build_script;
