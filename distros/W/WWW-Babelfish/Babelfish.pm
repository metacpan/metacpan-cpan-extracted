package WWW::Babelfish;

require 5.008;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();

$VERSION = '0.16';

# Preloaded methods go here.

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use HTML::TokeParser;
use IO::String;
use Encode;

my $MAXCHUNK = 1000;		# Maximum number of characters 
				# Bablefish will translate at one time 

my $MAXRETRIES = 50;		# Maximum number of retries for a chunk of text
$| = 1;

my $Services = {
		Babelfish => {
			      agent => $0 . ":" . __PACKAGE__ . "/" . $VERSION,

			      languagesrequest => sub {
				my $req = new HTTP::Request(GET => 'http://babelfish.altavista.com/babelfish/tr?il=en');
				return $req;
			      },

			      translaterequest => sub {
				my($langpair, $text) = @_;
				my $req = POST ( 'http://babelfish.altavista.com/babelfish/tr?il=en',
						 [ 'doit' => 'done', 'urltext' => encode("utf8",$text), 'lp' => $langpair, 'Submit' => 'Translate', 'enc' => 'utf8' ], qw(Accept-Charset utf-8) );
				return $req;
			      },

			      # Extract the text from the html we get back from babelfish and return
			      # it (keying on the fact that it's the first thing after a <br> tag,
			      # possibly removing a textarea tag after it).

# 			      extract_text => sub {
# 				my($html) = @_;
# 				my $p = HTML::TokeParser->new(\$html);
# 				my $tag;
# 				while ($tag = $p->get_tag('input')) {
# 				  $_ = @{$tag}[1]->{value} if @{$tag}[1]->{name} eq 'q';
# 				  return decode("utf8",$_);
# 				}

			      extract_text => sub {
				my($html) = @_;
				my $p = HTML::TokeParser->new(\$html);
				while ( my $_tag = $p->get_tag('div') ) {
				  my($tag,$attr,$attrseq) = @$_tag;
				  next unless @$attrseq == 1
				    && $attrseq->[-1] eq 'style'
				      && $attr->{style} eq 'padding:10px;';
				  my($token) = $p->get_token or return;
				  my ( $type, $text, $is_data ) = @$token;
				  next if $type ne 'T';
				  return decode( utf8 => $text );
				}


			      }
			     },

		Google =>    {
			      agent => 'Mozilla/5.0', # Google is finicky

			      languagesrequest => sub {
				my $req = new HTTP::Request(GET => 'http://www.google.com/language_tools?hl=en');
				return $req;
			      },

			      translaterequest => sub {
				my($langpair, $text) = @_;
				my $req = POST ( 'http://translate.google.com/translate_t',
						 [ 'text' => encode("utf8",$text), 'langpair' => $langpair, hl => 'en', ie => "UTF8", oe => "UTF8",]);
				return $req;
			      },

			      extract_text => sub {
				my($html) = @_;
				my $p = HTML::TokeParser->new(\$html);
				my $tag;
				while ($tag = $p->get_tag('div')) {
				  if (@{$tag}[1]->{id} eq 'result_box') {
				    $_ = $p->get_text;
				    return decode("utf8",$_);
				  }
				}
			      }
			     },

		Yahoo => {
			  agent => $0 . ":" . __PACKAGE__ . "/" . $VERSION,

			  languagesrequest => sub {
			    my $req = new HTTP::Request(GET => 'http://babelfish.yahoo.com/translate_txt');
			    return $req;
			  },

			  translaterequest => sub {
			    my($langpair, $text) = @_;
			    my $req = POST ( 'http://babelfish.yahoo.com/translate_txt',
					     [ 'ei' => 'UTF-8', 'doit' => 'done', 'tt' => 'urltext', 'trtext' => encode("utf8",$text), 'lp' => $langpair, 'btnTrTxt' => 'Translate', 'intl' => '1' ]);
			    return $req;
			  },

			  # Extract the text from the html we get back from Yahoo
			  extract_text => sub {
			    my($html) = @_;
			    my $p = HTML::TokeParser->new(\$html);
			    my $tag;
			    while ($tag = $p->get_tag('div')) {
			      next if (@{$tag}[1]->{id} ne 'result');
			      $_ = $p->get_text('/div');  
			      return decode("utf8",$_);
			    }
			  }
			 },
				
	       };


