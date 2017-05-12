#!perl -w
use strict;
use PPI;
use PPI::Dumper;

for my $file(@ARGV){
	my $document = PPI::Document->new($file) or die PPI::Document->errstr;

	$document->{file} = $file;
	print "$file:\n";
	$document->find(\&want_funcall);
	warn $@ if $@;
}

sub ppi_dump{
	PPI::Dumper->new(@_, whitespace => 0, comments => 0, locations => 0)->print();
}

sub want_funcall{
	my($doc, $elem) = @_;

	my $sibling;
	if( $elem->isa('PPI::Token::Word')
		&& ($sibling = $elem->snext_sibling)
		&& $sibling->isa('PPI::Structure::List') ){

		printf '%10s:%6d:', $doc->{file}, $elem->location->[0];
		print $elem, $sibling, "\n";
#		ppi_dump($elem);
#		ppi_dump($sibling);
	}
}
