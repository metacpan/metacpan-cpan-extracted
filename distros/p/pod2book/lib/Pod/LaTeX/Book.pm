package Pod::LaTeX::Book;

use strict;
use warnings;

use 5.008;

use Carp;
use Config::Any;
use Params::Validate qw(:all);
use Data::Dumper;
use Perl6::Slurp;
use Pod::Find;
use Pod::ParseUtils;  # for Pod::Hyperlink

use base qw/ Pod::LaTeX /;

use vars qw/ $VERSION /;

$VERSION = '0.0.1';



=pod

=head1 NAME

Pod::LaTeX::Book - Compile POD pages into a LaTeX book.



=head1 VERSION

This document describes Pod::LaTeX::Book version 0.0.1


=head1 SYNOPSIS

    use Pod::LaTeX::Book;

    my $parser = Pod::LaTeX::Book->new ( );

    # configure
    $parser->configure( $cfgRef );
    # or
    $parser->configure_from_file( 'config' );

    # output .tex file
    $parser->parse( 'out.tex' );


    # script for producing a LaTeX book
    pod2book --conf=conf_file --out=tex_file

=head1 DESCRIPTION

This module aims to provide a mechanism to compile the POD
documentation for a set of modules into a printable collection. LaTeX
is used as an intermediate format from which both pdf and printed
versions can be produced.

The modules builds on the functionality provided by Pod::LaTeX. For
this purpose several methods from Pod::LaTeX are either overridden or
extended. Perhaps most notably, this package uses the LaTeX packages
C<hyperref>, C<listings>, and C<fancyvrb> to produce more attractive,
extensively hyper-linked PDF.


=head1 INTERFACE

The following routines provide the public interface. Note, that the
methods from L<Pod::LaTeX>, from which this module inherits,
are also available.


=begin __PRIVATE__

=head2 C<initialize>

Initialise the object. This method is subclassed from C<Pod::LaTeX>.
The base class method is invoked.

=end __PRIVATE__

=cut


sub initialize{
    my $self = shift;

    $self->{_PodFiles}          = [ ]; # for storing Pod's in the book
    $self->{_VerbatimParagraph} = '';  # for building listings
    $self->{_Codes}             = [ ]; # for storing C<> interior sequences
    $self->{_Skipping}          = 0;   # for skipping sections
    $self->{_PastName}          = 0;   # for skipping sections
    $self->{_DoSkip}            = 0;   # for skipping sections

    # Run base initialize
    $self->SUPER::initialize;

}

=head2 C<configure>

Provide information about the documents to be combined and options for
the output to be produced. This function should not be invoked
directly; use L<configure_from_file> instead which calls this function.

Basic validation of the configuration parameters is performed.

=cut

sub configure{
    my $self    = shift;
    my $config  = shift;

    # validation and defaults
    # first check that the required sections exist ...
    my @temp = ( $config );
    validate( @temp,
              {
               DocOptions   => {
                                type => HASHREF,
                                optional => 0
                            },
               DocStructure => {
                                type => ARRAYREF,
                                optional => 0
                            },
               } );

    $self->{_DocOptions}   = $config->{DocOptions};
    $self->{_DocStructure} = $config->{DocStructure};

    # ... then validate dcument options
    @temp = ( $self->{_DocOptions} );
    %{$self->{_DocOptions}} = validate( @temp ,
              {
               Title         => { # required, string
                                 type => SCALAR,
                                 optional => 0
                             },
               Author        => { # optional, string, default: ''
                                 type => SCALAR,
                                 default => ''
                             },
               Date          => { # optional, string, default: latex sets date
                                 type => SCALAR,
                                 default => '\today'
                             },
               TexOut        => { # optional, string, default: 'book.tex'
                                 type => SCALAR,
                                 default => 'book.tex'
                             },
               UserPreamble  => { # optional, string, no default
                                 type => SCALAR,
                                 optional => 1
                             },
               UserPostamble => { # optional, string, no default
                                 type => SCALAR,
                                 optional => 1
                                 },
               AddPreamble   => { # optional, default FALSE
                                 type => SCALAR,
                                 default => 0
                                 },
               Head1Level    => { # optional, default: 1 (\section)
                                 type => SCALAR,
                                 default => 1
                                 },
               LevelNoNum    => { # optional, default: 4 (\paragraph)
                                 type => SCALAR,
                                 default => 4
                                 },
               ReplaceNAMEwithSection => { # optional, default TRUE
                                          type => SCALAR,
                                          default => 1
                                      },
               UniqueLabels  => { # optional, default TRUE
                                 type => SCALAR,
                                 default => 1
                                 }
           } );
    #print "Options: ", Dumper( $self->{_DocOptions} );

    # Finally, validate the document structure
    my $DSRef = $self->{_DocStructure};

    for ( @$DSRef ) {

        # section command can be used to break the document into parts
        if ( exists( $_->{Section} ) ) {
            @temp = ( $_->{Section} );
            %{$_->{Section}} = validate( @temp,
                      {
                       Title  => { # required, string for section title
                                  type => SCALAR,
                                  optional => 0
                              },
                       Level  => { # optional, string, default: part
                                  type => SCALAR,
                                  default => 'part'
                              },
                       } );
        }

        # input commands are used to insert pod or tex files
        elsif ( exists( $_->{Input} ) ) {
            @temp = ( $_->{Input} );
            %{$_->{Input}} = validate( @temp,
                      {
                       FileOrPod  => { # required, string, tex file name or
                                       # POD document to include
                                      type => SCALAR,
                                      optional => 0
                              },
                       SkipUntil  => { # optional, string, indicates section
                                       # title until which output is to be
                                       # supressed; title may be abbreviated.
                                      type => SCALAR,
                                      default => undef
                              },
                       SkipFrom   => { # optional, string, indicates section
                                       # title from which output is to be
                                       # supressed; title may be abbreviated.
                                      type => SCALAR,
                                      default => undef
                              },
                       } );

            # store pods for reference (don't worry about including tex files)
            push @{$self->{_PodFiles}}, $_->{Input}->{FileOrPod};
        }
        else {
            confess "Invalid key: only Section and Input are allowed";
        }
    }
    # print "Structure: ", Dumper( $self->{_DocStructure} );


    return $self;
}

