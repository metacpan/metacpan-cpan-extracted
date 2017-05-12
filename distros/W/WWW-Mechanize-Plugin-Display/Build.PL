use Module::Build;
# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass(
     class => 'WWW::Mechanize::Plugin::Display::Builder',
     code => '
        sub ACTION_dist {
            my $self = shift;
            `perldoc -t lib/WWW/Mechanize/Plugin/Display.pm>README`;
            $self->SUPER::ACTION_dist;
            }
        ',
);


$class->new( 
      create_makefile_pl => 'traditional',
      module_name     => 'WWW::Mechanize::Plugin::Display',
      license         => 'perl',
      requires        => {
            'HTML::Display'  => 0,
            'WWW::Mechanize' => 0,
      },
    )->create_build_script;
