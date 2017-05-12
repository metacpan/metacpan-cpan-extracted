package XML::SAX::RTF;
require 5.005_62;
use strict;  
use XML::SAX::Base;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
require Exporter;
@ISA = qw( Exporter XML::SAX::Base );
@EXPORT = qw( Version );
$VERSION = '0.2';
sub Version { $VERSION; }
our %features = 
    (
     DEBUG => 0,
     );


#
# internal globals
# 
my $file = '';                # name of file being parsed
my $inbuf;                    # input buffer with RTF to be processed
my $level;                    # element nesting level in result doc
my @elements;                 # open element stack for result doc


sub new {
#
# constructor
#
    my $class = shift;
    my $obj = {@_};
    my $self = bless( $obj, $class );
    return $self;
}


sub parse_file {
#
# parse a document, one line at a time
#
    my $self = shift;
    $file = shift;
    my $buf = '';
    if( open( F, $file )) {
	while( <F> ) {
	    $buf .= $_;
	}
	close F;
    }
    $self->parse_string( $buf );
    $file = '';
}


sub parse_string {
#
# parse a string containing RTF
#
    my $self = shift;
    $inbuf = shift;
    $level = 0;
    @elements = ();
    $self->_parse();
    $self->_close_everything;
}


sub set_feature {
#
# set a parser feature
#
    my( $self, $feature, $value ) = @_;
    if( exists( $features{ $feature })) {
	$features{ $feature } = $value;
    } else {
	$self->SUPER::set_feature( $feature, $value );
    }
}


sub get_feature {
#
# query a parser feature
#
    my( $self, $feature ) = @_;
    if( exists( $features{ $feature })) {
	return $features{ $feature };
    } else {
	return $self->SUPER::get_feature( $feature );
    }
}


my %paramcmds =
#
# commands with parameters to wrap
#
    (
     b                => 'bold',
     deff             => 'default-font',
     deflang          => 'language',
     dy               => 'day',
     edmins           => 'minutes-edited',
     f                => 'font',
     fcharset         => 'charset',
     footery          => 'footery',
     fprq             => 'pitch',
     fs               => 'font-size',
     headery          => 'headery',
     hr               => 'hour',
     id               => 'id',
     keepn            => 'keep-next',
     li               => 'indent-left',
     margl            => 'margin-left',
     margr            => 'margin-right',
     min              => 'min',
     mo               => 'month',
     nofchars         => 'number-chars',
     nofcharsws       => 'number-nonspace-chars',
     nofpages         => 'number-pages',
     nofwords         => 'numver-words',
     nowidctlpar      => 'nowidctlpar',
     pard             => 'style-default',
     qc               => 'align-center',
     qj               => 'align-justify',
     ql               => 'align-left',
     qr               => 'align-right',
     ri               => 'indent-right',
     rtf              => 'rtf-version',
     sa               => 'space-after',
     sb               => 'space-before',
     sbasedon         => 'style-base',
     sec              => 'sec',
     sl               => 'space-line',
     snext            => 'style-next',
     vern             => 'version',
     yr               => 'year',
     );


my %params =
#
# commands that are parameters, to be wrapped
#
    (
     ascii            => 'character-set',
     mac              => 'character-set',
     pc               => 'character-set',
     pca              => 'character-set',
     fnil             => 'family',
     froman           => 'family',
     fswiss           => 'family',
     fmodern          => 'family',
     fscript          => 'family',
     fdecor           => 'family',
     ftech            => 'family',
     fbidi            => 'family',
     ftnil            => 'type',
     fttruetype       => 'type',
     );


my %groupnames = 
#
# commands labelling groups
#
    (
     author           => 'author',
     b                => 'bold',
     buptim           => 'time-backedup',
     category         => 'category',
     colortbl         => 'color-table',
     comment          => 'comment',
     company          => 'company',
     creatim          => 'time-created',
     cs               => 'char-style',
     edmins           => 'minutes-edited',
     f                => 'font',
     field            => 'field',
     filetbl          => 'file-table',
     fldinst          => 'field-inst',
     fldrslt          => 'field-result',
     footer           => 'footer',
     footerf          => 'footer-first',
     footerl          => 'footer-left',
     footerr          => 'footer-right',
     footnote         => 'footnote',
     fonttbl          => 'font-table',
     header           => 'header',
     headerf          => 'header-first',
     headerl          => 'header-left',
     headerr          => 'header-right',
     i                => 'italic',
     info             => 'info',
     keywords         => 'keywords',
     listtables       => 'list-tables',
     manager          => 'manager',
     nofchars         => 'number-chars',
     nofcharsws       => 'number-nonspace-chars',
     nofpages         => 'number-pages',
     nofwords         => 'numver-words',
     operator         => 'operator',
     pn               => 'para-number',
     pnseclvl         => 'pn-sec-level',
     pntext           => 'pn-text',
     pntxta           => 'pn-txta',
     pntxtb           => 'pn-txtb',
     printim          => 'time-printed',
     revtbl           => 'rev-table',
     revtim           => 'time-revised',
     s                => 'para-style',
     title            => 'title',
     subject          => 'subject',
     stylesheet       => 'stylesheet',
     ul               => 'ul',
     vern             => 'version',
     version          => 'version',
     );


