use lib '.';
use Test::More tests => 3;
use t::Util; # gives us cant_ok()

BEGIN { use_ok("t::ToolSet::SelfExport") }

# our @EXPORT = qw( wibble );
can_ok( "main", "wibble" );

eval "use t::ToolSet::SelfExportFails";
like(
    "$@",
    qr{Can't import missing subroutine t::ToolSet::SelfExportFails::wobble},
    "dies trying to import a non-existant function"
);
