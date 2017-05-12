package XML::Checker::Parser;
use strict;
use XML::Parser;
use XML::Checker;

use vars qw( @ISA @InterceptedHandlers @SGML_SEARCH_PATH %URI_MAP
	     $_checker $_prevFAIL
	     $_Init $_Final $_Char $_Start $_End $_Element $_Attlist 
	     $_Doctype $_Unparsed $_Notation $_Entity $_skipInsignifWS
	     $_EndOfDoc
	   );

@ISA = qw( XML::Parser );

@InterceptedHandlers = qw( Init Final Char Start End Element Attlist 
			   Doctype Unparsed Notation Entity );

# Where to search for external DTDs (in local file system)
@SGML_SEARCH_PATH = ();

# Where to search for external DTDs as referred to by public ID in a 
# <!DOCTYPE ...> statement, e.g. "-//W3C//DTD HTML 4.0//EN"
# E.g. it could map "-//W3C//DTD HTML 4.0//EN" to "file:/user/html.dtd"
%URI_MAP = ();

sub new
{
    my ($class, %args) = @_;

    my $super = new XML::Parser (%args);
    $super->{Checker} = new XML::Checker (%args);

    my %handlers = %{$super->{Handlers}};

    # Don't need Comment handler - assuming comments are allowed anywhere
#?? What should Default handler do?
#?? Check XMLDecl, ExternEnt, Proc?  No, for now.
#?? Add CdataStart, CdataEnd support?

    for (@InterceptedHandlers)
    {
	my $func = "XML::Checker::Parser::$_";
	$handlers{$_} = \&$func;
    }

    $super->{UserHandlers} = $super->{Handlers};
    $super->{Handlers} = \%handlers;

    bless $super, $class;
}

sub getChecker
{
    $_[0]->{Checker}
}

sub parse
{
    my $self = shift;
    my $uh = $self->{UserHandlers};

    local $_checker = $self->{Checker};

    local $_Init = $uh->{Init};
    local $_Final = $uh->{Final};
    local $_Start = $uh->{Start};
    local $_End = $uh->{End};
    local $_Char = $uh->{Char};
    local $_Element = $uh->{'Element'};
    local $_Attlist = $uh->{'Attlist'};
    local $_Doctype = $uh->{Doctype};
    local $_Unparsed = $uh->{Unparsed};
    local $_Notation = $uh->{Notation};
    local $_Entity = $uh->{Entity};

    local $_prevFAIL = $XML::Checker::FAIL;
    local $XML::Checker::FAIL = \&fail_add_context;

    local $XML::Checker::INSIGNIF_WS = 0;
    local $_skipInsignifWS = $self->{SkipInsignifWS};

    local $_EndOfDoc = 0;
    
    $self->SUPER::parse (@_);
}

my $LWP_USER_AGENT;
sub set_LWP_UserAgent	# static
{
    $LWP_USER_AGENT = shift;
}

sub load_URL		# static
{
    my ($url, $lwp_user_agent) = @_;
    my $result;

    # Read the file from the web with LWP.
    #
    # Note that we read in the entire file, which may not be ideal
    # for large files. LWP::UserAgent also provides a callback style
    # request, which we could convert to a stream with a fork()...
    
    my $response;
    eval
    {
	use LWP::UserAgent;
	
	my $ua = $lwp_user_agent;
	unless (defined $ua)
	{
	    unless (defined $LWP_USER_AGENT)
	    {
		$LWP_USER_AGENT = LWP::UserAgent->new;
		
		# Load proxy settings from environment variables, i.e.:
		# http_proxy, ftp_proxy, no_proxy etc. (see LWP::UserAgent(3))
		# You need these to go thru firewalls.
		$LWP_USER_AGENT->env_proxy;
	    }
	    $ua = $LWP_USER_AGENT;
	}
	my $req = new HTTP::Request 'GET', $url;
	$response = $LWP_USER_AGENT->request ($req);
	$result = $response->content;
    };
    if ($@)
    {
	die "Couldn't load URL [$url] with LWP: $@";
    }
    if (!$result)
    {
	my $message = $response->as_string;
	die "Couldn't load URL [$url] with LWP: $message";
    }
    return $result;
}

