package oEdtk::FixIdx;
use base qw( Exporter );
use warnings;
use strict;
use utf8;
use feature 'say';
use autodie;
use Carp;
use English '-no_match_vars';
use File::Copy qw( copy );
use File::Temp;
use Text::CSV qw( csv );
use Data::Dumper;
use Readonly;

our $VERSION   = 2.1126;
our @EXPORT_OK = qw( make_docs_even_numbered );

# An index (CSV .idx file) is a list of "docs"
# A doc is a list of rows with pages numbered from 1 to max_doc

Readonly my $IDX_LAST        => -1;    # magic index of last element of a list
Readonly my $BAD_DOC_ID      => -1;    # cannot be a valid doc id
Readonly my $IDX_ED_IDLDOC   => 1;     # id doc of the "lot"
Readonly my $IDX_ED_IDSEQPG  => 2;     # page sequence in the "lot"
Readonly my $IDX_ED_IDDEST   => 6;     # page sequence in the "lot"
Readonly my $IDX_ED_SEQDOC   => 3;     # id of the document in the sequence
Readonly my $IDX_ED_SEQPGDOC => 39;    # current number of the page in the doc
Readonly my $IDX_ED_NBPGDOC  => 40;    # total number of pages in the doc

# add one page at the end of a doc and update total number of pages
sub add_one_page {
	my ($aoa) = @_;
	my @res;
	my $last_row = $aoa->[$IDX_LAST];
	foreach my $row ( @{$aoa} ) {    # NB: will also act on last_row (reference)
		$row->[$IDX_ED_NBPGDOC]++;    # increment total pages
		push @res, [ @{$row} ];
	}
	$last_row->[$IDX_ED_IDSEQPG]++;     # increment page sequence number
	$last_row->[$IDX_ED_SEQPGDOC]++;    # increment current page number
	push @res, [ @{$last_row} ];
	return \@res;
}

# if a doc has an odd number of pages, copy the last index row
# to make it even
sub complete_seq_doc {
	my ($aoa) = @_;
	my $nb_pages = scalar @{$aoa};
	return ( $nb_pages % 2 ) ? add_one_page($aoa) : $aoa;
}

# flush a doc at the end of a csv file
sub flush_seq_doc {
	my ( $fh, $csv, $aoa ) = @_;
	foreach ( @{ complete_seq_doc($aoa) } ) {
		$csv->print( $fh, $_ );
	}
	return 0;
}

# looping on data rows for make_docs_even_numbered
sub loop_on_data_rows {
	my ( $csv_in, $csv_out, $fh_in, $fh_out ) = @_;
	my ( $seq_doc_id, @seq_doc ) = ($BAD_DOC_ID);
	while ( my $row = $csv_in->getline($fh_in) ) {
		if ( $seq_doc_id eq "$row->[$IDX_ED_IDLDOC].$row->[$IDX_ED_SEQDOC].$row->[$IDX_ED_IDDEST]" )
		{    # still in the same doc
			push @seq_doc, [ @{$row} ];
		}
		else {    # new seq_doc_id, therefore new seq_doc
			flush_seq_doc( $fh_out, $csv_out, \@seq_doc );
			$seq_doc_id = "$row->[$IDX_ED_IDLDOC].$row->[$IDX_ED_SEQDOC].$row->[$IDX_ED_IDDEST]";
			@seq_doc    = [ @{$row} ];
		}
	}
	flush_seq_doc( $fh_out, $csv_out, \@seq_doc );    # do not forget the last doc!
	return 0;
}

# use a temp file to replace a CSV index file "in place"
# add a page at the end of the docs with an odd number of pages
sub make_docs_even_numbered {
	my ($in_file) = @_;
	my ( $fh_out, $tmp_file ) = tmpnam();
	my $csv_in  = Text::CSV->new();                          # auto diag
	my $csv_out = Text::CSV->new( { eol => "\n" } );
	open my $fh_in, q{<}, $in_file;
	$csv_out->print( $fh_out, $csv_in->getline($fh_in) );    # reuse headers
	loop_on_data_rows( $csv_in, $csv_out, $fh_in, $fh_out );
	close $fh_in;
	close $fh_out;
	copy( $tmp_file, $in_file ) || croak "Cannot copy: $OS_ERROR";
	unlink $tmp_file;
	return 0;
}

1;

=head1 NAME

oEdtk::FixIdx - make every document of a CSV index span an even number of pages

=head1 SYNOPSIS

    use oEdtk::FixIdx qw(make_docs_even_numbered);

    make_docs_even_numbered($idx_file);   # rewrites $idx_file in place

=head1 DESCRIPTION

A CSV C<.idx> index is a list of documents; a document is a run of rows whose
pages are numbered from 1 to the total for that document. When a document has
an odd number of pages, this module duplicates its last row so the document ends
on an even number of pages, which is what recto/verso printing needs. Ported
unchanged from the 0.8032 fork at S20 of the fork-merge plan.

=head1 FUNCTIONS

=head2 make_docs_even_numbered

    my $rc = make_docs_even_numbered($in_file);

Read C<$in_file>, make every document even, and write the result back over
C<$in_file> through a temporary file. Returns C<0>. The first row (the header) is
copied through untouched.

=head2 loop_on_data_rows

    loop_on_data_rows($csv_in, $csv_out, $fh_in, $fh_out);

Group consecutive rows by document (its C<IDLDOC.SEQDOC.IDDEST> triple) and
flush each group with L</flush_seq_doc>. Returns C<0>.

=head2 flush_seq_doc

    flush_seq_doc($fh, $csv, $aoa);

Write one document (an array of arrays) to C<$fh> with C<$csv>, after making its
page count even.

=head2 complete_seq_doc

    my $aoa = complete_seq_doc($aoa);

Return C<$aoa> unchanged when it already has an even number of rows, or a copy
with one extra row (L</add_one_page>) otherwise.

=head2 add_one_page

    my $aoa = add_one_page($aoa);

Return a copy of C<$aoa> whose last row is duplicated: every row's total page
count is incremented, and the duplicated row's page sequence numbers are bumped
too.

=head1 AUTHOR

The oEdtk team.

=cut
