use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Circle::FE::Term',
   dist_name   => 'circle-fe-term',
   requires => {
      'Convert::Color' => '0.06',
      'Convert::Color::XTerm' => 0,
      'IO::Async' => '0.14',
      'Net::Async::Tangence::Client' => '0.15',
      'String::Tagged' => 0,
      'Tangence::ObjectProxy' => '0.20_001',
      'Text::Balanced' => 0,
      'Tickit' => '0.55',
      'Tickit::App::Plugin::EscapePrefix' => 0,
      'Tickit::Async' => '0.21',
      'Tickit::Event' => '0.58',
      'Tickit::Style' => '0.40',
      'Tickit::Term' => '0.27',
      'Tickit::Widget::Entry' => '0.20',
      'Tickit::Widget::Entry::Plugin::Completion' => 0,
      'Tickit::Widget::HBox' => '0.32',
      'Tickit::Widget::Scroller' => '0.15',
      'Tickit::Widget::Tabbed' => '0.019',
      'Tickit::Widget::VBox' => '0.31',
      'Tickit::Window' => '0.42',
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   share_dir => {
      dist => "share",
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