sub parsefile
{
    my $self = shift;
    my $url = shift;

    # Any other URL schemes?
    if ($url =~ /^(https?|ftp|wais|gopher|file):/)
    {
	my $xml = load_URL ($url, $self->{LWP_UserAgent});
	my $result;
	eval
	{
	    # Parse the result of the HTTP request
	    $result = $self->parse ($xml, @_);
	};
	if ($@)
	{
	    die "Couldn't parsefile [$url]: $@";
	}
	return $result;
    }
    else
    {
	return $self->SUPER::parsefile ($url, @_);
    }
}

sub Init
{
    my $expat = shift;
    $_checker->{Expat} = $expat;

    $_checker->Init (@_);
    &$_Init ($expat) if $_Init;
}

sub Final
{
    my $expat = shift;
    $_EndOfDoc = 1;

    $_checker->Final (@_);
    my $result = &$_Final ($expat) if $_Final;

    # Decouple Expat from Checker
    delete $_checker->{Expat};

    # NOTE: Checker is not decoupled
    return $result;
}

sub Start
{
    my ($expat, $tag, @attr) = @_;

    $_checker->Start ($tag);

    my $num_spec = $expat->specified_attr;
    for (my $i = 0; $i < @attr; $i++)
    {
	my $spec = ($i < $num_spec);
	my $attr = $attr[$i];
	my $val = $attr[++$i];

#	print "--- $tag $attr $val $spec\n";
	$_checker->Attr ($tag, $attr, $val, $spec);
    }
    $_checker->EndAttr;

    &$_Start ($expat, $tag, @attr) if $_Start;
}

sub End
{
    my $expat = shift;
    $_checker->End (@_);
    &$_End ($expat, @_) if $_End;
}

sub Char
{
    my $expat = shift;
    $_checker->Char (@_);
    &$_Char ($expat, @_) 
	if $_Char && !($XML::Checker::INSIGNIF_WS && $_skipInsignifWS);
    # Skip insignificant whitespace
}

sub Element
{
    my $expat = shift;
    $_checker->Element (@_);
    &$_Element ($expat, @_) if $_Element;
}

sub Attlist
{
    my $expat = shift;
    $_checker->Attlist (@_);
    &$_Attlist ($expat, @_) if $_Attlist;
}


sub Doctype
{
    my $expat = shift;
    my ($name, $sysid, $pubid, $internal) = @_;

    my $dtd;
    unless ($_checker->{SkipExternalDTD}) 
    {
	if ($sysid)
	{
	    # External DTD...
	    
	    #?? I'm not sure if we should die here or keep going?	    
	    $dtd = load_DTD ($sysid, $expat->{LWP_UserAgent});
	}
	elsif ($pubid)
	{
	    $dtd = load_DTD ($pubid, $expat->{LWP_UserAgent});
	}
    }

    if (defined $dtd)
    {
#?? what about passing ProtocolEncoding, Namespaces, Stream_Delimiter ?
	my $parser = new XML::Parser (
	    Checker => $_checker, 
	    ErrorContext => $expat->{ErrorContext},
	    Handlers => { 
		Entity => \&XML::Checker::Parser::ExternalDTD::Entity,
		Notation => \&XML::Checker::Parser::ExternalDTD::Notation,
		Element => \&XML::Checker::Parser::ExternalDTD::Element,
		Attlist => \&XML::Checker::Parser::ExternalDTD::Attlist,
		Unparsed => \&XML::Checker::Parser::ExternalDTD::Unparsed,
	    });

	eval 
	{
	    $parser->parse ("<!DOCTYPE $name SYSTEM '$sysid' [\n$dtd\n]>\n<$name/>");
	};
	if ($@)
	{
	    die "Couldn't parse contents of external DTD <$sysid> :$@";
	}
    }
    $_checker->Doctype (@_);
    &$_Doctype ($expat, @_) if $_Doctype;
}

