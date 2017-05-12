# $Id: genericdb.pm,v 1.2 2004/05/04 16:27:56 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  GO::Handlers::genericdb     - 

=head1 SYNOPSIS

  use GO::Handlers::genericdb

=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package GO::Handlers::genericdb;
use GO::SqlWrapper qw (:all);
use base qw(GO::Handlers::base);

use strict;
use Carp;
use Data::Dumper;
use Data::Stag qw(:all);

sub apph {
    my $self = shift;
    $self->{_apph} = shift if @_;
    return $self->{_apph};
}

sub placeholder_h {
    my $self = shift;
    $self->{_placeholder_h} = shift if @_;
    return $self->{_placeholder_h};
}

sub curr_acc {
    my $self = shift;
    $self->{_curr_acc} = shift if @_;
    return $self->{_curr_acc};
}

sub rels {
    my $self = shift;
    $self->{_rels} = shift if @_;
    return $self->{_rels};
}


sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if (!defined($self->strictorder)) {
        $self->strictorder(1);
    }
    $self->curr_acc(0);
    $self->placeholder_h({});
    $self->rels([]);
}

sub id_h {
    my $self = shift;
    $self->{_id_h} = shift if @_;
    if (!$self->{_id_h}) {
	my $dbh = $self->apph->dbh;
	my $pairs =
	  select_rowlist($dbh,
			 "term",
			 undef,
			 "acc, id");
	$self->{_id_h} =
	  {map {@$_} @$pairs };

    }
    return $self->{_id_h};
}


sub g {
    my $self = shift;
}

# flattens tree to a hash;
# only top level, not recursive
sub hashify {
    my $tree = shift;
    return $tree if !ref($tree) || ref($tree) eq "HASH";
    return {stag_pairs($tree)};
}

sub insert {
    my $self = shift;
    my $dbh = $self->apph->dbh;
    insert_h($dbh,
             @_);
}

sub store {
    my $self = shift;
    my $tbl = shift;
    my $tree = shift;
    my $pk = shift;
    my $nostag_get = shift;

    my $dbh = $self->apph->dbh;
    my $selh = hashify($tree);
    foreach my $k (keys %$selh) {
        delete $selh->{$k} if !defined($selh->{$k});
    }
    my $h;
    unless ($nostag_get) {
	$h =
	  select_hash($dbh,
		      $tbl,
		      $selh);
    }
    my $id;
    if ($h) {
        if ($pk) {
            $id = $h->{$pk};
        }
    }
    else {
        $id =
          insert_h($dbh,
                   $tbl,
                   $selh);
    }
    $id;
}



1;
