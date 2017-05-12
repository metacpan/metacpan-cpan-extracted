package Lisp::Special;

# special forms are perl code references that are blessed into
# this package.

use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(make_special specialp);

sub make_special
{
    bless $_[0], "Lisp::Special";
}

sub specialp
{
    UNIVERSAL::isa($_[0], "Lisp::Special");
}


1;
