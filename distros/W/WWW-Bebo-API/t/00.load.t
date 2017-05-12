#######################################################################
# $Date$
# $Revision$
# $Author$
# ex: set ts=8 sw=4 et
#########################################################################
use Test::More tests => 15;

BEGIN {
    use_ok('WWW::Bebo::API');

    for (@WWW::Bebo::API::namespaces) {
        use_ok("WWW::Bebo::API::$_");
    }
}

diag("Testing WWW::Bebo::API $WWW::Bebo::API::VERSION");
