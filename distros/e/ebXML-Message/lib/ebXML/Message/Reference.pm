package ebXML::Message::Reference;

use strict;

use base qw(Class::Tangram);

our $VERSION = 0.01;

our $fields = {
				ref => { Description => "Message::Description", Schema=>"Message::Schema",},
				string => [ qw(id xlink_href xlink_role) ],
			       };
