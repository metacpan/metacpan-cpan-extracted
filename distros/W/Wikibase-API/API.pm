package Wikibase::API;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use JSON::XS qw(encode_json);
use MediaWiki::API;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Item;
use Wikibase::Datatype::Struct::Lexeme;
use Wikibase::Datatype::Struct::Mediainfo;

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# MediaWiki::API object.
	$self->{'mediawiki_api'} = MediaWiki::API->new;

	# MediaWiki site.
	$self->{'mediawiki_site'} = 'test.wikidata.org';

	# Login name.
	$self->{'login_name'} = undef;

	# Login password.
	$self->{'login_password'} = undef;

	# Process parameters.
	set_params($self, @params);

	$self->{'_mediawiki_base_uri'} = 'https://'.$self->{'mediawiki_site'};
	# XXX Entity URI has http instead of https.
	$self->{'_mediawiki_entity_uri'} = 'http://'.$self->{'mediawiki_site'}.'/entity/';

	if (ref $self->{'mediawiki_api'} ne 'MediaWiki::API') {
		err "Parameter 'mediawiki_api' must be a 'MediaWiki::API' instance."
	}
	$self->{'mediawiki_api'}->{'config'}->{'api_url'}
		= $self->{'_mediawiki_base_uri'}.'/w/api.php';

	# Login.
	if (defined $self->{'login_name'} && defined $self->{'login_password'}) {
		my $login_ret = $self->{'mediawiki_api'}->login({
			'lgname' => $self->{'login_name'},
			'lgpassword' => $self->{'login_password'},
		});
		$self->_mediawiki_api_error($login_ret, 'Cannot login.');
	}

	# Token.
	my $token_hr = $self->{'mediawiki_api'}->api({
		'action' => 'query',
		'meta' => 'tokens',
	});
	$self->_mediawiki_api_error($token_hr, 'Cannot get token.');
	$self->{'_csrftoken'} = $token_hr->{'query'}->{'tokens'}->{'csrftoken'};

	return $self;
}

sub create_item {
	my ($self, $item_obj) = @_;

	my $res = $self->{'mediawiki_api'}->api({
		'action' => 'wbeditentity',
		'new' => 'item',
		'data' => $self->_obj2json($item_obj),
		'token' => $self->{'_csrftoken'},
	});
	$self->_mediawiki_api_error($res, 'Cannot create item.');

	return $res;
}

sub get_item {
	my ($self, $id, $opts_hr) = @_;

	my $struct_hr = $self->get_item_raw($id, $opts_hr);
	if (! exists $struct_hr->{'type'}) {
		return;
	}

	my $item_obj;
	if ($struct_hr->{'type'} eq 'item') {
		$item_obj = Wikibase::Datatype::Struct::Item::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'mediainfo') {
		$item_obj = Wikibase::Datatype::Struct::Mediainfo::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'lexeme') {
		$item_obj = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
	} else {
		err 'Unsupported type.',
			'Type', $struct_hr->{'type'},
		;
	}

	return $item_obj;
}

sub get_item_raw {
	my ($self, $id, $opts_hr) = @_;

	# TODO $opts_hr - Muzu vyfiltrovat jenom claims napr.

	my $res = $self->{'mediawiki_api'}->api({
		'action' => 'wbgetentities',
		'format' => 'json',
		'ids' => $id,
	});
	$self->_mediawiki_api_error($res, 'Cannot get item.');

	my $struct_hr = $res->{'entities'}->{$id};

	return $struct_hr;
}

sub _obj2json {
	my ($self, $item_obj) = @_;

	if (! defined $item_obj) {
		return '{}';
	} else {
		if (! $item_obj->isa('Wikibase::Datatype::Item')) {
			err "Bad data. Must be 'Wikibase::Datatype::Item' object.";
		}
	}

	my $struct_hr = Wikibase::Datatype::Struct::Item::obj2struct($item_obj,
		$self->{'_mediawiki_entity_uri'});

	my $json = decode_utf8(JSON::XS->new->utf8->encode($struct_hr));

	return $json;
}

sub _mediawiki_api_error {
	my ($self, $res, $message) = @_;

	if (! defined $res) {
		err $message,
			'Error code' => $self->{'mediawiki_api'}->{'error'}->{'code'},
			'Error details' => $self->{'mediawiki_api'}->{'error'}->{'details'},
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::API - Class for API to Wikibase (Wikibase) system.

=head1 SYNOPSIS

 use Wikibase::API;

 my $obj = Wikibase::API->new(%params);
 my $res = $obj->create_item($item_obj);
 my $item_obj = $obj->get_item($id);

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::API->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<mediawiki_api>

MediaWiki::API object.

Default value is MediaWiki::API->new.

=item * C<mediawiki_site>

MediaWiki site.

Default value is 'test.wikidata.org'.

=item * C<login_name>

Login name.

Default value is undef.

=item * C<login_password>

Login password.

Default value is undef.

=back

=head2 C<create_item>

 my $res = $obj->create_item($item_obj)

Create item in system.
C<$item_obj> is Wikibase::Datatype::Item instance.

Returns reference to hash like this:

 {
         'entity' => {
                 ...
         },
         'success' => __STATUS_CODE__,
 }

=head2 C<get_item>

 my $item_obj = $obj->get_item($id);

Get item from system.

Returns Wikibase::Datatype::Item instance.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Cannot login.
                 Error code: %s
                 Error details: %s
         Cannot get token.
                 Error code: %s
                 Error details: %s

 create_item():
         Bad data. Must be 'Wikibase::Datatype::Item' object.

=head1 EXAMPLE1

=for comment filename=create_item_in_test_wikidata.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::API;
 use Wikibase::Datatype::Item;

 # API object.
 my $api = Wikibase::API->new;

 # Wikibase::Datatype::Item blank object.
 my $item_obj = Wikibase::Datatype::Item->new;

 # Create item.
 my $res = $api->create_item($item_obj);

 # Dump response structure.
 p $res;

 # Output like:
 # \ {
 #     entity    {
 #         aliases        {},
 #         claims         {},
 #         descriptions   {},
 #         id             "Q213698",
 #         labels         {},
 #         lastrevid      535146,
 #         sitelinks      {},
 #         type           "item"
 #     },
 #     success   1
 # }

=head1 EXAMPLE2

=for comment filename=get_item_from_test_wikidata.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::API;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 id\n";
         exit 1;
 }
 my $id = $ARGV[0];

 # API object.
 my $api = Wikibase::API->new;

 # Get item.
 my $item_obj = $api->get_item($id);

 # Dump response structure.
 p $item_obj;

 # Output for Q213698 argument like:
 # Wikibase::Datatype::Item  {
 #     Parents       Mo::Object
 #     public methods (9) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_array_object (Mo::utils), check_number (Mo::utils), check_number_of_items (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         aliases        [],
 #         descriptions   [],
 #         id             "Q213698",
 #         labels         [],
 #         lastrevid      535146,
 #         modified       "2020-12-11T22:26:06Z",
 #         ns             0,
 #         page_id        304259,
 #         sitelinks      [],
 #         statements     [],
 #         title          "Q213698"
 #     }
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<JSON::XS>,
L<MediaWiki::API>,
L<Unicode::UTF8>,
L<Wikibase::Datatype::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-API>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
