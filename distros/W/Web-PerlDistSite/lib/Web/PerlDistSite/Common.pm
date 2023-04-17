package Web::PerlDistSite::Common;

our $VERSION = '0.001011';

use v5.26;
use Type::Params qw( -sigs );
use YAML::PP;
use Types::Common ();
use Path::Tiny qw( path );
use HTML::HTML5::Entities ();

use Exporter::Almighty -setup => {
	tag => {
		sigs => [ 'signature', 'signature_for' ],
		path => [ 'path' ],
		html => [ 'esc_html' ],
	},
	const => {
		booleans => { true => !!1, false => !!0 },
	},
	type => [
		'Types::Common',
	],
	class => [
		'Path::Tiny',
	],
	also => [
		'strict',
		'warnings',
		'feature' => [ 'state' ],
		'experimental' => [ 'signatures' ],
	],
};

PathTiny->coercion->add_type_coercions(
	Types::Common::Str, q{ Path::Tiny::path( $_ ) },
);

*esc_html = \&HTML::HTML5::Entities::encode_entities;

sub Path::Tiny::spew_if_changed {
	my ( $self, $content ) = @_;
	my $orig = $self->exists ? $self->slurp_utf8 : \0;
	if ( ref $orig or $orig ne $content ) {
		$self->spew_utf8( $content );
	}
	return $self;
}

1;
