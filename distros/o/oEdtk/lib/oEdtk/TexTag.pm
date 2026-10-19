package oEdtk::TexTag;

use strict;
use utf8;

our $VERSION = '2.1126';
my $_FLAG_DIGITS = 1;

# A SIMPLE OBJECT THAT DESCRIBES A TEX TAG.
sub new {
	my ( $class, $name, $val ) = @_;

	my $ref = ref($val);
	if ( $ref ne '' && $ref ne 'ARRAY' && $ref ne 'HASH' && $ref ne 'oEdtk::TexDoc' ) {
		die "ERROR: Unexpected value type, must be a scalar or an oEdtk::TexDoc object\n";
	}

	if ( $name =~ /\d/ && $_FLAG_DIGITS ) {
		warn "INFO: Tex Tag name cannot contain digits : $name !\n";
		warn "INFO: further messages for Tex Tag containing digits will be ignored\n";
		$_FLAG_DIGITS = 0;
	}

	my $self = {
		name  => $name,
		value => $val
	};
	bless $self, $class;

	#	warn "INFO: TexTag object $self created...\n";
	return $self;
}

sub emit {
	my ($self) = @_;

	if ( defined $self->{'name'} && $self->{'name'} =~ /^_include_$/ ) {
		return "\\input{" . $self->{'value'} . "\}";
	}

	# A tag containing a scalar value or an HASH/ARRAY/TexDoc object.
	if ( defined $self->{'value'} ) {
		my $ref  = ref( $self->{'value'} );
		my $name = $self->{'name'};

		# A list of values.
		if ( $ref eq 'ARRAY' ) {
			my $macro = "\\edListNew{$self->{'name'}}";
			foreach ( @{ $self->{'value'} } ) {

				#				my $val = escape($_);
				my $val = oEdtk::TexDoc::escape($_);    # NOT CLEAN !

				#				warn "INFO: call to oEdtk::Doc::escape in TexTag $val\n";
				$macro .= "\\edListAdd{$self->{'name'}}{$val}";
			}
			return $macro;
		}

		# A tag containing other tags.
		my $value = $self->{'value'};
		if ( $ref eq 'HASH' ) {
			my $inner = oEdtk::TexDoc->new();
			while ( my ( $key, $val ) = each %{ $self->{'value'} } ) {
				$inner->append( $key, $val );
			}
			$value = $inner;
		}

		# Escape if we have a scalar value.
		if ( ref($value) eq '' ) {
			$value =~ s/\s+/ /g;

			#			$value = escape($value);
			$value = oEdtk::TexDoc::escape($value);

			#			warn "INFO: call to oEdtk::Doc::escape in TexTag $value\n";
		}

		return "\\long\\gdef\\$name\{$value\}";
	}

	# A command call.
	return "\\$self->{'name'}";
}

use oEdtk::Config qw(config_read);
use oEdtk::Dict;
my $_CFG = config_read();

# OPEN THE DICTIONARY STATICALLY TO AVOID MULTIPLE ACCESSES TO THE CORRESPONDING FILE
my $_DICO_CHAR = oEdtk::Dict->new( $_CFG->{'EDTK_DICO_XLAT'}, { section => 'LATEX' } );

# http://woufeil.developpez.com/tutoriels/perl/poo/
sub escape_0 {    # NOT CLEAN use inheritance! TexTag->TexDoc
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

	#	warn "INFO: \$_DICO_CHAR = $_DICO_CHAR\n";
	# xxx the following line causes an error after program end
	#	$new = $_DICO_CHAR->substitue($new);

	# \\"{} => CAUSES TEX ERRORS DURING THE INDEXING PROCESS (FOR DB INSERTION)
	$new =~ s/\\\"\{\}/\\textquotestraightdblbase{}/g;
	$new =~ s/\\\"/\\textquotestraightdblbase{}/g;

	# 01...@A...yz{}|~ 1°
	return $new;
}

#END {
#	undef $_DICO_CHAR;
#	undef $_CFG;
#	warn "INFO: TexTag object deleted!\n";
#}

1;

=head1 NAME

oEdtk::TexTag - a single LaTeX tag

=head1 SYNOPSIS

    use oEdtk::TexTag;

    my $tag = oEdtk::TexTag->new('NOM', 'value');
    print $tag->emit;   # \long\gdef\NOM{value}

=head1 DESCRIPTION

A small object describing one LaTeX tag: a name and a value. The value may be a
scalar, an array reference (emitted as a list macro), a hash reference (emitted
as nested tags), or an C<oEdtk::TexDoc> object.

=head1 METHODS

=head2 new

    my $tag = oEdtk::TexTag->new($name, $val);

Build a tag of name C<$name> and value C<$val>. A value that is not a scalar,
an array, a hash or an C<oEdtk::TexDoc> is an error; a name containing digits
raises a one-time warning.

=head2 emit

    my $latex = $tag->emit;

Return the LaTeX rendering: an C<\input{}> for an C<_include_> tag, a list
macro for an array value, a C<\long\gdef\name{...}> for a scalar or nested
value, or a bare C<\name> command when there is no value.

The C<escape_0> sub is a deprecated, not-clean duplicate of
L<oEdtk::TexDoc/escape>; it is kept for reference only and is not part of the
public API.

=head1 AUTHOR

The oEdtk team.

=cut
