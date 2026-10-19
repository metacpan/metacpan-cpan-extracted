package oEdtk::Infinite;

use strict;
use warnings;

our $VERSION = 2.1126;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( import_cobol_X import_cobol_S9V9
	is_entete is_flux is_ligne is_option
	id_ligne is_asspri record_values
	extract_options
);

# The Infinite record import is corporate data (it decodes the Infinite COBOL
# flow and cleans addresses through oEUser::Lib) and now lives in
# oEUser::Infinite. This generic module is a thin delegate so callers using the
# old oEdtk::Infinite name keep working. oEUser is an optional companion
# distribution: it is loaded on demand, and a missing one fails cleanly rather
# than breaking the oEdtk load.
sub _delegate {
	my ( $sub, @args ) = @_;
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::Infinite; 1 };
	}
	die "oEdtk::Infinite requires the companion distribution oEUser "
		. "(oEUser::Infinite is not installed): $@"
		unless $loaded;
	return oEUser::Infinite->can($sub)->(@args);
}

sub import_cobol_X          { return _delegate( 'import_cobol_X',          @_ ) }
sub import_cobol_S9V9       { return _delegate( 'import_cobol_S9V9',       @_ ) }
sub is_entete               { return _delegate( 'is_entete',               @_ ) }
sub is_flux                 { return _delegate( 'is_flux',                 @_ ) }
sub is_ligne                { return _delegate( 'is_ligne',                @_ ) }
sub is_option               { return _delegate( 'is_option',               @_ ) }
sub id_ligne                { return _delegate( 'id_ligne',                @_ ) }
sub is_asspri               { return _delegate( 'is_asspri',               @_ ) }
sub record_values           { return _delegate( 'record_values',           @_ ) }
sub extract_options         { return _delegate( 'extract_options',         @_ ) }
sub build_address           { return _delegate( 'build_address',           @_ ) }
sub ED_adresse_payeur       { return _delegate( 'ED_adresse_payeur',       @_ ) }
sub EL_adresse_souscripteur { return _delegate( 'EL_adresse_souscripteur', @_ ) }
sub IG_adresse_cpam         { return _delegate( 'IG_adresse_cpam',         @_ ) }
sub ED_index_variables      { return _delegate( 'ED_index_variables',      @_ ) }
sub ED_restitution          { return _delegate( 'ED_restitution',          @_ ) }
sub EL_restitution          { return _delegate( 'EL_restitution',          @_ ) }
sub EI_restitution          { return _delegate( 'EI_restitution',          @_ ) }
sub E7_adresse              { return _delegate( 'E7_adresse',              @_ ) }
sub E7_adresse_agence       { return _delegate( 'E7_adresse_agence',       @_ ) }
sub E7_index_variables      { return _delegate( 'E7_index_variables',      @_ ) }
sub compute_pic             { return _delegate( 'compute_pic',             @_ ) }
sub compute_value           { return _delegate( 'compute_value',           @_ ) }
sub map_sub                 { return _delegate( 'map_sub',                 @_ ) }
sub sub_list                { return _delegate( 'sub_list',                @_ ) }

1;

=head1 NAME

oEdtk::Infinite - delegate to the oEUser Infinite record import

=head1 SYNOPSIS

    use oEdtk::Infinite qw(import_cobol_X);

    my $val = import_cobol_X( $line, $pos, $len );    # see oEUser::Infinite

=head1 DESCRIPTION

The Infinite record import is corporate; it lives in C<oEUser::Infinite>. This
module keeps the old C<oEdtk::Infinite> name available to existing callers and
forwards every function to the companion distribution, which is loaded on
demand. When oEUser is not installed, the call fails with a clear message.

Every function below forwards its arguments to the same-named function in
C<oEUser::Infinite> and returns its result:

=over 4

=item import_cobol_X, import_cobol_S9V9

=item is_entete, is_flux, is_ligne, is_option

=item id_ligne, is_asspri, record_values, extract_options

=item build_address, ED_adresse_payeur, EL_adresse_souscripteur, IG_adresse_cpam

=item ED_index_variables, ED_restitution, EL_restitution, EI_restitution

=item E7_adresse, E7_adresse_agence, E7_index_variables

=item compute_pic, compute_value, map_sub, sub_list

=back

=head1 FUNCTIONS

=head2 import_cobol_X

    my $value = import_cobol_X(\$line, $position, $length);

Import C<$length> characters from C<$line> at the 1-based C<$position>, with the
trailing spaces removed.

=head2 import_cobol_S9V9

    my $value = import_cobol_S9V9(\$line, $position, $int_len, $frac_len);

Import a signed decimal Cobol field, C<int_len> digits and C<frac_len> decimals,
from C<$line> at C<$position>.

=head2 is_entete

    my $bool = is_entete(\$line);

True when the line is a header (C<ENTETE>) record.

=head2 is_flux

    my $bool = is_flux(\$line);

True when the line is a flux (C<FLUX>) record.

=head2 is_ligne

    my $bool = is_ligne(\$line);

True when the line is a detail (C<LIGNE>) record.

=head2 is_option

    my $bool = is_option(\$line);

True when the line is an option record.

=head2 id_ligne

    my $id = id_ligne(\$line);

Return the two-character identifier of a detail line.

=head2 is_asspri

    my $flag = is_asspri(\$line);

Return the associate/insured indicator of the line.

=head2 record_values

    my @errors = record_values(\%record, \%map, \$line);

Populate C<%record> by applying C<%map> to C<$line>, and return the list of
errors (empty on success).

=head2 extract_options

    my $options = extract_options(\$line);

Split an option line into its option list.

Every function forwards its arguments to the same-named function of the
companion C<oEUser::Infinite>, loaded on demand; a missing oEUser fails with a
clear message.

=head1 AUTHOR

The oEdtk team.

=cut
