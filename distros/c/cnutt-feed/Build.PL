use Module::Build;
my $build = Module::Build->new
    (
     dist_name => 'cnutt-feed',
     dist_author => 'Olivier Schwander <olivier.schwander@ens-lyon.org>',
     dist_abstract => 'A rss/atom reader which delivers entries to your mailboxes',
     dist_version_from => 'bin/cnutt-feed',
     license  => 'perl',
     requires => {
         'Config::Tiny' => 0,
         'Email::Address' => 0,
         'Email::Date' => 0,
         'Email::Folder' => 0,
         'Email::LocalDelivery' => 0,
         'Email::MIME::CreateHTML' => 0,
         'HTML::Encoding' => 0,
         'HTML::Entities' => 0,
         'HTML::FormatText::WithLinks' => 0,
         'HTML::TreeBuilder' => 0,
         'MIME::EncWords' => 0,
         'XML::Feed' => 0,
     },
	 build_requires => {
		 'Test::Dependencies' => 0,
	 },
    );
$build->create_build_script;

