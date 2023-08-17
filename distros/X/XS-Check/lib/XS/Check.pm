package XS::Check;
use warnings;
use strict;
use Carp;
use utf8;
our $VERSION = '0.14';
use C::Tokenize '0.18', ':all';
use Text::LineNumber;
use File::Slurper 'read_text';
use Carp qw/croak carp cluck confess/;

#  ____       _            _       
# |  _ \ _ __(_)_   ____ _| |_ ___ 
# | |_) | '__| \ \ / / _` | __/ _ \
# |  __/| |  | |\ V / (_| | ||  __/
# |_|   |_|  |_| \_/ \__,_|\__\___|
#                                 

sub debugmsg
{
    my (undef, $file, $line) = caller ();
    printf ("%s:%d: ", $file, $line);
    print "@_\n";
}

sub get_line_number
{
    my ($o) = @_;
    my $pos = pos ($o->{xs});
    if (! defined ($pos)) {
	confess "Bad pos for XS text";
	return "unknown";
    }
    return $o->{tln}->off2lnr ($pos);
}

# Report an error $message in $var

sub report
{
    my ($o, $message) = @_;
    my $file = $o->get_file ();
    my $line = $o->get_line_number ();
    confess "No message" unless $message;
    if (my $r = $o->{reporter}) {
	&$r (file => $file, line => $line, message => $message);
    }
    else {
	warn "$file$line: $message.\n";
    }
}

# Match a call to SvPV

my $svpv_re = qr/
    (
	(?:$word_re(?:->|\.))*$word_re
    )
    \s*=[^;]*
    (
	SvPV(?:byte|utf8)?
	(?:x|_(?:force|nolen))?
    )
    \s*\(\s*
    ($word_re)
    \s*,\s*
    ($word_re)
    \s*\)
/x;

# Look for problems with calls to SvPV.

sub check_svpv
{
    my ($o) = @_;
    while ($o->{xs} =~ /($svpv_re)/g) {
	my ($match, $lvar, $svpv, $arg1, $arg2) = ($1, $2, $3, $4, $5);
	my $lvar_type = $o->get_type ($lvar);
	my $arg2_type = $o->get_type ($arg2);
	if ($o->{verbose}) {
	    debugmsg ("<$match> $lvar_type $arg2_type");
	}
	if ($lvar_type && $lvar_type !~ /\bconst\b/) {
	    $o->report ("$lvar not a constant type");
	}
	if ($arg2_type && $arg2_type !~ /\bSTRLEN\b/) {
	    $o->report ("$arg2 is not a STRLEN variable ($arg2_type)");
	}
	if ($svpv !~ /bytes?|utf8/) {
	    $o->report ("Specify either SvPVbyte or SvPVutf8 to avoid ambiguity; see perldoc perlguts");
	}
    }
}

# Best equivalents.

my %equiv = (
    #  Newxc is for C++ programmers (cast malloc).
    malloc => 'Newx/Newxc',
    calloc => 'Newxz',
    free => 'Safefree',
    realloc => 'Renew',
);

# Look for calls to malloc/calloc/realloc/free and suggest replacing
# them.

