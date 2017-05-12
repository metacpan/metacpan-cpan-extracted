# Bind8 Conf parser
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

package Unix::Conf::Bind8::Conf;

use strict;
use warnings;

use Unix::Conf::Bind8::Conf::Lib;

use constant	EOF				=> 0;
use constant	NEWLINE			=> 1;
use constant	COMMENT			=> 2;
use constant	OPENCCOMMENT	=> 3;
use constant	CLOSECCOMMENT	=> 4;
use constant	SEMICOLON		=> 5;
use constant	OPENBRACE		=> 6;
use constant	CLOSEBRACE		=> 7;
use constant	EXCLAMATION		=> 8;
use constant	ASTERISK		=> 9;
use constant	NUMBER			=> 10;
use constant	STRING			=> 11;
use constant	WORD			=> 12;
use constant	IPv4			=> 13;
use constant	IP_PREFIX		=> 14;
use constant	_WHITESPACE		=> 15;
use constant	UNRECOGNISED	=> 16;

my @TokenType = (
	"EOF",
	"NEWLINE",
	"COMMENT",
	"OPENCCOMMENT",
	"CLOSECCOMMENT",
	"SEMICOLON",
	"OPENBRACE",
	"CLOSEBRACE",
	"EXCLAMATION",
	"ASTERISK",
	"NUMBER",
	"STRING",
	"WORD",
	"IPv4",
	"IP_PREFIX",
	"_WHITESPACE",
	"UNRECOGNISED",
);

my ($Conf, $FH, $Line, $Token, $ConfName, $Lineno);
my $Err = [];
# the following are treated as references, so that we can
# avoid the overhead of passing these string by copy to _rstring, _tws
# methods.
# my ($RString, $TWS);
our ($RString, $TWS);
# store positional info on where the last successfully accepted
# token ends. R_Offset contains the offset into RString, where
# the last token ends, _Lineno, the lineno, and L_Offset the pos ()
# where the last token match ended.
my ($R_Offset, $_Lineno, $L_Offset);

################## PARSER STATE DECLARATIONS ########################

use constant		P_NORMAL			=> 1;
use constant		P_INDIRECTIVE		=> 2;

my $ParserState;

#####################################################################

################## LEXER  STATE DECLARATIONS ########################

use constant	L_NORMAL		=> 1;
use constant	L_INCOMMENT		=> 2;
my $LexerState;

#####################################################################


# store the above data here in case we call _parse_conf recursively
# in case of an include directive.
my (@ParseStack);

sub __pushfile ()
{
	push (
		@ParseStack, 
		[ 
			$Conf,		$FH, 
			$Line,		$Token, 
			$ConfName,	$Lineno, 
			$RString,	$TWS, 
			$R_Offset,	$_Lineno, 
			$L_Offset,	$ParserState,
			$LexerState, pos ($Line),
		]
	);
	( 
		$Conf, 		$FH, 
		$Line, 		$Token, 
		$ConfName, 	$Lineno, 
		$RString, 	$TWS, 
		$R_Offset, 	$_Lineno, 
		$L_Offset, 	$ParserState,
		$LexerState,
	) = (undef) x 13;
}

sub __popfile ()
{
	my $pos;
	(
		$Conf,		$FH, 
		$Line,		$Token, 
		$ConfName,	$Lineno, 
		$RString,	$TWS, 
		$R_Offset,	$_Lineno, 
		$L_Offset,	$ParserState, 
		$LexerState, $pos,
	) = @{pop (@ParseStack)};
	pos ($Line) = $pos;
}


# Change to add this to the Conf object itself later using $Conf->__add_err ()
sub __die ($;$)
{
	die ($_[0]) if (@_ == 1);
	die (Unix::Conf->_err ($_[0]." ($ConfName:$Lineno)", $_[1]."\n" ));
}

sub __warn ($;$)
{
	if (@_ == 1) {
		$Conf->__add_err ($_[0]);
		return ();
	}
	$Conf->__add_err (Unix::Conf->_err ($_[0]." ($ConfName:$Lineno)", $_[1]."\n" ));
}

use constant 	T_TOKENTYPE		=> 0;
use constant	T_TOKEN			=> 1;
use constant	T_ROFFSET		=> 2;
use constant	T_LINENO		=> 3;
use constant 	T_LOFFSET		=> 4;

sub tokentype ($) { return $TokenType[$_[0]->[T_TOKENTYPE]]; }

