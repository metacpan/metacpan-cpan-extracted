package XML::TMX::Writer;

use 5.004;
use warnings;
use strict;
use Exporter ();
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = '0.32';
@ISA = 'Exporter';
@EXPORT_OK = qw();

=encoding utf-8

=head1 NAME

XML::TMX::Writer - Perl extension for writing TMX files

=head1 SYNOPSIS

   use XML::TMX::Writer;

   my $tmx = XML::TMX::Writer->new();

   $tmx->start_tmx(id => 'paulojjs');

   $tmx->add_tu('en' => 'some text', 'pt' => 'algum texto');
   $tmx->add_tu('en' => 'some text', 
                'pt' => 'algum texto',
                 -note => [32, 34 ],
                 -prop => { q => 23,
                           aut => "jj"}
               );

   $tmx->end_tmx();

=head1 DESCRIPTION

This module provides a simple way for writing TMX files.

=head1 METHODS

The following methods are available:

=head2 new

  $tmx = new XML::TMX::Writer();

Creates a new XML::TMX::Writer object

=cut

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my %ops = @_;
   my $self = { OUTPUT => \*STDOUT };
   binmode $self->{OUTPUT}, ":utf8" unless exists $ops{-encoding} and $ops{-encoding} !~ /utf.?8/i;
   bless($self, $class);
   return($self);
}

=head2 start_tmx

  $tmx->start_tmx(-output => 'some_file.tmx');

Begins a TMX file. Several options are available:

=over 4

=item -output

Output of the TMX, if none is defined stdout is used by default.

=item tool

Tool used to create the TMX. Defaults to 'XML::TMX::Writer'

=item toolversion

Some version identification of the tool used to create the TMX. Defaults
to the current module version

=item segtype

Segment type used in the I<E<lt>tuE<gt>> elements. Possible values are I<block>,
I<paragraph>, I<sentence> and I<phrase>. Defaults to I<sentence>.

=item srctmf

Specifies the format of the translation memory file from which the TMX document or
segment thereof have been generated.

=item adminlang

Specifies the default language for the administrative and informative
elements I<E<lt>noteE<gt>> and I<E<lt>propE<gt>>.

=item srclang

Specifies the language of the source text. If a I<E<lt>tuE<gt>> element does
not have a srclang attribute specified, it uses the one defined in the
I<E<lt>headerE<gt>> element. Defaults to I<*all*>.


=item datatype

Specifies the type of data contained in the element. Depending on that
type, you may apply different processes to the data.

The recommended values for the datatype attribute are as follow (this list is
not exhaustive):

=over 4

=item unknown

undefined

=item alptext

WinJoust data

=item cdf

Channel Definition Format

=item cmx

Corel CMX Format

=item cpp

C and C++ style text

=item hptag

HP-Tag

=item html

HTML, DHTML, etc

=item interleaf

Interleaf documents

=item ipf

IPF/BookMaster

=item java

Java, source and property files

=item javascript

JavaScript, ECMAScript scripts

=item lisp

Lisp

=item mif

Framemaker MIF, MML, etc

=item opentag

OpenTag data

=item pascal

Pascal, Delphi style text

=item plaintext

Plain text (default)

=item pm

PageMaker

=item rtf

Rich Text Format

=item sgml

SGML

=item stf-f

S-Tagger for FrameMaker

=item stf-i

S-Tagger for Interleaf

=item transit

Transit data

=item vbscript

Visual Basic scripts

=item winres

Windows resources from RC, DLL, EXE

=item xml

XML

=item xptag

Quark XPressTag

=back

=item srcencoding

All TMX documents are in Unicode. However, it is sometimes useful to know
what code set was used to encode text that was converted to Unicode for
purposes of interchange. This option specifies the original or preferred
code set of the data of the element in case it is to be re-encoded in a
non-Unicode code set. Defaults to none.

=item id

Specifies the identifier of the user who created the element. Defaults to none.

=item -note

A reference to a list of notes to be added in the header.

=item -prop

A reference fo a hash of properties to be added in the header. Keys
are used as the C<type> attribute, value as the tag contents.

=back

=cut

