package Wikibase::API::Resolve;

use strict;
use warnings;

use Class::Utils qw(set_params);
use File::Spec::Functions qw(catfile);
use IO::Barf qw(barf);
use JSON::XS qw(decode_json encode_json);
use Perl6::Slurp qw(slurp);
use Readonly;
use Wikibase::API;

Readonly::Array our @EXPORT_OK => qw(resolve);

our $VERSION = 0.04;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Login name.
	$self->{'login_name'} = undef;

	# Login password.
	$self->{'login_password'} = undef;

	# MediaWiki::API object.
	$self->{'mediawiki_api'} = MediaWiki::API->new;

	# MediaWiki site.
	$self->{'mediawiki_site'} = 'www.wikidata.org';

	# Resolve directory.
	$self->{'resolve_dir'} = '/var/lib/wb_resolve';

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub resolve {
	my ($self, $qid) = @_;

	my $qid_label;
	my $qid_file = catfile($self->{'resolve_dir'}, uc($qid));

	my $struct_hr;
	if (-r $qid_file) {
		$struct_hr = decode_json(slurp($qid_file));
	} else {
		$self->_lazy_api;
		$struct_hr = $self->{'api'}->get_item_raw($qid);
		barf($qid_file, encode_json($struct_hr));
	}

	my $item_obj = Wikibase::Datatype::Struct::Item::struct2obj($struct_hr);

	return $item_obj;
}

sub _lazy_api {
	my $self = shift;

	if (defined $self->{'api'}) {
		return;
	}

	$self->{'api'} = Wikibase::API->new(
		'mediawiki_api' => $self->{'mediawiki_api'},
		'mediawiki_site' => $self->{'mediawiki_site'},
		'login_name' => $self->{'login_name'},
		'login_password' => $self->{'login_password'},
	);

	return;
}

1;

__END__