my %Dispatch = (
		'acl'       	=> \&__parse_named_acl,
		'controls'  	=> \&__parse_controls,
		'include'   	=> \&__parse_include,
		'key'       	=> \&__parse_key,
		'logging'   	=> \&__parse_logging,
		'options'   	=> \&__parse_options,
		'server'    	=> \&__parse_server,
		'trusted-keys' 	=> \&__parse_trustedkeys,
		'zone'      	=> \&__parse_zone,
);

sub __parse_conf ($$)
{
	__pushfile ();

	($Conf, $FH) = ($_[0], $_[0]->fh ());
	$ConfName = "$FH";
	($Lineno, $L_Offset, $R_Offset) = (0, 0, 0);
	my ($token, $handler, $obj);


	$ParserState = P_NORMAL; $LexerState = L_NORMAL;
	$RString = undef;

	while (($token = __gettoken ())->[T_TOKENTYPE] != EOF) {
		# set the TWS for the last parsed object.
		# print "TWS\n[->$$TWS<-]\n" if (defined ($TWS));
		$obj->_tws ($TWS) if ($obj);
		$TWS = undef;
		if ($token->[T_TOKENTYPE] == COMMENT) {
			$obj = $Conf->new_comment ();
		}
		elsif ($token->[T_TOKENTYPE] == WORD) {
			# at this point it is still an assumption. 
			$ParserState = P_INDIRECTIVE;
			__die ("_parse_conf", "illegal/unsupported directive `$token->[T_TOKEN]', aborting")
				unless (defined ($handler = $Dispatch{$token->[T_TOKEN]}));
			$obj = &$handler();
		}
		# the file could be emtpy or the return an error
		if ($obj) {
			$ParserState = P_NORMAL;
			$obj->_rstring ($RString);
			# print "DIRECTIVE \n[->$$RString<-]\n" if (defined ($RString));
			$RString = undef;
		}
	}
	$Conf->dirty (0);
	__popfile ();
	return (1);
}

############################## Utility functions ###########################################

sub __slurp_semicolon ()
{
	my $token;
	if (($token = __gettoken ())->[T_TOKENTYPE] != SEMICOLON) {
		__ungettoken ($token); 
		__warn (
			'slurp_semicolon', 
			"expected token `SEMICOLON', got `$TokenType[$token->[T_TOKENTYPE]]', ignored"
		);
		return;
	}
	return (1);
}

sub __slurp_openbr ()
{
	my $token;
	if (($token = __gettoken ())->[T_TOKENTYPE] != OPENBRACE) {
		__ungettoken ($token); 
		__warn (
			'slurp_openbr', 
			"expected token `OPENBRACE', got `$TokenType[$token->[T_TOKENTYPE]]', ignored"
		);
		return;
	}
	return (1);
}

sub __slurp_closebr ()
{
	my $token;
	if (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		__ungettoken ($token); 
		__warn (
			'slurp_closebr', 
			"expected token `CLOSEBRACE', got `$TokenType[$token->[T_TOKENTYPE]]', ignored"
		);
		return;
	}
	return (1);
}


################################## Parse functions ############################################

# subroutine to eat up a directive. for unsupported directives.
# returns an instance of Unix::Conf::Bind8::Conf::Dummy.
sub __eat_directive ()
{
	my (@stack, $token);

	until (($token = __gettoken ())->[T_TOKENTYPE] == OPENBRACE) {;}

	while (($token = __gettoken ())->[T_TOKENTYPE] != EOF) {
		if ($token->[T_TOKENTYPE] == OPENBRACE) {
			push (@stack, OPENBRACE);
		}
		elsif ($token->[T_TOKENTYPE] == CLOSEBRACE) {
			last unless (defined (pop (@stack)));
		}
	}
	__slurp_semicolon ();
	return ($Conf->new_dummy ());
}

sub __parse_include ()
{
	my $token = __gettoken ()->[T_TOKEN];
	my ($include, %args);

	$token =~ s/"(.+)"/$1/;
	$args{FILE} = $token;
	$args{SECURE_OPEN} = $Conf->fh ()->secure_open ();
	$include = $Conf->new_include (%args) or die ($include);
	__slurp_semicolon ();
	return ($include);
}

# parse list of ipaddresses. used with the masters/forwarders/also-notify
# statements in the zone directive and the forwarders statement in the 
# options directive. Returns an anon array of addresses if defined, else
# an undef.
sub __parse_ipaddress_list ()
{
	my ($token, $ret);

	__slurp_openbr ();
	while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		push (@$ret, "$token->[T_TOKEN]");
		__slurp_semicolon ();
	}
	return ($ret);
}

