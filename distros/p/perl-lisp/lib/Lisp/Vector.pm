package Lisp::Vector;

use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(vector vectorp);

sub vector
{
    Lisp::Vector->new(@_);
}

sub vectorp
{
    UNIVERSAL::isa($_[0], "Lisp::Vector");
}

sub new
{
    my $class = shift;
    bless [@_], $class;
}

1;