=head2 C<configure_from_file>

Read configuration information from a file. The file may be in any
format supported by L<Config::Any>.

The format of the file is as follows (in YAML):

   ---
   DocOptions:
     Title:  Your Book
     Author: Your Name
     Date: August 2, 2007
     TexOut: mybook.tex
     UserPreamble: |
       \documentclass{book}
     UserPostamble: |
       \cleardoublepage
       \addcontentsline{toc}{chapter}{\numberline{}Index}
       \printindex
       \end{document}
     AddPreamble: 1
     Head1Level:  0
     LevelNoNum:  4
   DocStructure:
     - Input:
         FileOrPod: frontmatter.tex
     - Section:
         Level: part
         Title: First Part
     - Input:
         FileOrPod: Catalyst::Manual::Tutorial
         SkipUntil: DESCRIPTION
     - Input:
         FileOrPod: Catalyst::Manual
         SkipFrom: THANKS
     - Section:
         Level: part
         Title: Appendix

Of the document options, only C<Title> is required. All others have
sensitive defaults. The parameters C<AddPreamble>, C<Head1Level>, and
C<LevelNoNum> are passed to L<Pod::LaTeX>.

If the standard preamble is insufficient, it is recommended to set
things up as above. Specify a minimal C<UserPreamble>, set
C<AddPreamble> to a true value, and read the remainder of the preamble
from the first input file (here, C<frontmatter.tex>). Note, that the
preamble must include at least the following LaTeX packages.

=over

=item hyperref

=item listings

=item fancyvrb

=back

The C<DocStructure> specifies the sequence of documents to be
included, it consists of a list of C<Section> and C<Input>
directives. The C<Section> directives can be used to provide
additional section commands (e.g., parts). The C<Input> directives
specify the file name of a LaTeX document to be included or the name
of a POD page. POD pages are parsed and translated to LaTeX. It is
possible to skip leading sections in a POD via the C<SkipUntil>
directive or trailing sections via the C<SkipFrom> directive.

=cut

sub configure_from_file{
    my $self = shift;
    my $file = shift;

    my $cfg = Config::Any->load_files({files => [ $file ], use_ext => 1 });

    # print 'Config:', Dumper( $cfg->[0]  );

    for (@$cfg) {
        my ($filename, $config) = each %$_;
        $self->configure($config);
        # warn "loaded config from file: $filename";
    }

    return $self;
}

=pod

=head2 C<parse>

Construct the latex document by converting each of the PODs from the
configuration file. The bulk of the work is done by
L<Pod::LaTeX/parse_from_file>.

=cut

