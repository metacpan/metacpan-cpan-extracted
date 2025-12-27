use v5.37.9;
use feature 'class';
no warnings 'experimental::class';
use utf8;

package Video::NRK::Cache::ProgramId 3.02;  # Dist::Zilla doesn't know about class yet

class Video::NRK::Cache::ProgramId;
# ABSTRACT: NRK on-demand "PRF" program ID


use Carp qw( carp croak );
use HTTP::Tiny ();
use warnings::register;


our $QUICK_ID = 1;  # skip HTML parsing if possible, rely on hard-coded API base
our $NRK_BASE = 'https://tv.nrk.no/program';
our $PSAPI_BASE = 'https://psapi.nrk.no';


field $program_id;
field $url;
field $id;
field $psapi_base :param //= $PSAPI_BASE;
field $parse :param = undef;
field $ua :param = HTTP::Tiny->new;

my $nrk_re = qr{//[^/]*nrk\.no(?:/|$)};
my $prfid_re = qr/[A-ZØÆÅ]{4}[0-9]{8}/;


method id { $id }
method url { $url }
method psapi_base { $psapi_base }


ADJUST {
	$self->parse($parse) if defined $parse;
}


method parse ($parse_) {
	$parse = $parse_;
	
	# Strategies to obtain the NRK on-demand "PRF" program ID:
	# 1. parse from URL
	# 2. get from HTTP header
	# 3. parse from web page meta data
	# 4. first string on web page that looks like an ID
	
	$self->_parse_as_string and return;
	$url = $parse;
	$self->_parse_from_header and return;
	$self->_parse_from_body and return;
	
	croak "Failed to discover NRK 'PRF' program ID; giving up on '$url'";
}


method _parse_as_string () {
	return unless $parse =~ m/^$prfid_re$/;
	
	# the user supplied the program ID instead of the URL
	$id = $parse;
	$url = "$NRK_BASE/$parse";
}


method _parse_from_header () {
	return unless $QUICK_ID;
	
	if ($url =~ m<^http.+/($prfid_re)(?:/|$)>) {
		return $id = $1;
	}
	
	$id = eval { $ua->head($url)->{headers}{'x-nrk-program-id'} } // '';
	return $id if $id =~ m/^$prfid_re$/;
}


method _parse_from_body () {
	my $res = $ua->get($url, {headers => { Accept => 'text/html' }});
	$url = $res->{url};
	carp "Warning: This doesn't look like NRK. Check the URL '$url'" if warnings::enabled && $url !~ m/^https?:$nrk_re/i;
	my $error = $res->{status} eq "599" ? ": $res->{content}" : "";
	croak "HTTP error $res->{status} $res->{reason} on $url$error" unless $res->{success};
	
	my $html = $res->{content};
	my ($base_url) = $html =~ m/\bdata-psapi-base-url="([^"]+)"/i;
	$psapi_base = $base_url if $base_url && $base_url =~ m/https:$nrk_re/i;
	$id = $res->{headers}{'x-nrk-program-id'} // '';  # this header might not have been present in the HEAD response
	return $id if $id =~ m/^$prfid_re$/;
	
	return $id if ($id) = $html =~ m/\bprogram-id(?:"\s+content)?="($prfid_re)"/i;
	return $id if ($id) = $html =~ m/"prf(?:Id"\s*:\s*"|:)($prfid_re)"/;
	
	carp "Warning: Failed to discover NRK 'PRF' program ID; trying harder" if warnings::enabled;
	return $id if ($id) = $html =~ m/\b($prfid_re)\b/;
	return $id if ($id) = $html =~ m/(?:\\u002[Ff]|\%2[Ff])($prfid_re)\b/;
	return $id if ($id) = $html =~ m/(?:[0-9a-z_]|\\u[0-9A-F]{4}|\%[0-9A-F]{2})($prfid_re)\b/;  # last-ditch effort
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Video::NRK::Cache::ProgramId - NRK on-demand "PRF" program ID

=head1 VERSION

version 3.02

=head1 SYNOPSIS

 $program_id = Video::NRK::Cache::ProgramId->new( parse =>
   'https://tv.nrk.no/serie/monsen-paa-villspor/sesong/1/episode/2',
 );
 say $program_id->id;
   # MUHU10000214
 
 $program_id = Video::NRK::Cache::ProgramId->new;
 $program_id->parse( 'DVFJ64001010' );
 say $program_id->url;
   # https://tv.nrk.no/program/DVFJ64001010

=head1 DESCRIPTION

Utility class for discovering the NRK video on demand "PRF"
program ID.

=head1 PARAMETERS

When constructing a L<Video::NRK::Cache::ProgramId> object,
C<new()> accepts the following parameters:

=over

=item parse

Calls the C<parse()> method with the value provided. Optional.

=item psapi_base

The NRK PSAPI base URL to use. If not provided, by default
C<https://psapi.nrk.no> will be attempted first, before an
attempt is undertaken to determine the correct API base from
NRK's web site. Optional.

=item ua

The L<HTTP::Tiny> object to use for accessing NRK's web site.
If not provided, a new L<HTTP::Tiny> instance will be created
using default settings. Optional.

=back

=head1 METHODS

L<Video::NRK::Cache::ProgramId> provides the following methods:

=over

=item id

 $id = $program_id->id;

Return the NRK video on demand "PRF" program ID determined by
C<parse()>. This is usually a string of four letters and eight
digits (S<e. g.> DVFJ64001010).

=item parse

 $program_id->parse( $string );

Parses the provided string and attempts to determine the 
NRK video on demand "PRF" program ID and an URL from it.
Accepts a program ID or an URL.

=item psapi_base

 $psapi_url = $program_id->psapi_base;

Return the NRK PSAPI base URL. If the NRK web site has been
accessed and has been found to provide the PSAPI base, that is
the value returned by this method; otherwise, the value of the
C<psapi_base> parameter is returned.

=item url

 $url = $program_id->url;

Return a URL for the video on demand program identified.
NRK content may be accessible through more than one URL,
and the value returned by this method is is not necessarily
the canonical one.

=back

=head1 LIMITATIONS

This software's OOP API is new and still evolving. Additionally,
this software uses L<perlclass>, which is an experimental feature.
The class structure and API will likely be redesigned in future,
once the implementation of L<Corinna|https://github.com/Ovid/Cor>
in Perl is more complete.

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
