package Lisp::List;

use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(list);

sub list
{
    Lisp::List->new(@_);
}

sub new
{
    my $class = shift;
    bless [@_], $class;
}

sub print
{
    my $self = shift;
    require Lisp::Printer;
    Lisp::Printer::lisp_print($self);
}

sub eval
{
    my $self = shift;
    require Lisp::Interpreter;
    Lisp::Interpreter::lisp_eval($self);
}

1;
