# 
# Copyright (c) 1999 Michael Koehne <kraehe@copyleft.de>
# 
# XML::Handler::YAWriter is free software. You can redistribute
# and/or modify this copy under terms of GNU General Public License.

# Based on XML::Handler::XMLWriter Copyright (C) 1999 Ken MacLeod
# Portions derived from code in XML::Writer by David Megginson

package XML::Handler::YAWriter;

use strict;
use vars qw($VERSION);

$VERSION="0.23";

sub new {
    my $type = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    return bless $self, $type;
}

use vars qw($escapes);

$escapes = { '&'  => '&amp;',
	     '<'  => '&lt;',
	     '>'  => '&gt;',
	     '"'  => '&quot;',
	     '--' => '&#45;&#45;'
	 };

sub start_document {
    my ($self, $document) = @_;
    my ($lc,$uc);

    $self->{'Strings'}  = [];
    $self->{'Escape'}   = $escapes unless $self->{'Escape'};
    $self->{'Encoding'} = "UTF-8"  unless $self->{'Encoding'};

    if ($self->{'AsFile'}) {
	require IO::File;
	$self->{'Output'} = new IO::File(">".$self->{'AsFile'}) || die "$!";
    } elsif ($self->{'AsPipe'}) {
	require IO::File;
	$self->{'Output'} = new IO::File("|".$self->{'AsPipe'}) || die "$!";
    }

    $self->{'NoString'} = ($self->{'Output'} && ! $self->{'AsArray'});

    $self->{'Pretty'}   = {}  unless ref($self->{'Pretty'}) eq "HASH";

    $uc = $self->{'Pretty'};
    foreach (keys %$uc) {
    	$lc = lc $_;
	if ($lc ne $_) {
	    $self->{'Pretty'}{$lc} = $self->{'Pretty'}{$_};
	    delete $self->{'Pretty'}{$_};
	}
    }
    $self->{'LeftSPC'}  = $self->{'Pretty'}{'prettywhitenewline'} ? "\n" : "";
    $self->{'Indent'}   = $self->{'Pretty'}{'prettywhiteindent'} ? "  " : "";
    $self->{'AttrSPC'}  = $self->{'Pretty'}{'addhiddenattrtab'} ? "\n\t" : " ";
    $self->{'ElemSPC'}  = $self->{'Pretty'}{'addhiddennewline'} ? "\n" : "";
    $self->{'CompactAttr'} = $self->{'Pretty'}{'compactattrindent'};
    $self->{'Counter'}  = 0;
    $self->{'Section'}  = 0;
    $self->{LastCount}  = 0;
    $self->{'InCDATA'}  = 0;

    undef $self->{Sendleft};
    undef $self->{Sendbuf};
    undef $self->{Sendright};

    my $sub = 'sub { my ($str,$esc) = @_; $str =~ s/(' .
		join("|", map { $_ = "\Q$_\E" } keys %{$self->{Escape}}).
		')/$esc->{$1}/oge; return $str; }';

    $self->{EscSub} = eval $sub;

    $self->print(
    	undef,
    	"<?xml version=\"1.0\" encoding=\"".$self->{'Encoding'}."\"?>",
    	undef) unless $self->{'Pretty'}{'noprolog'};

}

sub end_document {
    my ($self, $document) = @_;

    $self->print(undef,"\n",undef) unless $self->{'LeftSPC'};
    $self->print(undef,undef,undef);

    my $string = undef;
       $string = join('', @{$self->{Strings}}) if $self->{AsString};

    if ($self->{'AsFile'}) {
	$self->{'Output'}->close();
	undef $self->{'Output'};
    }

    return($string);
}

sub doctype_decl {
    my ($self, $properties) = @_;

    return if $self->{'Pretty'}{'nodtd'};
    return unless $properties->{'Name'};

    my $attspc = $self->{'AttrSPC'};
    my $output = "DOCTYPE ".$properties->{'Name'};
       $output .= $attspc.'SYSTEM "'.$properties->{'SystemId'}.'"' if $properties->{'SystemId'};
       $output .= $attspc.'PUBLIC "'.$properties->{'PublicId'}.'"' if $properties->{'PublicId'};
       $output .= $attspc.$properties->{'Internal'} if $properties->{'Internal'};

    $self->print("<!",$output,">");
}

sub processing_instruction {
    my ($self, $pi) = @_;

    return if $self->{'Pretty'}{'nopi'};
    my $output = undef;

    $output  = $pi->{Target}." " if $pi->{Target};
    $output .= $pi->{Data}." "   if $pi->{Data};

    return unless $output;

    chop $output;

    if ($self->{'Pretty'}{issgml}) {
    	$self->print("<?", $output, ">")
    } else {
    	$self->print("<?", $output, "?>")
    }
}

