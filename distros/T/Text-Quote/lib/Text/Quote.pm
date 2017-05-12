package Text::Quote;
$Text::Quote::VERSION = '0.32';
use 5.006;
use strict;
use warnings;
use Compress::Zlib;
use MIME::Base64;
use Carp();
use Carp::Assert;
use warnings::register;


=head1 NAME

Text::Quote - Quotes strings as required for perl to eval them back correctly

=head1 SYNOPSIS

	use Text::Quote;

	my @quotes=map{$quoter->quote($_,indent=>6,col_width=>60)}('
		"The time has come"
			the	walrus said,
		"to speak of many things..."
	',"\0\1\2\3\4\5\6\a\b\t\n\13\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35\36\37",
	("\6\a\b\t\n\13\f\r\32\e\34" x 5),2/3,10,'00');
	for my $i (1..@quotes) {
		print "\$var$i=".$quotes[$i-1].";\n";
	}

Would produce:

	$var1=qq'"The time has come"\n\tthe\twalrus said,\n\t"to speak of man'.
	      qq'y things..."';
	$var2="\0\1\2\3\4\5\6\a\b\t\n\13\f\r\16\17\20\21\22\23\24\25\26\27".
	      "\30\31\32\e\34\35\36\37";
	$var3=("\6\a\b\t\n\13\f\r\32\e\34" x 5);
	$var4=0.666666666666667;
	$var5=10;
	$var6='00';


=head1 DESCRIPTION

Text::Quote is intended as a utility class for other classes that need to be able
to produce valid perl quoted strings.  It posses routines to determine the ideal quote
character to correctly quote hash keys, to correctly quote and encode binary strings.

This code was inspired by an analysis of L<Data::Dump|Data::Dump> by Gisle Aas.
In some cases it was much more than inspired. :-)

=head1 METHODS

=cut

# This code derives from a number of sources
# 1. Data::Dump   by Gisle Aas
# 2. MIME::Base64 by Gisle Aas
# Its primary intention is to isolate out the basic functionality
# of correctly, succintly and neatly quoting a non reference
# scalar variable.
#
# In this context "quoting" has a looser definition than the standard
# perl idea.  A string is considered by this module to be correctly
# quoted IFF the result of _evaling_ the resultant "quoted" text produces
# the exact same string.
# ie:
# my $quoted=Text::Quote->quote($string);
# my $result=eval($string);
# print "Text::Quote ",($string eq $result) ? "works!" : "sucks! :(","\n";
#
##
sub _stamp {
	my $i    = 1;
	my @list = ('----');
	while ( my ( $package, $filename, $line, $subroutine ) = caller($i) ) {
		push @list, "($i) $subroutine";
		$i++;
	}

	#warn $subroutine."\n";
	#warn join ( "\n", @list ), "\n";
}








# adds the method call and quoting symbols around a block of text.
sub _textquote_format_method {
	my ( $self, $method, $str, %opts ) = @_;

	$method .= '(' . ( ( $method eq "pack" ) ? "'H*'," : "" );
	$method = ( ref($self) || $self ) . "->" . $method
		unless $method =~ /^pack/;
	$opts{leading} = length($method);
	#$opts{indent} += 2;
	return $method . $self->quote_simple( $str, %opts, is_encoded => 1 ) . ")";

}

sub _textquote_compress {
	my ( $self, $str, %opts ) = @_;
	return unless $str;
	my $method = "";
	( $method, $str ) = $self->_textquote_encode64( Compress::Zlib::compress($str), %opts );
	$method = "decompress64";
	return wantarray ? ( $method, $str ) : $self->_textquote_format_method( $method, $str, %opts );
}

# Encodes a string in base64
sub _textquote_encode64 {
	my ( $self, $str, %opts ) = @_;
	$str = MIME::Base64::encode( $str, "" );
	return
		wantarray
		? ( "decode64", $str )
		: $self->_textquote_format_method( "decode64", $str, %opts );
}


#
# _textquote_encode
# Encodes a string, either by compression or by pack
#
sub _textquote_encode {

	my ( $self, $str, %opts ) = @_;

	$self->_stamp;
	my $method;
	my $encoded;
	my $encode_at =defined($opts{encode_at})?$opts{encode_at}:$self->quote_prop("encode_at");
	if ( length($str)*2 > $encode_at  ) {
		( $method, $encoded ) = $self->_textquote_encode64( $str, %opts );
	} else {
		$method = "pack";
		$encoded = unpack( "H*", $str );
	}

	return (wantarray)
		? ( $method, $encoded )
		: $self->_textquote_format_method( $method, $encoded, %opts );
}