my %wraptext = 
#
# situations where we want to wrap text in an element
#
    (
     font             => 'name',
     'para-style'     => 'name',
     );


sub _parse {
#
# parse contents of the input buffer
#
    my $self = shift;
    while( $inbuf ) {
	if( $inbuf =~ /^\{/ ) {
	    $self->_handle_group();
	    
	} elsif( $inbuf =~ /^\}/ ) {
	    $self->_parse_error() unless( $level > 0 );
	    return;
	    
	} elsif( $inbuf =~ /^\\/ ) {
	    $self->_handle_ctlword();

	} else {
	    $self->_handle_content();
	}
    }
}


sub _handle_content {
#
# process character data
#
    my $self = shift;
    my $curr = $self->_current_element;
    if( $inbuf =~ /([^\\\{\}]+)/ ) {
	my $data = $1;
	$inbuf = $';
	if( exists( $wraptext{ $curr })) {
	    $data =~ s/;//;
	    $self->_indent_start_element( $wraptext{ $curr });
	    $self->_characters( $data );
	    $self->_end_element;
	} else {
	    $self->_characters( $data );
	}
    } else {
    }
}


sub _handle_ctlword {
#
# process a control word
#
    my $self = shift;
    $inbuf =~ s/^\\//;
    if( $inbuf =~ /^([a-z]+)/ ) {
	my $command = $1;
	my $parameter;
	$inbuf = $';
	if( $inbuf =~ /^(-?[0-9]+)/ ) {
	    $parameter = $1;
	    $inbuf = $';
	}
	if( $inbuf =~ /^ / ) {
	    $inbuf = $';
	}
	$self->_command( $command, $parameter );

    } elsif( $inbuf =~/([\\\{\}])/ ) {
	$self->_characters( $1 );

    } elsif( $inbuf =~/([^a-z])/ ) {
	my $command = $1;
	$inbuf = $';
	$self->_start_element( 'command', {'param' => $command} );
	$self->_end_element;

    } else {
	parse_error();
    }
}


sub _command {
#
# process a command
#
    my( $self, $command, $param ) = @_;

    if( $command eq 'par' ) {
	$self->_end_element 
	    if( $self->_current_element eq 'para' );
	$self->_indent_start_element( 'para' );

    } elsif( exists( $paramcmds{$command} )) {
	$self->_indent_start_element( $paramcmds{ $command });
	$self->_characters( $param );
	$self->_end_element;

    } elsif( exists( $params{ $command })) {
	$self->_indent_start_element( $params{ $command });
	$self->_characters( $command );
	$self->_end_element;

    } elsif( defined( $param )) {
	$self->_start_element( $command, { param => $param });
	$self->_end_element;

    } else {
	$self->_start_element( $command );
	$self->_end_element;
    }
}


sub _handle_group {
#
# process a group
#
    my $self = shift;
    $inbuf =~ s/^\{//;
    if( $level == 0 ) {
	$self->_start_element( 'rtfdoc' );
	$self->_indent_start_element( 'header' );

    } elsif(( $inbuf =~ /^\s*\\([a-z]+)/ and exists( $groupnames{$1} ))
	   or( $inbuf =~ /^\s*\\\*\\([a-z]+)/ and exists( $groupnames{$1} ))) {
	$inbuf = $';
	my $name = $groupnames{$1};
	if( $name eq 'info' and $self->_current_element eq 'header' ) {
	    $self->_indent_end_element;
	    $self->_indent_start_element( 'document' );
	    $self->_indent_start_element( $name );

	} elsif( $inbuf =~ /^(-?[0-9]+)/ ) {
	    my $param = $1;
	    $inbuf = $';
	    $self->_indent_start_element( $name, { number => $param });

	} else {
	    $self->_indent_start_element( $name );
	}
	$inbuf = $' if( $inbuf =~ /^ / );

    } elsif( $self->_current_element eq 'stylesheet' ) {
	$self->_indent_start_element( 'para-style' );

    } else {
	$self->_indent_start_element( 'group', { level => $level });
    }
    $self->_parse();
    $inbuf =~ s/^\}//;
    $self->_indent_end_element;
}


sub _characters {
#
# clean up characters, call handler
#
    my( $self, $data ) = @_;
    return unless( defined( $data ));
    $self->_debug( "CHARACTERS: [$data]", 3 );
    $data = $self->_unprotect_chars( $data );
    $data =~ s/&/&amp;/g;
    $data =~ s/</&lt;/g;
    $data =~ s/>/&gt;/g;
    $data =~ s/\n//g;
    $self->SUPER::characters({ Data => $data });
}