sub new {
  my ($this, @args) = @_;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  return undef unless( $self->initialize(@args) );
  return $self;
}

sub initialize {
  my($self, %params) = @_;

  $self->{service} = $params{service} || 'Babelfish';
  die "No such service: " . $self->{service} unless defined $Services->{ $self->{service} };

  # Caller can set user agent; we default to "script:WWW::Babelfish/0.01"
  $self->{agent} = $params{agent} || $Services->{agent};

  $self->{proxy} = $params{proxy} if defined $params{proxy};

  # Get the page 
  my $ua = new LWP::UserAgent;
  $ua->proxy('http','http://' . $self->{proxy}) if defined $self->{proxy};
  $ua->agent($self->{agent});
  $self->{ua} = $ua;

  my $req = &{ $Services->{ $self->{service} }->{languagesrequest} };
  my $res = $ua->request($req);
  unless($res->is_success){ 
    warn(__PACKAGE__ . ":" . $res->status_line);
    return 0;
  }
  my $page = $res->content;

  # Extract the language names and the mapping of languages to options to
  # be passed back, and store them on our object in "Langs" hash of hashes
  # Incredibly, this works for both Babelfish and Google; it should really 
  # be a method in $Services
  my $p = HTML::TokeParser->new(\$page);
  my $a2b;
  if ( $p->get_tag("select") ) {
    while ( $_ = $p->get_tag("option") ) {
      $a2b = $p->get_trimmed_text;
      next if $a2b =~ /Select from and to languages/; # This for babelfish
      $a2b  =~ /(\S+)\sto\s(\S+)/ or next;
      $self->{Langs}{$1}{$2} = $_->[1]{value};
      $self->{Langs}{$2} ||= {};
    }
  }

  return 1;
}

sub services {
  my $self = shift;
  if($self){
    return keys %{$self->Services};
  }
  else{
    return keys %{$Services};
  }
}

sub languages {
  my $self = shift;
  return sort keys %{$self->{Langs}};
}

sub languagepairs {
  my $self = shift;
  return $self->{Langs};
}

sub translate {
  my ($self, %params) = @_;

  # Paragraph separator is "\n\n" by default
  local $/ = $params{delimiter} || "\n\n";
  local $_;

  $params{delimiter} = "\n\n" if ( ! defined( $params{delimiter} ) );

  undef $self->{error};
  unless ( exists($self->{Langs}->{$params{source}}) ) {
    $self->{error} = qq(Language "$params{source}" is not available);
    warn(__PACKAGE__ . ": " . $self->{error} . "\n");
    return undef;
  }

  # This "feature" is actually useful as a pass-thru filter.
  # Babelfish doesn't do same-to-same anyway (though it would be
  # pretty interesting if it did)
  return $params{text} if $params{source} eq $params{destination};

  unless ( exists($self->{Langs}->{$params{source}}{$params{destination}}) ) {
    $self->{error} =
      qq(Cannot translate from "$params{source}" to "$params{destination}");
    warn(__PACKAGE__ . ": " . $self->{error} . "\n");
    return undef;
  }

  my $langopt = $self->{Langs}{$params{source}}{$params{destination}};

  my $th;			# "Text Handle"
  if ( ref $params{text} ) {	# We've been passed a filehandle
    $th = $params{text};
  } else {			# We've been passed a string
    $th = new IO::String($params{text});
  }

  my $Text = "";
  my $WANT_STRING_RETURNED = 0;
  unless ( defined $params{ofh} ) {
    $params{ofh} = new IO::String($Text);
    $WANT_STRING_RETURNED = 1;
  }

  # Variables we use in the next mega-block
  my $para;			# paragraph
  my $num_paras = 0;		# number of paragraphs
  my $transpara;		# translated paragraph
  my $para_start_ws = "";	# initial whitespace in paragraph
  my $chunk;			# paragraph piece to feed to babelfish
  my $req;			# LWP request object
  my $ua;			# LWP user agent
  my $res;			# LWP result
  my $text;			# translated chunk
  my $i;			# a counter
  while ($para = <$th>) {
    $num_paras++;
    $transpara = "";

    # Extract any leading whitespace from the start of the paragraph
    # Babelfish will eat it anyway.
    if ($para =~ s/(^\s+)(\S)/$2/) {
      $para_start_ws = $1 || "";
    }
    $para =~ s/$params{delimiter}//; # Remove the para delimiter

  CHUNK:
    foreach $chunk ( $self->_chunk_text($MAXCHUNK, $para) ) {
      $req = &{ $Services->{ $self->{service} }->{translaterequest} }($langopt, $chunk);
      $ua = $self->{ua};

    RETRY:
      for ($i = 0; $i <= $MAXRETRIES; $i++) { 
	$res = $ua->request($req);

	if ( $res->is_success ) {

	  #$text = $self->_extract_text($res->as_string); #REMOVE
	  $text = &{ $Services->{ $self->{service} }->{extract_text} }($res->as_string);
	  if ( ( ! defined( $text ) ) ||
               ( $text =~ /^\*\*time-out\*\*/ )
             )			# in-band signalling; yuck
	    {
	      next RETRY;

	    }			## end if

	  $text =~ s/\n$//;	# Babelfish likes to append newlines
	  $transpara .= $text;

	  next CHUNK;
	}
      }
      $self->{error} = "Request timed out more than $MAXRETRIES times";
      return undef; 
    }
    print { $params{ofh} } $/ if $num_paras > 1;
    print { $params{ofh} } $para_start_ws . $transpara;
  }

  if ( $WANT_STRING_RETURNED ) {
    return $Text;
  } else {
    return 1;
  }
}

