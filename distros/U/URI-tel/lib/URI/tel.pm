##----------------------------------------------------------------------------
## URI::tel - ~/lib/URI/tel.pm
## Version v0.800.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2016/02/12
## Modified 2019/08/30
## 
##----------------------------------------------------------------------------
package URI::tel;
BEGIN
{
	use strict;
	use parent 'URI';
    our( $VERSION, $VERBOSE, $DEBUG, $ERROR );
    our( $RESERVED, $MARK, $UNRESERVED, $PCT_ENCODED, $URIC, $ALPHA, $DIGIT, $ALPHANUM, $HEXDIG );
    our( $PARAM_UNRESERVED, $VISUAL_SEPARATOR, $PHONEDIGIT, $GLOBAL_NUMBER_DIGITS, $PARAMCHAR, $DOMAINLABEL, $TOPLABEL, $DOMAINNAME, $DESCRIPTOR, $PNAME, $PVALUE, $PARAMETER, $EXTENSION, $ISDN_SUBADDRESS, $CONTEXT, $PAR, $PHONEDIGIT_HEX, $GLOBAL_NUMBER, $LOCAL_NUMBER, $OTHER, $TEL_SUBSCRIBER, $TEL_URI );
    our( $COUNTRIES, $IDD_RE );
    $VERSION     = 'v0.800.1';
	use overload ('""'     => 'as_string',
				  '=='     => sub { _obj_eq(@_) },
				  '!='     => sub { !_obj_eq(@_) },
				  fallback => 1,
				 );
};