sub start_tmx {
    my $self = shift;
    my %options = @_;
    my %o;

    my @time = gmtime(time);
    $o{'creationdate'} = sprintf("%d%02d%02dT%02d%02d%02dZ", $time[5]+1900,
                                 $time[4]+1, $time[3], $time[2], $time[1], $time[0]);

    my $encoding = $options{encoding} || "UTF-8";

    if (defined($options{'-output'})) {
        delete $self->{OUTPUT}; # because it is a glob
        open $self->{OUTPUT}, ">", $options{'-output'}
          or die "Cannot open file '$options{'-output'}': $!\n";
    }

    if ($encoding =~ m!utf.?8!i) {
        binmode $self->{OUTPUT}, ":utf8" 
    }
    $self->_write("<?xml version=\"1.0\" encoding=\"$encoding\"?>\n");

    my @valid_segtype = qw'block sentence paragraph phrase';
    if(defined($options{SEGTYPE}) && grep { $_ eq $options{SEGTYPE} } @valid_segtype) {
        $o{segtype} = $options{SEGTYPE};
    } else {
        $o{segtype} = 'sentence'
    }

    $o{'creationtool'}        = $options{tool}        || 'XML::TMX::Writer';
    $o{'creationtoolversion'} = $options{toolversion} || $VERSION;
    $o{'o-tmf'}               = $options{srctmf}      || 'plain text';
    $o{'adminlang'}           = $options{adminlang}   || 'en';
    $o{'srclang'}             = $options{srclang}     || 'en';
    $o{'datatype'}            = $options{datatype}    || 'plaintext';

    defined($options{srcencoding}) and $o{'o-encoding'} = $options{srcencoding};
    defined($options{id})          and $o{'creationid'} = $options{id};

    $self->_startTag(0, 'tmx', 'version' => 1.4)->_nl;
    $self->_startTag(1, 'header', %o)->_nl;

    $self->_write_props(2, $options{'-prop'}) if defined $options{'-prop'};
    $self->_write_notes(2, $options{'-note'}) if defined $options{'-note'};

    $self->_indent(1)->_endTag('header')->_nl;

    $self->_startTag(0,'body')->_nl->_nl;
}

sub _write_props {
    my ($self, $indent, $props) = @_;
    return unless ref($props) eq "HASH";
    for my $key (sort keys %$props) {
        if (ref($props->{$key}) eq "ARRAY") {
            for my $val (@{$props->{$key}}) {
                if ($key eq "_") {
                    $self->_startTag($indent, 'prop');
                } else {
                    $self->_startTag($indent, prop => (type => $key));
                }
                $self->_characters($val);
                $self->_endTag('prop')->_nl;
            }
        } else {
            if ($key eq "_") {
                $self->_startTag($indent, 'prop');
            } else {
                $self->_startTag($indent, prop => (type => $key));
            }
            $self->_characters($props->{$key});
            $self->_endTag('prop')->_nl;
        }
    }
}

sub _write_notes {
    my ($self, $indent, $notes) = @_;
    return unless ref($notes) eq "ARRAY";
    for my $p (@{$notes}) {
        $self->_startTag($indent, 'note');
        $self->_characters($p);
        $self->_endTag('note')->_nl;
    }
}

=head2 add_tu

  $tmx->add_tu(srclang => LANG1, LANG1 => 'text1', LANG2 => 'text2');
  $tmx->add_tu(srclang => LANG1, 
               LANG1 => 'text1', 
               LANG2 => 'text2',
               -note => ["value1",  ## notes
                        "value2"],
               -prop => { type1 => ["value1","value"], #multiple values
                          _ => 'value2',  # anonymound properties
                         typen => ["valuen"],}
              );

Adds a translation unit to the TMX file. Several optional labels can be
specified:

=over

=item id

Specifies an identifier for the I<E<lt>tuE<gt>> element. Its value is not
defined by the standard (it could be unique or not, numeric or
alphanumeric, etc.).

=item srcencoding

Same meaning as told in B<start_tmx> method.

=item datatype

Same meaning as told in B<start_tmx> method.

=item segtype

Same meaning as told in B<start_tmx> method.

=item srclang

Same meaning as told in B<start_tmx> method.

=back

=cut

