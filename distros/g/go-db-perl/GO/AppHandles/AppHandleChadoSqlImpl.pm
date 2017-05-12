# $Id: AppHandleChadoSqlImpl.pm,v 1.3 2006/09/11 22:51:02 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself


package GO::AppHandles::AppHandleChadoSqlImpl;

=head1 NAME

GO::AppHandles::AppHandleChadoSqlImpl

=head1 SYNOPSIS

you should never use this class directly. Use GO::AppHandle
(All the public methods calls are documented there)

=head1 DESCRIPTION

implementation of AppHandle for a Chado relational database

NOTE COMPLETE! The implementation is sufficient for loading, but not querying

For querying, use AppHandleSqlImpl with the godb-chado bridge layer

(see gmod/schema/modules/cv/bridges)

=head1 FEEDBACK

Email cjm@fruitfly.berkeley.edu

=cut

use strict;
use Carp;
use FileHandle;
use Carp;
use DBI;
use GO::Utils qw(rearrange pset2hash dd);
use GO::SqlWrapper qw(:all);
use Exporter;
use base qw(GO::AppHandles::AppHandleAbstractSqlImpl);
use vars qw($AUTOLOAD);

our $TBL_PATH="cvtermpath";
our $TBL_R = "cvterm_relationship";
our $TBL_T = "cvterm";
our $PK_T = "cvterm_id";
our $COL_TN = "name";
our $TBL_GPPROPERTY="gene_product_property";

sub refresh {
    my $self = shift;
    return;

    my $dbh = $self->dbh;

    # thanks to James Smith at Sanger for the optimisation tip..
    $self->{rtype_by_id} = {};
    my $hl = select_hashlist($dbh,
			     $TBL_R, "1",
			     "distinct $TBL_R.type_id as I"
			    );
    if (@$hl) {
	my $where = join ',', map $_->{'I'}, @$hl;
	$hl = select_hashlist($dbh, 
			      $TBL_T,
			      "$PK_T in ($where)", 
			      "$PK_T, $COL_TN" );
	foreach my $h (@$hl) {
	    $self->{rtype_by_id}->{$h->{$PK_T}} = $h->{$COL_TN};
	}
    }
    else {
	# empty db
    }
}


sub reset_acc2name_h {
    my $self = shift;
    delete $self->{_acc2name_h};
    return;
}

sub acc2name_h {
    my $self = shift;
    if (@_) {
        $self->{_acc2name_h} = shift;
    }
    if (!$self->{_acc2name_h}) {
        my $hl = 
          select_hashlist($self->dbh,
                          "cvterm INNER JOIN dbxref USING (dbxref_id) INNER JOIN db USING (db_id)",
                          [],
                          "db.name || ':' || dbxref.accession AS acc, cvterm.name AS name");
        my $a2n = {};
        foreach (@$hl) {
            $a2n->{$_->{acc}} = $_->{name};
        }
        $self->{_acc2name_h} = $a2n;
    }
    return $self->{_acc2name_h};
}


1;