sub parse {
    my $self = shift;

    # open file for output
    my $fh_out;
    my $outfile = $self->{_DocOptions}->{TexOut};

    open $fh_out, '>', $outfile or confess "Can't create $outfile: $!";

    # write preamble to output
    my $preamble = $self->make_preamble( );
    print $fh_out $preamble;

    # loop over elements of structure and produce output
    #    uses direct output for non-pod material
    #    Pod::LaTex::parse_from_file for pod
    foreach my $element ( @{$self->{_DocStructure}} ) {
        my $detailRef;

        if ( exists( $element->{Section} ) ) {
            $detailRef = $element->{Section};

            if ( $detailRef->{Title} =~ /Appendix/ ) {
                print $fh_out "\n\n\\appendix\n\n";
            }

            print $fh_out "\n\n\\" . $detailRef->{Level} .
                "\{$detailRef->{Title}\}\n\n"
        }

        if ( exists( $element->{Input} ) ) {
            $detailRef = $element->{Input};

            # is it a tex file? slurp in the file and dump it back out
            if ( $detailRef->{FileOrPod} =~ /.tex$/ ) {
                print $fh_out "\n\%\%   File: $detailRef->{FileOrPod}\n\n";

                my $texfile = slurp $detailRef->{FileOrPod};
                print $fh_out $texfile;
            }
            else { # it's got to be a POD
                # reset configuration for Pod::LaTeX
                $self->AddPreamble( 0 );  # no individual preambles;
                $self->UserPreamble( '' );
                $self->UserPostamble( '' );
                $self->Head1Level( $self->{_DocOptions}->{Head1Level} );
                $self->LevelNoNum( $self->{_DocOptions}->{LevelNoNum} );
                $self->ReplaceNAMEwithSection($self->{_DocOptions}->{ReplaceNAMEwithSection} );
                $self->UniqueLabels( $self->{_DocOptions}->{UniqueLabels} );
                $self->Label('');

                # prepare for skipping
                $self->{_Skipping} = defined $detailRef->{SkipUntil} ? 1 :0;
                $self->{_PastName} = not $self->ReplaceNAMEwithSection();
                $self->{_DoSkip}   = $self->{_Skipping} && $self->{_PastName};
                $self->{SkipUntil} = $detailRef->{SkipUntil};
                $self->{SkipFrom}  = $detailRef->{SkipUntil};

                # find file containing pod and parse
                my $location = Pod::Find::pod_where( { -inc => 1 },
                                                     $detailRef->{FileOrPod} );
                unless( defined( $location) ) {
                    confess "POD not found for $detailRef->{FileOrPod}";
                }

                print $fh_out "\n\%\%   POD:  $detailRef->{FileOrPod}";
                print $fh_out "\n\%\%   File: $location\n\n";

                $self->parse_from_file( $location, $fh_out );

                # output a pending verbatim paragraph (if needed)
                $self->output_verbatim();

            }
        }
    }

    # write postamble
    my $postamble = $self->make_postamble( );
    print $fh_out $postamble;

}

############################### Overridden subroutines ####################

=pod

=head1 Overriden Subroutines

The following routines from L<Pod::LaTeX> are overridden to modify or
extend functionality.

=cut

=pod

=head2 C<verbatim>

Overwrite the C<verbatim> in L<Pod::LaTeX> to use the I<listing>
environment rather than I<verbatim>.

The original package breaks listings up into chunks separated by empty
lines, here we combine those. output does not happen until we're done
with the entire block. See L</output_verbatim>.

=cut

sub verbatim {
    my $self = shift;
    my ($paragraph, $line_num, $parobj) = @_;

    # return immediately if we're currently skipping output
    return if $self->{_DoSkip};

    # Expand paragraph unless in =begin block
    if ($self->{_dont_modify_any_para}) {
        # Just print as is
        $self->_output($paragraph);

    } else {

        return if $paragraph =~ /^\s+$/;

        # Clean trailing space
        $paragraph =~ s/\s+$//;

        # Clean tabs. Routine taken from Tabs.pm
        # by David Muir Sharnoff muir@idiom.com,
        # slightly modified by hsmyers@sdragons.com 10/22/01
        my @l = split("\n",$paragraph);
        foreach (@l) {
            1 while s/(^|\n)([^\t\n]*)(\t+)/
                $1. $2 . (" " x
                          (4 * length($3)
                           - (length($2) % 4)))
                    /sex;
        }
        $paragraph = join("\n",@l);
        # End of change.


        # append paragraph to pending verbatim block
        if ($self->{_VerbatimParagraph} eq '' ) {
            $self->{_VerbatimParagraph} = $paragraph;
        }
        else {
            $self->{_VerbatimParagraph} .= "\n\n" . $paragraph;
        }
    }
}

=pod