my @zone_dir1 = qw (
	type
	file
	notify
	forward
	transfer-source
	check-names
	max-transfer-time-in
);

sub __parse_zone ()
{
	my ($token, $_token, $zone, $name, $ret);

	local $" = "|";
	$zone = $Conf->new_zone ( NAME => ($token = __gettoken ())->[T_TOKEN] )
		or __die ($zone);
	
	if (($token = __gettoken ())->[T_TOKENTYPE] != OPENBRACE) {
		$ret = $zone->class ($token->[T_TOKEN])
			or __warn ($ret);
		__slurp_openbr ();
	}
	
	# now parse zone directives
	while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		$_token = $token->[T_TOKEN];
		($_token =~ /^(@zone_dir1)$/) && do {
			$_token =~ s/-/_/g;
			$ret = $zone->$_token (__gettoken ()->[T_TOKEN])
				or __warn ($ret);
			goto SEMICOLON;
		};
		($_token =~ /^allow-(transfer|query|update)$/) && do {
			my $acl;
			$_token =~ tr/-/_/;
			__slurp_openbr ();
			($acl = __parse_acl ()) &&
				($ret = $zone->$_token ($acl) or __warn ($ret));
			next;
		};
		($_token eq 'masters') && do {
			my ($port, $address);
			if (($token = __gettoken ())->[T_TOKEN] eq 'port') {
				$port = __gettoken ()->[T_TOKEN];
			}
			else {
				__ungettoken ($token);
			}
			$address = __parse_ipaddress_list ();
			unless ($address) {
				__warn ("__parse_zone", "masters address list cannot be empty");
				goto SEMICOLON;
			}
			$ret = $zone->masters (PORT => $port, ADDRESS => $address)
				or __warn ($ret);
			goto SEMICOLON;
		};
		($_token =~ /^(also-notify|forwarders)$/) && do {
			$_token =~ tr/-/_/;
			my $list = __parse_ipaddress_list ();
			$list = [] unless (defined ($list));
			$ret = $zone->$_token ($list) or __warn ($list);
			goto SEMICOLON;
		};
		($_token eq 'pubkey') && do {
			my $ret;

			__warn ($ret) unless (
				$ret = $zone->pubkey (
				__gettoken ()->[T_TOKEN], __gettoken ()->[T_TOKEN],
				__gettoken ()->[T_TOKEN], __gettoken ()->[T_TOKEN],
				) 
			);
			__slurp_semicolon ();
			next;
		};
		# unhandled as the syntax does not define this zone directive
		($_token eq 'ixfr-base') && 	do {
			__gettoken ();
			__slurp_semicolon ();
			next;
		};
		__die ('__parse_zone', "`$_token' illegal/unsupported zone directive");

SEMICOLON:
		__slurp_semicolon ();
	}

	# end of the zone statement
	__slurp_semicolon (); 
	return ($zone);
}


sub __parse_named_acl () { return __parse_acl (1); }

sub __parse_acl (;$);

# Arguments:  '1' (indicating true) if it is a named acl (acl 'aclname' { ..)
# the same subroutine is used to parse acls in front of directives like
# allow-query.
sub __parse_acl (;$)
{
	my ($named) = @_;
	my ($token, $_token, $acl, $ret, $element);

	if ($named) {
		$acl = $Conf->new_acl (NAME => (__gettoken ()->[T_TOKEN]))
			or __die ($acl);
		__slurp_openbr ();
	}
	else {
		$acl = $Conf->new_acl () or die ($acl);
	}

	while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		$element = '';
		if ($token->[T_TOKEN] eq '!') {
			$element = "!"; 
			$token = __gettoken ();
		}

		# need to do something to handle when the whole
		# block is negated like in !{ ...; };
		if ($token->[T_TOKENTYPE] == OPENBRACE) {
			my $pacl;
			if ($pacl = __parse_acl ()) {
				$ret = $acl->add_elements ($pacl)
					or __warn ($ret);
			}
			else {
			 	__warn ($pacl);
			}
			next;
		}
		elsif ($token->[T_TOKEN] eq 'key') {
			$element .= sprintf ("key %s", __gettoken ()->[T_TOKEN]);
		}
		else {
			$element .= $token->[T_TOKEN]
		}
		$ret = $acl->add_elements ($element) or __warn ($ret);
		__slurp_semicolon ();
	}
	__slurp_semicolon ();
	return ($acl);
}