{
	#$RESERVED   			= qr{[\[\;\/\?\:\@\&\=\+\$\,\[\]]+};
	$RESERVED   			= q{[;/?:@&=+$,[]+};
	$MARK       			= q{-_.!~*'()};                                    #'; emacs
	$UNRESERVED 			= qq{A-Za-z0-9\Q$MARK\E};
	## "%" HEXDIG HEXDIG
	$PCT_ENCODED			= qr{\%[0-9A-Fa-f]{2}};
	#$URIC       = quotemeta( $RESERVED ) . $UNRESERVED . "%";
	$URIC					= qr{(?:[\Q$RESERVED\E]+|[$UNRESERVED]+|(?:$PCT_ENCODED)+)};
# 	$ALPHA 	    			= qr{A-Za-z};
# 	$DIGIT					= qr{\d};
	$ALPHA 	    			= qr{A-Za-z};
	$DIGIT					= qq{0-9};
# 	$ALPHANUM   			= qr{A-Za-z\d};
	$ALPHANUM   			= qq{A-Za-z0-9};
# 	$HEXDIG	    			= qr{\dA-F};
	$HEXDIG	    			= qr{\dA-F};
# 	$PARAM_UNRESERVED 		= qr{[\[\]\/\:\&\+\$]+};
	$PARAM_UNRESERVED 		= q{[]/:&+$};
	$VISUAL_SEPARATOR 		= q(-.());
	## DIGIT / [ visual-separator ]
# 	$PHONEDIGIT		  		= qr{$DIGIT\Q$VISUAL_SEPARATOR\E};
	$PHONEDIGIT		  		= qq{$DIGIT\Q$VISUAL_SEPARATOR\E};
	## "+" *phonedigit DIGIT *phonedigit
	$GLOBAL_NUMBER_DIGITS	= qr{\+[$PHONEDIGIT]*[$DIGIT]+[$PHONEDIGIT]*};
	## param-unreserved / unreserved / pct-encoded
	$PARAMCHAR				= qr{(?:[\Q$PARAM_UNRESERVED\E]+|[$UNRESERVED]+|(?:$PCT_ENCODED)+)};
	## alphanum / alphanum *( alphanum / "-" ) alphanum
	$DOMAINLABEL			= qr{(?:[$ALPHANUM]+|[$ALPHANUM]+(?:[$ALPHANUM\-]+)*[$ALPHANUM]+)};
	## ALPHA / ALPHA *( alphanum / "-" ) alphanum
	$TOPLABEL				= qr{(?:[$ALPHA]+|[$ALPHA]+[$ALPHANUM\-]*[$ALPHANUM]+)};
	## *( domainlabel "." ) toplabel [ "." ]
	$DOMAINNAME				= qr{(?:$DOMAINLABEL\.)*(?:$TOPLABEL\.?)+};
	## domainname / global-number-digits
	$DESCRIPTOR				= qr{(?:$DOMAINNAME|$GLOBAL_NUMBER_DIGITS)};
	## 1*( alphanum / "-" )
	$PNAME					= qr{[$ALPHANUM\-]+};
	## 1*paramchar
	$PVALUE					= qr{(?:$PARAMCHAR)};
	## ";" pname ["=" pvalue ]
	$PARAMETER				= qr{\;$PNAME=$PVALUE};
	## ";ext=" 1*phonedigit
	##$EXTENSION				= qr{\;ext=[$PHONEDIGIT]+}msxi;
	## Tweaking the rfc regular expression to add often used extension format
	## See: https://discussions.apple.com/thread/1635858?start=0&tstart=0
	## or
	## http://stackoverflow.com/questions/2403767/string-format-phone-numbers-with-extension
	$EXTENSION				= qr{(?:[\;\,]?ext[\=\.]?|x)[$PHONEDIGIT]+}msxi;
	## ";isub=" 1*uric
	$ISDN_SUBADDRESS		= qr{\;isub=$URIC}msxi;
	## ";phone-context=" descriptor
	$CONTEXT				= qr{\;phone-context=$DESCRIPTOR}msxi;
	## parameter / extension / isdn-subaddress
	$PAR					= qr{(?:(?:($PARAMETER)|($EXTENSION)|($ISDN_SUBADDRESS)))+};
	## HEXDIG / "*" / "#" / [ visual-separator ]
	$PHONEDIGIT_HEX			= qr{[$HEXDIG\*\#$VISUAL_SEPARATOR]+};
	## *phonedigit-hex (HEXDIG / "*" / "#")*phonedigit-hex
	$LOCAL_NUMBER_DIGITS	= qr{(?:$PHONEDIGIT_HEX)?[$HEXDIG\*\#]+(?:$PHONEDIGIT_HEX)?};
	## global-number-digits *par => "+" *phonedigit DIGIT *phonedigit
	$GLOBAL_NUMBER	  = qr{($GLOBAL_NUMBER_DIGITS)($PAR)*};
	## local-number-digits *par context *par
	$LOCAL_NUMBER	  = qr{($LOCAL_NUMBER_DIGITS)($PAR)*($CONTEXT)($PAR)*};
	## This is a non-rfc standard requirement, but a necessity to catch local number with no context
	## such as 03-1234-5678 plain and simple
	$OTHER					= qr{(\+?[$PHONEDIGIT]*[$DIGIT]+[$PHONEDIGIT]*)($PAR)*};
	## Like +1-800-LAWYR-UP => +1-800-52997-87
	$VANITY					= qr{(\+?[$PHONEDIGIT]*[A-Z0-9\Q$VISUAL_SEPARATOR\E]+[$PHONEDIGIT]*)};
	$TEL_SUBSCRIBER	  		= qr{(?:$VANITY|$GLOBAL_NUMBER|$LOCAL_NUMBER|$OTHER)}xs;
	##$TEL_SUBSCRIBER	  = qr{(?:$GLOBAL_NUMBER)};
	$TEL_URI		  		= qr{(?:tel\:)?$TEL_SUBSCRIBER};
	# https://tools.ietf.org/search/rfc3966#section-3
	
	$COUNTRIES = {};
}

sub _init
{
    my $class = shift( @_ );
    my( $str, $scheme ) = @_;
    # find all funny characters and encode the bytes.
    $str = $class->_uric_escape( $str );
    $str = "$scheme:$str" unless $str =~ /^[a-zA-Z][a-zA-Z0-9.+\-]*:/o ||
                                 $class->_no_scheme_ok;
    #my $self = bless \$str, $class;
    #$self;
    return( $class->new( $str ) );
}

sub new
{
	my $this = shift( @_ );
	my $str  = shift( @_ );
	my $class = ref( $this ) || $this;
	my $orig  = $str;
	$str      =~ s/[[:blank:]]+//gs;
	my $temp  = {};
	my @matches = ();
	my @names = ();
	if( @matches = $str =~ /^((?:tel\:)?$GLOBAL_NUMBER)$/ )
	{
		@names = qw( all subscriber params last_param );
		$temp->{ 'type' } = 'global';
	}
	elsif( @matches = $str =~ /^((?:tel\:)?$LOCAL_NUMBER)$/ )
	{
		$temp->{ 'type' } = 'local';
		@names = qw( all subscriber params1 last_param1 ignore5 ignore6 context params2 last_param2 ignore10 ignore11 );
		$temp->{ '_has_context_param' } = 1 if( length( $matches[6] ) );
		$temp->{ 'local_number' } = $str;
		$temp->{ 'local_number' } =~ s/^tel\://;
	}
	## e.g. 911, 110 or just ordinary local phones like 03-1234-5678
	elsif( @matches = $str =~ /^((?:tel\:)?$OTHER)$/ )
	{
		$temp->{ 'type' } = 'other';
		@names = qw( all subscriber params ignore4 last_param );
	}
	## e.g. +1-800-LAWYR-UP
	elsif( @matches = $str =~ /^((?:tel\:)?$VANITY)$/ )
	{
		$temp->{ 'type' } = 'vanity';
		@names = qw( all subscriber );
	}
	else
	{
		$ERROR = "Unknown telephone number '$str'.";
		warn( $ERROR );
	}
	
	## The component name for each match
	@$temp{ @names } = @matches;
	
	$temp->{ 'params' } = $temp->{ 'params1' } ? $temp->{ 'params1' } : $temp->{ 'params2' } if( !length( $temp->{ 'params' } ) );
	$temp->{ 'context' } =~ s/;[^=]+=(.*?)$/$1/gs;
	
	if( $str =~ /^(?:tel\:)?\+/ )
	{
		$temp->{ 'intl_code' } = $this->_extract_intl_code( $str );
	}
	elsif( $temp->{ 'context' } && 
		$temp->{ 'context' } !~ /^[a-zA-Z]/ &&
		substr( $temp->{ 'context' }, 0, 1 ) eq '+' )
	{
		$temp->{ 'intl_code' } = $this->_extract_intl_code( $temp->{ 'context' } );
		## We flag it as extracted from context, because we do not want to prepend the subscriber number with it.
		## It's just too dangerous as we cannot tell the subscriber number is actually a proper number that can be dialed from outside e.g. 911 or 110 are emergency number who may heva a context with international code
		## However, if the international code was provided by the user then that's his responsibility
		## If the user wants to just provide some context, then better to use context() instead.
		## Knowing the international code helps getting some other useful information, but it should not necessarily affect the format of the number
		$temp->{ '_intl_code_from_context' } = 1;
	}
	$temp->{ 'context' } = '+' . $temp->{ 'intl_code' } if( !length( $temp->{ 'context' } ) && length( $temp->{ 'intl_code' } ) );
	
	if( $temp->{ 'type' } eq 'global' && $temp->{ 'intl_code' } )
	{
		$temp->{ 'local_number' } = $this->_extract_local_number( $temp->{ 'intl_code' }, $temp->{ 'subscriber' } );
	}
	
	my $hash  = {
	'original'		=> ( $orig ne $str ) ? $orig : $temp->{ 'all' },
	'is_global'		=> $temp->{ 'type' } eq 'global' ? 1 : 0,
	'is_local'		=> ( $temp->{ 'type' } eq 'local' or $temp->{ 'type' } eq 'other' ) ? 1 : 0,
	'is_other'		=> $temp->{ 'type' } eq 'other' ? 1 : 0,
	'is_vanity'		=> $temp->{ 'type' } eq 'vanity' ? 1 : 0,
	'subscriber'	=> $temp->{ 'subscriber' },
	'params'		=> $temp->{ 'params' },
	'last_param'	=> $temp->{ 'last_param' } ? $temp->{ 'last_param' } : $temp->{ 'last_param1' } ? $temp->{ 'last_param1' } : $temp->{ 'last_param2' },
	'context'		=> $temp->{ 'context' },
	'intl_code'		=> $temp->{ 'intl_code' },
	'_intl_code_from_context' => $temp->{ '_intl_code_from_context' },
	'local_number'	=> $temp->{ 'local_number' },
	};
	my $self  = bless( $hash, $class );
	my $prams = [];
	if( length( $temp->{ 'params' } ) )
	{
		my $pram_str = $temp->{ 'params' };
		$pram_str    =~ s/^[\.\,\#\;]//;
		$prams    = [ $self->split_str( $pram_str ) ];
	}
	## Private parameters
	my $priv  = {};
	foreach my $this ( @$prams )
	{
		$this =~ s/^(x|ext)\.?(\d+)$/ext=$2/i;
		my( $p, $v ) = split( /=/, $this, 2 );
		$p =~ s/\-/\_/gs;
		if( lc( $p ) =~ /^(ext|isdn_subaddress)$/ )
		{
			$hash->{ lc( $p ) } = $v;
		}
		elsif( lc( $p ) eq 'phone_context' )
		{
			$hash->{ 'context' } = $v;
			$temp->{ '_has_context_param' } = 1;
		}
		else
		{
			$priv->{ lc( $p ) } = $v;
		}
	}
	$self->{ 'private' } = $priv;
	$self->{ 'ext' } = $temp->{ 'ext' } if( !length( $hash->{ 'ext' } ) && !$self->{ 'is_vanity' } );
	$self->{ 'ext' } =~ s/\D//gs;
	## Because a context may be +81 or it could be a domain name example.com
	## if we had it as a parameter at instantiation, we remember it and honour it when we stringify
	$self->{ '_prepend_context' } = $temp->{ '_has_context_param' } ? 0 : 1;
	return( $self );
}

sub as_string
{
	my $self = shift( @_ );
	return( $self->{ 'cache' } ) if( length( $self->{ 'cache' } ) );
	my @uri = ( 'tel:' . $self->{ 'subscriber' } ) if( length( $self->{ 'subscriber' } ) );
	my @params = ();
	push( @params, sprintf( "ext=%s", $self->{ 'ext' } ) ) if( length( $self->{ 'ext' } ) );
	push( @params, sprintf( "isub=%s", $self->{ 'isdn_subaddress' } ) ) if( length( $self->{ 'isdn_subaddress' } ) );
	if( length( $self->{ 'context' } ) )
	{
		if( !$self->{ '_prepend_context' } )
		{
			push( @params, sprintf( "phone-context=%s", $self->{ 'context' } ) );
		}
		## Context is not some domain name
		elsif( $self->{ 'subscriber' } !~ /^\+\d+/ && $self->{ 'context' } !~ /[a-zA-Z]+/ )
		{
			@uri = ( 'tel:' . $self->{ 'context' } . '-' . $self->{ 'subscriber' } );
		}
	}
	if( length( $self->{ 'intl_code' } ) && !$self->{ '_intl_code_from_context' } )
	{
		if( $self->{ 'subscriber' } !~ /^\+\d+/ && $uri[0] !~ /^tel\:\+/ )
		{
			@uri = ( 'tel:' . '+' . $self->{ 'intl_code' } . '-' . $self->{ 'subscriber' } );
		}
	}
	my $priv = $self->{ 'private' };
	foreach my $k ( sort( keys( %$priv ) ) )
	{
		push( @params, sprintf( "$k=%s", $priv->{ $k } ) ) if( length( $priv->{ $k } ) );
	}
	push( @uri, join( ';', @params ) ) if( scalar( @params ) );
	$self->{ 'cache' } = join( ';', @uri );
	return( $self->{ 'cache' } );
}

*letters2digits = \&aton;

sub aton
{
	my $self = shift( @_ );
	my $str  = shift( @_ ) || $self->{ 'subscriber' };
	my $letters = 'abcdefghijklmnopqrstuvwxyz';
	my $digits  = '22233344455566677778889999';
	return( $str ) if( $str !~ /[a-zA-Z]+/ || !$self->is_vanity );
	$str = lc( $str );
	my $res = '';
	for( my $i = 0; $i < length( $str ); $i++ )
	{
		my $c = substr( $str, $i, 1 );
		my $p = index( $letters, $c );
		$res .= $p != -1 ? substr( $digits, $p, 1 ) : $c;
	}
	return( $res );
}

sub canonical
{
	my $self = shift( @_ );
	my $tel  = $self->aton;
	$tel     =~ s/[\Q$VISUAL_SEPARATOR\E]+//gs;
	my $uri  = $self->new( "tel:$tel" );
	$uri->ext( $self->{ 'ext' } ) if( length( $self->{ 'ext' } ) );
	$uri->isub( $self->{ 'isdn_subaddress' } ) if( length( $self->{ 'isdn_subaddress' } ) );
	$uri->context( $self->{ 'context' } ) if( length( $self->{ 'context' } ) );
	$uri->international_code( $self->{ 'intl_code' } ) if( length( $self->{ 'intl_code' } ) );
	$uri->{ '_has_context_param' } = $self->{ '_has_context_param' };
	$uri->{ '_prepend_context' } = $self->{ '_prepend_context' };
	$uri->{ '_intl_code_from_context' } = $self->{ '_intl_code_from_context' };
	$uri->{ 'local_number' } = $self->{ 'local_number' };
	my $priv = $self->{ 'private' };
	%{$uri->{ 'private' }} = %$priv;
	return( $uri );
}

sub cc2context
{
	my $self = shift( @_ );
	my $cc   = uc( shift( @_ ) );
	return( $self->error( "No country code provided." ) ) if( !length( $cc ) );
	$self->_load_countries;
	my $hash = $COUNTRIES;
	foreach my $k ( sort( keys( %$hash ) ) )
	{
		## array ref
		my $ref = $hash->{ $k };
		foreach my $this ( @$ref )
		{
			if( $this->{ 'cc' } eq $cc )
			{
				return( '+' . $k );
			}
		}
	}
	## Nothing found
	return( '' );
}

sub clone
{
	my $self  = shift( @_ );
	my $class = ref( $self );
	my $hash  = {};
	my @keys  = keys( %$self );
	@$hash{ @keys } = @$self{ @keys };
	delete( $hash->{ 'cache' } );
	return( bless( $hash, $class ) );
}

sub context
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $str  = shift( @_ );
		if( $str !~ /^$DESCRIPTOR$/ )
		{
			warn( "'$str' is not a valid context\n" );
			return( undef() );
		}
		delete( $self->{ 'cache' } );
		$self->{ '_has_context_param' } = 1;
		$self->{ '_prepend_context' } = 0;
		$self->{ 'context' } = $str;
		## We found an international country code in the prefix provided, so let's set it
		if( !length( $self->{ 'intl_code' } ) && ( my $code = $self->_extract_intl_code( $str ) ) )
		{
			$self->{ '_intl_code_from_context' } = 1;
			$self->{ 'intl_code' } = $code;
		}
	}
	return( $self->{ 'context' } );
}

sub country
{
	my $self = shift( @_ );
	no overloading;
	$self->_load_countries;
	my $hash = $COUNTRIES;
	my $code = $self->international_code;
	return( wantarray() ? () : [] ) if( !length( $code ) );
	$code =~ s/[\Q$VISUAL_SEPARATOR\E]+//g;
	if( $code =~ /^\+($IDD_RE)/ )
	{
		$code = $1;
	}
	return( wantarray() ? () : [] ) if( !exists( $hash->{ $code } ) );
	my $ref = $hash->{ $code };
	return( wantarray() ? @$ref : \@$ref );
}

sub country_code
{
    my $self = shift( @_ );
    my $ref  = $self->country_codes;
    return( '' ) if( ref( $ref ) ne 'ARRAY' );
    return( $ref->[0] );
}

sub country_codes
{
    my $self = shift( @_ );
    my $ref  = $self->country;
    return( '' ) if( ref( $ref ) ne 'ARRAY' );
    my @codes = map( $_->{cc}, @$ref );
    return( wantarray() ? @codes : \@codes );
}

sub country_name
{
    my $self = shift( @_ );
    my $ref  = $self->country_names;
    return( '' ) if( ref( $ref ) ne 'ARRAY' );
    return( $ref->[0] );
}

sub country_names
{
    my $self = shift( @_ );
    my $ref  = $self->country;
    return( '' ) if( ref( $ref ) ne 'ARRAY' );
    my @names = map( $_->{name}, @$ref );
    return( wantarray() ? @names : \@names );
}

sub error
{
    my $self  = shift( @_ );
    my $level = 0;
    my $caller = caller;
    my $err   = join( '', @_ );
    my $class = ref( $self ) || $self;
    if( $err && length( $err ) )
    {
        my( $frame, $caller ) = ( $level, '' );
        while( $caller = ( caller( $frame ) )[ 0 ] )
        {
            last if( $caller ne 'URI::tel' );
            $frame++;
        }
        my( $pack, $file, $line ) = caller( $frame );
        $err =~ s/\n$//gs;
        $self->{ 'error' } = ${ $class . '::ERROR' } = $err;
        return( undef() );
    }
    return( $self->{ 'error' } || $ERROR );
}

*extension = \&ext;

sub ext
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $val = shift( @_ );
		if( length( $val ) && $val !~ /^[$PHONEDIGIT]+$/ )
		{
			warn( "'$val' is not a valid extension ([$PHONEDIGIT]+)\n" );
			return( undef() );
		}
		delete( $self->{ 'cache' } );
		$self->{ 'ext' } = $val;
	}
	return( $self->{ 'ext' } );
}

sub international_code
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $val = shift( @_ );
		if( length( $val ) && $val !~ /^[$PHONEDIGIT]+$/ )
		{
			warn( "'$val' is not a valid international code.\n" );
			return( undef() );
		}
		delete( $self->{ 'cache' } );
		## The international code was provided by the user as opposed to using the context() method,
		## so we flag it properly so it can be used in stringification of the phone number
		$self->{ '_intl_code_from_context' } = 0;
		$self->{ 'is_global' } = 1;
		$self->{ 'intl_code' } = $val;
	}
	return( $self->{ 'intl_code' } );
}

sub is_global
{
	return( shift->{ 'is_global' } );
}

sub is_local
{
	return( shift->{ 'is_local' } );
}

sub is_other
{
	return( shift->{ 'is_other' } );
}

sub is_vanity
{
	return( shift->{ 'is_vanity' } );
}

*isdn_subaddress = \&isub;
sub isub
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $val  = shift( @_ );
		if( length( $val ) && $val !~ /^$URIC$/ )
		{
			warn( "'$val' is not a isdn subaddress\n" );
			return( undef() );
		}
		delete( $self->{ 'cache' } );
		$self->{ 'isub' } = $val;
	}
	return( $self->{ 'isub' } );
}