sub Unparsed
{
    my $expat = shift;
    $_checker->Unparsed (@_);
    &$_Unparsed ($expat, @_) if $_Unparsed;
}

sub Entity
{
    my $expat = shift;
    $_checker->Entity (@_);
    &$_Entity ($expat, @_) if $_Entity;
}

sub Notation
{
    my $expat = shift;
    $_checker->Notation (@_);
    &$_Notation ($expat, @_) if $_Notation;
}

sub Default
{
#?? what can I check here?
#    print "Default handler got[" . join (", ", @_) . "]";
}

#sub XMLDecl
#{
#?? support later?
#}

sub setHandlers
{
    my ($self, %h) = @_;
    my (%oldhandlers);

    for my $name (@InterceptedHandlers)
    {
	if (exists $h{$name})
	{
	    $oldhandlers{$name} = $self->{UserHandlers}->{$name};
	    $self->{UserHandlers}->{$name} = $h{$name};
	    delete $h{$name};
	}
    }

    # Pass remaining handlers to the parent class (XML::Parser)
    return (%oldhandlers, $self->SUPER::setHandlers (%h));
}

# Add (line, column, byte) to error context (unless it's EOF)
sub fail_add_context	# static
{
    my $e = $_checker->{Expat};

    my $byte = $e->current_byte;	# -1 means: end of XML document
    if ($byte != -1 && !$_EndOfDoc)
    {
	push @_, (line => $e->current_line, 
		  column => $e->current_column, 
		  byte => $byte);
    }
    &$_prevFAIL (@_);
}

#-------- STATIC METHODS related to External DTDs ---------------------------

