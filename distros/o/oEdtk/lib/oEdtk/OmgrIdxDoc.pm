package oEdtk::OmgrIdxDoc;
our $VERSION = 0.8021;

use base 'oEdtk::Doc';
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(@INDEX_COLS);
use oEdtk::Dict;
use Text::CSV;

use strict;
use warnings;


sub new {
	my ($class) = @_;

	my $self = {};	
#			fields	=> @fields,
#			csv		=> $csv,
#			header	=> $header
#	};

	$self->{csv}	= Text::CSV->new({ binary => 1, eol => "\n", quote_space => 0 });
#	my @fields = map { $row->{$$_[0]} } @INDEX_COLS;
	$self->{fields}= map { $$_[0] } @INDEX_COLS;
#	my $status= $csv->combine ([map { $$_[0] } @INDEX_COLS]);
	$self->{csv}->combine ($self->{fields});
	$self->{header}= $self->{csv}->string ();
#my $toto = sprintf ("%s", ${self->{csv}}->string());
#	warn "DEBUG: header => " .$toto. "\n";
	#$csv->print($fh, [map { $$_[0] } @INDEX_COLS]);

	bless $self, $class;
	$self->reset();
	return $self;
}


sub mktag {
	my ($self, $name, $value) = @_;
		$self->{idxTag}{$name}=$value;

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
	foreach (@{$self->{'fields'}}) {
		push (@values, $self->{idxTag}{$_});
#		my $tag = $_->emit;
#		$out .= $tag;
	}
	my $status = ${self->csv}->combine (@values);

	return ${self->csv}->string ();
}


1;