sub error {
  my $self = shift;
  return $self->{error};
}

# Given a maximum chunk size and some text, return
# an array of pieces of the text chopped up in a 
# logical way and less than or equal to the chunk size
sub _chunk_text {
  my($self, $max, $text) = @_;

  my @result;

  # The trivial case
  return($text) if length($text) <= $max; 

  # Hmmm. There are a couple of ways we could do this. 
  # I'm guessing that Babelfish doesn't look at any structure larger than 
  # a sentence; in fact I'm often tempted to guess that it doesn't look
  # at anything larger than a word, but we'll give it the benefit of the doubt.
  #

  # FIXME there are no built-in regexps for matching sentence
  # breaks; I'm not sure if terminal punctuation will work for all
  # languages...

  my $total = length($text);
  my $offset = 0;
  my $lastoffset = 0;
  my $test;
  my $chunk;

  while ( ($total - $lastoffset) > $max) {
    $test = $lastoffset + $max;
	
    # Split by terminal punctuation...
    @_ = sort {$b <=> $a} ( rindex($text, '.', $test), 
			    rindex($text, '!', $test),      
			    rindex($text, '?', $test),      
			  );
    $offset = shift(@_) + 1;

    # or by clause...
    if ( $offset == -1 or $offset <= $lastoffset   ) {
      @_ = sort {$b <=> $a} ( rindex($text, ',', $test), 
			      rindex($text, ';', $test),      
			      rindex($text, ':', $test),      
			    ); 
      $offset = shift(@_) + 1;


      # or by word
      if ( $offset == -1 or $offset <= $lastoffset) {
	$offset = rindex($text, " ", $test);
      }

      # or give up
      return undef if $offset == -1;
    }
	
    $chunk = substr($text, $lastoffset, $offset - $lastoffset);

    push( @result, $chunk);
    $lastoffset = $offset;
  }

  push( @result, substr($text, $lastoffset) );
  return @result;
}

# This code is now obsoleted by the new result page format, but I'm
# leaving it here commented out in case we end up needing the
# whitespace hack again.
#
#    my ($tag,$token);
#    my $text="";
#     if ($tag = $p->get_tag('br')) {
# 	while ($token = $p->get_token) {
# 	    next if shift(@{$token}) ne "T";
# 	    $text = shift(@{$token});

