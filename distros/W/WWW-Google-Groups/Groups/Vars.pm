# $Id: Vars.pm,v 1.1 2003/09/14 08:09:43 cvspub Exp $

package WWW::Google::Groups::Vars;

use Exporter;
our @ISA = (Exporter);
our @EXPORT = qw(@agent_alias);

our @agent_alias = (
                    'Windows IE 6',
                    'Windows Mozilla',
                    'Mac Safari',
                    'Mac Mozilla',
                    'Linux Mozilla',
                    'Linux Konqueror',
                    );
1;