#
# Tries to find a repeated pattern in the text
#
sub _textquote_pattern {    #not a pattern, really a multiple
	my $self = shift;

	$self->_stamp;
	local $_ = shift;
	return unless $_;
	my %opts = @_;

	return if $opts{no_repeat};

	# Check for repeated string
	my $rl = ( exists( $opts{repeat_len} ) ) ? $opts{repeat_len} : $self->quote_prop("repeat_len");

	if (/\A(.{1,$rl}?)(\1*)\z/s) {

		my $base = $self->quote_simple($1);

		my $repeat = length($2) / length($1) + 1;

		return "($base x $repeat)";
	}

	return;
}


#
# Escapes a string
# takes the string, the type of quote (qq or q) and the symbol used
#
sub _textquote_escaped {
	my $self = shift;

	$self->_stamp;
	local $_ = ( my $str = shift );
	my $type  = shift;
	my $qsymb = shift;

	# Now we need to escape our quote char in string.
	( my $escaped = $qsymb ) =~ s/(.)/\\$1/g;

	#and escape variables and our quote chars
	if ( "qq" eq $type ) {
		s/([$escaped\\\@\$])/\\$1/g;
	} else {    # dont have to escape variables
		s/([$escaped\\])/\\$1/g;
	}

	# fast exit for straight chars
	if ($self->quote_prop("encode_high")) {
		return ($_) unless /[^\t\040-\176]/;
	} else {
		return ($_) unless /[^\t\040-\377]/;
	}

	my $esc_class = $self->quote_prop("esc_class");
	my $esc_chars = $self->quote_prop("esc_chars");
	s/($esc_class)/$esc_chars->{$1}/g;    # escape interpolatable symbols

	# octal escapes -- harder to read but shorter
	# no need for 3 digits in escape for these
	s/([\0-\037])(?!\d)/'\\'.sprintf('%o',ord($1))/eg;

	# still go for the low ones cause there could be a digit following,
	# either way use 3 digits
	s/([\0-\037\177-\377])/'\\'.sprintf('%03o',ord($1))/eg;

	return $_;
}

sub _textquote_number {

	#returns undef or the value of the number

	my ( $self, $num ) = @_;

	if ( defined $num && $num =~ /\A-?(?:0|[1-9]\d{0,8})(\.\d{0,18})?\z/ ) {
		return $num;
	}
	return;
}




=head2 quote(STR,OPTS)

Quotes a string.  Will encode or compress or otherwise change the strings representation
as the options specify. If an option is omitted the class default is used if it exists then
an internal procedure default is used.

Normal behaviour is as follows

=over 4

=item Numbers

Not quoted

=item Short Repeated Substr

Converted into a repeat statement C<($str x $repeat)>

=item Simple Strings

Single quoted, or double quoted if multiline or containing small numbers of other
control characters (tabs excluded).

=item Binary Strings

Converted into hex using L<pack()|pack()> or if larger into Base64 using L<decode64()|"decode64(STR)">

=item Large Strings

Converted to a call to L<decompress64()|"decompress64(STR)">.

=back

The output and OPTS will passed on to L<quote_columns()|"quote_columns(STR,QB,QE,OPTS)"> for formatting if it
is multiline.  No indentation of the first line is done.

See L<init()|init()> for options.

=cut