sub _newline {
#
# output a newline character
#
    my $self = shift;
    $self->SUPER::characters({ Data => "\n" });
}


sub _indent_start_element {
#
# start new element with indentation
#
    my( $self, $name, $params ) = @_;
    $self->_newline;
    $self->_characters( '  ' x $level );
    $self->_start_element( $name, $params );
}


sub _indent_end_element {
#
# end an indented element
#
    my $self = shift;
    $self->_newline;
    $self->_characters( '  ' x ( $level-1 ));
    $self->_end_element;
}


sub _start_element {
#
# generate element start event, push name onto stack
#
    my( $self, $name, $atts ) = @_;
    $self->_debug( "START ELEMENT: $name", 3 );
    $level ++;
    push( @elements, $name );
    if( $atts ) {
	$self->SUPER::start_element({ Name => $name, Attributes => $atts });
    } else {
	$self->SUPER::start_element({ Name => $name });
    }
}


sub _end_element {
#
# generate element finished event, pop name from stack
#
    my $self = shift;
    my $name = pop( @elements );
    $self->_debug( "END ELEMENT: $name", 3 );
    $level --;
    $self->SUPER::end_element({ Name => $name });
    return $name;
}


sub _current_element {
#
# return name of current element on stack
#
    my $self = shift;
    return $elements[ $#elements ];
}


sub _inside {
#
# return true if current element or ancestor has given name
#
    my $self = shift;
    my $name = shift;
    foreach( @elements ) {
	return 1 if( $name eq $_ );
    }
    return 0;
}


sub _close_everything {
#
# close all open elements
#
    my $self = shift;
    $self->_debug( "ENTER _close_everything", 2 );
    while( $level ) {
	$self->_indent_end_element;
    }
    $self->_debug( "EXIT _close_everything", 2 );
}


sub _protect_chars {
#
# escape special characters from parsing
#
    my $self = shift;
    my $data = shift;
    $data =~ s/&/\001RTF-AMPERSAND\001/g;
    #$data =~ s/\\>/\001RTF-GREATER-THAN\001/g;
    #$data =~ s/\\</\001RTF-LESS-THAN\001/g;
    return $data;
}


sub _unprotect_chars {
#
# resolve escaped characters
#
    my $self = shift;
    my $data = shift;
    $data =~ s/\001RTF-AMPERSAND\001/&/g;
    $data =~ s/\001RTF-COLON\001/:/g;
    $data =~ s/\001RTF-EQUALS\001/=/g;
    return $data;
}


sub _parse_error {
#
# handle parse exception
#
    my $self = shift;
    print STDERR "PARSE ERROR!\n";
    print STDERR "HERE: $1\n" if( $inbuf =~ /(...........................)/ );
    exit;
}


sub _debug {
#
# print a debug message
#
    my( $self, $message, $level ) = @_;
    if( $features{DEBUG} >= $level ) {
	print STDERR "XML::SAX::RTF DEBUG-$level> $message\n";
    }
}


1;
__END__
##################################################################

=head1 XML::SAX::RTF

XML::SAX::RTF - SAX Driver for Microsoft's Rich Text Format (RTF)

=head1 SYNOPSIS

  use XML::SAX::ParserFactory;
  use XML::SAX::RTF;
  my $handler = new MyHandler;
  my $parser = XML::SAX::ParserFactory->parser( Handler => $handler );
  $parser->parse_file( shift @ARGV );

  package MyHandler;
  sub new {
      my $class = shift;
      my $self = {@_};
      return bless( $self, $class );
  }
  sub start_element {
      my( $self, $data ) = @_;
      print "<", $data->{Name};
      if( exists( $data->{Attributes} )) {
	  my %atts = %{$data->{Attributes}};
	  foreach my $att ( keys %atts ) {
	      my $val = $atts{$att};
	      $val =~ s/\"/&quot;/g;
	      print " $att=\"$val\"";
	  }
      }
      print ">";
  }
  sub end_element {
      my( $self, $data ) = @_;
      print "</", $data->{Name}, ">";
  }
  sub characters {
      my( $self, $data ) = @_;
      print $data->{Data};
  }

=head1 DESCRIPTION

This is a subclass of XML::SAX::Base which implements a SAX driver for
RTF documentation. It generates XML that closely matches the structure
of RTF, i.e. a set of paragraph types with text and inline tags inside.

=head1 AUTHOR

Erik Ray (eray@oreilly.com)

=head1 MAINTAINER NEEDED

The original author seems to have abandoned this module.  If you find the
module useful, please consider adopting it.  Contact grantm@cpan.org for
co-maintainer access.

=head1 COPYRIGHT

Copyright 2002 Erik Ray and O'Reilly & Associates Inc.

=cut
