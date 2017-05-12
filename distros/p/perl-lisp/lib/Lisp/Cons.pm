package Lisp::Cons;

# Only used to represent (a . b) cons cells.  The normal
# (a b c d) list is represented with a unblessed array [a,b,c,d]

use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(cons consp);

sub cons
{
    Lisp::Cons->new(@_);
}

sub consp
{
    UNIVERSAL::isa($_[0], "Lisp::Cons") || ref($_[0]) eq "ARRAY";
}

sub new
{
    my($class, $car, $cdr) = @_;
    bless [$car, $cdr], $class;
}

sub car
{
    my $self = shift;
    my $old = $self->[0];
    $self->[0] = shift if @_;
    $old;
}

sub cdr
{
    my $self = shift;
    my $old = $self->[1];
    $self->[1] = shift if @_;
    $old;
}

1;