sub original
{
	return( shift->{ 'original' } );
}

sub prepend_context
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->{ '_prepend_context' } = shift( @_ );
		delete( $self->{ 'cache' } );
	}
	return( $self->{ '_prepend_context' } );
}

sub private
{
	my $self = shift( @_ );
	my( $name, $val ) = @_;
	if( length( $name ) )
	{
		## The value could be blank and if so, we would remove the parameter
		if( defined( $val ) )
		{
			if( $name !~ /^$PNAME$/ )
			{
				warn( "'$name' is not a valid parameter name.\n" );
				return( undef() );
			}
			if( length( $val ) )
			{
				if( $val !~ /^$PVALUE$/ )
				{
					warn( "'$val' is not a valid parameter value.\n" );
					return( undef() );
				}
				delete( $self->{ 'cache' } );
				$self->{ 'private' }->{ $name } = $val;
				return( $self->{ 'private' }->{ $name } );
			}
			else
			{
				return( delete( $self->{ 'private' }->{ $name } ) );
			}
		}
		else
		{
			return( wantarray() ? %${$self->{ 'private' }->{ $name }} : \%${$self->{ 'private' }->{ $name }} );
		}
	}
	return( wantarray() ? %{$self->{ 'private' }} : \%{$self->{ 'private' }} );
}

