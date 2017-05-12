package Text::Format::Screenplay;

use 5.008009;
use strict;
use warnings;
use File::Slurp qw(read_file);
use PDF::Create;
use Text::Wrap;

our $VERSION = '0.01';

my $DOUBLE_DIALOG_LINES = 0;
my $SHOW_SCENE_NUMBERS  = 0;

my $CHAR_WIDTH  = 7;
my $CHAR_HEIGHT = 12;
my $PAGE_WIDTH  = 612;
my $PAGE_HEIGHT = 792;

# parse infile
my $TITLE    = '';
my @AUTHOR   = ();
my @CONTACT  = ();
my $DRAFT    = '';
my $DATE     = '';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->_init();
}

sub _init
{
	my ($self, %opts) = @_;
	return $self;
}

sub pdf
{
	my ($self, $filename, $outfile) = @_;

	# structure of $scenes: each element: [ 'type', 'content' ]
	my $scenes = $self->_parse_infile( read_file($filename) );
	
	$self->_create_outfile( $scenes, $outfile );
}

sub _parse_infile
{
  my ($self, @lines) = @_;
  my @sp;
    
  my $i; my $j;
  for ($i=0; $i<scalar(@lines); $i++)
	{
	  next if $lines[$i] =~ /^[\s\t\n\r]*$/;  # ignore blank lines
	  next if $lines[$i] =~ /^[\s\t\n\r]*\#/; # ignore comment lines
	  
	  # parse next paragraph
	  my $para = '';
	  for ($j=$i; $j<scalar(@lines); $j++) {
		chomp($lines[$j]);
		next if $lines[$j] =~ /^[\s\t\n\r]*\#/; # ignore comment lines
		last if $lines[$j] =~ /^[\s\t\n\r]*$/;  # ignore blank lines
		$para .= $lines[$j];
	  }
	  $i = $j;
	  
	  # split into pre-colon and post-colon parts        
	  my ($pre, $post) = $para =~ /^([^\:\~\>]*[\:\~\>]?)(.*)$/;
	  $post = '' unless $post;
	  
	  if ($pre eq 'title:') {
		($TITLE) = uc($post) =~ /^[\s\t]*(.*)[\s\t\r\n]*$/;
	  } elsif ($pre eq 'author:') {
		@AUTHOR = map { s/^[\s\t]*(.*)[\s\t\r\n]*$/$1/; $_ } split /;/, $post;
	  } elsif ($pre eq 'contact:') {
		@CONTACT = map { s/^[\s\t]*(.*)[\s\t\r\n]*$/$1/; $_ } split /;/, $post;
	  } elsif ($pre eq 'draft:') {
		$DRAFT = $post;
	  } elsif ($pre eq 'date:') {
		$DATE = $post;
	  } elsif ($pre eq ':') {
		push @sp, ['s', $post];
	  } elsif ($pre eq '>') {
		push @sp, ['t', $post];
	  } elsif ($pre eq '~') {
		push @sp, ['c', $post];        
	  } elsif ($pre =~ /^.{1,20}\:$/) {
		$pre =~ s/\:$//;
		push @sp, [$pre, $post];
	  } else {
		push @sp, ['d', $pre];            
	  }
    }
  
  return \@sp;
}