# 	    #$text =~ s/[\r\n]//g;
# 	    # This patch for whitespace handling from Olivier Scherler
#             $text =~ s/[\r\n]/ /g;
#             $text =~ s/^\s*//;
#             $text =~ s/\s+/ /g;
#             $text =~ s/\s+$//;

# 	    last if defined($text) and $text ne "";
# 	}
#    }
#    return $text;


#}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

WWW::Babelfish - Perl extension for translation via Babelfish or Google

=head1 SYNOPSIS

  use WWW::Babelfish;
  $obj = new WWW::Babelfish( service => 'Babelfish', agent => 'Mozilla/8.0', proxy => 'myproxy' );
  die( "Babelfish server unavailable\n" ) unless defined($obj);

  $french_text = $obj->translate( 'source' => 'English',
                                  'destination' => 'French',
                                  'text' => 'My hovercraft is full of eels',
				  'delimiter' => "\n\t",
				  'ofh' => \*STDOUT );
  die("Could not translate: " . $obj->error) unless defined($french_text);

  @languages = $obj->languages;

=head1 DESCRIPTION

Perl interface to the WWW babelfish translation server.

=head1 METHODS

=over 4

=item new

Creates a new WWW::Babelfish object.

Parameters:

 service:        Babelfish, Google or Yahoo; default is Babelfish
 agent:          user agent string
 proxy:          proxy in the form of host:port

=item services

Returns a plain array of the services available (currently Babelfish, Google or Yahoo).

=item languages

Returns a plain array of the languages available for translation.

=item languagepairs

Returns a reference to a hash of hashes.
The keys of the outer hash reflect all available languages.
The hashes the corresponding values reference contain one (key) entry
for each destination language that the particular source language can
be translated to.
The values of these inner hashes contain the Babelfish option name for
the language pair.
You should not modify the returned structure unless you really know
what you're doing.

Here's an example of a possible return value:

	{
	  'Chinese' => {
	                 'English' => 'zh_en'
	               },
	  'English' => {
	                 'Chinese' => 'en_zh',
	                 'French' => 'en_fr',
	                 'German' => 'en_de',
	                 'Italian' => 'en_it',
	                 'Japanese' => 'en_ja',
	                 'Korean' => 'en_ko',
	                 'Portuguese' => 'en_pt',
	                 'Spanish' => 'en_es'
	               },
	  'French' => {
	                'English' => 'fr_en',
	                'German' => 'fr_de'
	              },
	  'German' => {
	                'English' => 'de_en',
	                'French' => 'de_fr'
	              },
	  'Italian' => {
	                 'English' => 'it_en'
	               },
	  'Japanese' => {
	                  'English' => 'ja_en'
	                },
	  'Korean' => {
	                'English' => 'ko_en'
	              },
	  'Portuguese' => {
	                    'English' => 'pt_en'
	                  },
	  'Russian' => {
	                 'English' => 'ru_en'
	               },
	  'Spanish' => {
	                 'English' => 'es_en'
	               }
	};

=item translate

Translates some text using Babelfish.

Parameters: 

 source:      Source language
 destination: Destination language
 text:        If this is a reference, translate interprets it as an 
              open filehandle to read from. Otherwise, it is treated 
              as a string to translate.
 delimiter:   Paragraph delimiter for the text; the default is "\n\n".
              Note that this is a string, not a regexp.
 ofh:         Output filehandle; if provided, the translation will be 
              written to this filehandle.

If no ofh parameter is given, translate will return the text; otherwise 
it will return 1. On failure it returns undef.


=item error

Returns a (hopefully) meaningful error string.

=back

=head1 NOTES

Babelfish translates 1000 characters at a time. This module tries to
break the source text into reasonable logical chunks of less than 1000
characters, feeds them to Babelfish and then reassembles
them. Formatting may get lost in the process; also it's doubtful this
will work for non-Western languages since it tries to key on
punctuation. What would make this work is if perl had properly
localized regexps for sentence/clause boundaries.

Support for Google is preliminary and hasn't been extensively tested (by me).
Google's translations used to be suspiciously similar to Babelfish's,
but now some people tell me they're superior.

=head1 AUTHOR

Dan Urist, durist@frii.com

=head1 SEE ALSO

perl(1).

=cut