sub subscriber
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $val = shift( @_ );
		if( length( $val ) && $val !~ /^$TEL_SUBSCRIBER$/ )
		{
			warn( "'$val' is not a valid subscriber value.\n" );
			return( undef() );
		}
		delete( $self->{ 'cache' } );
		$self->{ 'subscriber' } = $val;
	}
	return( $self->{ 'subscriber' } );
}

sub type
{
	return( shift->{ 'type' } );
}

sub _extract_intl_code
{
	my $self = shift( @_ );
	my $str  = shift( @_ ) || return( '' );
	#print( STDERR "Trying to find international code from '$str'\n" );
	my $code;
	## Extract the global idd
	$self->_load_countries;
	( my $str2 = $str ) =~ s/[\Q$VISUAL_SEPARATOR\E]+//g;
	$str2 =~ s/^tel\://;
	if( $str2 =~ /^\+($IDD_RE)/ )
	{
		my $idd = $1;
		#print( STDERR "\tIDD is '$idd'\n" );
		if( CORE::exists( $COUNTRIES->{ $idd } ) )
		{
			my $idds = $COUNTRIES->{ $idd }->[0]->{ 'idd' };
			#print( STDERR "\tFound entry.\n" );
			foreach my $thisIdd ( @$idds )
			{
				my $check = $thisIdd;
				$check =~ s/\D//g;
				if( $check eq $idd )
				{
					#$temp->{ 'context' } = '+' . $thisIdd;
					$code = $thisIdd;
					last;
				}
			}
		}
	}
	#print( STDERR "\tReturning '$code'\n" );
	return( $code );
}

