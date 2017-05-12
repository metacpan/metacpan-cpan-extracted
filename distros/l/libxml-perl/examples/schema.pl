# This template file is in the Public Domain.
# You may do anything you want with this file.
#
# $Id: schema.pl,v 1.1 1999/08/10 21:43:50 kmacleod Exp $
#

# This is the example script in the XML::PatAct::ToObjects module doc,
# it also uses XML::PatAct::MatchName and is an example of using PatAct
# modules.

use XML::Parser::PerlSAX;
use XML::PatAct::MatchName;
use XML::PatAct::ToObjects;

my $patterns =
    [
     'schema'      => [ qw{ -holder                                  } ],
     'table'       => [ qw{ -make Schema::Table                      } ],
     'name'        => [ qw{ -field Name -as-string                   } ],
     'summary'     => [ qw{ -field Summary -as-string                } ],
     'description' => [ qw{ -field Description -grove                } ],
     'column'      => [ qw{ -make Schema::Column -push-field Columns } ],
     'unique'      => [ qw{ -field Unique -value 1                   } ],
     'non-null'    => [ qw{ -field NonNull -value 1                  } ],
     'default'     => [ qw{ -field Default -as-string                } ],
     ];

my $matcher = XML::PatAct::MatchName->new( Patterns => $patterns );
my $handler = XML::PatAct::ToObjects->new( Patterns => $patterns,
					   Matcher => $matcher);

my $parser = XML::Parser::PerlSAX->new( Handler => $handler );
$schema = $parser->parse(Source => { SystemId => $ARGV[0] } );

require 'dumpvar.pl';
dumpvar('main', 'schema');
