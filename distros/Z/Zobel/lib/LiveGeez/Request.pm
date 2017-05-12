package LiveGeez::Request;


BEGIN
{
	use strict;
	use vars qw($VERSION @ISA $cgi_loaded);

	$VERSION = '0.20';

	require 5.000;

	use Convert::Ethiopic::System;
	require LiveGeez::URI;

	$cgi_loaded = 0;
}


sub ximport
{
shift;

	push ( @ISA, "LiveGeez::Cgi" );
	if ( @_ && $_[1] ) {
		require Apache::Request;
		push ( @ISA, "Apache::Request" );
		use LiveGeez::Cgi( apache => 1 );
	}
	else {
		use LiveGeez::Cgi ( @_ );  # presumably a path is passed
	}

}


sub new
{
my $class = shift;
my $self  = {};

	my $blessing = bless $self, $class;

	# $self->{apache} = ( $self->isa ("Apache::Request") ) 
	 #  ? $self->SUPER::new ( shift )
	  # : 0
	# ;

	$self->{config} = $self->{apache} = $self->{cookieParsed} = 0;

	# print STDERR "BEFORE CONFIG\n";

	$self->config  ( shift, shift ) unless ( @_ == 1 && $_[0] == 0 );
	# print STDERR "BEFORE PARSEQUERY\n";
	$self->ParseQuery ( @_ ) unless ( @_ == 1 && $_[0] == 0 );
	# print STDERR "LEAVING\n";

	$blessing;
}


sub show
{
my $self = shift;

	foreach $key (sort keys %$self) {
		$self->print ( "  $key = $self->{$key}<br>\n" );
	}

}


sub config
{
my $self = shift;

	# print STDERR "Enter Config ", ref($_[0]), "\n";
	return unless ( @_ && $_[0]->isa ( "LiveGeez::Config" ) );

	$self->{config} = $_[0];

	push ( @ISA, "LiveGeez::Cgi" );
	use LiveGeez::Cgi ( @_ );

	if ( $self->{config}->{useapache} ) {
		require Apache::Request;
		push ( @ISA, "Apache::Request" );
		$self->{apache} =  new Apache::Request ( $_[1] );
	}


1;
}