sub _extract_local_number
{
	my $self = shift( @_ );
	my( $intl_code, $subscriber ) = @_;
	my $j = 0;
	for( my $i = 0; $i < length( $intl_code ); $i++ )
	{
		# Skip until we are on a number
		next if( substr( $intl_code, $i, 1 ) !~ /^\d$/ );
		# and here too so we can compare number to number
		while( substr( $subscriber, $j, 1 ) !~ /^\d$/ )
		{
			$j++;
		}
		# Our international code does not seem to match the prefix of our subscriber! This should not happen.
		if( substr( $subscriber, $j, 1 ) ne substr( $intl_code, $i, 1 ) )
		{
			# printf( STDERR "Mismatch... %s at position %d vs %s at position %d\n", substr( $intl_code, $i, 1 ), $i, substr( $subscriber, $j, 1 ), $j );
			#last;
			return( '' );
		}
		$j++;
	}
	$j++ while( substr( $subscriber, $j, 1 ) !~ /^\d$/ );
	return( substr( $subscriber, $j ) );
}

# Check if two objects are the same object
# https://tools.ietf.org/search/rfc3966#section-4
sub _obj_eq 
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    return( 0 ) if( !ref( $other ) || !$other->isa( 'URI::tel' ) );
    my $sub = $self->canonical->subscriber;
    my $sub2 = $other->canonical->subscriber;
    $sub =~ s/^\+//;
    $sub2 =~ s/^\+//;
    return( 0 ) if( $sub ne $sub2 );
    my $context = $self->context;
    my $context2 = $other->context;
    return( 0 ) if( $context ne $context2 );
    my $ext = $self->ext;
    my $ext2 = $other->ext;
    return( 0 ) if( $ext ne $ext2 );
    my $priv = $self->private;
    my $priv2 = $other->private;
    foreach my $k ( keys( %$priv ) )
    {
    	return( 0 ) if( !exists( $priv2->{ $k } ) );
    	return( 0 ) if( $priv->{ $k } ne $priv2->{ $k } );
    }
    foreach my $k ( keys( %$priv2 ) )
    {
    	return( 0 ) if( !exists( $priv->{ $k } ) );
    	return( 0 ) if( $priv2->{ $k } ne $priv->{ $k } );
    }
    use overloading;
    return( 1 );
}

## Taken from http://www.perlmonks.org/bare/?node_id=319761
## This will do a split on a semi-colon, but being mindful if before it there is an escaped backslash
## For example, this would not be skipped: something\;here
## But this would be split: something\\;here resulting in something\ and here after unescaping
sub split_str
{
	my $self = shift( @_ );
	my $s    = shift( @_ );
	my $sep  = @_ ? shift( @_ ) : ';';
	my @parts = ();
	my $i = 0;
	foreach( split( /(\\.)|$sep/, $s ) ) 
	{
		defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
	}
	return( @parts );
}

