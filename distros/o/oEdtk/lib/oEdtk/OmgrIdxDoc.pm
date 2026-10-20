package oEdtk::OmgrIdxDoc;
use strict;
use warnings;

our $VERSION = 2.1129;

use base 'oEdtk::Doc';
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(@INDEX_COLS);
use oEdtk::Dict;
use Text::CSV;

sub new {
	my ($class) = @_;

	my $self = {};

	#			fields	=> @fields,
	#			csv		=> $csv,
	#			header	=> $header
	#	};

	$self->{csv} = Text::CSV->new( { binary => 1, eol => "\n", quote_space => 0 } );

	#	my @fields = map { $row->{$$_[0]} } @INDEX_COLS;
	$self->{fields} = [ map { $$_[0] } @INDEX_COLS ];

	#	my $status= $csv->combine ([map { $$_[0] } @INDEX_COLS]);
	$self->{csv}->combine( @{ $self->{fields} } );
	$self->{header} = $self->{csv}->string();

	#my $toto = sprintf ("%s", ${self->{csv}}->string());
	#	warn "DEBUG: header => " .$toto. "\n";
	#$csv->print($fh, [map { $$_[0] } @INDEX_COLS]);

	bless $self, $class;
	$self->reset();
	return $self;
}

sub mktag {
	my ( $self, $name, $value ) = @_;
	$self->{idxTag}{$name} = $value;

	return $name;
}

sub reset {
	my ($self) = @_;

	$self->{idxTag} = {};
}

sub dump {
	my ($self) = @_;
	my @values;

	# my @fields = map { $row->{$$_[0]} } @INDEX_COLS;
	# my $csv->print($fh, \@fields);

	#	## my $doclib;
	#	while (my $row = $sth->fetchrow_hashref()) {
	#		# Gather the values in the same order as @INDEX_COLS.
	#		my @fields = map { $row->{$$_[0]} } @INDEX_COLS;
	#		$csv->print($fh, \@fields);
	#		## $doclib = $row->{'ED_DOCLIB'} unless defined $doclib;
	#	}

	#	my $out = '';
	#	foreach (@{$self->{'taglist'}}) {
	foreach ( @{ $self->{'fields'} } ) {
		push( @values, $self->{idxTag}{$_} );

		#		my $tag = $_->emit;
		#		$out .= $tag;
	}
	my $status = $self->{csv}->combine(@values);

	return $self->{csv}->string();
}

1;

=head1 NAME

oEdtk::OmgrIdxDoc - Outmngr index document (CSV lines)

=head1 SYNOPSIS

    use oEdtk::OmgrIdxDoc;

    my $doc = oEdtk::OmgrIdxDoc->new;
    $doc->mktag('ED_IDLDOC', $idldoc);
    $doc->dump;   # one CSV line, in @INDEX_COLS order

=head1 DESCRIPTION

An C<oEdtk::Doc> subclass that produces the index records consumed by
Outmngr. The column list and order come from C<@INDEX_COLS> in
C<oEdtk::DBAdmin>; each emitted document is a single CSV line built with
C<Text::CSV>.

=head1 METHODS

=head2 new

    my $doc = oEdtk::OmgrIdxDoc->new;

Build the document, creating the C<Text::CSV> writer and the header line from
C<@INDEX_COLS>, and clear the tag hash.

=head2 mktag

    my $name = $doc->mktag($name, $value);

Record the index value C<$value> under the column C<$name> and return C<$name>.

=head2 reset

    $doc->reset;

Clear the recorded tag values.

=head2 dump

    my $line = $doc->dump;

Return the recorded values, in C<@INDEX_COLS> order, combined into one CSV
line.

=head1 AUTHOR

The oEdtk team.

=cut