sub quote {

	# Main routine, the essence of this is that a returns back a quoted construct
	# it calls all the others as it needs/or can depending on the size of the string,
	# the type of data it contains and any options passed.This can include reducing the
	# the string to a ("ABC" x $count) or conterting it to a different format, such as
	# hex or base64, or even compressing it.
	my $self = shift->_self_obj;
	my $str = shift(@_);

	$self->_stamp;


	return 'undef' unless defined $str;
	$str="".$str;

	Carp::croak "cant use odd number of parameters:" . scalar(@_)
		unless @_ % 2 == 0;
	my %opts = @_;

	my $compress_at =
		defined( $opts{compress_at} ) ? $opts{compress_at} : $self->quote_prop("compress_at");
	my $encode_at = defined( $opts{encode_at} ) ? $opts{encode_at} : $self->quote_prop("encode_at");
	my $repeat_at =
		defined( $opts{repeat_at} ) ? $opts{repeat_at} : $self->quote_prop("repeat_at");

	my $ret = $self->_textquote_number($str);
	return $ret if defined $ret;

	$opts{indent} ||= 0;

	if ( $compress_at && length($str) > $compress_at ) {

		my $ret = $self->_textquote_compress( $str, %opts );

		$opts{reqs}->{__PACKAGE__}++ if $opts{reqs};

		return $ret if $ret;
	}

	if ( $repeat_at && length($str) > $repeat_at ) {

		my $ret = $self->_textquote_pattern( $str, %opts );
		return $ret if defined $ret;

	}

	my ( $qq, $qb, $qe, $nqq ) = $self->best_quotes( $str, %opts );
	my $escaped = $self->_textquote_escaped( $str, $qq, $qb . $qe );

	if ( $encode_at
		&& ( length($escaped) > $encode_at
		&& length($escaped) > ( length($str) * 2 ) ) )
	{

		# too much binary data, better to represent as a hex string?
		# Base64 is more compact than hex when string is longer than
		# 17 bytes (not counting any require statement needed).
		# But on the other hand, hex is much more readable.
		my ( $method, $str ) = $self->_textquote_encode( $str, %opts );
		$opts{reqs}->{__PACKAGE__}++ if $method && $method ne "pack" && $opts{reqs};
		return $self->_textquote_format_method( $method, $str, %opts ) if $method;
	}

	return $self->quote_columns( $escaped, ( $nqq ? $qq . $qb : $qb ), $qe, %opts );

}


=head2 quote_simple(STR,OPTS)

Quotes a string.  Does not attempt to encode it, otherwise the same L<quote()|"quote(STR,OPTS)">

=cut

sub quote_simple {
	my $self = shift(@_);
	my $str  = "".shift(@_);
	my %opts = @_;

	$self->_stamp;
	my $ret = $self->_textquote_number($str);
	return $ret if $ret;
	my ( $qq, $qb, $qe, $nqq ) =
		( $opts{is_encoded} ? ( 'q', "'", "'", 0 ) : $self->best_quotes( $str, %opts ) );
	my $escaped = $self->_textquote_escaped( $str, $qq, $qb . $qe );
	return $self->quote_columns( $escaped, ( $nqq ? $qq . $qb : $qe ), $qe, %opts );
}

=head2 quote_key(STR,OPTS)

Quotes a string as though it was a hash key. In otherwords will only quote it
if it contains whitespace, funky characters or reserved words.

See L<init()|init()> for options.

=cut


sub quote_key {
	my $self = shift(@_);
	my $key  = "".shift(@_);
	my %opts = @_;
	$self->_stamp;

	#$key="$key";
	my $rule=$self->quote_prop("key_quote");
	return "''" if $key eq "";
	unless ($rule) {
		return $key;
	} elsif ($rule eq 'auto') {
		if (  $key =~ /\A(?:-[A-Za-z]+\w*|[_A-Za-z]+\w*|\d+)\z/ && !$self->quote_prop("key_quote_hash")->{$key} ) {
			return $key;
		} else {
			return $self->quote_simple( $key, %opts );
		}
	} else {
		return $self->quote_simple( $key, %opts );
	}
}

=head2 quote_regexp(STR)

Quotes a regexp or string as though it was a regexp, includes the qr operator.
Will automatically select the appropriate quoting char.

=cut

sub quote_regexp {
	my $self = shift;
	my $rex  = "".shift(@_);

	# a stringified regex will look like (?-xism: ... )
	# when it was created by an optionless  //
	# this means that if we do bf_dump(eval(bf_dump(qr/.../)))
	# we dont get the same regex (it will be nested again)
	# so we strip the added layer off if it is (?-xism:
	# note this means the regexp is safe:had there been any options
	# the prefix would be different and we would ignore it.
	if ( substr( $rex, 0, 8 ) eq "(?-xism:" ) {
		$rex = substr( $rex, 8, length($rex) - 9 );
	}

	# find the ideal quote symbol for the regex
	my ( $qq, $qb, $qe, $nqq ) = $self->best_quotes( $rex, chars => [qw( / ! {} - & ; )] );
	my $qs = quotemeta $qb . $qe;

	# escape any quote symbols in the regex, ideally there shouldnt
	# be any because of _quote_best
	$rex =~ s/([$qs])/\\$1/g;
	return "qr$qb$rex$qe";
}