sub __parse_options ()
{
	my ($token, $_token, $ret);
	my $options;
	$options = $Conf->new_options () or __die ($options);
	
	__slurp_openbr ();
	while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		$_token = $token->[T_TOKEN];
		($_token eq 'rrset-order')	&&	do {
			__slurp_openbr ();
			while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
				my %args;
				if ($token->[T_TOKEN] eq 'class') {
					$args{CLASS} = __gettoken ()->[T_TOKEN];
					$token = __gettoken ();
				}
				if ($token->[T_TOKEN] eq 'type') {
					$args{TYPE} = __gettoken ()->[T_TOKEN];
					$token = __gettoken ();
				}
				if ($token->[T_TOKEN] eq 'name') {
					$args{NAME} = __gettoken ()->[T_TOKEN];
					$token = __gettoken ();
				}
				__die ('__parse_options', "expected `order' got `$token->[T_TOKEN]'")
					unless ($token->[T_TOKEN] eq 'order');
				$args{ORDER} = __gettoken ()->[T_TOKEN];
				$ret = $options->add_to_rrset_order (%args)
					or __warn ($ret);
				__slurp_semicolon ();
			}
			goto SEMICOLON;
		};
		($_token eq 'forwarders') && do {
			my $list = __parse_ipaddress_list ();
			$list = [] unless (defined ($list));
			$ret = $options->forwarders ($list) 
				or __warn ($ret);
			goto SEMICOLON;
		};
		($_token eq 'check-names') && do {
			$ret = $options->add_to_check_names (
				__gettoken ()->[T_TOKEN], __gettoken ()->[T_TOKEN]
			) or __warn ($ret);
			goto SEMICOLON;
		};
		($_token eq 'listen-on') && do {
			my ($port, $acl);
			if (($token = __gettoken ())->[T_TOKEN] eq 'port') {
				$port = __gettoken ()->[T_TOKEN];
			}
			else {
				__ungettoken ($token);
				$port = '';
			}
			__slurp_openbr ();
			$acl = __parse_acl () or __die ($acl);
			$ret = $options->add_to_listen_on ($port => $acl->elements ())
				or __warn ($ret);
			next;
		};
		($_token eq 'query-source') && do {
			my %args;
			while (($token = __gettoken ())->[T_TOKENTYPE] != SEMICOLON) {
				$args{PORT} = __gettoken ()->[T_TOKEN] 	if ($token->[T_TOKEN] eq 'port');
				$args{ADDRESS} = __gettoken ()->[T_TOKEN]	if ($token->[T_TOKEN] eq 'address');
			}
			$ret = $options->query_source (%args) or __warn ($ret);	
			next;
		};
		($_token =~ /^(topology|sortlist|blackhole)$/) && do {
			my $acl;
			__slurp_openbr ();
			($acl = __parse_acl ()) && 
				($ret = $options->$_token ($acl) or __warn ($acl));
			next;
		};
		($_token =~ /^allow-(query|recursion|transfer)$/) && do {
			my $acl;
			$_token =~ s/-/_/g;
			__slurp_openbr ();
			($acl = __parse_acl ()) && 
				($ret = $options->$_token ($acl) or __warn ($acl));
			next;
		};

		# Handle the general case 
		do {
			__die ('__parse_options', "`$_token' illegal/unsupported option")
				unless ($options->__valid_option ($_token));
			$_token =~ s/-/_/g;
			$ret = $options->$_token (__gettoken ()->[T_TOKEN]) or __warn ($ret);
			goto SEMICOLON;
		};

SEMICOLON:	__slurp_semicolon ();	
	}

	__slurp_semicolon ();
	return ($options);
}


sub __parse_logging ()
{
	my ($token, $logging);

	$logging = $Conf->new_logging () or die ($logging);
	__slurp_openbr ();
	while (($token = __gettoken ())->[T_TOKENTYPE] != CLOSEBRACE) {
		($token->[T_TOKEN] eq 'channel') 	&&	do { __parse_channel ($logging); };
		($token->[T_TOKEN] eq 'category') 	&&	do { __parse_category ($logging); };
	}
	__slurp_semicolon ();
	return ($logging);
}