sub _create_outfile
{
  my ($self, $sp, $outfile) = @_;

  my $pdf = new PDF::Create
	('filename' => $outfile,
	 'Version'  => 1.2,
	 'PageMode' => 'UseOutlines',
	 'Author'   => join(', ', @AUTHOR),
	 'Title'    => $TITLE,
	);
  my $root = $pdf->new_page('Media-Box' => [0, $PAGE_WIDTH, 0, $PAGE_HEIGHT]);
  my $font = $pdf->font
	('Subtype'  => 'Type1',
	 'Encoding' => 'WinAnsiEncoding',
	 'BaseFont' => 'CourierNew');

  my $mid = sprintf "%.0f", ($PAGE_WIDTH / $CHAR_WIDTH / 2);

  #
  # title page
  #
  my $page = $root->new_page; # inherit from root

  my $line = 25;
  $line = _put($page, $font, $TITLE, $line, _mid($mid,$TITLE));
  $line += 4;
  $line = _put($page, $font, "written by", $line, _mid($mid,"written by"));
  $line++;
  foreach (@AUTHOR) { $line = _put($page, $font, $_, $line, _mid($mid,$_)) }
  _put($page, $font, join("\n",@CONTACT), 61-scalar(@CONTACT), 15);
  _put($page, $font, $DRAFT, 56, 62);
  _put($page, $font, $DATE, 60, 62);

  #
  # script pages
  #
  my $pnum = 1; # page counter
  my $snum = 1; # scene counter
  
  $page = $root->new_page;
  _put($page, $font, sprintf("%10s", "$pnum."), 4, 62);
  $line = 6;
  for (my $e=0; $e<@{$sp}; $e++)
  {
    my $type = $sp->[$e]->[0];
    my $text = $sp->[$e]->[1];
    
    if ($type !~ /^[stcd]$/) { $text =~ s/\(/\n\(/g; $text =~ s/\)/)\n/g }

    # check if current page is full
    my $till = 0; # till what line the next element needs space
    if ($type eq 's') {
      # own + 1 line space + space for next part
      $till = $line + _sizeof($text,1000);
      $till += 10;
    } elsif ($type eq 't' || $type eq 'c') {
      # one line (+ 2 empty lines of not last line)
      $till = $line + 1;
      $till += 2 unless $till == 60;
    } elsif ($type eq 'd') {
      # own size (+ 1 empty line if not on last line)
      $till = $line + _sizeof($text,54);
      $till++ unless $till == 60;
    } else {
      # name line + dialog lines
      $till = $line + 1 + _sizeof($text,32);
      $till += _sizeof($text,32) if $DOUBLE_DIALOG_LINES;
    }
    
    # create new page
    if ($till > 60) {
      $pnum++;
      $page = $root->new_page;
      _put($page, $font, sprintf("%10s", "$pnum."), 4, 62);
      $line = 6;
      next;
    }

    # add current element + space to page
    if ($type eq 's') {
      if ($SHOW_SCENE_NUMBERS) {
        _put($page, $font, sprintf("%5s",$snum), $line, 13);
        _put($page, $font, $snum, $line, 74);
        $snum++;
      }
      $line = _put($page, $font, $text, $line, 19);
      $line++;
    } elsif ($type eq 't') {
      $line = _put($page, $font, $text, $line, 62);
      $line += 2 unless $line == 60;
    } elsif ($type eq 'c') {
      $line = _put($page, $font, $text, $line, _mid($mid,$text));
      $line += 2 unless $line == 60;
    } elsif ($type eq 'd') {
      $line = _put($page, $font, _wrapit($text,54), $line, 19);
      if (($e+1 < scalar(@{$sp})) &&
          ($sp->[$e+1]->[0] eq 't' || $sp->[$e+1]->[0] eq 'c' ||
           $sp->[$e+1]->[0] eq 's')) {
        $line += 2 unless $line == 60;
      } else {
        $line++ unless $line == 60;
      }
    } else {
      $line = _put($page, $font, $type, $line, 43);
      $text = _wrapit($text,32); $text =~ s/\(/       \(/g;
      if ($DOUBLE_DIALOG_LINES) {
        $text =~ s/\n/\n\n/g; $text = "\n$text" }
      $line = _put($page, $font, $text, $line, 29);
      if (($e+1 < scalar(@{$sp})) && ($sp->[$e+1]->[0] !~ /^stcd$/)) {
        $line++ unless $line == 60;
      } else {
        $line += 2 unless $line == 60;
      }
    }
  }

  $pdf->close;    
}

sub _sizeof
{
  my ($text, $width) = @_;
  $text = _wrapit($text, $width);
  my @lines = split /\n/, $text;
  return scalar(@lines);
}

sub _wrapit
{
  my ($text, $width) = @_;
  $Text::Wrap::columns = $width;
  $text = Text::Wrap::wrap("", "", $text);
  $text =~ s/\s*\n\s*/\n/g;
  $text =~ s/^\s*//g;
  return $text;
}

sub _mid
{
  my ($mid, $str) = @_;
  return sprintf("%.0f", $mid - (length($str) / 2));
}

# places a text block onto a page, starting at a certain position
sub _put
{
  my ($page, $font, $text, $line, $column) = @_;
  foreach (split /\n/, $text) {
	$page->stringl($font, 10,
				   ($column * $CHAR_WIDTH),
				   ($PAGE_HEIGHT - ($line * $CHAR_HEIGHT)), $_);
	$line++;
  }
  return $line;
}

1;
__END__
=head1 NAME

Text::Format::Screenplay - Create a movie screenplay PDF from text.

=head1 SYNOPSIS

  use Text::Format::Screenplay;
  my $formatter = Text::Format::Screenplay->new();
  $formatter->pdf("./myscreenplay.sp", "./myscreenplay.pdf");

=head1 DESCRIPTION

This module takes a text file and turns it into a printable movie
screenplay PDF. The text file contains minimal syntax to identify the
parts of the screenplay.

=head2 new()

This function creates a new instance of Text::Format::Screenplay and
returns it.

=head2 pdf( I<input-filename>, I<output-filename> )

This method formats the file given and creates a PDF file.
The generated file can then be read on screen or printed, for example.

Currently the formatter applies all industry standards on how a movie
screenplay should be formatted.

=head2 Text screenplay format

This module expects as input a file in a custom text-based format.
This section explaines this format, which is kept very simple and
minimal so to not interfer with the writing process - after all the
screenplay format is very simple itself.

The format introduced is called "SP" (ScreenPlay) and the file ending
is usually ".sp", but this is not a restriction.

The format is B<paragraph based>, so when read the file is split into
paragraphs, each having a specific meaning, determined by the first
characters of that paragraph (e.g. ":"). In some cases there can be
a label before the first character (like in dialoge, s.below).

Here is a complete example of a valid .sp file:

  title: Pulp Fiction
  
  author: Quentin Tarantino
  
  contact:
  Writers Guild;
  Westend Drive 1234;
  5342 Los Angeles, CA;
  United States of America
  
  draft: Final Draft
  
  date: May 1993
  
  :INT. COFFEE SHOP - MORNING
  
  A normal Denny's, Spires-like coffee shop in Los Angeles.
  It's about 9:00 in the morning.  While the place isn't jammed,
  there's a healthy number of people drinking coffee, munching
  on bacon and eating eggs.
  
  It is impossible to tell where the Young Woman is from
  old she is; everything she does contradicts something she did.
  The boy and girl sit in a booth.  Their dialogue is to be said
  in a rapid-pace "HIS GIRL FRIDAY" fashion.
  
  YOUNG MAN: No, forget it, it's too risky.  I'm
  through doin' that shit.
  
  YOUNG WOMAN: You always say that, the same thing
  every time: never again, I'm through, too dangerous.
  (imitates a duck) Quack, quack, quack, quack, quack,
  quack, quack...
  
  The boy and girl laugh, their laughter putting a pause in
  there, back and forth.
  
  >CUT OUT
  
  :CUT TO
  
  CREDIT SEQUENCE
  
  :INT. '74 CHEVY (MOVING) - MORNING 
  
  An old gas guzzling, dirty, white 1974 Chevy Nova
  a homeless-ridden street in Hollywood.  In the front seat are
  two young fellas -- one white, one black -- both wearing cheap
  black suits with thin black ties under long green dusters.
  Their names are VINCENT VEGA (white) and JULES WINNFIELD
  
  ~THE END

=head4 Titlepage parts

The titlepage parts follow the normal paragraph format B<I<partname>:I<partcontent>>.
The example above shows all available titlepage parts:
title, author, contact, draft and date. As you can see, titlepage parts
can span several lines (see contact in the example above).

=head4 Scene headlines

A scene starts with a headline, which is a single line preceeded by a colon (":"),
e.g.:

  :INT. '74 CHEVY (MOVING) - MORNING 

=head4 Dialog

When a character's dialogue is to be written, just write the character's name,
then a colon (":") and then the spoken text, which can span multiple lines.

=head4 Transitions

Transitions are optional markings at the start or end of a scene
(like "CUT TO"). These are preceeded by a "<" or ">" depending on the
alignment that should be used for the transition:

  >CUT OUT
  
  :CUT TO

=head4 Scene description

Any paragraphs not beeing a titlepage part, a scene headline, a dialoge
text or a transition is considered a scene description.

=head2 EXPORT

None by default.

=head1 THE FUTURE

The future of this module depends on its users. If you have any
suggestions or find bugs, let me know, so I can improve this module
and fix those bugs. Also, anyone who finds errors in the way the
screenplay is formatted: please, let me know.

=head1 SEE ALSO

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
