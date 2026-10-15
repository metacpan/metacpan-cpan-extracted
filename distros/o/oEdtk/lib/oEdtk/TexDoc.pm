package oEdtk::TexDoc;
use strict;
use utf8;

our $VERSION = 2.1109;

use base 'oEdtk::Doc';
use oEdtk::Config qw(config_read);
use oEdtk::Dict;
use oEdtk::TexTag;
use Carp         qw(croak);
use Data::Dumper qw(Dumper);
use JSON::PP     qw(encode_json);
use YAML::Tiny;
use Text::QRCode;
use Readonly;

use strict;
use warnings;

# QR code geometry defaults.
Readonly my $DEFAULT_QR_CODE_LEVEL => 'H';    # error-correction level: L M Q H
Readonly my $DEFAULT_QR_CODE_UNIT  => 'mm';
Readonly my $DEFAULT_QR_CODE_SIZE  => 25;
Readonly my $PAGE_WIDTH_IN_MM      => 210;
Readonly my $RIGHT_MARGIN_IN_MM    => 10;
Readonly my $TOP_MARGIN_IN_MM      => 10;
Readonly my $DEFAULT_QR_CODE_HPOS => sprintf '%f%s',
	$PAGE_WIDTH_IN_MM - $RIGHT_MARGIN_IN_MM - $DEFAULT_QR_CODE_SIZE,
	$DEFAULT_QR_CODE_UNIT;
Readonly my $DEFAULT_QR_CODE_VPOS => sprintf '%f%s', $TOP_MARGIN_IN_MM, $DEFAULT_QR_CODE_UNIT;

sub mktag {
	my ( $self, $name, $value ) = @_;

	return oEdtk::TexTag->new( $name, $value );
}

sub append_table {
	my ( $self, $name, @values ) = @_;

	$self->append( $name, \@values );
	return $self;
}

sub hhline_content {
	my ($row) = @_;
	return join q{}, map { $_ eq '*' ? '-' : '~' } @{$row};
}

sub is_in_list {
	my ( $item, @l ) = @_;
	foreach my $v (@l) {
		return 1 if $item eq $v;
	}
	return 0;
}

# Write a QR code as a LaTeX textblock through the output-file handle.
# $tag is a lowercase macro name; $obj is a scalar, ARRAY or HASH to encode;
# $level / $size / $unit / $hpos / $vpos override the Readonly defaults.
sub append_qr_code {
	my ( $self, $tag, $obj, $level, $size, $unit, $hpos, $vpos ) = @_;
	require oEdtk::Main;    # lazy: oEdtk::Main itself requires this module
	croak "Bad tag name '$tag'" if $tag =~ m{[^a-z]}six;
	croak 'Bad object: ' . Dumper($obj)
		if !is_in_list( ( ref $obj ), q{}, 'ARRAY', 'HASH' );
	$level //= $DEFAULT_QR_CODE_LEVEL;
	$size  //= $DEFAULT_QR_CODE_SIZE;
	$unit  //= $DEFAULT_QR_CODE_UNIT;
	$hpos  //= $DEFAULT_QR_CODE_HPOS;
	$vpos  //= $DEFAULT_QR_CODE_VPOS;

	my $string = ( ref $obj ) ? YAML::Tiny::Dump($obj) : $obj;
	my @log    = ( encode_json( [$string] ) );
	unshift @log, encode_json($obj) if ref $obj;

	my $aoa = Text::QRCode->new( level => $level )->plot($string);
	my $n   = scalar @{$aoa};
	die 'Empty QR code' if !$n;
	my $hsize = sprintf '%s%s',   $size, $unit;
	my $len   = sprintf '%.6f%s', $size / $n, $unit;

	foreach my $tex_line (
		( map { "% QR code coding: $_" } @log ),
		"\\long\\gdef\\$tag\{%",
		"\\begin{textblock*}{$hsize}($hpos,$vpos)",
		"\\let\\arrayrulewidthSav\\relax",    # TeX stack exchange 184991
		"\\newlength{\\arrayrulewidthSav}",
		"\\setlength{\\arrayrulewidthSav}{\\arrayrulewidth}",
		"\\setlength{\\arrayrulewidth}{$len}",
		"\\setlength{\\tabcolsep}{0pt}",
		"\\setlength{\\extrarowheight}{0pt}",
		"\\newcolumntype{U}{>{\\centering\\arraybackslash }b{$len}}",
		"\\begin{tabular}{" . ( 'U' x $n ) . '}',
		( map { "\\hhline{" . hhline_content($_) . "}" } @{$aoa} ),
		( '&' x ( $n - 1 ) ) . '\\\\',
		"\\end{tabular}",
		"\\setlength{\\arrayrulewidth}{\\arrayrulewidthSav}",
		"\\end{textblock*}",
		'}',
		)
	{
		oEdtk::Main::oe_print_to_output_file("$tex_line\n");
	}
	return $self;
}

sub line_break {
	return "%\n";
}

my $_CFG = config_read();

# OPEN THE DICTIONARY STATICALLY TO AVOID MULTIPLE ACCESSES TO THE CORRESPONDING FILE
my $_DICO_TEX_CHAR = oEdtk::Dict->new( $_CFG->{'EDTK_DICO_XLAT'}, { section => 'LATEX' } );

# http://woufeil.developpez.com/tutoriels/perl/poo/
sub escape {
	my $str = shift;

	# ESCAPE SPECIAL CARACTERS FOR TEXTAGS

	# Deal with backslashes and curly braces first and at the same
	# time, because escaping backslashes introduces curly braces, and,
	# inversely, escaping curly braces introduces backslashes.
	# see http://detexify.kirelabs.org/classify.html
	my $new = '';
	foreach my $s ( split( /([{}\\])/, $str ) ) {
		if ( $s eq "{" ) {
			$new .= "\\textbraceleft{}";
		}
		elsif ( $s eq "}" ) {
			$new .= "\\textbraceright{}";
		}
		elsif ( $s eq "\\" ) {
			$new .= "\\textbackslash{}";
		}
		else {
			$new .= $s;
		}
	}
	$new =~ s/([%&\$_#])/\\$1/g;

	# warn "DEBUG : \$_DICO_TEX_CHAR = $_DICO_TEX_CHAR\n";
	$new = $_DICO_TEX_CHAR->substitue($new);

	# \\"{} => CAUSES TEX ERRORS DURING THE INDEXING PROCESS (FOR DB INSERTION)
	$new =~ s/\\\"\{\}/\\textquotestraightdblbase{}/g;
	$new =~ s/\\\"/\\textquotestraightdblbase{}/g;

	# 01...@A...yz{}|~ 1°
	return $new;
}

1;
