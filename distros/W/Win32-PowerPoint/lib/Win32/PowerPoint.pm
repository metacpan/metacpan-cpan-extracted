package Win32::PowerPoint;

use strict;
use warnings;
use Carp;

our $VERSION = '0.10';

use File::Spec;
use File::Basename;
use Win32::OLE;
use Win32::PowerPoint::Constants;
use Win32::PowerPoint::Utils qw(
  RGB
  canonical_alignment
  canonical_pattern
  canonical_datetime
  convert_cygwin_path
  _defined_or
);

sub new {
  my $class = shift;
  my $self  = bless {
    c            => Win32::PowerPoint::Constants->new,
    was_invoked  => 0,
    application  => undef,
    presentation => undef,
    slide        => undef,
  }, $class;

  $self->connect_or_invoke;

  return $self;
}

sub c { shift->{c} }

##### application #####

sub application { shift->{application} }

sub connect_or_invoke {
  my $self = shift;

  $self->{application} = Win32::OLE->GetActiveObject('PowerPoint.Application');

  unless (defined $self->{application}) {
    $self->{application} = Win32::OLE->new('PowerPoint.Application')
      or die Win32::OLE->LastError;
    $self->{was_invoked} = 1;
  }
}

sub quit {
  my $self = shift;

  return unless $self->application;

  $self->application->Quit;
  $self->{application} = undef;
}

##### presentation #####