sub __parse_channel ($)
{
	my $logging = $_[0];
	my ($ret, $channel, $token, $_token, $path, $versions, $size);

	$channel = $logging->new_channel (NAME => __gettoken ()->[T_TOKEN])
		or __die ($channel);
	__slurp_openbr ();

	until (($token = __gettoken ())->[T_TOKENTYPE] == CLOSEBRACE) {
		$_token = $token->[T_TOKEN];
		($_token eq 'file') && do {
			my @args;
			$ret = $channel->output ($_token) or __warn ($ret); 
			push (@args, ( PATH => __gettoken ()->[T_TOKEN]));
			while (($token = __gettoken ())->[T_TOKENTYPE] != SEMICOLON) {
				($token->[T_TOKEN] eq 'versions') and 
					push (@args, ( VERSIONS => __gettoken ()->[T_TOKEN]));
				($token->[T_TOKEN] eq 'size') and 
					push (@args, ( SIZE => __gettoken ()->[T_TOKEN]));
			}
				
			$ret = $channel->file ( @args ) or __warn ($ret);
			next;
		};
		# we slurp the semicolon in every case instead of doing in at the bottom
		# is so that we can check for the illegal channel directive.
		($_token eq 'syslog') && do {
			$ret = $channel->output ($_token) or __warn ($ret); 

			# channel boo { syslog; } is legal syntax. refer to the named.conf
			# in src/bin/named (channel no_info_messages). however the
			# syntax in the named.conf man page doesnt suggest that
			if (($token = __gettoken ())->[T_TOKENTYPE] != SEMICOLON) {
				$ret = $channel->syslog ($token->[T_TOKEN]) or __warn ($ret);
				__slurp_semicolon ();
			}
			next;
		};
		($_token eq 'null') && do {
			$ret = $channel->output ($_token) or __warn ($ret); 
			__slurp_semicolon ();
			next;
		};
		($_token eq 'severity') && do {
			my @args = ( NAME => __gettoken ()->[T_TOKEN]);
			# check to see if there is a debug level
			if (($token = __gettoken ())->[T_TOKENTYPE] != SEMICOLON) {
				push (@args, (LEVEL => $token->[T_TOKEN]));
				__slurp_semicolon ();
			}
			$ret = $channel->severity (@args) or __warn ($ret);
			next;
		};
		($_token =~ /^print-(category|severity|time)$/) && do {
			# convert into method name
			$_token =~ s/-/_/g;
			$ret = $channel->$_token (__gettoken ()->[T_TOKEN]) 
				or __warn ($ret);
			__slurp_semicolon ();
			next;
		};
		die (Unix::Conf->_err ('__parse_channel', "`$_token' illegal channel directive"));
	}

	__slurp_semicolon ();
	return (1);
}

sub __parse_category ($)
{
	my $logging = $_[0];
	my ($ret, $channel, $category, @channels, @pos);

	$category = __gettoken ()->[T_TOKEN];
	__slurp_openbr ();
	while (($channel = __gettoken ()->[T_TOKEN]) ne '}') {
		if ($logging->__valid_channel ($channel)) {
			push (@channels, $channel);
		}
		else {
			die (Unix::Conf->_err ('__parse_category', "`$channel' undefined channel"));
		}
		__slurp_semicolon ();
	}
	__slurp_semicolon ();
	$ret = $logging->category ($category, \@channels) or __warn ($ret);
	return (1);
}

sub __parse_trustedkeys
{
	my ($tk, $token, $ret);

	$tk = $Conf->new_trustedkeys () or __die ($tk);
	__slurp_openbr ();
	until (($token = __gettoken ())->[T_TOKENTYPE] == CLOSEBRACE) {
		$ret = $tk->add_key (
			$token->[T_TOKEN],
			__gettoken ()->[T_TOKEN], __gettoken ()->[T_TOKEN], 
			__gettoken ()->[T_TOKEN], __gettoken ()->[T_TOKEN],
		) or __warn ($ret);
		__slurp_semicolon ();
	}
	__slurp_semicolon ();
	return ($tk);
}

sub __parse_key
{
	my ($token, $name, $algo, $secret, $obj);
	$name = __gettoken ()->[T_TOKEN];
	__slurp_openbr ();
	__die ('__parse_key', "expected `algorithm' got `$token->[T_TOKEN]'")
		if (($token = __gettoken ())->[T_TOKEN] ne 'algorithm');
	$algo = __gettoken ()->[T_TOKEN];
	__slurp_semicolon ();
	__die ('__parse_key', "expected `secret' got `$token->[T_TOKEN]'")
		if (($token = __gettoken ())->[T_TOKEN] ne 'secret');
	$secret = __gettoken ()->[T_TOKEN];
	__slurp_semicolon (); __slurp_closebr (); __slurp_semicolon ();
	
	$obj = $Conf->new_key (NAME => $name, ALGORITHM => $algo, SECRET => $secret)
		or __die ($obj);
	return ($obj);
}