sub ParseQuery
{
my $self = shift;
my ( $key, $pragma );
local %input = ( @_ ) 		#  We are passed something.
          ? ( ref $_[0] )       #  Was it a reference?
            ?  %{$_[0]}            # Yes. 
            : @_                   # No. 
          : ()		        #  We were not passed anything, so declare our own.
          ;


	#==========================================================================
	#
	# First parse input and cookie data unless of course we already have data

	unless ( scalar (%input) ) {
		$self->ParseCgi ( \%input );
	} else {
		$self->ParseCookie;
	}


	#==========================================================================
	#
	# Next we reduce the lexicon we are going to work with 
	# by eliminating synanyms.

	$input{sysOut}  = $input{sys}  if ( $input{sys}  && !$input{sysOut} );
	$input{xferOut} = $input{xfer} if ( $input{xfer} && !$input{xferOut} );

	# printf STDERR "SYSOUT = $input{sysOut}\n";

	#==========================================================================
	#
	# Parse Pragma since directives can also be nested in sysOut variables
	#

	$self->Pragma;


	#==========================================================================
	#
	# Now to define sysIn and sysOut and set defaults.
	#

	if ( exists($input{file}) &&  $input{file} =~ "://" )  {  # A URL
		$self->{sysIn}  =  ( $input{sysIn} )
		                ?  Convert::Ethiopic::System->new( $input{sysIn} )
		                :  ( $input{file} =~ /.sera./i )
		                   ? Convert::Ethiopic::System->new( "sera" )
		                   : 0
		                   ;
	}
	else {
		$self->{sysIn} = ( $input{sysIn} )
		               ?  Convert::Ethiopic::System->new( $input{sysIn} )
		               :  Convert::Ethiopic::System->new( $self->{config}->{sysin} )
		               ;
	}
	$self->SysOut;


	#==========================================================================
	#
	#
	#

	if (  exists($input{xferOut}) && $input{xferOut} eq "PFR" ) {   #  || $input{xferOut} eq "WEFT" || ...
		$self->{WebFont} = $input{xferOut};
	}
	else {
		$self->{WebFont} = 0;
		$self->{sysOut}->SysXfer ( lc ( $input{xferOut} ) );
	}
	$self->{sysIn}->SysXfer ( lc ( $input{xferIn} ) ) if ( $self->{sysIn} );


	#==========================================================================
	#
	# If the "image" type is requested and the image path is appended
	# as a transfer variant, cut off the path and assign it to our 
	# iPath variable.
	#

	$self->{sysOut}->{iPath} = ( $self->{sysOut}->{sysName} =~ /image/i
	                             && $self->{sysOut}->{xfer} ) 
	                           ? $self->{sysOut}->{xfer}
	                           : $self->{config}->{ipath}
	                         ;


	#==========================================================================
	#
	# We are going to compactify our date information.  This simplifies
	# our API and makes working with the LIVEGEEZ markup "date" attribute
	# a little smoother.
	#

	$self->{date} = "$input{day},$input{month},$input{year}" if ( $input{day} );

	$input{calIn} = $input{cal} if ( $input{cal} );
	if ( $input{calIn} ) {
		$self->{calIn} = $input{calIn};
	}
	elsif ( $input{datesys} ) {				# here for backwards compatibility
		$self->{calIn} = $input{datesys};
	}
	elsif ( $self->{date} ) {
		$self->{calIn} = "euro";			# default when not specified
	}

	#==========================================================================
	#
	#  Set the Request Language.
	#

	$input{lang} = $input{langOut} if (exists($input{langOut}));
	$self->{sysOut}->{lang}
	= ( $input{lang} )
	  ? $input{lang}
	  : ( $self->{'cookie-lang'} )
	    ? $self->{'cookie-lang'}
	    : $self->{config}->{lang}
	; 

	$self->{sysOut}->LangNum;
	#
	#  fix before release!!
	#
	# $self->{sysOut}->{langNum} = 3;

	# $self->{sysOut}->{LCInfo} = ( $self->{sysOut}->{sysName} ne "Transcription" ) ? $Convert::Ethiopic::System::WITHUTF8 : 0 ;
	$self->{sysOut}->{LCInfo} = 0;


	#==========================================================================
	#
	#  Miscellaneous
	#

	$self->{frames}    = ( $input{frames} )    ? $input{frames}    : $self->{config}->{useframes};
	$self->{setCookie} = ( $input{setcookie} ) ? $input{setcookie} : "false";
	# print STDERR "ENCODING: ", $self->{apache}->content_encoding, "\n";
	# print STDERR "ENCODING: ", $self->{apache}->header_in('Accept-Encoding'), "\n";
	# print STDERR "AGENT: ", $self->{apache}->header_in('User-Agent'), "\n";
	# my $agent = $self->{apache}->header_in('User-Agent');
	# print STDERR "AGENT: $agent\n";
	$self->SetCookie     if ( ($self->{setCookie} eq "true") || ( !$self->{cookieParsed} && $self->{sysOut}->{sysName} ne "FirstTime" ) );
	$self->{'x-gzip'}  = (
		!$self->{config}->{usemod_gzip} 
		&& (
		( $self->{apache} && ( $self->{apache}->header_in('Accept-Encoding') =~ /gzip/ ) && ( $self->{apache}->header_in('User-Agent') !~ /MSIE/ ) )
		||
		(
			!$self->{apache}
		  &&
		 	( exists($ENV{HTTP_ACCEPT_ENCODING}) && $ENV{HTTP_ACCEPT_ENCODING} =~ "gzip" )
		  &&
		  	( exists($ENV{HTTP_USER_AGENT})      && $ENV{HTTP_USER_AGENT}      !~ "MSIE" )
		)
	    )
	) ? 1 : 0;

	# print STDERR "ZIP[0]: $self->{'x-gzip'}\n";

	#==========================================================================
	#
	#  Finally lets ID the request type itself.
	#

	if ( $input{file} ) {
		$self->{type}  =  "file";
		$self->{file}  =  $input{file};
		$self->{file}  =~ s/$self->{config}->{uris}->{webroot}\///;
		$self->{file} .= "/" unless ( $self->{file} =~ m|/| || $self->{file} =~ /\.\w+$/ );
		$self->{uri}   =  new LiveGeez::URI ( $self->{file} );
	} elsif ( $self->{date} ) {
		$self->{type} = "calendar";
	} elsif ( $input{string} ) {
		$self->{type}   = "string";
		$self->{string} = $input{string};
	} elsif ( $input{number} ) {
		$self->{type}   = "number";
		$self->{number} = $input{number};
	} elsif ( $input{game} ) {
		$self->{type} = "game-$input{game}";
	} elsif ( $input{about} ) {
		$self->{type} = "about";
	}

	$self->{cache_check_override} = 0;

   	undef ( %input ) unless ( @_ );

	1;
}


