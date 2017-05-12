package Apache::HTPL::Lib;

use HTML::HTPL::Sys;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(exit);

*import = \&Exporter::import;

sub exit {
    &HTML::HTPL::Sys::cleanup;
    goto htpl_lblend;
}

1;