sub load_DTD		# static
{
    my ($sysid, $lwp_user_agent) = @_;

    # See if it is defined in the %URI_MAP
    # (Public IDs are stored here, e.g. "-//W3C//DTD HTML 4.0//EN")
    if (exists $URI_MAP{$sysid})
    {
	$sysid = $URI_MAP{$sysid};
    }
    elsif ($sysid !~ /^\w+:/) 
    {
	# Prefix the sysid with 'file:' if it has no protocol identifier
	unless ($sysid =~ /^\//) 
	{
	    # Not an absolute path. See if it's in SGML_SEARCH_PATH.
	    my $relative_sysid = $sysid;

	    $sysid = find_in_sgml_search_path ($sysid);
	    if (! $sysid) 
	    {
		if ($ENV{'SGML_SEARCH_PATH'}) 
		{
		    die "Couldn't find external DTD [$relative_sysid] in SGML_SEARCH_PATH ($ENV{'SGML_SEARCH_PATH'})";
		}
		else 
		{
		    die "Couldn't find external DTD [$relative_sysid], may be you should set SGML_SEARCH_PATH";
		}
	    }
	}
	$sysid = "file:$sysid";
    }

    return load_URL ($sysid, $lwp_user_agent);
}

sub map_uri			# static
{
    %URI_MAP = (%URI_MAP, @_);
}

sub set_sgml_search_path	# static
{
    @SGML_SEARCH_PATH = @_;
}

sub find_in_sgml_search_path	# static
{
    my $file = shift;

    my @dirs = @SGML_SEARCH_PATH;
    unless (@dirs)
    {
	my $path = $ENV{SGML_SEARCH_PATH};
	if ($path)
	{
	    @dirs = split (':', $path);
	}
	else
	{
	    my $home = $ENV{HOME};
	    @dirs = (".", "$home/.sgml", "/usr/lib/sgml", "/usr/share/sgml");
	}
    }

    for my $directory (@dirs) 
    {
	if (-e "$directory/$file") 
	{
	    return "$directory/$file";
	}
    }
    return undef;
}

package XML::Checker::Parser::ExternalDTD;

sub Element {
	my $expat = shift;
	$expat->{Checker}->Element(@_);
}

sub Attlist {
	my $expat = shift;
	$expat->{Checker}->Attlist(@_);
}

sub Unparsed {
	my $expat = shift;
	$expat->{Checker}->Unparsed(@_);
}

sub Notation {
	my $expat = shift;
	$expat->{Checker}->Notation(@_);
}

sub Entity {
	my $expat = shift;
#	print "Entity: $expat\n";
	$expat->{Checker}->Entity(@_);
}

sub my_final
{
        return 1;
}

1; # package return code

__END__

=head1 NAME

XML::Checker::Parser - an XML::Parser that validates at parse time

=head1 SYNOPSIS

 use XML::Checker::Parser;

 my %expat_options = (KeepCDATA => 1, 
		      Handlers => [ Unparsed => \&my_Unparsed_handler ]);
 my $parser = new XML::Checker::Parser (%expat_options);

 eval {
     local $XML::Checker::FAIL = \&my_fail;
     $parser->parsefile ("fail.xml");
 };
 if ($@) {
     # Either XML::Parser (expat) threw an exception or my_fail() died.
     ... your error handling code here ...
 }

 # Throws an exception (with die) when an error is encountered, this
 # will stop the parsing process.
 # Don't die if a warning or info message is encountered, just print a message.
 sub my_fail {
     my $code = shift;
     die XML::Checker::error_string ($code, @_) if $code < 200;
     XML::Checker::print_error ($code, @_);
 }

=head1 DESCRIPTION

XML::Checker::Parser extends L<XML::Parser>

I hope the example in the SYNOPSIS says it all, just use 
L<XML::Checker::Parser> as if it were an XML::Parser. 
See L<XML::Parser> for the supported (expat) options.

You can also derive your parser from XML::Checker::Parser instead of 
from XML::Parser. All you should have to do is replace:

 package MyParser;
 @ISA = qw( XML::Parser );

with:

 package MyParser;
 @ISA = qw( XML::Checker::Parser );

=head1 XML::Checker::Parser constructor

 $parser = new XML::Checker::Parser (SkipExternalDTD => 1, SkipInsignifWS => 1);

The constructor takes the same parameters as L<XML::Parser> with the following additions:

=over 4

=item SkipExternalDTD

By default, it will try to load external DTDs using LWP. You can disable this
by setting SkipExternalDTD to 1. See L<External DTDs|"External DTDs"> for details.

=item SkipInsignifWS

By default, it will treat insignificant whitespace as regular Char data.
By setting SkipInsignifWS to 1, the user Char handler will not be called
if insignificant whitespace is encountered. 
See L<XML::Checker/INSIGNIFICANT_WHITESPACE> for details.

=item LWP_UserAgent

When calling parsefile() with a URL (instead of a filename) or when loading
external DTDs, we use LWP to download the
remote file. By default it will use a L<LWP::UserAgent> that is created as follows:

 use LWP::UserAgent;
 $LWP_USER_AGENT = LWP::UserAgent->new;
 $LWP_USER_AGENT->env_proxy;

Note that L<env_proxy> reads proxy settings from your environment variables, 
which is what I need to do to get thru our firewall. 
If you want to use a different LWP::UserAgent, you can either set
it globally with:

 XML::Checker::Parser::set_LWP_UserAgent ($my_agent);

or, you can specify it for a specific XML::Checker::Parser by passing it to 
the constructor:

 my $parser = new XML::Checker::Parser (LWP_UserAgent => $my_agent);

Currently, LWP is used when the filename (passed to parsefile) starts with one of
the following URL schemes: http, https, ftp, wais, gopher, or file 
(followed by a colon.) If I missed one, please let me know. 

The LWP modules are part of libwww-perl which is available at CPAN.

=back

=head1 External DTDs

XML::Checker::Parser will try to load and parse external DTDs that are 
referenced in DOCTYPE definitions unless you set the B<SkipExternalDTD>
option to 1 (the default setting is 0.) 
See L<CAVEATS|"CAVEATS"> for details on what is not supported by XML::Checker::Parser.

L<XML::Parser> (version 2.27 and up) does a much better job at reading external 
DTDs, because recently external DTD parsing was added to expat.
Make sure you set the L<XML::Parser> option B<ParseParamEnt> to 1 and the 
XML::Checker::Parser option B<SkipExternalDTD> to 1. 
(They can both be set in the XML::Checker::Parser constructor.)

When external DTDs are parsed by XML::Checker::Parser, they are
located in the following order:

=over 4

=item *

With the %URI_MAP, which can be set using B<map_uri>.
This hash maps external resource ids (like system ID's and public ID's)
to full path URI's.
It was meant to aid in resolving PUBLIC IDs found in DOCTYPE declarations 
after the PUBLIC keyword, e.g.

  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">

However, you can also use this to force L<XML::Checker> to read DTDs from a
different URL than was specified (e.g. from the local file system for
performance reasons.)

=item * 

on the Internet, if their system identifier starts with a protocol 
(like http://...)

=item *

on the local disk, if their system identifier starts with a slash 
(absolute path)

=item *

in the SGML_SEARCH_PATH, if their system identifier is a 
relative file name. It will use @SGML_SEARCH_PATH if it was set with
B<set_sgml_search_path()>, or the colon-separated $ENV{SGML_SEARCH_PATH},
or (if that isn't set) the list (".", "$ENV{'HOME'}/.sgml", "/usr/lib/sgml",
"/usr/share/sgml"), which includes the
current directory, so it should do the right thing in most cases.

=back

=head2 Static methods related to External DTDs

=over 4

=item set_sgml_search_path (dir1, dir2, ...)

External DTDs with relative file paths are looked up using the @SGML_SEARCH_PATH,
which can be set with this method. If @SGML_SEARCH_PATH is never set, it
will use the colon-separated $ENV{SGML_SEARCH_PATH} instead. If neither are set
it uses the list: ".", "$ENV{'HOME'}/.sgml", "/usr/lib/sgml",
"/usr/share/sgml".

set_sgml_search_path is a static method.

=item map_uri (pubid => uri, ...)

To define the location of PUBLIC ids, as found in DOCTYPE declarations 
after the PUBLIC keyword, e.g.

  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">

call this method, e.g.

  XML::Checker::Parser::map_uri (
	"-//W3C//DTD HTML 4.0//EN" => "file:/user/html.dtd");

See L<External DTDs|"External DTDs"> for more info.

XML::Checker::Parser::map_uri is a static method.

=back

=head1 Switching user handlers at parse time

You should be able to use setHandlers() just as in L<XML::Parser>.
(Using setHandlers has not been tested yet.)

=head1 Error handling

XML::Checker::Parser routes the fail handler through 
XML::Checker::Parser::fail_add_context() before calling your fail handler
(i.e. the global fail handler: $XML::Checker::FAIL. 
See L<XML::Checker/ERROR_HANDLING>.)
It adds the (line, column, byte) information from L<XML::Parser> to the 
error context (unless it was the end of the XML document.)

=head1 Supported XML::Parser handlers

Only the following L<XML::Parser> handlers are currently routed through
L<XML::Checker>: Init, Final, Char, Start, End, Element, Attlist, Doctype,
Unparsed, Notation.

=head1 CAVEATS

When using XML::Checker::Parser to parse external DTDs 
(i.e. with SkipExternalDTD => 0),
expect trouble when your external DTD contains parameter entities inside 
declarations or conditional sections. The external DTD should probably have
the same encoding as the orignal XML document.

=head1 AUTHOR

Enno Derksen is the original author.

Send bug reports, hints, tips, suggestions to T.J. Mather at
<F<tjmather@tjmather.com>>.

=head1 SEE ALSO

L<XML::Checker> (L<XML::Checker/SEE_ALSO>), L<XML::Parser>