sub Pragma
{
my $self = shift;
########################
#
#  We use the %input from ParseQuery which is dynamically scoped.
#  This works because we know that Pragma is not accessed by anyone else.
#
#  my ( *input ) = @_;  # We have passed _ONLY_ the reference
my ( $pragma, $key );


	# Look for pragma directives and group them together as a
	# comma deliminated list.  Pragmi might be passed as "pragma",
	# "pragma1", "pragma2", etc.

	for $key ( keys %input ) {
		$pragma .= "$input{$key}," if ($key =~ /pragma/i);
	}

	# if we found any pragma directives chop off the last comma 
	# and copy the complete list back into the %input hash.

	if ( $pragma ) {
		chop ( $self->{pragma} = lc ($pragma) );

		# since I can never remember if there is a minus or not
		# lets do a little spell checking.

		$self->{pragma}       =~ s/7bit/7-bit/ig;

		$self->{phrase}       =  "true"  if ( $self->{pragma} =~ /phrase/     );
		$self->{'no-cache'}   =  "true"  if ( $self->{pragma} =~ /no-cache/   );
		$self->{'date-only'}  =  "true"  if ( $self->{pragma} =~ /date-only/  );
		$self->{'is-holiday'} =  "true"  if ( $self->{pragma} =~ /is-holiday/ );

		# We don't want to propogate "no-cache" into new links:
		$self->{pragma}       =~ s/no-cache(,)?//;
	}
	else {
		$self->{pragma} = "";
	}

	1;
}


sub SysOut
{
my $self = shift;
########################
#
#  We use the %input from ParseQuery which is dynamically scoped.
#  This works because we know that SysOut is not accessed by anyone else.
#
# my ( *input ) = @_;  # We have passed _ONLY_ the reference


	#==========================================================================
	#
	#  Check Cookies for extra info each time a page is loaded.
	#  Don't get cookie data if we are setting a new cookie.
	#
	$input{sysOut} = ( !$input{setcookie} && $self->{'cookie-geezsys'} )
				   ? $self->{'cookie-geezsys'}
				   : $self->{config}->{sysout}
				 	 unless ( $input{sysOut} )  # we were passed an explicit
				   ;                                # and over-riding sysOut
	# printf STDERR "COOOKIE-SYSOUT = $self->{'cookie-geezsys'}\n";


	if ( $input{sysOut} =~ /\./ ) {
	 	my ($A,$B) = split ( /\./, $input{sysOut} );
		$input{sysOut}  = $A;
		$input{xferOut} = $B unless ( $input{xferOut} );
	}


	$self->DieCgi ( "Unrecognized Conversion System: $input{sysOut}." )
		if ( !($self->{sysOut} = Convert::Ethiopic::System->new( $input{sysOut} )) );

	if ( !exists($input{setcookie})
	     && ( exists($self->{'cookie-7-bit'}) && ($self->{'cookie-7-bit'} eq "true") ) ) {
		if ( $self->{pragma} ) {
			$self->{pragma} .= ",7-bit" if ( $self->{pragma} !~ /7-bit/ );
		} else {
			$self->{pragma}  = "7-bit";
		}
	}


	#==========================================================================
	#
	#  May as well set the output font number while we're at it...
	#

	$self->{sysOut}->FontNum;


	#==========================================================================
	#
	#  Finally set extra encoding options
	#

	$self->{sysOut}->{options}  = $noOps;

	$self->{sysOut}->{options} |= $self->{sysOut}->{TTName}
							   if ( $self->{sysOut}->TTName =~ /^\d$/ );

	if ( exists($self->{pragma}) ) {
		$self->{sysOut}->{'7-bit'}  = "true"       if ( $self->{pragma} =~ /7-bit/      );
		$self->{sysOut}->{options} |= $debug       if ( $self->{pragma} =~ /debug/      );
		$self->{sysOut}->{options} |= $ethOnly     if ( $self->{pragma} =~ /ethOnly/    );
		$self->{sysOut}->{options} |= $qMark       if ( $self->{pragma} =~ /qMark/      );
		$self->{sysOut}->{options} |= $gSpace      if ( $self->{pragma} =~ /gSpace/     );
		$self->{sysOut}->{options} |= $ungeminate  if ( $self->{pragma} =~ /ungeminate/ );
		$self->{sysOut}->{options} |= $uppercase   if ( $self->{pragma} =~ /uppercase/  );
	}
	$self->{sysOut}->{'7-bit'} ||= "false";

	$self->{FirstTime} = ( $self->{sysOut}->{sysName} eq "FirstTime" )
	? 1 : 0 ;
	# printf STDERR "SYSOUT = $self->{sysOut}->{sysName}\n";

	1;
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

LiveGeez::Request - Parse a LiveGe'ez CGI Query

=head1 SYNOPSIS

 use LiveGeez::Request;
 use LiveGeez::Services;

 main:
 {

 	my $r = LiveGeez::Request->new;

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );

	exit (0);

 }

=head1 DESCRIPTION

Request.pm instantiates an object that contains a parsed LiveGe'ez query.
Upon instantiation the environment is checked for CGI info and cookie data
is read and used.  This does B<NOT> happen if a populated hash table is
passed (in which case the hash data is applied) or if "0" is passed as an
arguement.
The request object is required by any other LiveGe'ez function of object.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
