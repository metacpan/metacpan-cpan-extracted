use Module::Build;
my $build = Module::Build->new
  (
   dist_author => 'Mark Stosberg <mark@summersault.com>',
   module_name => 'Titanium',
   license  => 'perl',
   create_readme => 1, 
   requires => {
                    'CGI::Application'                      => 4,
                    'CGI::Application::Dispatch'            => 0,
                    'CGI::Application::Server'              => 0,
                    'CGI::Application::Plugin::ConfigAuto'  => 0,
                    'CGI::Application::Plugin::DBH'         => 0,
                    'CGI::Application::Plugin::DebugScreen' => 0,
                    'CGI::Application::Plugin::DevPopup'    => 0,
                    'CGI::Application::Plugin::ErrorPage'   => 1.20,
                    'CGI::Application::Plugin::FillInForm'  => 0,
                    'CGI::Application::Plugin::Forward'     => 0,
                    'CGI::Application::Plugin::LogDispatch' => 0,
                    'CGI::Application::Plugin::Redirect'    => 0,
                    'CGI::Application::Plugin::Session'     => 0,
                    'CGI::Application::Plugin::Stream'      => 0,
                    'CGI::Application::Plugin::ValidateRM'  => 0,
                    'CGI::Application::Standard::Config'    => 0,

                    # This is an indirect dependency. We explictly require it here to make
                    # sure that we get a new enough version.
                    'Compress::Raw::Zlib'                   => 2.0,
                    'Module::Starter::Plugin::CGIApp'       => 0.05,
                    'Test::WWW::Mechanize::CGIApp'          => 0,
               },
    create_makefile_pl => 'traditional',

  );
$build->create_build_script;