sub check_malloc
{
    my ($o) = @_;
    while ($o->{xs} =~ /\b((?:m|c|re)alloc|free)\s*\(/g) {
	# Bad function
	my $badfun = $1;
	my $equiv = $equiv{$badfun};
	if (! $equiv) {
	    $o->report ("(BUG) No equiv for $badfun");
	}
	else {
	    $o->report ("Change $badfun to $equiv");
	}
    }
}

# Look for a Perl_ prefix before functions.

sub check_perl_prefix
{
    my ($o) = @_;
    while ($o->{xs} =~ /\b(Perl_$word_re)\b/g) {
	$o->report ("Remove the 'Perl_' prefix from $1");
    }
}

# Regular expression to match a C declaration.

my $declare_re = qr/
    (
	(
	    (?:
		(?:$reserved_re|$word_re)
		(?:\b|\s+)
	    |
		\*\s*
	    )+
	)
	(
	    $word_re
	)
    )
    # Match initial value.
    \s*(?:=[^;]+)?;
/x;

# Read the declarations.

sub read_declarations
{
    my ($o) = @_;
    while ($o->{xs} =~ /$declare_re/g) {
	my $type = $2;
	my $var = $3;
	if ($o->{verbose}) {
	    debugmsg ("type = $type for $var");
	}
	if ($o->{vars}{$type}) {
	    # This is very likely to produce false positives in a long
	    # file. A better way to do this would be to have variables
	    # associated with line numbers, so that x on line 10 is
	    # different from x on line 20.
	    warn "duplicate variable $var of type $type\n";
	}
	$o->{vars}{$var} = $type;
    }
}

# Get the type of variable $var.

sub get_type
{
    my ($o, $var) = @_;
    # We currently do not have a way to store and retrieve types of
    # structure members
    if ($var =~ /->|\./) {
	$o->report ("Cannot get type of $var, please check manually");
	return undef;
    }
    my $type = $o->{vars}{$var};
    if (! $type) {
	$o->report ("(BUG) No type for $var");
    }
    return $type;
}

# Set up the line numbering object.

sub line_numbers
{
    my ($o) = @_;
    my $tln = Text::LineNumber->new ($o->{xs});
    $o->{tln} = $tln;
}

# This adds a colon to the end of the file, so it shouldn't really be
# user-visible.

sub get_file
{
    my ($o) = @_;
    if (! $o->{file}) {
	return '';
    }
    return "$o->{file}:";
}

# Clear up old variables, inputs, etc. Don't delete everything since
# we want to keep at least the field "reporter" from one call to
# "check" to the next.

sub cleanup
{
    my ($o) = @_;
    for (qw/vars xs file/) {
	delete $o->{$_};
    }
}

# Regex to match (void) in XS function call.

my $void_re = qr/
    $word_re\s*
    \(\s*void\s*\)\s*
    (?=
	# CODE:, PREINIT:, etc.
	[A-Z]+:
	#		    |
	# Normal C function start
	#			\{
    )
/xsm;

# Look for (void) XS functions

sub check_void_arg
{
    my ($o) = @_;
    while ($o->{xs} =~ /$void_re/g) {
	$o->report ("Don't use (void) in function arguments");
    }
}

sub
check_hash_comments
{
    my ($o) = @_;
    while ($o->{xs} =~ /^#\s*(\w*)/gsm) {
	my $hash = $1;
	if ($hash !~ /
	    ^(?:
		define|
		elif|
		else |
		endif|
		error|
		ifdef|
		ifndef|
		if |
		include|
		line|
		undef|
		warning|
		ZZZZZZZZZZZ)(\s+|$
	    )/x) {
	    $o->report ("Put whitespace before # in comments");
	}
    }
}

sub
check_c_pre
{
    my ($o) = @_;
    while ($o->{xs} =~ /^#\s*(\w*)/gsm) {
	my $hash = $1;
	if ($hash =~ /(?:if|else|endif)\s+/) {
	    # Complicated!
	}
    }
}

sub check_fetch_deref
{
    my ($o) = @_;
    while ($o->{xs} =~ m!(\*\s*(?:a|h)v_fetch)!g) {
	$o->report ("Dereference of av/hv_fetch");
    }
}

sub check_av_len
{
    my ($o) = @_;
    while ($o->{xs} =~ m!^(.*av_len\s*\([^\)]*\)(.*))!g) {
	my $later = $2;
	if ($later !~ /\+\s*1/) {
	    $o->report ("Add one to av_len");
	}
    }
}

#  _   _                       _     _ _     _      
# | | | |___  ___ _ __  __   _(_)___(_) |__ | | ___ 
# | | | / __|/ _ \ '__| \ \ / / / __| | '_ \| |/ _ \
# | |_| \__ \  __/ |     \ V /| \__ \ | |_) | |  __/
#  \___/|___/\___|_|      \_/ |_|___/_|_.__/|_|\___|
#                                                  

sub new
{
    my ($class, %options) = @_;
    my $o = bless {};
    if (my $r = $options{reporter}) {
	if (ref $r ne 'CODE') {
	    carp "reporter should be a code reference";
	}
	else {
	    $o->{reporter} = $r;
	}
    }
    if (defined $options{verbose}) {
	$o->{verbose} = $options{verbose};
    }
    return $o;
}

sub set_file
{
    my ($o, $file) = @_;
    if (! $file) {
	$file = undef;
    }
    $o->{file} = $file;
}

# Check the XS.

sub check
{
    my ($o, $xs) = @_;
    $o->{xs} = $xs;
    $o->{xs} = strip_comments ($o->{xs});
    $o->line_numbers ();
    $o->read_declarations ();
    $o->check_svpv ();
    $o->check_malloc ();
    $o->check_perl_prefix ();
    $o->check_void_arg ();
    $o->check_c_pre ();
    $o->check_hash_comments ();
    $o->check_fetch_deref ();
    $o->check_av_len ();
    # Final line
    $o->cleanup ();
}

sub check_file
{
    my ($o, $file) = @_;
    $o->set_file ($file);
    my $xs = read_text ($file);
    $o->check ($xs);
}

1;