sub __parse_controls
{
	my ($token, $controls, $ret);
	$controls = $Conf->new_controls () or __die ($controls);
	__slurp_openbr ();
	until (($token = __gettoken ())->[T_TOKENTYPE] == CLOSEBRACE) {
		if ($token->[T_TOKEN] eq 'inet') {
			my ($addr, $port, $allow);
			$addr = __gettoken ()->[T_TOKEN];
			__warn ('__parse_controls', "expected `port' got `$token->[T_TOKEN]'")
				unless (__gettoken ()->[T_TOKEN] eq 'port');
			$port = __gettoken ()->[T_TOKEN];
			__warn ('__parse_controls', "expected `allow' got `$token->[T_TOKEN]'")
				unless (__gettoken ()->[T_TOKEN] eq 'allow');
			__slurp_openbr ();
			# NOTE
			# __parse_acl () will read in the trailing semicolon
			# ideally it shouldn't unless it is a named acl
			$allow = __parse_acl () or __warn ($allow);
			# invoke method only if the __parse_acl call above suceeded
			$ret = $controls->inet ($addr, $port, $allow) or __warn ($ret)
				if ($allow);
		}
		elsif ($token->[T_TOKEN] eq 'unix') {
			my ($path, $perm, $owner, $group);
			$path = __gettoken ()->[T_TOKEN];
			__warn ('__parse_controls', "expected `perm' got `$token->[T_TOKEN]'")
				unless (__gettoken ()->[T_TOKEN] eq 'perm');
			$perm = __gettoken ()->[T_TOKEN];
			__warn ('__parse_controls', "expected `owner' got `$token->[T_TOKEN]'")
				unless (__gettoken ()->[T_TOKEN] eq 'owner');
			$owner = __gettoken ()->[T_TOKEN];
			__warn ('__parse_controls', "expected `group' got `$token->[T_TOKEN]'")
				unless (__gettoken ()->[T_TOKEN] eq 'group');
			$group = __gettoken ()->[T_TOKEN];
			$ret = $controls->unix ($path, $perm, $owner, $group) or __warn ($ret);
			__slurp_semicolon ();
		}
		else {
			return (
				Unix::Conf->_err (
					'__parse_controls', 
					"unrecognized token `$token->[T_TOKEN]' in controls"
				)
			);
		}
	}
	__slurp_semicolon ();
	return ($controls);
}

my @server_statements = qw (
	bogus
	support-ixfr
	transfers
	transfer-format
);

sub __parse_server
{
	my ($token, $_token, $server, $ret);

	$server = $Conf->new_server ( NAME => __gettoken ()->[T_TOKEN] )
		or __die ($server);
	__slurp_openbr ();
	until (($token = __gettoken ())->[T_TOKENTYPE] == CLOSEBRACE) {
		no strict 'refs';
		$_token = $token->[T_TOKEN];
		local $" = "|";
		($_token =~ /^(@server_statements)$/)	&& do {
			my $meth = $1;
			$meth =~ tr/-/_/;
			$ret = $server->$meth (__gettoken ()->[T_TOKEN])
				or __warn ($ret);
			goto SEMICOLON;
		};
		($_token eq 'keys')				&& do {
			my @keys;
			__slurp_openbr ();
			until (($token = __gettoken ())->[T_TOKENTYPE] == CLOSEBRACE) {
				push (@keys, $token->[T_TOKEN]);
				__slurp_semicolon ();
			}
			$ret = $server->keys (@keys) or __warn ($ret);
		};
SEMICOLON:
		__slurp_semicolon ();
	}
	__slurp_semicolon ();
	return ($server);
}


############################################ Lexer ###################################################

# don't use [:posix:], as we may make this code compatible
# later with perl version below 5.6.0.
our $rHex			= qr/[0-9a-fA-F]{0,4}/;
our $rDD 			= qr/[0-2]?[0-9]?[0-9]/;

our $rIPv4			= qr/(?:$rDD\.){3}$rDD/o;
#our $rIPv6			= qr/(?:$rHex:){1,7}$rHex/o;
our $rIPv4_PREFIX 	= qr($rDD(\.$rDD){0,3}/[1-3]?[0-9])o;

