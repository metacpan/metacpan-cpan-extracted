package oEdtk::ECM;

# ECM injector, ported from the fork's oEUser::ECM at S22b (decision D22): upload
# a document to the ECM API, or stamp the mailed date on an existing document. The
# fork pinned a corporate CA and disabled host-name verification inline here; that
# is now the shared, safe-by-default transport of oEdtk::Net, and every corporate
# value (URL, API key) is read from the configuration. The oEUser::ECM name stays
# available as a delegate for the fork's applications.
#
# Configuration keys:
#   APIECM_URL               base URL of the ECM API
#   APIECM_APIKEY_EDITIQUE   value put in the Authorization header
#   EDTK_SSL_VERIFY          transport verification, ON by default (oEdtk::Net)
#   EDTK_SSL_CA_PATH         optional CA bundle (oEdtk::Net)

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Carp                  qw(croak);
use File::Basename        qw(basename);
use HTTP::Request::Common qw(POST PUT);
use HTTP::Status          ();
use JSON;
use Time::Piece;

use oEdtk::Config qw(config_read);
use oEdtk::Net    qw(make_ua);

our $VERSION = 2.1131;

# The wire contract, unchanged from the fork.
use constant USER_AGENT      => 'oEUser';
use constant API_ROLE        => 'EDITIQUE';
use constant UPLOAD_PATH     => '/v1/documents/upload';
use constant DOCUMENT_PATH   => '/v1/documents/%s';
use constant MAILED_STATE    => 'MAILED';
use constant DATE_IN_FORMAT  => '%Y%m%d';
use constant DATE_OUT_FORMAT => '%Y-%m-%dT12:%M:%S.000Z';
use constant STATUS_CREATED  => HTTP::Status::HTTP_CREATED;
use constant STATUS_OK       => HTTP::Status::HTTP_OK;

# A configuration value by key; a missing or empty one is fatal and named.
sub _config ( $cfg, $key ) {
	my $value = $cfg->{$key};
	croak "ECM: missing configuration key $key" unless defined $value && length $value;
	return $value;
}

# Service URL for a path, with the API role query, as the fork built it.
sub _url ( $cfg, $path ) {
	return _config( $cfg, 'APIECM_URL' ) . $path . '?apirole=' . API_ROLE;
}

# The User-Agent and Authorization headers, exactly as the fork sent them.
sub _headers ($cfg) {
	return (
		'User-Agent'    => USER_AGENT,
		'Authorization' => _config( $cfg, 'APIECM_APIKEY_EDITIQUE' ),
	);
}

# Upload a document to the ECM.
#   $file_url   path of the file to send; its base name becomes the ECM file name
#   $metadatas  hashref of index metadata, sent as the JSON "text" form part
#   $cfg        optional configuration hashref (defaults to config_read())
# Returns the decoded JSON response; croaks on a non-201 status.
sub send_document ( $file_url, $metadatas, $cfg = undef ) {
	$cfg //= config_read();
	my $filedata = _get_file_content($file_url);
	my $filename = basename($file_url);
	my $req      = POST _url( $cfg, UPLOAD_PATH ), _headers($cfg),
		Content_Type => 'form-data',
		Content      => [
		'filepdf' => [ undef, $filename, Content => $filedata ],
		'text'    => JSON::encode_json($metadatas),
		];
	my $res = make_ua($cfg)->request($req);
	croak 'ECM upload failed: ' . $res->content unless $res->code == STATUS_CREATED;
	return JSON::decode_json( $res->content );
}

# Stamp an existing ECM document as mailed on a date.
#   $docid   ECM document id
#   $date    mailing date, "YYYYMMDD"; the fork's fixed 12:MM:SS wire form is kept
#   $cfg     optional configuration hashref (defaults to config_read())
# Returns the decoded JSON response; croaks on a non-200 status.
sub http_put_envoidate_for_iddoc ( $docid, $date, $cfg = undef ) {
	$cfg //= config_read();
	my $dateiso = Time::Piece->strptime( $date, DATE_IN_FORMAT )->strftime(DATE_OUT_FORMAT);
	my $body    = JSON::encode_json( { last_state => MAILED_STATE, envoi_date => $dateiso } );
	my $req = PUT _url( $cfg, sprintf( DOCUMENT_PATH, $docid ) ), _headers($cfg), Content => $body;
	my $res = make_ua($cfg)->request($req);
	croak 'ECM mailed-date update failed: ' . $res->content unless $res->code == STATUS_OK;
	return JSON::decode_json( $res->content );
}

# Whole-file slurp (the fork read it in one go with "local $RS").
sub _get_file_content ($filename_arg) {
	open my $fh, '<', $filename_arg or croak "ECM: cannot open file $filename_arg";
	my $contents = do { local $/; <$fh> };
	close $fh or croak "ECM: cannot close file $filename_arg";
	return $contents;
}

1;

=head1 NAME

oEdtk::ECM - inject documents into the ECM and stamp their mailed date

=head1 SYNOPSIS

    use oEdtk::ECM;

    my $doc = oEdtk::ECM::send_document( $file, { id => 42 } );    # => decoded JSON
    oEdtk::ECM::http_put_envoidate_for_iddoc( $doc->{iDoc}, '20260113' );

=head1 DESCRIPTION

Two calls against the ECM API, ported unchanged from the fork's
C<oEUser::ECM> (decision D22):

=over 4

=item *

C<send_document> uploads a file, with its index metadata as a JSON "text" form
part, to C</v1/documents/upload?apirole=EDITIQUE> and returns the decoded JSON of
the C<201> response.

=item *

C<http_put_envoidate_for_iddoc> stamps the C<MAILED> state and an C<envoi_date> on
an existing document via C<PUT /v1/documents/I<id>?apirole=EDITIQUE>, and returns
the decoded JSON of the C<200> response.

=back

Both authenticate with a static API key, not a token: the C<Authorization> header
is C<APIECM_APIKEY_EDITIQUE> verbatim. The base URL is C<APIECM_URL>; transport
security comes from L<oEdtk::Net> (verification ON by default). Each function
takes an optional trailing configuration hashref -- the fork's two-argument form
still works, defaulting to L<oEdtk::Config/config_read>.

The fork's own name L<oEUser::ECM> remains available as a delegate to this module.

=head1 FUNCTIONS

=head2 send_document

    my $response = send_document($file_url, \%metadatas, $cfg);

Upload C<$file_url> with its index metadata as a JSON form part, and return the
decoded JSON of the C<201> response.

=head2 http_put_envoidate_for_iddoc

    my $response = http_put_envoidate_for_iddoc($docid, $date, $cfg);

Stamp the C<MAILED> state and the mailed date on document C<$docid>, and return
the decoded JSON of the C<200> response.

Both calls take an optional trailing configuration hash reference, defaulting to
L<oEdtk::Config/config_read>. The internal helpers C<_config>, C<_url>,
C<_headers> and C<_get_file_content> are not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