=head2 C<interior_sequence>

Partially overwrite the functionality in Pod::LaTeX. Specifically, we
replace processing of C-tags to use the C<listings> of C<fancyvrb>
package. Also, proper hyperlinking is provided via the C<hyperref>
package.

=cut

sub interior_sequence {
    my $self = shift;

    my ($seq_command, $seq_argument, $pod_seq) = @_;

    # override C-tags
    if ($seq_command eq 'C') {
        my $text = $seq_argument;

        # often codes are just URL's, set those via \\texttt
        if ( $text =~ /(\w+):\/\/(\S+)/ ) {
            $text = $self->_replace_special_chars( $text );
            #$text =~ s/(\w)(\/|\?|\.)(\w)/$1$2\\-$3/g;
            $text =~ s/(\/|\?|\.|=)(\w)/\\discretionary{$1}{$2}{$1$2}/g;

            return ' \texttt{'. $text . '} ';
        }

        # A list of separators we're willing to use for e.g., \lstinline!time!
        my @separators = ( '!', '+','|', '=', '*', 'q', 'z', 'k', 'Q', 'Z');

        my $separator;

        do {
            $separator = shift @separators;
        } while ( index( $text, $separator ) >= 0 );

        unless (defined( $separator )) {
            confess "Can't find a suitable separator for $text.";
        };

        # we turn long-ish in-line codes into displayed versions
        if ( length( $text ) > 30 && $self->{_inTextBlock}) {
            return "\n" .
                '\begin{lstlisting}' .
                "\n$text\n" . '\end{lstlisting}' . "\n";
        }
        else {
            return '\lstinline[breaklines=true]' .
                $separator . $text . $separator;
        }
    }


    # override L-tags
    elsif ($seq_command eq 'L') {
        my $link = new Pod::Hyperlink($seq_argument);

        # undef on failure
        unless (defined $link) {
            carp $@;
            return;
        }

        # external links
        if ( $link->type() eq 'hyperlink' ) {
            my $target = $link->node();
            # allow hyphenation in text
            (my $text   = $link->text()) =~
                s/(\/|\?|\.|=)(\w)/\\discretionary{$1}{$2}{$1$2}/g;
            return "\\href{$target}{$text}";
        }
        elsif ( $link->page() eq '' ) { # link within this POD
             my $target = $self->_create_label( $link->node( ) );
             my $text   = $link->text();

             return "\\hyperlink{$target}{$text}";
        }
        else {                          # link to another POD page
            my $page = $link->page( );

            my $foundPage = grep { $page eq $_ } @{$self->{_PodFiles}};

            if ( $foundPage > 0 ){
                # case 1: link to a page in this collection of PODs
                my $OrigLabel = $self->Label;
                $self->Label( $page );

                my $target = $link->node( )
                    ? $self->_create_label( $link->node( ) )
                    : "_$page";
                (my $text   = $link->text()) =~
                    s/::(\w+)/\\discretionary{::}{$1}{::$1}/g;

                return "\\hyperlink{$target}{$text}";

                $self->Label( $OrigLabel ) =~
                    s/::(\w+)/\\discretionary{::}{$1}{::$1}/g;
            }
            else {
            # case 2: link to a page NOT in this collection (link to CPAN)
                my $cpan_link = "http://search.cpan.org/search?query=" .
                    $link->page();
                (my $text = $link->text())=~
                    s/::(\w+)/\\discretionary{::}{$1}{::$1}/g;

                return "\\href{$cpan_link}{$text}";
            }
        }

        # print "Link: $seq_argument ", Dumper( $link );
    }
    else {
        # anything we didn't process is passed to Pod::LaTeX
        return
            $self->SUPER::interior_sequence( $seq_command,
                                             $seq_argument, $pod_seq );
    }
}


=pod

=head2 C<textblock>

Plain text paragraph. Modified to output any pending C<verbatim> output.

=cut

sub textblock {
  my $self = shift;
  my ($paragraph, $line_num, $parobj) = @_;

  # output a pending verbatim paragraph (if needed)
  $self->output_verbatim();

  # return immediately if we're currently skipping output
  return if $self->{_DoSkip};

  # mark the fact that we're in a text block
  $self->{_inTextBlock} = 1;

  # invoke parent function
  $self->SUPER::textblock( $paragraph, $line_num, $parobj );

  # mark the fact that we're not in a text block
  $self->{_inTextBlock} = 0;
}


=pod

=head2 C<command>

Process basic pod commands. Modified to output any pending C<verbatim> output.

=cut

