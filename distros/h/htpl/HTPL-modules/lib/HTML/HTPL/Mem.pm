
require 5.004;
use strict;


use SQL::Statement;
use SQL::Eval;
use HTML::HTPL::Lib;
use HTML::HTPL::Sys qw(getvar);
use HTML::HTPL::Result;

############################################################################
#
# A subclass of Statement::SQL which implements tables as arrays of
# arrays.
#

package HTML::HTPL::Mem;


@HTML::HTPL::Mem::ISA = qw(SQL::Statement);

sub open_table ($$$$$) {
    my($self, $data, $tname, $createMode, $lockMode) = @_;
    my($table);
    if ($createMode) {
	if (exists($data->{$tname})) {
	    die "A table $tname already exists";
	}
	$table = $data->{$tname} = { 'res' => new HTML::HTPL::Res(undef),
                                     'NAME' => $tname };
	bless($table, ref($self) . "::Table");
        my %hash = ($tname, $table);
        &HTML::HTPL::Lib::Publish(%hash);
    } else {
	$table = $data->{$tname};
        unless ($table) {
            $table = {'res' => HTML::HTPL::Sys::getvar($tname), 'NAME' => $tname};
            bless($table, ref($self) . "::Table");
            $table->push_names($data, $table->{'res'}->{'fields'});
            $data->{$tname} = $table;
        }
	$table->{'res'}->{'cursor'} = 0;
        delete $table->{'res'}->{'cursor2'};
    }
    $table;
}

sub cursor {
    my ($sql, @params) = @_;
    my $sth = HTML::HTPL::Mem->new($sql);
    $HTML::HTPL::Mem::database ||= {};
    $sth->execute($HTML::HTPL::Mem::database, \@params);
    my $orig = new HTML::HTPL::Mem::Orig($sth);
    my (@tn) = $sth->tables;
    my ($tbl, $tobj);
    my @fields2 = map {$_->name !~ /\*$/ ? $_->name : ( eval {
         $tbl = $_->table;
         $tobj = $HTML::HTPL::Mem::database->{$tbl};
         map {($#tn ? ($tbl . '.') : '') . $_;} 
                 @{$tobj->{'col_names'}};
            } ) } $sth->columns;
    my $res = new HTML::HTPL::Result($orig, @fields2);
    $res->receive;
    $res;    
}



package HTML::HTPL::Mem::Table;

@HTML::HTPL::Mem::Table::ISA = qw(SQL::Eval::Table);

sub push_names ($$$) {
    my($self, $data, $names) = @_;
    $self->{'res'}->{'fields'} = $names;
    $self->{'col_names'} = $names;
    my($colNums) = {};
    for (my $i = 0;  $i < @$names;  $i++) {
	$colNums->{$names->[$i]} = $i;
    }
    $self->{'col_nums'} = $colNums;
}

sub push_row ($$$) {
    my($self, $data, $row) = @_;
    $self->{'res'}->lowputrow(@$row);
    $self->{'res'}->{'cursor'}++;
}

sub fetch_row ($$$) {
    my($self, $data, $row) = @_;
    return undef unless ($self->{'res'}->sync);
    my @v = $self->{'res'}->asrow;
    $self->{'res'}->{'cursor'}++;
    $self->{'row'} = \@v;
}

sub seek ($$$$) {
    my($self, $data, $pos, $whence) = @_;
    my($currentRow) = $self->{'res'}->{'cursor'};
    if ($whence == 0) {
	$currentRow = $pos;
    } elsif ($whence == 1) {
	$currentRow += $pos;
    } elsif ($whence == 2) {
	$currentRow = @{$self->{'res'}->{'rows'}} + $pos;
    } else {
	die $self . "->seek: Illegal whence argument ($whence)";
    }
    if ($currentRow < 0) {
	die "Illegal row number: $currentRow";
    }
    $self->{'res'}->{'cursor'} = $currentRow;
}

sub truncate ($$) {
    my($self, $data) = @_;
    $#{$self->{'res'}->{'rows'}} = $self->{'res'}->{'cursor'};
}

sub drop ($$) {
    my($self, $data) = @_;
    delete $data->{$self->{'NAME'}};
    return 1;
}



package HTML::HTPL::Mem::Orig;

@HTML::HTPL::Mem::Orig::ISA = qw(HTML::HTPL::Orig);

sub new {
    my ($class, $sth) = @_;
    bless {'sth' => $sth, 'cols' => $sth->{'col_names'},
           'cursor' => 0}, $class;
}

sub realfetch {
    my $self = shift;
    my $crs = $self->{'cursor'}++;
    my $rows = $self->{'sth'}->{'NUM_OF_ROWS'};
    return undef if ($crs >= $rows);
    $self->{'sth'}->{'data'}->[$crs];
}

1;