=head2 quote_columns(STR,QB,QE,OPTS)

Takes a preescaped string and chops it into lines with a specific maximum length
each line is independantly quoted and concatenated together, this allows the column
to be set at a precise indent and maximum width. It also handles slicing the string
at awkward points, such as in an escape sequence that might invalidate the quote.
Note the first line is not indented by default.

STR is the string to quote. QB is the begin quote pattern. QE is end quote pattern.
OPTS can be

	col_width    (defaults 76) Width of text excl. quote symbols and cat char
	leading      (defaults 0)  Width of first line offset.
	indent       (defaults 0)  Width of overall indentation
	indent_first (defaults 0)  Whether the first line is indented.

=cut


sub quote_columns {
	my $self=shift;
	my $str="".shift(@_);
	my ($qb, $qe, %opts ) = @_;

	$self->_stamp;
	my @rows;
	my $line   = "";
	my $pos    = 0;
	my $width  = $opts{col_width} || 76;
	my $lead   = $opts{leading} || 0;
	my $indent = $opts{indent} || 0;

	#$lead -= 2 if $lead > 2; #???
	my $len = $width - $lead;
	while ( $str =~ /\G([^\\]{1,$len}|\\\d{1,3}|\\.)/gs ) {


		if ( length($line) + length($1) > $width - $lead ) {
		    push @rows, $line;
		    $lead = 0 if ($lead);
		    $line = "";
		}
		$line .= $1;
		$len = $width - $lead - length($line) || 1;
		$pos = pos($str);

		#warn "$pos $len $line\n";
	}
	push @rows, $line if $line;
	die "pos:" . $pos . "\n" . substr( $str, $pos ) . "\n"
		if $pos != length($str);

	#print $str;
	return $qb . join ( $qe . ".\n" . ( " " x $indent ) . $qb, @rows ) . $qe;
}



=head2 decompress64(STR)

Takes a compressed string in quoted 64 representation and decompresses it.

=cut

# takes a compressed quoted64 string and dequotes it
sub decompress64 {
	my ( $self, $str ) = @_;
	return Compress::Zlib::uncompress( $self->decode64($str) );
}

=head2 decode64(STR)

Takes a string encoded in base 64 and decodes it.

=cut

# takes a quoted64 string and dequotes it
sub decode64 {
	my ( $self, $str ) = @_;
	return MIME::Base64::decode($str);
}

=head2 best_quotes(STR,OPTS)

Selects the optimal quoting character and quoting type for a given string.

Returns a list

  $qq          - Either 'q' or 'qq'
  $qbegin      - The beginning quote character
  $qend        - The ending quote character
  $needs_type  - Whether $qq is needed to make the quotes valid.

OPTS may include the normal options as well as

  chars : a list of chars (or pairs) to be allowed for quoting.

=cut

sub best_quotes {

	# is capable of deciding if something should be single
	# quoted, or double quoted and which quote character to
	# use.
	# A string may be single quoted if it contains no control
	# characters or line breaks.
	# returns ( $qsym, $qq, $qbegin, $qend,$fqbegin )
	# needs a complete rework
	my $self = shift;

	$self->_stamp;
	local $_ = "".shift(@_);
	my %opts = @_;

	warnings::warnif("Undef passed at _textquote_best") unless defined($_);
	warnings::warnif("Reference passed at _textquote_best") if ref $_;

	# Use double quotes if we have non tab control chars or high bit chars
	# (\n included)
	my $qq = exists( $opts{use_qq} ) ? $opts{use_qq} :
			$self->quote_prop('encode_high') ? /[^\t\040-\176]/ : /[^\t\040-\377]/;

	my @chars;    # chars we can use for quoting with
	if ( $opts{chars} ) {    # Did they supply a list of choices?
		@chars = @{ $opts{chars} };    # use them
	} else {                           # Use the defaults
		@chars = @{ $self->quote_prop("quote_chars") };
		unshift @chars, ($qq) ? qw( " ' ) : qw( ' " );
	}

	#print "Using @chars\n";
	my $char_class = "[" . join ( "", map { quotemeta } @chars ) . "]";
	my %counts;
	@counts{@chars} = (0) x @chars;

	$counts{$1}++ while /($char_class)/g;

	{
		no warnings;
		$counts{'{}'} = $counts{'{'} + $counts{'}'} if exists $counts{'{}'};
		$counts{'[]'} = $counts{'['} + $counts{']'} if exists $counts{'[]'};
		$counts{'()'} = $counts{'('} + $counts{')'} if exists $counts{'()'};
		$counts{'<>'} = $counts{'<'} + $counts{'>'} if exists $counts{'<>'};
	}
	delete $counts{$_} foreach qw' { } [ ] ( ) < >';

	my $qsym   = shift @chars;
	my $low    = $counts{$qsym};
	my $lowsym = $qsym;
	while ( $low > 0 ) {
		last unless @chars;
		$qsym = shift @chars;
		if ($counts{$qsym} < $low) {
			$low = $counts{$qsym};
			$lowsym=$qsym;
		}
	}
	$qsym=$lowsym;

	my $qbegin = substr( $qsym, 0,  1 );
	my $qend   = substr( $qsym, -1, 1 );
	my $needs_type;
	if ($qq) {
		$qq = 'qq';
		$needs_type = $qbegin eq '"' ? 0 : 1;
	} else {
		$qq = 'q';
		$needs_type = $qbegin eq "'" ? 0 : 1;
	}

	return ( $qq, $qbegin, $qend, $needs_type );
}