sub start_element {
    my ($self, $element) = @_;
    my $name;
    my $esc_value;
    my $attr;

    my $output = $element->{Name};
    my $attrspc= $self->{'AttrSPC'};

       $attrspc= "\n".$self->{'Indent'} x (2+$self->{'Counter'})
       		 if $self->{'Indent'};
       $attrspc= " " if $self->{'CompactAttr'};

    if ($element->{Attributes}) {
	$attr = $element->{Attributes};
	foreach $name (sort keys %$attr) {
	    $esc_value = $self->encode($attr->{$name});

    	    $output .= $attrspc . "$name=\"$esc_value\"";
	}
    }

    $self->print("<", $output, ">");
    $self->{'Counter'}++;
}

sub end_element {
    my ($self, $element) = @_;
    my $name   = $element->{Name};

    $self->{'Counter'}--;
    if ($self->{'Pretty'}{'catchemptyelement'} &&
        ($self->{Sendbuf} =~ /^$name/ ) &&
        ($self->{Sendleft} eq "<") &&
        ($self->{Sendright} eq ">") ) {
        $self->{Sendright} = "/>";
    } else {
        $self->print("</", $name, ">");
    }
}

sub characters {
    my ($self, $characters) = @_;

    return unless defined $characters->{Data};

    my $output = $self->{'InCDATA'} ?
        $characters->{Data} :
        $self->encode($characters->{Data});

    if ($self->{'Pretty'}{'catchwhitespace'} && !$self->{'InCDATA'}) {
	$output =~ s/^([ \t\n\r]+)//; $self->print("<!--", $1, "-->") if $1;
	return if $output eq "";
	$output =~ s/([ \t\n\r]+)\$//; $self->print("<!--", $1, "-->") if $1;
	return if $output eq "";
    } elsif ($self->{'Pretty'}{'nowhitespace'} && !$self->{'InCDATA'}) {
	$output =~ s/^([ \t\n\r]+)//;
	return if $output eq "";
	$output =~ s/([ \t\n\r]+)\$//;
	return if $output eq "";
    }
    
    $self->print(undef, $output, undef);
}

sub ignorable_whitespace {
    my ($self, $whitespace) = @_;

    my $output = $whitespace->{Data};

    return unless $output;

    $self->print("<!--", $output, "-->");
#   $self->print($output, undef, undef);
}

sub comment {
    my ($self, $comment) = @_;

    return if $self->{'Pretty'}{'nocomments'};
    my $output = $self->encode($comment->{Data});
    return unless $output;

    $self->print("<!--", " ".$output." ", "-->");
}

sub encode {
    my ($self, $string) = @_;

    return &{$self->{EscSub}}($string, $self->{'Escape'});
}

sub start_cdata {
	my ($self, $cdata) = @_;
	$self->{'InCDATA'} = 1;
	$self->print(undef, '<![CDATA[', undef);
}

sub end_cdata {
	my ($self, $cdata) = @_;
	$self->{'InCDATA'} = 0;
	$self->print(undef, ']]>', undef);
}

sub print {
    my ($self, $left, $output, $right) = @_;
    my $sendbuf = "";

    if ($self->{Sendleft}) {
	$sendbuf .= $self->{'LeftSPC'};
	$sendbuf .= $self->{'Indent'} x $self->{'LastCount'}
            if $self->{'Indent'};
	$sendbuf .= $self->{Sendleft};
    }
    $sendbuf .= $self->{Sendbuf} if defined $self->{Sendbuf};
    $sendbuf .= $self->{'ElemSPC'}.$self->{Sendright} if $self->{Sendright};

    if ($sendbuf ne "") {
    	$self->{Output}->print( $sendbuf )  if     $self->{Output};
    	push(@{$self->{Strings}}, $sendbuf) unless $self->{NoString};
    }

    $self->{Sendleft}  = $left;
    $self->{Sendbuf}   = $output;
    $self->{Sendright} = $right;
    $self->{LastCount} = $self->{'Counter'};
}

1;

=head1 NAME

XML::Handler::YAWriter - Yet another Perl SAX XML Writer

=head1 SYNOPSIS

  use XML::Handler::YAWriter;

  my $ya = new XML::Handler::YAWriter( %options );
  my $perlsax = new XML::Parser::PerlSAX( 'Handler' => $ya );

=head1 DESCRIPTION

YAWriter implements Yet Another XML::Handler::Writer. The reasons for
this one are that I needed a flexible escaping technique, and want
some kind of pretty printing. If an instance of YAWriter is created
without any options, the default behavior is to produce an array of
strings containing the XML in :

  @{$ya->{Strings}}

=head2 Options

Options are given in the usual 'key' => 'value' idiom.

=over

=item Output IO::File

This option tells YAWriter to use an already open file for output, instead
of using $ya->{Strings} to store the array of strings. It should be noted
that the only thing the object needs to implement is the print method. So
anything can be used to receive a stream of strings from YAWriter.

=item AsFile string

This option will cause start_document to open named file and end_document
to close it. Use the literal dash "-" if you want to print on standard
output.

=item AsPipe string

This option will cause start_document to open a pipe and end_document
to close it. The pipe is a normal shell command. Secure shell comes handy
but has a 2GB limit on most systems.

=item AsArray boolean

This option will force storage of the XML in $ya->{Strings}, even if the
Output option is given.

=item AsString boolean

