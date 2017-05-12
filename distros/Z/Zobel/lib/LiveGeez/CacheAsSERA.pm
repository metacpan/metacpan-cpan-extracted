package LiveGeez::CacheAsSERA;
use base qw(HTML::Parser Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT_OK @gFile @FontStack %SystemList %CheckTags $s $p);

	$VERSION = '0.20';

	@EXPORT_OK = qw(Local Remote);

	require LiveGeez::Services;
	require Convert::Ethiopic::System;
	require HTML::Entities;
	require LiveGeez::HTML;
	require LiveGeez::Directives;

	use URI;
	$URI::ABS_REMOTE_LEADING_DOTS = 1;

	# $#gFile     = 100;
	$#FontStack = 4;

	%CheckTags = (
		font	=> 1,
		# a	=> 1,
		# frame	=> 1,
		# base	=> 1,
		# link	=> 1,
	);

	$s = new Convert::Ethiopic::System ( "sera" );
	
	$p = new LiveGeez::CacheAsSERA ( api_version => 3,
		    start_h   => ['start', "self, tagname, attr, text"],
		    end_h     => ['end', "self, tagname, text"],
		    text_h    => ['textOut', "self, dtext, text"],
		    default_h => [sub { push ( @gFile, @_ ) }, 'text']
	);
}


sub textOut
{
my ($self, $decoded, $orig) = @_;

	$_ = $orig;

	# if ( /\S/so && !/^[\s\xa0]+$/o && !/^<!\[/o && !/\]>/ ) { 
	if ( !/^[\s\xa0]+$/o && !/^<!\[/o && !/\]>/ ) { 
	# unless ( /^[\s\xa0]+$/o ) { 
		$_ = $decoded;
		$decoded = &decode_more_entities(HTML::Entities::decode($decoded));
		if ( /\S/so && $self->{fontStack} && ${$FontStack[ $self->{fontStack} ]{sysIn}} ) {
			$self->{request}->{sysIn}  = ${$FontStack [ $self->{fontStack} ]{sysIn}};
			# $self->{request}->{string} = &decode_more_entities(HTML::Entities::decode($_));
			$self->{request}->{string} = $decoded;
			# print "[ $self->{request}->{string} ]\n";
			# print "FONT:  ${$FontStack[ $self->{fontStack} ]{sysIn}} \n";
			$_ = "<sera>" . LiveGeez::Services::ProcessString ( $self->{request} ) . "</sera>";
		}
		else {
			$_ = $orig;  # original text
		}
	}

	push ( @gFile, $_ );


}