my @LexStack;
# this function is called when recursive calls to __gettoken ()
# when a comment has been encountered. So after storing
# the original positional info, we store the info after
# the comment has been matched. This is needed if this state
# (//|#)<newline>. For // & # tokens are read in until newline.
# so we need to unget the newline, which is treated as TWS.
# As after matching '//' or '#'  __gettoken () does
# not store positional info which is only stored just
# before returning the token. so push the stack, and store the
# positional info after, which is used to unget the newline to
# //|#..
sub __push_lexstack () 
{
	push (@LexStack, [ $R_Offset, $_Lineno, $L_Offset ]);  
	$L_Offset = pos ($Line); 
	$R_Offset = length ($$RString);
	$_Lineno  = $Lineno;
}

sub __pop_lexstack ()  { ($R_Offset, $_Lineno, $L_Offset) = @{pop (@LexStack)}; }

# forward decl for recursive calls
sub __gettoken ();

# __gettoken () handles comments by parsing them, by calling itself
# recursively to get tokens. While doing so it enters L_INCOMMENT state
# where whitespace, newlines are returned, and position info is not
# updated. Comments are returned only when the parser is not in the
# P_INDIRECTIVE state. While lexing tokens, __gettoken () also carves
# up in the input stream part for a directive, comments and all, and 
# stores in $$RString. This is used to recreate the directive as it is,
# in case it is not changed. Comments between directives are treated
# as dummy directives. Whitespace following directives (comments), are
# stored in $$TWS (traling whitespace), and stored alongwith the $$RString 
# in the directive object. All this hoopla is so that we can modify as 
# little of the configuartion file as possible.
sub __gettoken () 
{
	my $token;

GETLOOP:
	while (1) {
		# $Line empty
		(!defined ($Line) || $Line =~ m/\G\z/gc)	&& do {
			unless (__readline ()) {
				$token =  [EOF, undef, $R_Offset, $_Lineno, $L_Offset];
				last GETLOOP;
			}
		};

		# suck up all whitespace and store it in $$TWS if we are
		# outside a directive. This is attached to the directive
		# object, so that we can modify as little of a file as
		# possible. Comments outside directives are also treated
		# as directives (dummy) and whitespace following it is also
		# preserved. When a comment is deleted, $$TWS following
		# it is deleted. TWS stands for trailing whitespace
		($ParserState == P_NORMAL && $LexerState == L_NORMAL) && do {
			while ($Line =~ m/\G(\s+)/gc) {
				$$TWS .= $1;
				# readline again
				if ($Line =~ m/\G\z/gc) {
					unless (__readline ()) {
						$token = [EOF, undef, $R_Offset, $_Lineno, $L_Offset];
						last GETLOOP;
					}
				}
			}
		};

		# whitespace is needed only when inside a comment
		# as we preserve comments only outside directives.
		$Line =~ m/\G([ \t]+)/gc	&& do {
			$$RString .= $1;
			# return as we have been called recursively by
			# __gettoken () and don't need to unget info.
			if ($LexerState == L_INCOMMENT) {
				$token =  [_WHITESPACE, $1];
				last GETLOOP;
			}
			next;
		};

		# newline is needed only when inside a comment
		# as we preserve comments only outside directives.
		# NEWLINE is needed to terminate # and // style
		# comments. that is why it is not clubbed with
		# _WHITESPACE above.
		$Line =~ m/\G(\n)/gc		&& do {
			$$RString .= $1;
			# return as we have been called recursively by
			# __gettoken () and don't need to unget info.
			if ($LexerState == L_INCOMMENT) {
				$token = [NEWLINE, $1, $R_Offset, $_Lineno, $L_Offset];
				last GETLOOP;
			}
			next;
		};

		$Line =~ m/\G("[^"]+")/gc	&& do {
			$$RString .= $1;
			$token = [STRING, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m[\G(#|//)]gc			&& do {
			$$RString .= $1;
			# if we are already inside a comment do not
			# recognise # or // as starting a comment.
			# else we will start eating up tokens till newline
			# while our calling invocation of __gettoken () is 
			# doing the same.
			if ($LexerState == L_INCOMMENT) {
				$token = [UNRECOGNISED, $1];
				last GETLOOP;
			}

			my $comment = $1;
			my $_token;
			# this makes __gettoken () return whitespace, newlines etc.
			# which it normally doesn't
			$LexerState = L_INCOMMENT;
			# eat data till but not including end of line.
			__push_lexstack ();
			while (1) {
				$_token = __gettoken ();
				last if ($_token->[T_TOKENTYPE] == EOF);
				if ($_token->[T_TOKENTYPE] == NEWLINE) {
					# unget so that the trailing newline will
					# be read as TWS in the next call.
					__ungettoken ($_token);
					last;
				}
				$comment .= $_token->[T_TOKEN];
			}
			__pop_lexstack ();
			$LexerState = L_NORMAL;
			# comment eaten but do not return it if
			# we are inside a directive
			next if ($ParserState == P_INDIRECTIVE);
			$token = [COMMENT, $comment, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m[\G(\*/)]gc		&& do {
			$$RString .= $1;
			$token =  [CLOSECCOMMENT, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m[\G(/\*)]gc		&& do {
			$$RString .= $1;
			# do not recognise start of C style comment if
			# already within one.
			if ($LexerState == L_INCOMMENT) {
				$token = [UNRECOGNISED, $1];
				last GETLOOP;
			}

			my $_token;
			my $comment = $1;
			$LexerState = L_INCOMMENT;
			__push_lexstack ();
			while (1) {
				$_token = __gettoken ();
				__die ("__gettoken", "Unexpected EOF inside comment, aborting")
					if ($_token->[T_TOKENTYPE] == EOF);
				$comment .= $_token->[T_TOKEN];
				last if ($_token->[T_TOKENTYPE] == CLOSECCOMMENT);
			}
			__pop_lexstack ();
			$LexerState = L_NORMAL;
			next if ($ParserState == P_INDIRECTIVE);
			$token = [COMMENT, $comment, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(;)/gc			&& do {
			$$RString .= $1;
			$token = [SEMICOLON, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(\{)/gc		&& do {
			$$RString .= $1;
			$token = [OPENBRACE, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(\})/gc		&& do {
			$$RString .= $1;
			$token = [CLOSEBRACE, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(!)/gc			&& do {
			$$RString .= $1;
			$token = [EXCLAMATION, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(\*)/gc		&& do {
			$$RString .= $1;
			$token = [ASTERISK, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		# this regex is not perfect, but passes for now. change to
		# something that matches perfectly, else use code to validate
		# and reset the pos to before on failure.
		$Line =~ m/\G($rIPv4_PREFIX)/ogc	&& do {
			$$RString .= $1;
			$token = [IP_PREFIX, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		# this regex is not perfect, but passes for now. change to
		# something that matches perfectly, else use code to validate
		# and reset the pos to before on failure.
		$Line =~ m/\G($rIPv4)/ogc 	&& do {
			$$RString .= $1;
			$token = [IPv4, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		# make sure the digits are followed by a non word char.
		# if it is followed by a word char, should be a WORD.
		# we can't put the WORD regex before NUMBER as that would
		# match always against a NUMBER.
		$Line =~ m/\G([0-9]+)(?=\W)/gc	&& do {
			$$RString .= $1;
			$token = [NUMBER, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G([a-zA-Z0-9._-]+)/gc && do {
			$$RString .= $1;
			# add code to check and return a token type
			# of size spec if the parser expects one.
			$token = [WORD, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};

		$Line =~ m/\G(\S+)/gc 		&& do {
			$$RString .= $1;
			$token = [UNRECOGNISED, $1, $R_Offset, $_Lineno, $L_Offset];
			last GETLOOP;
		};
	}

	# store the posinfo for this token, which
	# will be returned with the next token as the
	# position to backup to, in case caller wants
	# to unget. Do so only if lexer is not in the
	# middle of a recursive call to parse comments.
	# also after the last token $RString is undef. so
	# check for that condition too.
	# if ($LexerState == L_NORMAL && defined ($RString)) {
	if (defined ($RString)) {
		$L_Offset = pos ($Line); 
		$R_Offset = length ($$RString);
		$_Lineno  = $Lineno;
	}
	return ($token);
}

sub __readline ()
{
	unless (defined ($Line = $FH->getline ())) {
		__die ("__readline", "Unexpected EOF when token expected, aborting")
			if ($ParserState == P_INDIRECTIVE);
		return;
	}
	$Lineno = $FH->lineno ();
	return (1);
}

# provides one level of unget.
# get the position info from token and backup to
# that point in the input stream, where the last
# successfully lex'ed and accepted token ends.
sub __ungettoken ($) 
{
	my $token = $_[0]; 
	$$RString = substr ($$RString, 0, $token->[T_ROFFSET]);
	$FH->lineno ($token->[T_LINENO] - 1);
	__readline ();
	pos ($Line) = $token->[T_LOFFSET];
}

1;