sub command {
  my $self = shift;
  my ($command, $paragraph, $line_num, $parobj) = @_;

  # output a pending verbatim paragraph (if needed)
  $self->output_verbatim();

  # update skipping behaviour
  if ( $self->{_DoSkip} ) {
      $self->{_DoSkip} = 0
          if $paragraph =~ /$self->{SkipUntil}/ && $command =~ /head/i;
    }
    else {
        $self->{_DoSkip} = 1
            if defined $self->{SkipFrom} &&
                $paragraph =~ /$self->{SkipFrom}/ &&
                $command =~ /head/i;
    }

  # return immediately if we're currently skipping output
  return if $self->{_DoSkip};

  # invoke parent function
  $self->SUPER::command( $command, $paragraph, $line_num, $parobj );

}

=pod

=begin __PRIVATE__

=head2 C<head>

Print a heading of the required level.

  $parser->head($level, $paragraph, $parobj);

The first argument is the pod heading level. The second argument
is the contents of the heading. The 3rd argument is a Pod::Paragraph
object so that the line number can be extracted.

This is an extension of the function with the same name in
L<Pod::LaTeX>. Additonal functionality includes creating internal
hyperlinks (using hyperref) and skipping of document sections.

Also, the output produced for latex's section commands is changed so
that labels and index entries are moved outside the section
command. This is better because section titles are "moving" arguments
and the included commands are "fragile".

=cut

sub head {
    my $ self = shift;

    my $num       = shift;
    my $paragraph = shift;
    my $parobj    = shift;

    # If we replace 'head1 NAME' with a section
    # we return immediately if we get it
    if ($self->{_CURRENT_HEAD1} =~ /^NAME/i &&
        $self->ReplaceNAMEwithSection()) {
        # mark the fact that we found just found 'head Name'
        $self->{_PastName} = -1;
        return;
    }

    # return immediately if we're currently skipping output
    return if $self->{_DoSkip};

    # Create a label
    my $label = $self->_create_label($paragraph);

    # Create an index entry
    my $index = $self->_create_index($paragraph);

    # Work out position in the above array taking into account
    # that =head1 is equivalent to $self->Head1Level

    my $level = $self->Head1Level() - 1 + $num;

    # Warn if heading to large
    my @LatexSections = (qw/
                  chapter
                  section
                  subsection
                  subsubsection
                  paragraph
                  subparagraph
                  /);

    if ($num > $#LatexSections) {
        my $line = $parobj->file_line;
        my $file = $self->input_file;
        warn "Heading level too large ($level) for LaTeX at line $line of file $file\n";
        $level = $#LatexSections;
    }

    # Check to see whether section should be unnumbered
    my $star = ($level >= $self->LevelNoNum ? '*' : '');

    # if there are latex commands inside the section text, we insert a
    # \protect statement before
    $paragraph =~ s/\\(\w+)/\\protect\\$1/g;

    # allow hyphenation after ::
    $paragraph =~ s/::(\w+)/\\discretionary{::}{$1}{::$1}/g
        unless $paragraph =~ /\\protect/;

    # Section
    $self->_output("\n\\" .$LatexSections[$level] .$star ."{$paragraph}\n");
    $self->_output("\\label{".$label ."}\n");
    $self->_output("\\index{".$index."}\n") unless $index =~ m/http:\/\//;
    # additional hypertarget for hyperref
    # my $label = $self->_create_label($paragraph);
    $self->_output("\\hypertarget{$label}{}\n\n");

    # check  if we just set the 'Head = Name' information
    if ( $self->{_PastName} == -1 ) {
        $self->{_PastName} = 1;
        $self->{_DoSkip} = $self->{_Skipping};
    }
}

=pod

=head2 C<_replace_special_chars>

Subroutine to replace characters that are special in C<latex>
with the escaped forms

  $escaped = $parser->_replace_special_chars($paragraph);

Need to call this routine before interior_sequences are munged but not
if verbatim or C<>. It must be called before interpolation of interior
sequences so that curly brackets and special latex characters inserted
during interpolation are not themselves escaped. This means that < and
> can not be modified here since the text still contains interior
sequences.