sub new_presentation {
  my $self = shift;

  return unless $self->{application};

  my %options = ( @_ == 1 and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  $self->{slide} = undef;

  $self->{presentation} = $self->application->Presentations->Add
    or die Win32::OLE->LastError;

  $self->_apply_background(
    $self->presentation->SlideMaster->Background->Fill,
    %options
  );
}

sub presentation {
  my $self = shift;

  return unless $self->{application};

  $self->{presentation} ||= $self->application->ActivePresentation
    or die Win32::OLE->LastError;
}

sub _apply_background {
  my ($self, $target, %options) = @_;

  my $forecolor = _defined_or(
    $options{background_forecolor},
    $options{masterbkgforecolor}
  );
  if ( defined $forecolor ) {
    $target->ForeColor->{RGB} = RGB($forecolor);
    $self->slide->{FollowMasterBackground} = $self->c->msoFalse if $options{slide};
  }

  my $backcolor = _defined_or(
    $options{background_backcolor},
    $options{masterbkgbackcolor}
  );
  if ( defined $backcolor ) {
    $target->BackColor->{RGB} = RGB($backcolor);
    $self->slide->{FollowMasterBackground} = $self->c->msoFalse if $options{slide};
  }

  if ( defined $options{pattern} ) {
    if ( $options{pattern} =~ /\D/ ) {
      my $method = canonical_pattern($options{pattern});
      $options{pattern} = $self->c->$method;
    }
    $target->Patterned( $options{pattern} );
  }
}

sub save_presentation {
  my ($self, $file) = @_;

  return unless $self->presentation;
  return unless defined $file;

  my $absfile   = File::Spec->rel2abs($file);
  my $directory = dirname( $file );
  unless (-d $directory) {
    require File::Path;
    File::Path::mkpath($directory);
  }

  $self->presentation->SaveAs( convert_cygwin_path( $absfile ) );
}

sub close_presentation {
  my $self = shift;

  return unless $self->presentation;

  $self->presentation->Close;
  $self->{presentation} = undef;
}

sub set_master_footer {
  my $self = shift;

  return unless $self->presentation;
  my $master_footers = $self->presentation->SlideMaster;
  $self->_set_footer($master_footers, @_);
}

sub _set_footer {
  my ($self, $slide, @args) = @_;

  my $target = $slide->HeadersFooters;

  my %options = ( @args == 1 and ref $args[0] eq 'HASH' ) ? %{ $args[0] } : @args;

  if ( defined $options{visible} ) {
    $target->Footer->{Visible} = $options{visible} ? $self->c->msoTrue : $self->c->msoFalse;
  }

  if ( defined $options{text} ) {
    $target->Footer->{Text} = $options{text};
  }

  if ( defined $options{slide_number} ) {
    $target->SlideNumber->{Visible} = $options{slide_number} ? $self->c->msoTrue : $self->c->msoFalse;
  }

  if ( defined $options{datetime} ) {
    $target->DateAndTime->{Visible} = $options{datetime} ? $self->c->msoTrue : $self->c->msoFalse;
  }

  if ( defined $options{datetime_format} ) {
    if ( !$options{datetime_format} ) {
      $target->DateAndTime->{UseFormat} = $self->c->msoFalse;
    }
    else {
      if ( $options{datetime_format} =~ /\D/ ) {
        my $format = canonical_datetime($options{datetime_format});
        $options{datetime_format} = $self->c->$format;
      }
      $target->DateAndTime->{UseFormat} = $self->c->msoTrue;
      $target->DateAndTime->{Format}    = $options{datetime_format};
    }
  }
}

##### slide #####

sub slide {
  my ($self, $id) = @_;
  if ($id) {
    $self->{slide} = $self->presentation->Slides->Item($id)
      or die Win32::OLE->LastError;
  }
  $self->{slide};
}

sub new_slide {
  my $self = shift;

  my %options = ( @_ == 1 and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  $self->{slide} = $self->presentation->Slides->Add(
    $self->presentation->Slides->Count + 1,
    $self->c->LayoutBlank
  ) or die Win32::OLE->LastError;
  $self->{last} = undef;

  $self->_apply_background(
    $self->slide->Background->Fill,
    %options,
    slide => 1,
  );
}

sub set_footer {
  my $self = shift;

  return unless $self->slide;
  $self->_set_footer($self->slide, @_);
}

sub add_text {
  my ($self, $text, $options) = @_;

  return unless $self->slide;
  return unless defined $text;

  $options = {} unless ref $options eq 'HASH';

  $text =~ s/\n/\r/gs;

  my ($left, $top, $width, $height);
  if (my $last = $self->{last}) {
    $left   = _defined_or($options->{left},   $last->Left);
    $top    = _defined_or($options->{top},    $last->Top + $last->Height + 20);
    $width  = _defined_or($options->{width},  $last->Width);
    $height = _defined_or($options->{height}, $last->Height);
  }
  else {
    $left   = _defined_or($options->{left},   30);
    $top    = _defined_or($options->{top},    30);
    $width  = _defined_or($options->{width},  600);
    $height = _defined_or($options->{height}, 200);
  }

  my $new_textbox = $self->slide->Shapes->AddTextbox(
    $self->c->TextOrientationHorizontal,
    $left, $top, $width, $height
  );

  my $frame = $new_textbox->TextFrame;
  my $range = $frame->TextRange;

  $frame->{WordWrap} = $self->c->True;
  $range->ParagraphFormat->{FarEastLineBreakControl} = $self->c->True;
  $range->{Text} = $text;

  $self->decorate_range( $range, $options );

  $frame->{AutoSize} = $self->c->AutoSizeNone;
  $frame->{AutoSize} = $self->c->AutoSizeShapeToFitText;

  $self->{last} = $new_textbox;

  return $new_textbox;
}

sub add_picture {
  my ($self, $file, $options) = @_;

  return unless $self->slide;
  return unless defined $file and -f $file;

  $options = {} unless ref $options eq 'HASH';

  my ($left, $top);
  if (my $last = $self->{last}) {
    $left   = _defined_or($options->{left}, $last->Left);
    $top    = _defined_or($options->{top},  $last->Top + $last->Height + 20);
  }
  else {
    $left   = _defined_or($options->{left}, 30);
    $top    = _defined_or($options->{top},  30);
  }

  my $new_picture = $self->slide->Shapes->AddPicture(
    convert_cygwin_path( $file ),
    ( $options->{link}
      ? ( $self->c->msoTrue,  $self->c->msoFalse )
      : ( $self->c->msoFalse, $self->c->msoTrue )
    ),
    $left, $top, $options->{width}, $options->{height}
  );

  $self->{last} = $new_picture;

  return $new_picture;
}

sub insert_before {
  my ($self, $text, $options) = @_;

  return unless $self->slide;
  return unless defined $text;

  $options = {} unless ref $options eq 'HASH';

  $text =~ s/\n/\r/gs;

  my $num_of_boxes = $self->slide->Shapes->Count;
  my $last  = $num_of_boxes ? $self->slide->Shapes($num_of_boxes) : undef;
  my $range = $self->slide->Shapes($num_of_boxes)->TextFrame->TextRange;

  my $selection = $range->InsertBefore($text);

  $self->decorate_range( $selection, $options );

  return $selection;
}

sub insert_after {
  my ($self, $text, $options) = @_;

  return unless $self->slide;
  return unless defined $text;

  $options = {} unless ref $options eq 'HASH';

  $text =~ s/\n/\r/gs;

  my $num_of_boxes = $self->slide->Shapes->Count;
  my $last  = $num_of_boxes ? $self->slide->Shapes($num_of_boxes) : undef;
  my $range = $self->{slide}->Shapes($num_of_boxes)->TextFrame->TextRange;

  my $selection = $range->InsertAfter($text);

  $self->decorate_range( $selection, $options );

  return $selection;
}

sub decorate_range {
  my ($self, $range, $options) = @_;

  return unless defined $range;

  $options = {} unless ref $options eq 'HASH';

  my ($true, $false) = ($self->c->True, $self->c->False);

  $range->Font->{Bold}        = $options->{bold}        ? $true : $false;
  $range->Font->{Italic}      = $options->{italic}      ? $true : $false;
  $range->Font->{Underline}   = $options->{underline}   ? $true : $false;
  $range->Font->{Shadow}      = $options->{shadow}      ? $true : $false;
  $range->Font->{Subscript}   = $options->{subscript}   ? $true : $false;
  $range->Font->{Superscript} = $options->{superscript} ? $true : $false;
  $range->Font->{Size}        = $options->{size}       if $options->{size};
  $range->Font->{Name}        = $options->{name}       if $options->{name};
  $range->Font->{Name}        = $options->{font}       if $options->{font};
  $range->Font->Color->{RGB}  = RGB($options->{color}) if $options->{color};

  my $align = $options->{alignment} || $options->{align} || 'left';
  if ( $align =~ /\D/ ) {
    my $method = canonical_alignment( $align );
    $align = $self->c->$method;
  }
  $range->ParagraphFormat->{Alignment} = $align;

  $range->ActionSettings(
    $self->c->MouseClick
  )->Hyperlink->{Address} = $options->{link} if $options->{link};
}

sub DESTROY {
  my $self = shift;

  $self->quit if $self->{was_invoked};
}

1;
__END__

=head1 NAME

Win32::PowerPoint - helps to convert texts to PP slides

=head1 SYNOPSIS

    use Win32::PowerPoint;

    # invoke (or connect to) PowerPoint
    my $pp = Win32::PowerPoint->new;

    # set presentation-wide information
    $pp->new_presentation(
      background_forecolor => [255,255,255],
      background_backcolor => 'RGB(0, 0, 0)',
      pattern => 'Shingle',
    );

    # and master footer if you prefer (optional)
    $pp->set_master_footer(
      visible         => 1,
      text            => 'My Slides',
      slide_number    => 1,
      datetime        => 1,
      datetime_format => 'MMMMyy',
    );

    (load and parse your slide text)

    # do whatever you want to do for each of your slides
    foreach my $slide (@slides) {
      $pp->new_slide;

      $pp->add_text($slide->title, { size => 40, bold => 1 });
      $pp->add_text($slide->body);
      $pp->add_text($slide->link,  { link => $slide->link });

      # you may add pictures
      $pp->add_picture($file, { left => 10, top => 10 });
    }

    $pp->save_presentation('slide.ppt');

    $pp->close_presentation;

    # PowerPoint closes automatically

=head1 DESCRIPTION

Win32::PowerPoint helps you to create a PowerPoint presentation. You can add texts/pictures incrementally to your slides.

=head1 METHODS

=head2 new

Invokes (or connects to) PowerPoint.

=head2 connect_or_invoke

Explicitly connects to (or invoke) PowerPoint.

=head2 quit

Explicitly disconnects from PowerPoint, and closes it if this module invoked it.

=head2 new_presentation (options)

Creates a new (probably blank) presentation. Options are:

=over 4

=item background_forecolor, background_backcolor

You can specify background colors of the slides with an array ref of RGB
components ([255, 255, 255] for white) or formatted string ('255, 0, 0'
for red). You can use '(0, 255, 255)' or 'RGB(0, 255, 255)' format for
clarity. These colors are applied to all the slides you'll add, unless
you specify other colors for the slides explicitly.

You can use 'masterbkgforecolor' and 'masterbkgbackcolor' as aliases.

=item pattern

You also can specify default background pattern for the slides.
See L<Win32::PowerPoint::Constants> (or MSDN or PowerPoint's help) for
supported pattern names. You can omit 'msoPattern' part and the names
are case-sensitive.

=back

=head2 save_presentation (path)

Saves the presentation to where you specified. Accepts relative path.
You might want to save it as .pps (slideshow) file to make it easy to
show slides (it just starts full screen slideshow with a doubleclick).

=head2 close_presentation

Explicitly closes the presentation.

=head2 new_slide (options)

Adds a new (blank) slide to the presentation. Options are:

=over 4

=item background_forecolor, background_backcolor

You can set colors just for the slide with these options.
You can use 'bkgforecolor' and 'bkgbackcolor' as aliases.

=item pattern

You also can set background pattern just for the slide.

=back

=head2 add_text (text, options)

Adds (formatted) text to the slide. Options are:

=over 4

=item left, top, width, height

of the Textbox.

=back

See 'decorate_range' for other options.

=head2 add_picture (file, options)

Adds file to the slide. Options are:

=over 4

=item left, top, width, height

of the picture. width and height are optional.

=item link

If set to true, the picture will be linked, otherwise, embedded.

=back

=head2 insert_before (text, options)

=head2 insert_after (text, options)

Prepends/Appends text to the current Textbox. See 'decorate_range' for options.

=head2 set_footer, set_master_footer (options)

Arranges (master) footer. Options are:

=over 4

=item visible

If set to true, the footer(s) will be shown, and vice versa.

=item text

Specifies the text part of the footer(s)

=item slide_number

If set to true, slide number(s) will be shown, and vice versa.

=item datetime

If set to true, the date time part of the footer(s) will be shown, and vice versa.

=item datetime_format

Specifies the date time format of the footer(s) if you specify one of the registered ppDateTimeFormat name (see L<Win32::PowerPoint::Constants> or MSDN for details). If set to false, no format will be used.

=back

=head2 decorate_range (range, options)

Decorates text of the range. Options are:

=over 4

=item bold, italic, underline, shadow, subscript, superscript

Boolean.

=item size

Integer.

=item color

See above for the convention.

=item font

Font name of the text. You can use 'name' as an alias.

=item alignment

One of the 'left' (default), 'center', 'right', 'justify', 'distribute'.

You can use 'align' as an alias.

=item link

hyperlink address of the Text.

=back

(This method is mainly for the internal use).

=head1 IF YOU WANT TO GO INTO DETAIL

This module uses L<Win32::OLE> internally. You can fully control PowerPoint through the following accessors. See L<Win32::OLE> and other appropriate documents like intermediate books on PowerPoint and Visual Basic for details (after all, this module is just a thin wrapper of them). If you're still using old PowerPoint (2003 and older), try C<Record New Macro> (from the C<Tools> menu, then, C<Macro>, and voila) and do what you want, and see what's recorded (from the C<Tools> menu, then C<Macro>, and C<Macro...> submenu. You'll see Visual Basic Editor screen).

=head2 application

returns an Application object.

    print $pp->application->Name;

=head2 presentation

returns a current Presentation object (maybe ActivePresentation but that's not assured).

    $pp->save_presentation('sample.ppt') unless $pp->presentation->Saved;

    while (my $last = $pp->presentation->Slides->Count) {
      $pp->presentation->Slides($last)->Delete;
    }

=head2 slide

returns a current Slide object.

    $pp->slide->Export(".\\slide_01.jpg",'jpg');

    $pp->slide->Shapes(1)->TextFrame->TextRange
       ->Characters(1, 5)->Font->{Bold} = $pp->c->True;

As of 0.10, you can pass an index number to get an arbitrary Slide object.

=head2 c

returns Win32::PowerPoint::Constants object.

=head1 CAVEATS FOR CYGWIN USERS

This module itself seems to work under the Cygwin environment. However, MS PowerPoint expects paths to be Windows-ish, namely without /cygdrive/. So, when you load or save a presentation, or import some materials with OLE (native) methods, you usually need to convert them by yourself. As of 0.08, Win32::PowerPoint::Utils has a C<convert_cygwin_path> function for this. Win32::PowerPoint methods use this function internally, so you don't need to convert paths explicitly.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006- by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