=head1 OVERIDE METHODS

These methods are defined by Text::Quote for when it runs as a stand alone.
Normally they would be overriden by child classes, or alternatively used by
the child class.

=cut

BEGIN {

	# things we need to escape
	#from G.A.

	my %esc_chars = (
		"\a" => "\\a",
		"\b" => "\\b",
		"\t" => "\\t",
		"\n" => "\\n",
		"\f" => "\\f",
		"\r" => "\\r",
		"\e" => "\\e",
	);

	my %known_keywords = map { $_ => 1 }
		qw( __FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ AUTOLOAD BEGIN CORE
		DESTROY END EQ GE GT INIT LE LT NE abs accept alarm and atan2 bind
		binmode bless caller chdir chmod chomp chop chown chr chroot close
		closedir cmp connect continue cos crypt dbmclose dbmopen defined
		delete die do dump each else elsif endgrent endhostent endnetent
		endprotoent endpwent endservent eof eq eval exec exists exit exp fcntl
		fileno flock for foreach fork format formline ge getc getgrent
		getgrgid getgrnam gethostbyaddr gethostbyname gethostent getlogin
		getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid
		getpriority getprotobyname getprotobynumber getprotoent getpwent
		getpwnam getpwuid getservbyname getservbyport getservent getsockname
		getsockopt glob gmtime goto grep gt hex if index int ioctl join keys
		kill last lc lcfirst le length link listen local localtime lock log
		lstat lt m map mkdir msgctl msgget msgrcv msgsnd my ne next no not oct
		open opendir or ord pack package pipe pop pos print printf prototype
		push q qq qr quotemeta qw qx rand read readdir readline readlink
		readpipe recv redo ref rename require reset return reverse rewinddir
		rindex rmdir s scalar seek seekdir select semctl semget semop send
		setgrent sethostent setnetent setpgrp setpriority setprotoent setpwent
		setservent setsockopt shift shmctl shmget shmread shmwrite shutdown
		sin sleep socket socketpair sort splice split sprintf sqrt srand stat
		study sub substr symlink syscall sysopen sysread sysseek system
		syswrite tell telldir tie tied time times tr truncate uc ucfirst umask
		undef unless unlink unpack unshift untie until use utime values vec
		wait waitpid wantarray warn while write x xor y);

=head2 init()

Takes a list of options and uses them to initialize the quoting object.
Defaults are provided if an option is not specified.

  esc_chars     : a hash of chars needing to be escaped and their escaped equivelent
  esc_class     : a regex class that matches the chars needing to be escaped
  quote_chars   : chars to be used as alternate quote chars
  key_quote_hash    : hash of words that must be quoted if used as a hash key
  repeat_len    : Length of pattern to look for in the string
  encode_high   : Set to 1 to cause high bits chars to be escaped. Dafaults to 0

Set the following to 0 to disable

  repeat_at     : Length of string at which Text::Quote should see if there is a repeated pattern.
  encode_at     : Length at which binary data should be quoted in Base64
  compress_at   : Length at which the string should be compressed using Compress::Zlib

These options are set using L<quote_prop()|quote_prop()>

=cut

	sub init {
		my $self = shift;

		$self->_stamp;
		my %hash = (
		    esc_chars => {%esc_chars},
		    esc_class => join ( "", "[", keys(%esc_chars), "]" ),

		    #Forbidden until best_quotes is fixed :
		    quote_chars    => [ qw; / ! |  - .  :  () [] {} ;, '#', ';' ],
		    key_quote_hash => {%known_keywords},
		    key_quote      => 'auto', #auto/true/false
		    repeat_len  => 20,     # maximum size of repeat sequence
		    repeat_at   => 20,     # number of chars before we even bother
		    encode_at   => 160,
		    compress_at => 512,    # number of chars at which we compress no matter what
		    encode_high => 0,
		    @_
		);
		$self->quote_prop( \%hash );
		return \%hash;
	}
}

