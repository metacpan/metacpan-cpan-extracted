package Apache::AxKit::Language::Babel;

@ISA = ('Apache::AxKit::Language');

use strict;

use Apache;
use Apache::Request;
use Apache::AxKit::Language;
use XML::Twig;

my( @default_lang, @available_lang, @requested_lang, @content_languages, $uri );

sub stylesheet_exists{ 0 }

sub handler {
    my $class = shift;
    my ($r, $xml_provider, undef, $last_in_chain) = @_;
    
	$uri = $r->uri;
	my %args = $r->args;
	@content_languages = split ',' => $r->content_languages;
	@requested_lang = split ',' => $args{lang};

	AxKit::Debug(8, "Requested Languages: ", join ' ', @requested_lang );

	my $doc;
	$doc = $r->pnotes('xml_string') ||
           eval { ${$xml_provider->get_strref()} };
   

	my $t = new XML::Twig( TwigHandlers => { _all_     => \&babel,
		                                     doc_lang  => \&doc_lang,
	                                         lang_menu => \&lang_menu });
	$t->parse( $doc );
    
	$r->print( $t->sprint );
	$t->purge;
}

sub offline
{
	if( $ARGV[0] =~ /^lang=(\S+)$/ )
	{
		shift @ARGV;
		@requested_lang = split ',' => $1;
	}
	my $t = new XML::Twig( TwigHandlers => { _all_     => \&babel,
		                                     doc_lang  => \&doc_lang,
	                                         lang_menu => \&lang_menu });
	$t->parsefile( shift @ARGV );
   
	$t->flush;
}

sub doc_lang
{
	# if there's no lang in the query line, take the defaults
	@requested_lang = split ',', $_[1]->atts->{default} unless @requested_lang;
	
	@available_lang = split ',', $_[1]->atts->{available};

	unless( @requested_lang )
	{
		for my $l ( @content_languages )
		{
			push @requested_lang, $l and return
				if grep $_ eq $l, @available_lang; 
		}
		# *sigh* just give'im the first available lang, then...
		push @requested_lang, $available_lang[0];
	}

	# remove the tag (should we?)
	$_[1]->delete;

	AxKit::Debug(8, "Requested Languages, after doc_lang: ", join ' ', @requested_lang );
}


sub babel
{
	# AxKit::Debug(8, "Entering Babel..." );

	# if no lang defined, let it go
	my $a = $_[1]->atts or return;
	my @langs = split ',', $a->{lang} or return;

	for my $l ( @langs )
	{
		return if grep $l eq $_, @requested_lang;
	}

	# element is in non-desired language, remove it
	 $_[1]->delete;
}


sub lang_menu
{
	my %languages = 
		(  fr  => 'francais', 
 		   en  => 'english',
		  'ge' => 'deutch'      );

	my $elt= parse XML::Twig::Elt( "<p>".
		join( "<br/>", map "<a href='$uri?lang=$_'>$languages{$_}</a>",
		@available_lang ) . "</p>" );

	$elt->replace( $_[1] );
}

1;

=head1 NAME

Apache::AxKit::Language::Babel - Lamguage selector for multilingal documents

=head1 SYNOPSIS

in httpd.conf or .htaccess


The languages of the document are selected to be the first
non-null element of the following:

1. The lang attribute of the query string
	(e.g., http://some.site.com/doc.xml?lang=fr)

2. The default attribute of the <doc_lang> tag.

	E.g.:  <doc_lang default="fr" available="fr,en" />

3. The first content-language as defined by the browser
	listed in the available attribute of <doc_lang>.

4. The first language listed in the available attribute of <doc_lang>.

	<doc>
		<doc_lang default='en' available='en,fr,ge' />
		<title>Babel</title>
		<lang_menu />
		<p lang='en'>Hi there!</p>
		<p lang='fr'>Bien le bonjour!</p>
		<p lang='ge'>Gutten Tag!</p>
		<p>This paragraph will appears in all versions 
			of the document.</p>
	</doc>


available 
	used by the <lang_menu /> tag

<lang_menu/>
	generate an html menu of all available languages, as provided
	in <doc_lang/>

	For example, the xml doc above would produce

	<p><a href="/your/uri?lang=en">english</a><br/>
	   <a href="/your/uri?lang=fr">francais</a></p>

