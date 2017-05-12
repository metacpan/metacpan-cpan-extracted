# -------------------------------------------------------------------------------------
# TripleStore::Update
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Update.pm,v 1.1.1.1 2003/01/13 18:20:39 jhiver Exp $
#
#    Description:
#
# -------------------------------------------------------------------------------------
package TripleStore::Update;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Mixin::Class/;


# $self->set_subject ($subject);
# $self->set_predicate ($predicate);
# $self->set_object ($subject);
BEGIN
{
    no strict 'refs';
    foreach my $method_name (qw /subject predicate object/)
    {
	my $set_name = "set_$method_name";
	my $del_name = "del_$method_name";
	my $exists_name = "exists_$method_name";
	
	*$set_name = sub {
	    my $self = shift;
	    $self->{$method_name} = shift;
	};
	
	*$del_name = sub {
	    my $self = shift;
	    delete $self->{$method_name};
	};
	
	*$exists_name = sub {
	    my $self = shift;
	    exists $self->{$method_name};
	};
	
	*$method_name = sub {
	    my $self = shift;
	    return $self->{$method_name};
	};
    }
}


##
# $class->new (%args);
# --------------------
# Instanciates a new TripleStore::Update
##
sub new
{
    my $class = shift->class;
    return bless { @_ }, $class;
}


sub bound_values
{
    my $self = shift;
    my @res  = ();
    push @res, $self->subject() if ($self->exists_subject());
    push @res, $self->predicate() if ($self->exists_predicate());
    push @res, $self->object() if ($self->exists_object());
    
    @res = map {
	do {
	    no warnings;
	    my $x = $_;
	    my $y = 0 + $_;
	    "$x", "$y";
	};
    } @res;
    
    return wantarray ? @res : \@res;
}

1;