Special characters and the C<latex> equivalents are:

  }     \}
  {     \{
  _     \_
  $     \$
  %     \%
  &     \&
  \     $\backslash$
  ^     \^{}
  #     \#

Modified this routine to ignore C<> commands and leave ~ alone.

=cut

sub _replace_special_chars {
  my $self = shift;
  my $paragraph = shift;

  # Go through paragraph and extract all C<> sequences and replace
  # them with something innocuous: 'CqqPodBook', a string that's
  # unlikely to appear. They will be restored after interpolation by
  # _replace_special_chars_late.

  # make paragraph into a single line, in case C<> breaks across lines.
  $paragraph = join ' ', split /\s+/, $paragraph;

  # Extract C<> sequences and save for later reinsertions, this is
  # tricky because pod also allows C<<>>, and so on. We simply rely on
  # L<Pod::Parser>'s C<parse_text()> to help us find C<> interior
  # sequences.


  my @Codes;

  if ( $paragraph =~ m/C(<(?:<+\s)?)/ ) {

    my $ptree = $self->parse_text( $paragraph );

    $paragraph = $self->expandCparagraph( $ptree, \@Codes );
  }

  # hide \~ (as it occurs in URLs) from replacement
  $paragraph =~ s/\/~/BACKSLASHTILDE/g;

  # invoke function in parent
  $paragraph = $self->SUPER::_replace_special_chars( $paragraph );

  # store @Codes so that they can be re-inserted by _replace_special_chars_late
  $self->{_Codes} = \@Codes;

  # check for URL's that aren't marked with L<> or bare e-mail addresses
  #if ( $paragraph =~ /\w+:\/\/\S+/ && not $paragraph =~ /(?:<|\|)\w+:\/\/\S+/ ) {
  #    $paragraph =~ s/(\w+:\/\/\S+)/ L<$1> /g;
  #}

  # $paragraph =~ s/[^<]\s*(\w+@\w+(\w|\.)+)\s*[^>]/ L<mailto:$1> /g;

  return $paragraph;

}

=pod

=head2 C<_replace_special_chars_late>

Replace special characters that can not be replaced before interior
sequence interpolation. See C<_replace_special_chars> for a routine
to replace special characters prior to interpolation of interior
sequences.

Does the following transformation:

  <   $<$
  >   $>$
  |   $|$

Modified this routine to reinsert C<> commands and then interpolate them.

=cut

sub _replace_special_chars_late {
  my $self = shift;
  my $paragraph = shift;

  # invoke function in parent
  $paragraph = $self->SUPER::_replace_special_chars_late( $paragraph );

  # Put C<> back in and interpolate
  if ( $paragraph =~ /CqqPodBook/ ) {
      my @Codes = @{$self->{_Codes}};

      my $new_para = '';
      my $segment;

      # put /~ back
      $paragraph =~ s/BACKSLASHTILDE/\/~/g;

      # split paragraph into segments separated by marker
      my @Segments = split 'CqqPodBook', $paragraph;
      foreach my $code (  @Codes ) {
          $segment = shift @Segments;

          # append original code where marker used to be
          $segment = '' unless defined $segment;
          $new_para .= $segment . $code;
      }
      # don't forget the final segment
      $segment = shift @Segments;
      $new_para .= $segment if defined( $segment );

      # now, the C<> tags must be interpolated
      $paragraph = $self->interpolate( $new_para, 1);
  }


  return $paragraph;
}

=pod

=head2 C<add_item>

Augment the functionality of the function in the parent by setting a
hypertarget if the item creates an index entry.

  $parser->add_item($paragraph, $line_num);

=end __PRIVATE__

=cut

sub add_item {
  my $self = shift;
  my $paragraph = shift;
  my $line_num = shift;

  # return immediately if we're currently skipping output
  return if $self->{_DoSkip};

  # figure out the type of list (from Pod::LaTeX)
  $paragraph =~ s/\s+$//;
  $paragraph =~ s/^\s+//;

  my $type;
  if (substr($paragraph, 0,1) eq '*') {
      $type = 'itemize';
  } elsif ($paragraph =~ /^\d/) {
      $type = 'enumerate';
  } else {
      $type = 'description';
  }


  # description texts cannot contain \lstinline or \Verb commands,
  # change to \textt
  if ($type eq 'description') {
      $paragraph =~ s/\\lstinline\[breaklines=true\](\S)/DqqPodBook/g;
      my $delim = $1;

      if ( defined $delim ) {
          my $pos = -1;
          while ( $paragraph =~ m/DqqPodBook(.+)$delim/g ) {
              my $contents = $1;
              my $pos = pos( $paragraph )-1;
              substr( $paragraph, $pos, 1 ) = 'PodBookDqq';

              # ensure $contents contains nothing objectionable to latex
              $contents = $self->_replace_special_chars( $contents );
              $contents = $self->_replace_special_chars_late( $contents );

              $paragraph =~ s/DqqPodBook(.+)PodBookDqq/\\texttt\{$contents\}/;

          }
      }


  }

  # invoke function in parent
  $self->SUPER::add_item( $paragraph, $line_num );

  # if $paragraph contains an \\index call, we also set a hypertarget.
  if ( $paragraph =~ /\\index\{(\S+)\}/ ) {
      ( my $label = $1 ) =~ s/!/_/g;
      $self->_output("\\hypertarget{$label}{}");
  }

}


############################### Private Subroutines ########################

=pod

=begin __PRIVATE__

=head1 Private Subroutines that are exclusive to this package

=cut

=pod

=head2 C<make_preamble>

Create a string for the document preamble; this normally starts with
I<\documentclass{book}> and ends with I<\begin{document}>.

If C<AddPreamble> is C<FALSE> no output is produced. If
C<UserPreamble> is set, then the preamble is set from that. Otherwise,
a default preamble is produced.

=cut

sub make_preamble{
    my $self = shift;

    my $preamble = '';

    if ( $self->{_DocOptions}->{AddPreamble} ) {

        if ( exists( $self->{_DocOptions}->{UserPreamble} ) ){
            $preamble = $self->{_DocOptions}->{UserPreamble};
        }
        else { # default preamble
            my $config = '';
            for (@{$self->{_DocStructure}}) {
                my ($type, $detailRef) = each( %{$_} );
                $config .= "\n" . '%%    ' . $type . ":";
                foreach my $field ( keys %$detailRef ) {
                    if ( defined( $detailRef->{$field} ) ) {
                        $config .= "\n" . '%%       ' . $field . ": " .
                            $detailRef->{$field};
                    }
                }
            }

            my $class  = ref($self);
            my $now    = gmtime(time);
            my $author = $self->{_DocOptions}->{Author};
            my $title  = $self->{_DocOptions}->{Title};
            my $date   = $self->{_DocOptions}->{Date};

            $preamble = << "__END_PREAMBLE__"
\\documentclass[11pt]{book}
\\usepackage[T1]{fontenc}
\\usepackage{textcomp}

\\usepackage[pdftex,
            pdftitle={$title},
            colorlinks,
            breaklinks,
            pdfauthor={$author}]{hyperref}

\\usepackage[papersize={7.44in,9.68in},scale=0.8]{geometry}

\\usepackage{listings}
\\newcommand{\\MyHookSign}{\\hbox{\\ensuremath\\hookleftarrow}}
%
%%  Latex generated from configuration: $config
%%  Using the perl module $class
%%  Converted on $now


\\usepackage{makeidx}
\\makeindex

\\usepackage{fancyvrb}

\% \\lstset{basicstyle={\\small\\ttfamily},numberbychapter=false,showstringspaces=false,\%
\%   classoffset=0,\%
\%   language=Perl,commentstyle={\\footnotesize\\ttfamily},keywordstyle={\\bfseries},identifierstyle={\\ttfamily},\%
\%  classoffset=1,\%
\% language=SQL,commentstyle={\\footnotesize\\ttfamily},keywordstyle={\\bfseries},identifierstyle={\\ttfamily}}

\\lstset{basicstyle={\\footnotesize\\ttfamily},
         breaklines=true,prebreak={\\space\\MyHookSign}}

\\begin{document}
\\pagestyle{empty}

\\title{$title}
\\author{$author}
\\date{$date}

\\maketitle

\\cleardoublepage
\\pagenumbering{roman}
\\pagestyle{headings}

\\addcontentsline{toc}{chapter}{\\numberline{}Contents}
\\tableofcontents

\\cleardoublepage
\\pagenumbering{arabic}

__END_PREAMBLE__

         }
    }

    return $preamble;
}



=pod

=head2 C<make_postamble>

Create a string for the document postamble; this normally is just
I<\end{document}>.

If C<AddPreamble> is C<FALSE> no output is produced. If
C<UserPostamble> is set, then the postamble is set from that. Otherwise,
a default postamble is produced.

=cut

sub make_postamble{
    my $self = shift;

    my $postamble = '';

    if ( $self->{_DocOptions}->{AddPreamble} ) {

        if ( exists( $self->{_DocOptions}->{UserPostamble} ) ){
            $postamble = $self->{_DocOptions}->{UserPostamble};
        }
        else { # default postamble

            $postamble = '\printindex' . "\n" . '\end{document}' . "\n";
        }
    }

    return $postamble;
}

=pod

=head2 C<output_verbatim>

Output a pending verbatim block.

=cut


sub output_verbatim{
    my $self =shift;

    # nothing to output? return.
    if ( $self->{_VerbatimParagraph} eq '' ) {
        return;
    }

    my $paragraph = $self->{_VerbatimParagraph};

    my $maxLen = 0;
    my @lines = split /\n/, $paragraph;
    for ( @lines ) {
        my $len = length;
        $maxLen = $len unless $len < $maxLen;
    }

    # $self->_output("\n\nLength of line: $maxLen\n\n");


    my $VerbatimOptions = 'fontfamily=courier,gobble=1,frame=lines';

    if ( $maxLen > 95 ) {
        $self->_output("\n" . '\begin{lstlisting}[frame=lines,gobble=1]' .
                   "\n$paragraph\n".
                   '\end{lstlisting}'."\n\n");
    }
    else{
        if ( $maxLen > 83 ) {
            $VerbatimOptions   .= ',fontsize=\scriptsize';
        }
        elsif ( $maxLen > 70 ) {
            $VerbatimOptions   .= ',fontsize=\footnotesize';
        }
        else {
            $VerbatimOptions   .= ',fontsize=\small';
        }

        $self->_output("\n" . '\begin{Verbatim}[' . $VerbatimOptions . ']' .
                   "\n$paragraph\n".
                   '\end{Verbatim}'."\n\n");
    }

    # reset $self->{_VerbatimParagraph}
    $self->{_VerbatimParagraph} = '';
}

=pod

=head2 C<expandCparagraph>

Process a paragraph containing C<> tags to protect those tags from
interpolation.

=cut

sub expandCparagraph{
    my $self      = shift;
    my $ptree     = shift;
    my $CodesRef  = shift;

    my $CParagraph = '';

    # traverse the parse tree in depth first order
    foreach my $node ( @$ptree ) {
        if ( ref $node && $node->isa( "Pod::InteriorSequence" ) ) {
            # its an interior sequence, is it a C<> sequence?
            if ( $node->{-name} eq 'C' ) {
                my @CCodes = ();
                my $text =
                    $self->expandCparagraph( $node->{-ptree}, \@CCodes);
                if ( $#CCodes > -1 ) {
                    carp "Found nested C tags, expect the unexpected:\n $text";
                }

                # manually expand E<lt> and E<gt> inside C tags
                $text =~ s/E<lt>/</g;
                $text =~ s/E<gt>/>/g;

                # store code, making sure we have plenty of <'s
                push @$CodesRef, 'C<<<< ' . $text . ' >>>>';

                # insert marker
                $CParagraph .= 'CqqPodBook';
            }
            else {
                # not a C-sequence, just put it back together
                $CParagraph .= $node->{-name} .
                    $node->{-ldelim} .
                    $self->expandCparagraph( $node->{-ptree}, $CodesRef ) .
                    $node->{-rdelim};
            }
        }
        else {
            # $node is just a string
            $CParagraph .= $node;
        }
    }

    return $CParagraph;
}

1; # Magic true value required at end of module
__END__

=end __PRIVATE__

=head1 DIAGNOSTICS

=over

=item C<Invalid key: only Section and Input are allowed>

A key, other than C<Section> or C<Input> was specified for the
document structure. Occurs when the document structure in the
configuration file is incorrect. In YAML, it must look something like:

   DocStructure:
     - Section:
         Level: part
         Title: First Part
     - Input:
         FileOrPod: Catalyst::Manual::Tutorial
     - Input:
         FileOrPod: Catalyst::Manual
     - Section:
         Level: part
         Title: Appendix


=item C<Mandatory parameter '...' missing in call to Pod::Book::configure>

This and similar errors occur when the configuration does not meet
specifications.

=item C<POD not found for ...>

No POD documentation available on the system. Check for typos.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Pod::Book is configured by means of a configuration file that provides details about the PODs to be combined. See L</parse_from_file> for details.


=head1 DEPENDENCIES

Module Pod::Book is sub-classed from L<PoD::LaTeX>. It also needs L<Carp>,
L<Config::Any>,
L<Params::Validate>,
L<Perl6::Slurp>,
L<Pod::Find>, and
L<Pod::ParseUtils>.


=head1 INCOMPATIBILITIES


None reported.


=head1 BUGS AND LIMITATIONS


The conversion process with L<pdflatex> is rarely smooth. Beyond the
usual complaints about overfull hboxes, frequent error messages
surrounding the C<listings> package are common. Try ignoring them.

Similarly, complaints about multiply defined labels and hypertargets
are common.

Please report any bugs or feature requests to
C<bug-pod-book@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Peter Paris  C<< <lutetius@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