sub start
{
my ($self, $tagname, $attr, $text) = @_;
my $test = 0;

	# print STDERR "TAG: $tagname | $text\n";
	# if ( exists($CheckTags{$tagname}) || ( $test = ( $attr->{style} && $attr->{style} =~ /font-family/ ) ) ) {
	if ( ( $test = ( $attr->{style} && $attr->{style} =~ /font-family/ ) ) || exists($CheckTags{$tagname}) ) {

	if ( $test || ( $tagname eq "font" && $attr->{face} ) ) { 
		$FontStack[ ++$self->{fontStack} ]{tag} = $tagname;
		$text = "";
		if ( $tagname eq "font" ) {
			$FontStack[ $self->{fontStack} ]{sysIn} = GetSystemOut ( $self, $attr->{face} );
			if ( my $newtext = $self->UpdateFontTag($attr) ) {
				# printf STDERR "OLD <$_[3]>   =>  NEW <$newtext>\n";
				$FontStack[ $self->{fontStack} ]{keep} = 1;
				$text = $newtext;
			}
			# $FontStack[ $self->{fontStack} ]{sysIn} = $attr->{face};
			# print "  " x $self->{fontStack};
			# print "OPEN <$tagname>: $attr->{face}  [$self->{fontStack}]\n";
		}
		elsif ( $attr->{style} && $attr->{style} =~ /font-family:\s*(['"]|(&quot;))?([\w -]+)[;'"&]?/i ) {
			$CheckTags{$tagname} = 1;
			$FontStack[ $self->{fontStack} ]{sysIn} = ( $3 ) ? GetSystemOut ( $self, $3 ) : undef;
			if ( my $newtext = $self->UpdateStyle($tagname, $attr) ) {
				if ( $newtext eq "<span>" ) {
					$newtext = "";
				}
				else {
					$FontStack[ $self->{fontStack} ]{keep} = 1;
				}
				$text = $newtext;
			}
			# $FontStack[ $self->{fontStack} ]{sysIn} = ( $3 ) ?  $3 : undef;
			# print "  " x $self->{fontStack};
			# print "OPEN <$tagname>: $3  [$self->{fontStack}]\n";
		}
	}
	elsif ( exists ($FontStack[ $self->{fontStack} ]{tag}) && ($tagname eq $FontStack[ $self->{fontStack} ]{tag}) ) {
		$FontStack[ ++$self->{fontStack} ]{tag} = $tagname;
		$FontStack[ $self->{fontStack} ]{sysIn} = $FontStack[ ($self->{fontStack} - 1) ]{sysIn};
		$FontStack[ $self->{fontStack} ]{keep}  = 1;
	}

	}

	# print STDERR "PUSHING: $text\n==========================\n";
	push ( @gFile, $text );


}  


sub end
{
my ($self, $tagname, $text) = @_;


	if ( exists ($FontStack[ $self->{fontStack} ]{tag}) && ($tagname eq $FontStack[ $self->{fontStack} ]{tag}) ) {
		if ( exists($FontStack[ $self->{fontStack} ]{keep}) ) {
			push ( @gFile, $text );
			delete($FontStack[ $self->{fontStack} ]{keep});
		}
		delete($FontStack[ $self->{fontStack} ]{tag});
		delete($FontStack[ $self->{fontStack}-- ]{sysIn}); 
	}
	else {
		push ( @gFile, $text );
	}

}


sub UpdateFontTag
{
my ( $self, $attr ) = @_;


	delete ( $attr->{face} );
	return unless ( %{$attr} );

	my $args;
	foreach ( keys %$attr ) {
		$args .= " $_=\"$attr->{$_}\"";
	}

	"<font$args>";

}


sub UpdateStyle
{
my ( $self, $tagname, $attr ) = @_;


	my $style = $attr->{style};
	delete ( $attr->{style} );

	#
	# if ( ($style !~ /font-size/i) && ($style !~ /font-color/i) ) {
	#
	# return if ( $style !~ ";" || $style =~ "char-type:" );
	return if ( $style =~ "char-type:" );

	# $style =~ s/(\s*)?((\w+-)*)?font-family:\s*(['"]|&quot;)?(.*?);+?//gi;
	#
	#  This takes care of font names with boundaries:
	#
	$style =~ s/(\s*)?((\w+-)*)?font-family:\s*(['"]|&quot;)(.*?)$1//gi;
	#
	#  This takes care of font names without boundaries:
	#
	$style =~ s/(\s*)?((\w+-)*)?font-family:\s*[\w -]+//gi;

	$attr->{style} = $style if ( $style );

	return unless ( %$attr );

	my $args;
	foreach ( keys %$attr ) {
		$args .= " $_=\"$attr->{$_}\"";
	}

	"<$tagname$args>";

}


sub GetSystemOut
{
my ( $self, $face )  = ( shift, shift );


	if ( !$face ) {
		return unless ( $self->{fontStack} && ${$FontStack[ $self->{fontStack} ]{sysIn}} );
		$face = $lastFace;
	}
	$lastFace = $face;

	$SystemList{$face} ||= new Convert::Ethiopic::System ( $face );

	\$SystemList{$face};  # Return the pointer

}


sub PostUpdateHREF
{
my ($base_uri, $link, $file_query) = @_;

	# printf STDERR "Entering PostUpdateHREF $file_query\n";
	my $attr = $link;

	$attr =~ s/(href\s*=\s*\S+)(.*)?/$1/i;
	$attr =~ s/href//i;
	$attr =~ s/=//;
	$attr =~ s/"//g;
	$attr =~ s/^\s+//;

	my $uri = new URI ( $attr );
	
	if ( my $scheme = $uri->scheme ) {
		# printf STDERR "YES SCHEME\n";
		return ( $link ) if ( $scheme eq "mailto" || $scheme eq "file" );

		return ( $link ) if ( $link =~ s/nolivegeezlink//i );
	}
	else {
		# printf STDERR "NO SCHEME\n";
		my $uri_out = URI->new_abs ( $uri, $base_uri->{_uri} );
		# printf STDERR $uri_out->canonical,"\n";
		return ( "href=\"".$uri_out->canonical."\"" ) if ( $link =~ /nolivegeezlink/i );
		$uri = $uri_out;
	}

		# printf STDERR "QUERY: $URIS{file_query}\n";
	
	qq(href="$file_query) . $uri->canonical . qq(");
}


sub UpdateTitle
{
	#
	#  This will use the last "sysIn" value which may not correspond to the encoding
	#  here, so this approach will be hit-and-miss.  Consider a 2 part font where
	#  the last encoding might have been the 2nd part (GeezNewB), we should have a
	#  method to get the first part encoding
	#

	$_[0]->{request}->{string} = &decode_more_entities ( HTML::Entities::decode ( $_[0]->{request}->{string} ) );

	LiveGeez::Services::ProcessString ( $_[0]->{request} );

}


sub FakeCCS
{
my ( $sourceFile ) = @_;

	open (FILE, "$sourceFile");
	$_ = join ( "", <FILE> );
	close (FILE);

	
	if ( /<link href=".*?vg.css"/oi ) {
		s/<link href=".*?vg.css" .*?>//oi;
		s/(<p.*?><.*?>)/$1<font face="VG2 Main">/isgo;
		s/(<t[dh].*?>)/$1<font face="VG2 Main">/isgo;
	}

	s/(<\/(p|(t[dh]))>)/<\/font>$1/isgo;

	open (FILEX, ">$sourceFile");
	print FILEX;
	close (FILEX);
}


sub Local
{
my ( $file, $sourceFile ) = @_;

	open ( FILE, "$sourceFile" );
	local $/ = undef;
	# @gFile = <FILE>;
	# $_ = join ( "", @gFile);
	$_ = <FILE>;
	close ( FILE );
	# $#gFile = -1;

	my $updated = 0;
	if ( /livegeez/i ) {
		$updated = 1;
		$_ = LiveGeez::Directives::ParseDirectives ( $file, $_ );
	}
	if ( /href/i ) {
		$updated = 1;
		unless ( $file->{request}->{config}->{usecookies} ) {
			my $uri = new LiveGeez::URI ( $file->{request}->{uri}->canonical );
			s#<a(\s+)(href[^>]+)>(.*?)</a>#$space = $1; $arg = $2; $data = $3; $link = ($3 =~ "<sera>" && $arg !~ $file->{scriptRoot} && $arg !~ /mailto:/i) ? PostUpdateHREF( $uri, $arg, $file->{request}->{config}->{uris}->{file_query} ) : $arg ;  "<a$space$link>$data</a>"#oeisg;
		}
		s/ NOLIVEGEEZLINK>/>/oig;
	}

	$file->{refsUpdated} = 1;

	return ( $sourceFile ) unless ( $updated );

	my $seraFileIn = $sourceFile;
	$seraFileIn =~ s/$file->{ext}$/sera.html/i;
	$seraFileIn =~ s/sera\.sera\.html$/zobel.html/i;
	$seraFileIn =~ s/$file->{request}->{config}->{uris}->{webroot}/$file->{request}->{config}->{uris}->{cachelocal}/
		unless ( $sourceFile =~ "cache" );

	my $seraFileOut = $seraFileIn;

	unless ( $seraFileIn =~ /index\.($file->{request}->{sysOut}->{lang}\.)?zobel\.html$/ ) {
		$seraFileOut .= ".gz";
		$file->{isZipped} = "true";
	}
	$file->{request}->{sysIn} = $s;

	# printf STDERR "SeraFile[$$]: $seraFileOut\n";
	if (-e $seraFileOut) {
	# printf STDERR "Found[$$]: $seraFileOut\n";
	# 	$file->{refsUpdated} = 1;
		return ( $seraFileOut )
	}
	open ( SERACACHE, ">$seraFileIn" ) || $file->{request}->DieCgi
		 ( "!: Could Not Open Source File: $seraFileIn!\n" );

	print SERACACHE;

	close ( SERACACHE );

	system ( 'gzip' , $seraFileIn ) if ( $file->{isZipped} eq "true" );

	$seraFileOut;             # this is the return value
}


sub Remote
{
my ( $file, $sourceFile ) = @_;


	#
	#  The first thing we do is check if we have a cached sera file,
	#  if so we're outa here:
	#
	my $seraFileIn = $sourceFile;
	# printf STDERR "SOURCE[$$]: $sourceFile\n";
	$seraFileIn =~ s/$file->{ext}$/sera.html/i;
	$seraFileIn =~ s/sera\.sera\.html$/zobel.html/i;
	$seraFileIn =~ s/$file->{request}->{config}->{uris}->{webroot}/$file->{request}->{config}->{uris}->{cachelocal}/
		unless ( $sourceFile =~ "cache" );

	my $seraFileOut = $seraFileIn;

	unless ( $seraFileIn =~ /index\.($file->{request}->{sysOut}->{lang}\.)?zobel\.html$/ ) {
		$seraFileOut .= ".gz";
		$file->{isZipped} = "true";
	}

	# printf STDERR "SeraFile[$$]: $seraFileOut\n";
	if (-e $seraFileOut) {
	# printf STDERR "Found[$$]: $seraFileOut\n";
		$file->{refsUpdated} = 1;
		$file->{request}->{sysIn} = $s;
		return ( $seraFileOut )
	}

	$p->{uri} = new LiveGeez::URI ( $file->{request}->{uri}->canonical );

	if ( $file->{request}->{sysIn}->{sysName} eq "sera" ) {
		open ( FILE, "$sourceFile" );
		# @gFile = <FILE>;
		# $_ = join ( "", @gFile);
		local $/ = undef;
		$_ = <FILE>;
		close ( FILE );
	}
	else {

	FakeCCS ( $sourceFile )
		if ( $file->{request}->{file} =~ m|http://www.waltainfo.com|i );

	$p->{fontStack} = 0;

	$p->{request}->{sysOut} = $s;
	$p->{request}->{sysOut}->{langNum} = $file->{request}->{sysOut}->{langNum};
	$p->{request}->{sysOut}->{options} = $file->{request}->{sysOut}->{options};
	$p->{request}->{sysOut}->{iPath}   = "";
	$p->{request}->{sysOut}->{fontNum} = 0;
	$p->{request}->{pragma} = $file->{request}->{pragma};

	system ( 'gzip', '-d', $sourceFile ) if ( $sourceFile =~ s/\.gz$// );

	# printf STDERR "Parsing[$$]: $sourceFile\n";
	$p->parse_file( $sourceFile );
	# printf STDERR "Done[$$]:    $sourceFile\n";

	$_ = join ( "", @gFile );

	# printf STDERR "$_\n";
	#
	# convert title to sera if 8-bit chars present
	#
	my ($space, $link, $data);
	s#<title>(.*?)</title>#$title = $1; if ( $title =~ /[\x80-\xff]/ ) { $p->{request}->{string} = $title ; $title = UpdateTitle ( $p ); } "<title>$title</title>"#imse;

	$#gFile = -1;
	}

	# $#gFile = -1;

	$file->{refsUpdated} = -1;

	$file->{request}->{sysIn} = $s;

	$_ = LiveGeez::Directives::ParseDirectives ( $file, $_ );

	#
	# strip extra <sera> and </sera> tags
	#
	s#</sera>(<((br)|((/)?(p)))>)?<sera>#$1#og;
	s#<sera>&nbsp;</sera>#&nbsp;#g;

	#
	# set up local links with Ethiopic text to use Zobel
	#
	# printf STDERR "Before PostUpdateHREF [$URIS{zuri}]\n";
	# printf STDERR "$_\n";
	unless ( $file->{request}->{config}->{usecookies} ) {
		s#<a(\s+)(href[^>]+)>(.*?)</a>#$space = $1; $arg = $2; $data = $3; $link = ($3 =~ "<sera>" && $arg !~ $file->{scriptRoot} && $arg !~ /mailto:/i) ? PostUpdateHREF( $p->{uri}, $arg, $file->{request}->{config}->{uris}->{file_query} ) : $arg ;  "<a$space$link>$data</a>"#oeisg;
	}
	s/ NOLIVEGEEZLINK>/>/oig;


	#
	# strip meta tags which we no longer need and may infact set
	# charsets that we don't want.
	#
	s/<META([^>]+)>(\r)?(\n)?//oig;

	#
	# strip out anything before the <html declaration or
	# libeth gets confused with the tokens, we gotta fix libeth
	#
	s/(.*?)(<HTML)/$2/si;


	open ( SERACACHE, ">$seraFileIn" ) || $file->{request}->DieCgi
		 ( "!: Could Not Open Source File: $seraFileIn!\n" );

	print SERACACHE;

	close ( SERACACHE );

	system ( 'gzip' , $seraFileIn ) if ( $file->{isZipped} eq "true" );

	$seraFileOut;             # this is the return value

}


%entity2char		=(
	'sbquo'		=>	"\x82",
	'bdquo'		=>	"\x84",
	'hellip'	=>	"\x85",
	'dagger'	=>	"\x86",
	'Dagger'	=>	"\x87",
	'permil'	=>	"\x89",
	'circ'		=>	"\x88",
	'Scaron'	=>	"\x8a",
	'lsaquo'	=>	"\x8b",
	'OElig'		=>	"\x8c",
	'lsquo'		=>	"\x91",
	'rsquo'		=>	"\x92",
	'ldquo'		=>	"\x93",
	'rdquo'		=>	"\x94",
	'bull'		=>	"\x95",
 	'ndash'		=>	"\x96",
 	'mdash'		=>	"\x97",
	'tilde'		=>	"\x98",
	'trade'		=>	"\x99",
	'scaron'	=>	"\x9a",
	'rsaquo'	=>	"\x9b",
	'oelig'		=>	"\x9c",
	'Yuml'		=>	"\x9f"
);


sub decode_more_entities
{
my $array;


	if (defined wantarray) {
		$array = [@_]; # copy
	}
	else {
		$array = \@_;  # modify in-place
	}
	for (@$array) {
		s/(&(\w+);?)/$entity2char{$2} || $1/eg;
	}

	$array->[0];
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::CacheAsSERA - HTML Conversion for LiveGe'ez 

=head1 SYNOPSIS

$cacheFile = LiveGeez::CacheAsSERA::HTML($f, $sourceFile)

Where $f is a File.pm object and $sourceFile is the pre-cached file name.

=head1 DESCRIPTION

CacheAsSERA.pm contains the routines for conversion of HTML document content
from Ethiopic encoding systems into SERA for document caching and later
conversion into other Ethiopic systems.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