sub _load_countries
{
	my $self = shift( @_ );
	if( !%$COUNTRIES )
	{
		my $in = 0;
		my $hash = {};
		my @data = <DATA>;
		foreach ( @data )
		{
			chomp;
			next unless( $in || /^\#{2} BEGIN DATA/ );
			last if( /^\#{2} END DATA/ );
			$in++;
			next if( /^\#{2} BEGIN DATA/ );
			my( $cc, $cc3, $name, $idd ) = split( /[[:blank:]]*\;[[:blank:]]*/, $_ );
			my $keys = index( $idd, ',' ) != -1 ? [ split( /[[:blank:]]*\,[[:blank:]]*/, $idd ) ] : [ $idd ];
			my $info = 
			{
			'cc' => $cc,
			'cc3' => $cc3,
			'name' => $name,
			'idd' => $idd,
			};
			$info->{ 'idd' } = $keys;
			foreach my $k ( @$keys )
			{
				my $k2 = $k;
				$k2 =~ s/-//gs;
				$hash->{ $k2 } = [] if( !exists( $hash->{ $k2 } ) );
				push( @{$hash->{ $k2 }}, $info );
			}
		}
		$COUNTRIES = $hash;
		my @list = sort{ $b <=> $a } keys( %$hash );
		my $re_list = join( '|', @list );
		$IDD_RE = qr{(?:$re_list)};
	}
}

1;

__DATA__
=encoding utf8

=head1 NAME

URI::tel - Implementation of rfc3966 for tel URI

=head1 SYNOPSIS

    my $tel = URI::tel->new( 'tel:+1-418-656-9254;ext=102' );
    ## or
    my $tel = URI::tel->new( 'tel:5678-1234;phone-context=+81-3' );
    ## or
    my $tel = URI::tel->new( '03-5678-1234' );
    $tel->context( '+81' );
    $tel->ext( 42 );
    print( $tel->canonical->as_string, "\n" );
    my $tel2 = $tel->canonical;
    print( "$tel2\n" );
    ## or
    my $tel = URI::tel->new( '+1-800-LAWYERS' );
    my $actualPhone = $tel->aton;
    ## would produce +1-800-5299377

    ## Comparing 2 telephones
    ## https://tools.ietf.org/search/rfc3966#section-4
    if( $tel == $tel2 )
    {
        ## then do something
    }

=head1 DESCRIPTION

C<URI::tel> is a package to implement the tel URI
as defined in rfc3966 L<https://tools.ietf.org/search/rfc3966>.

tel URI is structured as follows:

tel:I<telephone-subscriber>

I<telephone-subscriber> is either a I<global-number> or a I<local-number>

I<global-number> can be composed of the following characters:

+[0-9\-\.\(\)]*[0-9][0-9\-\.\(\)]* then followed with one or zero parameter, extension, isdn-subaddress

I<local-number> can be composed of the following characters:

[0-9A-F\*\#\-\.\(\)]* ([0-9A-F\*\#])[0-9A-F\*\#\-\.\(\)]* followed by one or zero of 
parameter, extension, isdn-subaddress, then at least one context then followed by one or zero of 
parameter, extension, isdn-subaddress.

I<parameter> is something that looks like ;[a-zA-Z0-9\-]+=[\[\]\/\:\&\+\$0-9a-zA-Z\-\_\.\!\~\*\'\(\)]+

I<extension> is something that looks like ;ext=[0-9\-\.\(\)]+

I<isdn-subaddress> is something that looks like ;isub=[\;\/\?\:\@\&\=\+\$\,a-zA-Z0-9\-\_\.\!\~\*\'\(\)%0-9A-F]+

I<context> is something that looks like 
;phone-context=([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\.)?([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])
or
;phone-context=+([0-9]+[\-\.\(\)]*)?[0-9]+([0-9]+[\-\.\(\)]*)?

=head1 METHODS

=over 4

=item B<new>( tel URI )

B<new>() is provided with a tel URI and return an instance of this package.

=item B<as_string>()

Returns a string representation of the tel uri. This package is overloaded, so one can get the same result by doing

    my $str = $tel->as_string;

=item B<aton>( [ telephone ] )

If no phone number is given as argument, it will use the I<subscriber> value of the object used to call this method.
It returns the phone number with the letters replaced by their digit counterparts.

For example a subscriber such as C<tel:+1-800-LAWYERS> would return C<tel:+1-800-5299377>

=item B<canonical>

Return the tel uri in a canonical form, ie without any visualisation characters, ie no C<hyphen>, C<comma>, C<dot>, etc

=item B<clone>()

Returns an exact copy of the current object.

=item B<context>( [ CONTEXT ] )

Given a telephone context, sets the value accordingly.
It returns the current existing value.

For example, with a phone number of 03-1234-5678, this is a local number, and one could set some context, such as 

    $tel->context( '+81' )

Thus, when called upon as a string, the object would return:

    03-1234-5678;phone-context=+81

=item B<country>()

If the current telephone uri is as global number, this method will try to find out to which country it belongs.
It returns an array in list context and an array reference in scalar context.

If there are more than one country using the same international dialling code, it will return multiple entry in the array.
This is typically true for countries like Canada and the United States who both uses the same C<+1> international dialling code.

One could then do something like the following:

    my $ref = $tel->country;
    print( "Country: ", @$ref > 1 ? join( ' or ', map( $_->{ 'name' }, @$ref ) ) : @$ref ? $ref->[0]->{ 'name' } : 'not found', "\n" );

which would produce:

    Country: Canada or United States

Each array entry is a reference to an associative array, which contains the following fields:

=over 8

=item I<cc> for the iso 3166 2-letters code

=item I<cc3> for the iso 3166 3-letters code

=item I<name> for the country name

=item I<idd> for the international dialling code. I<idd> is an array reference which may contains one or more entries, as there may be multiple international dialling code per country.

=back

=item B<international_code>( [ PHONE DIGITS ] )

This returns the international code, if any. The international code is the international country code unique to each country or territory. It may be found as a prefix to the subscriber number or as a context to the phone number. For example:

    +1-418-656-9254;ext=102;phone-context=example.com
    tel:656-9254;ext=102;phone-context=+1-212
    tel:911;phone-context=+1

If an international country code is provided, it will be used to get information such as country name and iso 3166 country codes and also it will be used in formatting the phone number by prefixing the subscriber number with the international country code provided. If, instead you want to just set a context, then use the B<context> method instead. For example with a subscriber number such as I<911>, you may want to give it some context by adding +1 such as :

	my $tel = URI::tel->new( "911" );
	$tel->context( '+1' );
	print( "$tel\n" ); # will produce 911;phone-context=+1

	# But don't do this!
	$tel->international_code( 1 );
	# print will now trigger a bad phone number
	print( "$tel\n" ); " will produce +1-911

=item B<is_global>()

Returns true or false depending on whether the phone number is a global one, ie starting with C<+>.

=item B<is_local>()

Returns true or false depending on whether the phone number is a local one, ie a number without the C<+> prefix.
This can happen of course with numbers such as C<03-1234-5678>, but also for emergency number, such as C<110> (police in Japan) or
C<911> (police in the U.S.).

One could set a prefix to clarify, such as:

    my $tel = URI::tel->new( '110' );
    $tel->context( '+81' );
    ## which would produce:
    ## 110;phone-context=+81

=item B<is_other>()

Normally, as per rfc 3966, a non global number must have a context, but in everyday life this is rarely the case, so B<is_other> flags those numbers who are local but lack a context.

It returns true or false.

=item B<is_vanity>()

Returns true or false whether the telephone number is a vanity number, such as C<+1-800-LAWYERS>.

=item B<isub>( [ ISDN SUBADDRESS ] )

Optionally sets the isdn subaddress if a value is provided.
It returns the current value set.

    $tel->isub( 1420 );

=item B<original>()

Returns the original telephone number provided, before any possible changes were brought.

=item B<private>( [ NAME, [ VALUE ] ] )

Given a I<NAME>, B<private> returns the value entry for that parameter. If a I<VALUE> is provided, it will set this value for the given name.
if no I<NAME>, and no I<VALUE> was provided, B<private> returns a list of all the name-value pair currently set, or a reference to that associative array in scalar context.

=item B<subscriber>( [ PHONE ] )

Returns the current telephone number set for this telephone uri. For example:

    my $tel = URI::tel->new( 'tel:+1-418-656-9254;ext=102' );
    my $subscriber = $tel->subscriber;

will return: C<+1-418-656-9254>

=item B<type>()

This is a read-only method. It returns the type of the telephone number. The type can be one of the following values: global, local, other, vanity

=back

=head1 SEE ALSO

List of country calling codes: E<lt>F<https://en.wikipedia.org/wiki/List_of_country_calling_codes>E<gt>

=head1 CREDITS

Credits to Thiago Berlitz Rondon for the initial version.

=head1 COPYRIGHT

Copyright (c) 2016-2018 Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

## BEGIN DATA
CA;CAN;Canada;1
US;USA;United States;1
EG;EGY;Egypt;20
ZA;ZAF;South Africa;27
GR;GRC;Greece;30
NL;NLD;Netherlands;31
BE;BEL;Belgium;32
FR;FRA;France;33
ES;ESP;Spain;34
HU;HUN;Hungary;36
IT;ITA;Italy;39
RO;ROU;Romania;40
CH;CHE;Switzerland;41
AT;AUT;Austria;43
GG;GGY;Guernsey;44-1481
GB;GBR;United Kingdom;44
DK;DNK;Denmark;45
SE;SWE;Sweden;46
NO;NOR;Norway;47
SJ;SJM;Svalbard and Jan Mayen;47-79
PL;POL;Poland;48
DE;DEU;Germany;49
PE;PER;Peru;51
MX;MEX;Mexico;52
CU;CUB;Cuba;53
AR;ARG;Argentina;54
BV;BVT;Bouvet Island;55
BR;BRA;Brazil;55
CL;CHL;Chile;56
CO;COL;Colombia;57
VE;VEN;Venezuela;58
MY;MYS;Malaysia;60
AU;AUS;Australia;61
ID;IDN;Indonesia;62
PH;PHL;Philippines;63
NZ;NZL;New Zealand;64
SG;SGP;Singapore;65
TH;THA;Thailand;66
JP;JPN;Japan;81
KR;KOR;Korea;82
VN;VNM;Viet Nam;84
CN;CHN;China;86
TR;TUR;Turkey;90
IN;IND;India;91
PK;PAK;Pakistan;92
AF;AFG;Afghanistan;93
LK;LKA;Sri Lanka;94
MM;MMR;Myanmar;95
IR;IRN;Iran;98
SS;SSD;South Sudan;211
MA;MAR;Morocco;212
EH;ESH;Western Sahara;212
DZ;DZA;Algeria;213
LY;LBY;Libya;218
GM;GMB;Gambia;220
SN;SEN;Senegal;221
MR;MRT;Mauritania;222
ML;MLI;Mali;223
GN;GIN;Guinea;224
CI;CIV;Ivory Coast;225
BF;BFA;Burkina Faso;226
NE;NER;Niger;227
TG;TGO;Togo;228
BJ;BEN;Benin;229
MU;MUS;Mauritius;230
LR;LBR;Liberia;231
SL;SLE;Sierra Leone;232
GH;GHA;Ghana;233
NG;NGA;Nigeria;234
TD;TCD;Chad;235
CF;CAF;Central African Republic;236
CM;CMR;Cameroon;237
CV;CPV;Cape Verde;238
ST;STP;Sao Tome and Principe;239
GQ;GNQ;Equatorial Guinea;240
GA;GAB;Gabon;241
CG;COG;Republic of the Congo;242
CD;COD;Congo;243
AO;AGO;Angola;244
GW;GNB;Guinea-Bissau;245
IO;IOT;British Indian Ocean Territory;246
SC;SYC;Seychelles;248
SD;SDN;Sudan;249
RW;RWA;Rwanda;250
ET;ETH;Ethiopia;251
SO;SOM;Somalia;252
DJ;DJI;Djibouti;253
KE;KEN;Kenya;254
TZ;TZA;Tanzania;255
UG;UGA;Uganda;256
BI;BDI;Burundi;257
MZ;MOZ;Mozambique;258
ZM;ZMB;Zambia;260
MG;MDG;Madagascar;261
TF;ATF;French Southern Territories;262
RE;REU;Reunion;262
ZW;ZWE;Zimbabwe;263
NA;NAM;Namibia;264
MW;MWI;Malawi;265
LS;LSO;Lesotho;266
BW;BWA;Botswana;267
SZ;SWZ;Swaziland;268
KM;COM;Comoros;269
SH;SHN;Saint Helena, Ascension and Tristan da Cunha;290
ER;ERI;Eritrea;291
AW;ABW;Aruba;297
FO;FRO;Faroe Islands;298
GL;GRL;Greenland;299
GI;GIB;Gibraltar;350
PT;PRT;Portugal;351
LU;LUX;Luxembourg;352
IE;IRL;Ireland;353
IS;ISL;Iceland;354
AL;ALB;Albania;355
MT;MLT;Malta;356
CY;CYP;Cyprus;357
AX;ALA;Aland Islands;358
FI;FIN;Finland;358
BG;BGR;Bulgaria;359
LT;LTU;Lithuania;370
LV;LVA;Latvia;371
EE;EST;Estonia;372
MD;MDA;Moldova;373
AM;ARM;Armenia;374
BY;BLR;Belarus;375
AD;AND;Andorra;376
MC;MCO;Monaco;377
SM;SMR;San Marino;378
VA;VAT;Vatican City;379,39-06-698
UA;UKR;Ukraine;380
RS;SRB;Serbia;381
ME;MNE;Montenegro;382
HR;HRV;Croatia;385
SI;SVN;Slovenia;386
BA;BIH;Bosnia and Herzegovina;387
MK;MKD;Macedonia;389
CZ;CZE;Czech Republic;420
SK;SVK;Slovakia;421
LI;LIE;Liechtenstein;423
GS;SGS;South Georgia and the South Sandwich Islands;500
BZ;BLZ;Belize;501
GT;GTM;Guatemala;502
SV;SLV;El Salvador;503
HN;HND;Honduras;504
NI;NIC;Nicaragua;505
CR;CRI;Costa Rica;506
PA;PAN;Panama;507
PM;SPM;Saint Pierre and Miquelon;508
HT;HTI;Haiti;509
GP;GLP;Guadeloupe;590
BL;BLM;Saint Barthelemy;590
MF;MAF;Saint Martin;590
BO;BOL;Bolivia;591
GY;GUY;Guyana;592
EC;ECU;Ecuador;593
GF;GUF;French Guiana;594
PY;PRY;Paraguay;595
MQ;MTQ;Martinique;596
SR;SUR;Suriname;597
UY;URY;Uruguay;598
BQ;BES;Bonaire, Sint Eustatius and Saba;599-3,599-4,599-7
TL;TLS;Timor-Leste;670
AQ;ATA;Antarctica;672
NF;NFK;Norfolk Island;672
BN;BRN;Brunei;673
NR;NRU;Nauru;674
PG;PNG;Papua New Guinea;675
TO;TON;Tonga;676
SB;SLB;Solomon Islands;677
VU;VUT;Vanuatu;678
FJ;FJI;Fiji;679
PW;PLW;Palau;680
WF;WLF;Wallis and Futuna;681
CK;COK;Cook Islands;682
NU;NIU;Niue;683
WS;WSM;Samoa;685
KI;KIR;Kiribati;686
NC;NCL;New Caledonia;687
TV;TUV;Tuvalu;688
PF;PYF;French Polynesia;689
TK;TKL;Tokelau;690
FM;FSM;Micronesia;691
MH;MHL;Marshall Islands;692
UM;UMI;United States Minor Outlying Islands;699
KP;PRK;North Korea;850
HK;HKG;Hong Kong;852
MO;MAC;Macao;853
KH;KHM;Cambodia;855
LA;LAO;Laos;856
BD;BGD;Bangladesh;880
TW;TWN;Taiwan;886
MV;MDV;Maldives;960
LB;LBN;Lebanon;961
JO;JOR;Jordan;962
SY;SYR;Syria;963
IQ;IRQ;Iraq;964
KW;KWT;Kuwait;965
SA;SAU;Saudi Arabia;966
YE;YEM;Yemen;967
OM;OMN;Oman;968
PS;PSE;Palestine;970
AE;ARE;United Arab Emirates;971
IL;ISR;Israel;972
BH;BHR;Bahrain;973
QA;QAT;Qatar;974
BT;BTN;Bhutan;975
MN;MNG;Mongolia;976
NP;NPL;Nepal;977
TJ;TJK;Tajikistan;992
TM;TKM;Turkmenistan;993
AZ;AZE;Azerbaijan;994
GE;GEO;Georgia;995
KG;KGZ;Kyrgyzstan;996
UZ;UZB;Uzbekistan;998
BS;BHS;Bahamas;1-242
BB;BRB;Barbados;1-246
AI;AIA;Anguilla;1-264
AG;ATG;Antigua and Barbuda;1-268
VG;VGB;British Virgin Islands;1-284
VI;VIR;United States Virgin Islands;1-340
KY;CYM;Cayman Islands;1-345
BM;BMU;Bermuda;1-441
GD;GRD;Grenada;1-473
TC;TCA;Turks and Caicos Islands;1-649
MS;MSR;Montserrat;1-664
MP;MNP;Northern Mariana Islands;1-670
GU;GUM;Guam;1-671
AS;ASM;American Samoa;1-684
SX;SXM;Sint Maarten;1-721
LC;LCA;Saint Lucia;1-758
DM;DMA;Dominica;1-767
VC;VCT;Saint Vincent and the Grenadines;1-784
PR;PRI;Puerto Rico;1-787,1-939
DO;DOM;Dominican Republic;1-809,1-829,1-849
TT;TTO;Trinidad and Tobago;1-868
KN;KNA;Saint Kitts and Nevis;1-869
JM;JAM;Jamaica;1-876
TN;TUN;Tunisia;216
YT;MYT;Mayotte;262
HM;HMD;Heard Island and McDonald Islands;334
VA;VAT;Holy See;379
JE;JEY;Jersey;44-1534
IM;IMN;Isle of Man;44-1624
FK;FLK;Falkland Islands;500
CW;CUW;Curaçao;599-9
CX;CXR;Christmas Island;61-8-9164
CC;CCK;Cocos (Keeling) Islands;61-8-9162
PN;PCN;Pitcairn;64
RU;RUS;Russia;7
KZ;KAZ;Kazakhstan;7-6,7-7
## END DATA
