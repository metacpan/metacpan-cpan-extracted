#!perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
   require_ok( 'WWW::Kickstarter'                         );
   require_ok( 'WWW::Kickstarter::Data'                   );
   require_ok( 'WWW::Kickstarter::Data::Categories'       );
   require_ok( 'WWW::Kickstarter::Data::Category'         );
   require_ok( 'WWW::Kickstarter::Data::Location'         );
   require_ok( 'WWW::Kickstarter::Data::NotificationPref' );
   require_ok( 'WWW::Kickstarter::Data::Project'          );
   require_ok( 'WWW::Kickstarter::Data::Reward'           );
   require_ok( 'WWW::Kickstarter::Data::User'             );
   require_ok( 'WWW::Kickstarter::Data::User::Myself'     );
   require_ok( 'WWW::Kickstarter::Error'                  );
   require_ok( 'WWW::Kickstarter::HttpClient::Lwp'        );
   require_ok( 'WWW::Kickstarter::Iterator'               );
   require_ok( 'WWW::Kickstarter::JsonParser::JsonXs'     );
}

diag( "Testing WWW::Kickstarter $WWW::Kickstarter::VERSION" );
diag( "Using Perl $]" );

for ( sort grep /\.pm\z/, keys %INC ) {
   s{\.pm\z}{};
   s{/}{::}g;
   eval { diag( join( ' ', $_, $_->VERSION || '<unknown>' ) ) };
}