This option will cause end_document to return the complete XML document
in a single string. Most SAX drivers return the value of end_document
as a result of their parse method. As this may not work with some
combinations of SAX drivers and filters, a join of $ya->{Strings} in
the controlling method is preferred.

=item Encoding string

This will change the default encoding from UTF-8 to anything you like.
You should ensure that given data are already in this encoding or provide
an Escape hash, to tell YAWriter about the recoding.

=item Escape hash

The Escape hash defines substitutions that have to be done to any
string, with the exception of the processing_instruction and doctype_decl
methods, where I think that escaping of target and data would cause more
trouble than necessary.

The default value for Escape is

    $XML::Handler::YAWriter::escape = {
            '&'  => '&amp;',
            '<'  => '&lt;',
            '>'  => '&gt;',
            '"'  => '&quot;',
            '--' => '&#45;&#45;'
            };

YAWriter will use an evaluated sub to make the recoding based on a given
Escape hash reasonably fast. Future versions may use XS to improve this
performance bottleneck.

=item Pretty hash

Hash of string => boolean tuples, to define kind of
prettyprinting. Default to undef. Possible string values:

=over

=item AddHiddenNewline boolean

Add hidden newline before ">"

=item AddHiddenAttrTab boolean

Add hidden tabulation for attributes

=item CatchEmptyElement boolean

Catch empty Elements, apply "/>" compression

=item CatchWhiteSpace boolean

Catch whitespace with comments

=item CompactAttrIndent

Places Attributes on the same line as the Element

=item IsSGML boolean

This option will cause start_document, processing_instruction and doctype_decl
to appear as SGML. The SGML is still well-formed of course, if your SAX events
are well-formed.

=item NoComments boolean

Supress Comments

=item NoDTD boolean

Supress DTD

=item NoPI boolean

Supress Processing Instructions

=item NoProlog boolean

Supress <?xml ... ?> Prolog

=item NoWhiteSpace boolean

Supress WhiteSpace to clean documents from prior pretty printing.

=item PrettyWhiteIndent boolean

Add visible indent before any eventstring

=item PrettyWhiteNewline boolean

Add visible newlines before any eventstring

=item SAX1 boolean (not yet implemented)

Output only SAX1 compliant eventstrings

=back

=back

=head2 Notes:

Correct handling of start_document and end_document is required!

The YAWriter Object initialises its structures during start_document
and does its cleanup during end_document.  If you forget to call
start_document, any other method will break during the run. Most likely
place is the encode method, trying to eval undef as a subroutine. If
you forget to call end_document, you should not use a single instance
of YAWriter more than once.

For small documents AsArray may be the fastest method and AsString
the easiest one to receive the output of YAWriter. But AsString and
AsArray may run out of memory with infinite SAX streams. The only
method XML::Handler::Writer calls on a given Output object is the print
method. So it's easy to use a self written Output object to improve
streaming.
  
A single instance of XML::Handler::YAWriter is able to produce more
than one file in a single run. Be sure to provide a fresh IO::File
as Output before you call start_document and close this File after
calling end_document. Or provide a filename in AsFile, so start_document
and end_document can open and close its own filehandle.
  
Automatic recoding between 8bit and 16bit does not work in any Perl correctly !

I have Perl-5.00563 at home and here I can specify "use utf8;" in the right
places to make recoding work. But I dislike saying "use 5.00555;" because
many systems run 5.00503.
  
If you use some 8bit character set internally and want use national characters,
either state your character as Encoding to be ISO-8859-1, or provide an Escape
hash similar to the following :

    $ya->{'Escape'} = {
		    '&'  => '&amp;',
		    '<'  => '&lt;',
		    '>'  => '&gt;',
		    '"'  => '&quot;',
		    '--' => '&#45;&#45;'
		    'ö' => '&ouml;'
		    'ä' => '&auml;'
		    'ü' => '&uuml;'
		    'Ö' => '&Ouml;'
		    'Ä' => '&Auml;'
		    'Ü' => '&Uuml;'
		    'ß' => '&szlig;'
		    };

You may abuse YAWriter to clean whitespace from XML documents. Take a look
at test.pl, doing just that with an XML::Edifact message, without querying
the DTD. This may work in 99% of the cases where you want to get rid of
ignorable whitespace caused by the various forms of pretty printing.
  
    my $ya = new XML::Handler::YAWriter(
        'Output' => new IO::File ( ">-" );
        'Pretty' => {
            'NoWhiteSpace'=>1,
            'NoComments'=>1,
            'AddHiddenNewline'=>1,
            'AddHiddenAttrTab'=>1,
        } );
  
XML::Handler::Writer implements any method XML::Parser::PerlSAX wants.
This extends the Java SAX1.0 specification. I have in mind using
Pretty=>SAX1=>1 to disable this feature, if abusing YAWriter for a
SAX proxy.
  
=head1 AUTHOR

Michael Koehne, Kraehe@Copyleft.De

=head1 Thanks

"Derksen, Eduard (Enno), CSCIO" <enno@att.com> helped me with the Escape
hash and gave quite a lot of useful comments.

=head1 SEE ALSO

L<perl> and L<XML::Parser::PerlSAX>

=cut