sub add_tu {
    my $self = shift;
    my %tuv = @_;
    my %prop = ();
    my @note = ();
    my %opt;

    my $verbatim = 0;
    my $cdata = 0;

    if (exists($tuv{-raw})) {
        # value already includes <tu> tags, hopefully, at least!
        # so we will not mess with it.
        $self->_write($tuv{-raw});
        return;
    }

    for my $key (qw'id datatype segtype srclang creationid creationdate') {
        if (exists($tuv{$key})) {
            $opt{$key} = $tuv{$key};
            delete $tuv{$key};
        }
    }
    if (defined($tuv{srcencoding})) {
        $opt{'o-encoding'} = $tuv{srcencoding};
        delete $tuv{srcencoding};
    }
    $verbatim++            if defined $tuv{-verbatim};
    delete $tuv{-verbatim} if exists  $tuv{-verbatim};

    if (defined($tuv{"-prop"})) {
        %prop = %{$tuv{"-prop"}};
        delete $tuv{"-prop"};
    }
    if (defined($tuv{"-note"})) {
        @note = @{$tuv{"-note"}};
        delete $tuv{"-note"};
    }
    if (defined($tuv{"-n"})) {
        $opt{id}=$tuv{"-n"};
        delete $tuv{"-n"};
    }

    $self->_startTag(0,'tu', %opt)->_nl;

    ### write the prop s <prop type="x-name">problemas 23</prop>
    $self->_write_props(3, \%prop);
    $self->_write_notes(3, \@note);

    for my $lang (sort keys %tuv) {
        my $cdata = 0;
        $self->_startTag(1, 'tuv', 'xml:lang' => $lang);
        if (ref($tuv{$lang}) eq "HASH") {
            $cdata++ if defined($tuv{$lang}{-iscdata});
            delete($tuv{$lang}{-iscdata}) if exists($tuv{$lang}{-iscdata});

            $self->_write_props(2, $tuv{$lang}{-prop}) if exists $tuv{$lang}{-prop};
            $self->_write_notes(2, $tuv{$lang}{-note}) if exists $tuv{$lang}{-note};
            $tuv{$lang} = $tuv{$lang}{-seg} || "";
        }
        $self->_startTag(0, 'seg');
        if ($verbatim) {
            $self->_write($tuv{$lang});
        } elsif ($cdata) {
            $self->_write("<![CDATA[");
            $self->_write($tuv{$lang});
            $self->_write("]]>");
        } else {
            $self->_characters($tuv{$lang});
        }
        $self->_endTag('seg');
        $self->_endTag('tuv')->_nl;
    }
    $self->_endTag('tu')->_nl->_nl;
}


=head2 end_tmx

  $tmx->end_tmx();

Ends the TMX file, closing file handles if necessary.

=cut

sub end_tmx {
    my $self = shift();
    $self->_endTag('body')->_nl;
    $self->_endTag('tmx')->_nl;
    close($self->{OUTPUT});
}

=head1 SEE ALSO

TMX Specification L<https://www.gala-global.org/oscarStandards/tmx/tmx14b.html>

=head1 AUTHOR

Paulo Jorge Jesus Silva, E<lt>paulojjs@bragatel.ptE<gt>

Alberto Simões, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Projecto Natura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub _write {
    my $self = shift;
    print {$self->{OUTPUT}} @_;
    return $self;
}

sub _nl {
    my $self = shift;
    $self->_write("\n");
}

sub _startTag {
  my ($self, $indent, $tagName, %attributes) = @_;
  my $attributes = "";
  $attributes = " ".join(" ",map {"$_=\"$attributes{$_}\""} sort keys %attributes) if %attributes;
  $self->_indent($indent)->_write("<$tagName$attributes>");
}

sub _indent {
    my ($self, $indent) = @_;
    $indent = "  " x $indent;
    $self->_write($indent);
}

sub _characters {
    my ($self, $text) = @_;

    $text = "" unless defined $text;
    $text =~ s/\n/ /g;
    $text =~ s/  +/ /g;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s!&lt;(b|emph)&gt;(.+?)&lt;/\1&gt;!<$1>$2</$1>!gs;

    $self->_write($text);
}

sub _endTag {
    my ($self, $tagName) = @_;

    $self->_write("</$tagName>");
}

1;


