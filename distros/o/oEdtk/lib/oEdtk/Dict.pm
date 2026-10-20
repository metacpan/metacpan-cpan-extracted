package oEdtk::Dict;
use strict;
use warnings;

use Config::IniFiles;
use Exporter;
our $VERSION = 2.1129;
our @ISA     = qw(Exporter);

# Create a dictionary from an INI file.
sub new {
	my ( $class, $path, $options ) = @_;

	my $invert      = $options->{'invert'}      || 0;
	my $section     = $options->{'section'}     || 'DEFAULT';
	my $ignore_case = $options->{'ignore_case'} || 1;

	# warn "INFO: Path EDTK_DICO >$path< \n";
	tie my %ini, 'Config::IniFiles', ( -file => $path, -default => $section );

	my $dico = $ini{$section};
	if ($invert) {

		# Invert the hash.
		my %tr = ();
		while ( my ( $key, $val ) = each %$dico ) {
			if ( ref($val) eq 'ARRAY' ) {
				$tr{$_} = $key foreach @$val;
			}
			else {
				$tr{$val} = $key;
			}
		}
		$dico = \%tr;
	}
	if ($ignore_case) {
		my $dico2 = {};
		while ( my ( $key, $val ) = each %$dico ) {
			$dico2->{ lc($key) } = $val;
		}
		$dico = $dico2;
	}
	my $self = {
		ignore_case => $ignore_case,
		dico        => $dico
	};

	# 	warn "INFO: Dict object $class $self ($section $path) created...\n";
	return bless $self, $class;
}

sub translate {

	# pass the 'check' option to request a check that the value is present in the dictionary
	# if the value is absent from the dictionary, returns 'undef'
	my ( $self, $word, $check ) = @_;

	my $key = $word;
	if ( $self->{'ignore_case'} ) {
		$key = lc($key);
	}
	my $val = $self->{'dico'}->{$key};
	if ( !$check && !defined($val) ) {
		$val = $word;
	}

	return $val;
}

sub substitue {
	my ( $self, $var ) = @_;

	#	warn "DEBUG: Dict::substitute value = '$var'\n";

	if ( defined($var) && length($var) > 0 ) {
		while ( my ( $key, $val ) = each %{ $self->{'dico'} } ) {
			$var =~ s/$key/$val/ig;
		}

		#		warn "DEBUG: Dict::substitute value = '$var'\n";
	}

	return $var;
}

1;

=head1 NAME

oEdtk::Dict - INI-backed translation dictionary

=head1 SYNOPSIS

    use oEdtk::Dict;

    my $dict  = oEdtk::Dict->new('countries.ini', { section => 'COUNTRIES' });
    my $label = $dict->translate('FR');
    my $text  = $dict->substitue('Payable a FR');

=head1 DESCRIPTION

Loads a dictionary from one section of an INI file and offers word lookup and
global substitution. It backs the corporate-entity, character translation and
country dictionaries used across the toolkit.

=head1 METHODS

=head2 new

    my $dict = oEdtk::Dict->new($path, $options);

Read the C<$path> INI file and build the dictionary. C<$options> accepts:
C<invert> (swap keys and values, default off), C<section> (INI section to read,
default C<DEFAULT>) and C<ignore_case> (fold keys to lowercase, default on).

=head2 translate

    my $value = $dict->translate($word, $check);

Look up C<$word> and return its translation. When C<$check> is true an unknown
word yields C<undef>; otherwise the word is returned unchanged.

=head2 substitue

    my $text = $dict->substitue($var);

Case-insensitively replace every dictionary entry found in C<$var> and return
the result. (The name keeps the historical spelling.)

=head1 AUTHOR

The oEdtk team.

=cut