=head2 new()

Creates a hash based object and calls L<init(@_)|init()> afterwards

=cut


sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->init(@_);
	return $self;
}


=head2 quote_prop()

As this class is intended to be subclassed all of its parameters are kept
and accessed through a single accessor.

This hash is normally stored as $obj->{Text::Quote} however should the default
class type not be a hash this method may be overriden to provide access to the
the Text::Quote proprty hash. Or even to redirect various properties elsewhere.

Called with no parameters it returns a reference to the property hash.
Called with a string as the only parameter it returns the value of that named property.
Called with a string as the first parameter and a value it will set the property
to equal the value and return the new value. Called with a reference as the only parameter
the passed value is substituted for the property hash.

=cut


#use Data::Dumper;
sub quote_prop {
	my $self = shift->_self_obj;
	#$self->_stamp;
	#print Dumper($self);
	my $pck = __PACKAGE__;

	return $self->{$pck} unless @_;


	my $prop = shift;
	if ( ref $prop ) {
		Carp::croak "Expecting HASH based property bag!"
		    unless UNIVERSAL::isa( $prop, "HASH" );
		return $self->{$pck} = $prop;
	}

	should( ref $self->{$pck}, "HASH" ) if DEBUG;

	warnings::warnif("Property '$prop' not known")
		unless exists( $self->{$pck}->{$prop} );

	$self->{$pck}->{$prop} = shift if @_;
	return $self->{$pck}->{$prop};

}

=head2 _self_obj()

This is a utility method to enable Text::Quote and its descendants the ability to
act as both CLASS and OBJECT methods.  Creates an object to act as a class object.

If called as an object method returns the object

If called as a class method returns a singleton, which is the result of calling
class->new(); The singleton is inserted into the calling classes package under
the global scalar $class::SINGLETON and is reused thereafter. The object is kept in
a closure for maximum privacy of the object data.

=cut


sub _self_obj {
	ref( $_[0] ) && return $_[0];
	no strict 'refs';
	#closure to keep singleton private from prying dumpers.
	#thank dan brook.
	unless (${ $_[0] . '::SINGLETON' }) {
		my $obj=$_[0]->new();
		my $sub=sub{$obj=shift if @_; $obj};
		${ $_[0] . '::SINGLETON' } = $sub;
	}
	return ${ $_[0] . '::SINGLETON' }->();
}

#print __PACKAGE__->quote([]);
#/|'"-,!([{#;.:

#exit;

=head1 INTENTION

I wrote this module to enable me to avoid having to put code for how to neatly output perl quoted
strings in a reasonable way in the same module as L<Data::BFDump|Data::BFDump>.  I've documented
it and packaged in the mind that others may find it useful, and or help me improve it.  I was thinking
for example that there are a number of modules with one form of quoting or another, be it SQL
statements or excel CSV quoting.  There are lots of modules (and ways) of reading these formats
but no one clear location for finding ones that output them.  Perhaps they could live here?
Feedback welcome.

=head1 TODO

Better synopsis.  Better Description.  More tests.

=head1 EXPORTS

None.

=head1 REPOSITORY

L<https://github.com/neilbowers/Text-Quote>

=head1 AUTHOR

Yves Orton, E<lt>demerphq@hotmail.comE<gt>

Parts by Gisle Aas

Additional testing and encouragement Dan Brook

=head1 CAVEAT

This module is currently in B<BETA> condition.  It should not be used in a
production enviornment, and is released with no warranty of any kind whatsoever.

Corrections, suggestions, bugreports and tests are welcome!

=head1 SEE ALSO

L<perl>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Yves Orton <yves@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
