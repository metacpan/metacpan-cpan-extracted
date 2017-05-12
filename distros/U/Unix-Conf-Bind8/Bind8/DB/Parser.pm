# Parse a Bind8 DB
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

package Unix::Conf::Bind8::DB;

use strict;
use warnings;
use Unix::Conf;
use Unix::Conf::Bind8::DB::Lib;

# 
my $ttl_pat = qr/(?:\d+[wdhms])+|\d+/oi;
my $type_pat = qr/SOA|A|NS|MX|CNAME|PTR/oi;
my $class_pat = qr/IN/oi;

my ($FH, @Parse_Stack, $DB_Origin, $DB, %Args, $Include_Encountered);

sub __pushfile () { push (@Parse_Stack, [ $FH ]);	}
sub __popfile ()  { ($FH) = @{pop (@Parse_Stack)}; }

# forward decl to suppress warning
sub __parse_loop ($$);

sub __parse_db ($)
{
	$DB = $_[0];

	# make the origin absolute.
	$DB_Origin = $DB->origin ();
	__parse_loop ($DB->fh (), $DB->origin ());
	# clean so we don't sync to db just because we read in the data
	# but don't do it if we encountered an $INCLUDE, as we delete
	# the include file and print all the data in this one.
	$DB->dirty (0) unless ($Include_Encountered);
	undef ($DB);
	return (1);
}

sub __die ($;$)
{
	die ($_[0])	if (@_ == 1);
	die (Unix::Conf->_err (sprintf ("$_[0]($FH:%s)",$FH->lineno ()), "$_[1]\n"))
}

sub __parse_loop ($$) 
{
	__pushfile ();
	$FH = $_[0];
	my $corigin = $_[1];
	my ($def_ttl, $line, @tokens);
	my ($token, $rtype, $ret);

	while (defined (($line = __getline ()))) {
		# this is for the method call at the end of this loop.
		no strict 'refs';
		($line =~ /^\$TTL(?:\s+)($ttl_pat+)(?:\s*)$/i)	&& do {
			$def_ttl = $1;
			next;
		};
		#
		($line =~ /^\$ORIGIN\s+([\w.-]+)\s*$/i) 			&& do {
			# if the argument to $ORIGIN is not absolute make it into one
			$corigin = __make_absolute ($corigin, $1);
			next;
		};
		# read in data and delete the file.
		($line =~ /^\$INCLUDE\s+(\S+)\s*(\S*)\s*$/)		&& do {
			# $DB->new_include ();;
			my ($fh, $origin);
			$fh = Unix::Conf->_open_conf (NAME => $1, SECURE_OPEN => 0) or 
				return ($fh);
			$origin = __make_absolute ($origin, $2);
			__parse_loop ($fh, $origin);
			$Include_Encountered = 1;
			next;	
		};

		@tokens = split (/\s+/, $line);
		# get label for the record
		$token = shift (@tokens);
		if ($token eq '@') {
			$Args{LABEL} = __make_relative ($DB_Origin, $corigin);
		}
		# __make_absolute only if label exists. otherwise
		# we will do it to the last label, which could
		# result in an error if it was empty.
		elsif ($token) {
			$Args{LABEL} = __make_relative ($DB_Origin, __make_absolute ($corigin, $token));
		}

		# if there was no label specifed, the last one used 
		# remains.

		# check to see if next token is TTL or CLASS.
		(($token = shift (@tokens)) =~ /^$ttl_pat$/)		&& do {
			$Args{TTL} = $token; $token = shift (@tokens);
		};
		($token =~ /^$class_pat$/)	&& do {
			$Args{CLASS} = $token; $token = shift (@tokens);
		};
		# at this point what we have must be the record type
		__die ('__parse_db', "illegal record type `$token'")
			unless ($token =~ /^$type_pat$/);
		$rtype = $token;
		if ($rtype =~ /soa/i) {
			__die ('__parse_loop', "SOA owner `$Args{LABEL}' not same as DB origin `$DB_Origin'")
				if (__make_absolute ($DB_Origin, $Args{LABEL}) ne $DB_Origin);
			($Args{AUTH_NS}, $Args{MAIL_ADDR}, $Args{SERIAL}, $Args{REFRESH},
				$Args{RETRY}, $Args{EXPIRE}, $Args{MIN_TTL}) = @tokens;
			$Args{AUTH_NS} 		= __make_relative ($corigin, $Args{AUTH_NS}); 
			$Args{MAIL_ADDR} 	= __make_relative ($corigin, $Args{MAIL_ADDR});
		}
		elsif ($rtype =~ /mx/i) {
			$Args{MXPREF} = shift (@tokens);
			$Args{RDATA} = __make_relative ($DB_Origin, __make_absolute ($corigin, shift (@tokens)));
		}
		# RDATA for A are not labels but IP addresses so don't try append with corigin
		elsif ($rtype =~ /a/i) {
			$Args{RDATA} = shift (@tokens);
		}
		else {
			$Args{RDATA} = __make_relative ($DB_Origin, __make_absolute ($corigin, shift (@tokens)));
		}
		# invoke as a subroutine but pass the object as the first
		# argument, method like.
		$ret = &{"new_\L$rtype\E"} ($DB, %Args) or __die ($ret);
	}
	__popfile ();
}

sub __getline
{
	while (<$FH>) {
		chomp;
		s/^(.*?);.*$/$1/;
		# get another line if no non white space chars after stripping comment
		next if ($_ !~ /\S/);
		if (s/^(.+)\(\s*$/$1/) {
			my $tmp;
			while (defined (($tmp = <$FH>))) {
				$tmp =~ s/^(.*?);.*$/$1/;
				$_ .= $tmp;
				last if (s/^([^)]+)\).*$/$1/);
			}
			# remove any newline added above in the while loop
			chomp;
		}
		return ($_);
	}
	return;
}

1;
