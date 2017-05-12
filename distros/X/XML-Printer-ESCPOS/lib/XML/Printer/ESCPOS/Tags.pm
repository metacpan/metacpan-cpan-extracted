package XML::Printer::ESCPOS::Tags;

use strict;
use warnings;
use Text::Wrapper;
use GD;


our $VERSION = '0.05';

=head2 new

Constructs a tags object.

=cut

sub new {
    my ( $class, %options ) = @_;
    return if not exists $options{printer} or not ref $options{printer};
    return if not exists $options{caller}  or not ref $options{caller};
    return bless {%options}, $class;
}

=head2 tag_allowed

Returns true if the given tag is defined.

=cut

sub tag_allowed {
    my ( $self, $method ) = @_;
    return !!grep { $method eq $_ } qw/
        0
        barcode
        bold
        color
        doubleStrike
        image
        invert
        lf
        printAreaWidth
        set
        unset
        qr
        repeat
        rot90
        tab
        tabpositions
        text
        underline
        upsideDown
        utf8ImagedText
        justify
        hr
        /;
}

=head2 parse( $element )

Method for recursive parsing of tags.

=cut

sub parse {
    my ( $self, $tags ) = @_;
    my @elements = @$tags;
    my $hashref  = shift @elements;
    if ( ref $hashref ne 'HASH' or %$hashref ) {
        return $self->{caller}->_set_error_message('first element should be an empty hashref ({})');
    }

    while (@elements) {
        my $tag  = shift @elements;
        my $data = shift @elements;
        return $self->{caller}->_set_error_message("tag $tag is not allowed") if not $self->tag_allowed($tag);
        my $method = '_' . $tag;
        $self->$method($data) or return;
    }
    return 1;
}

=head2 simple_switch

Helper method for simple 0/1 switches.

=cut

sub simple_switch {
    my ( $self, $method, $tags ) = @_;
    $self->{states}->{$method} //= 0;
    $self->{states}->{$method}++;
    $self->{printer}->$method(1) if $self->{states}->{$method} == 1;

    $self->parse($tags) or return;

    $self->{printer}->$method(0) if $self->{states}->{$method} == 1;
    $self->{states}->{$method}--;
    return 1;
}

=head2 include_global_options

Helper method to add global options to object options.

=cut

sub include_global_options {
    my ($self, $options) = @_;

    return {
        %{ $self->{global_options} // {} },
        %$options,
    };
}

=head2 _0

Prints plain text and strips out leading and trailing whitespaces.

=cut

sub _0 {
    my ( $self, $text ) = @_;
    $text =~ s/^\s+//gm;
    $text =~ s/\s+$//gm;
    if ($text =~ /\S/) {
        $self->{printer}->justify( $self->{justify_state} ) if $self->{justify_state};
        $self->{printer}->text($text);
    }
    return 1;
}

=head2 _text

Prints plain text. To activate automatic word wrapping, you can use the attribute I<wordwrap> to set the word
wrap width (use the maximum number of characters per line.
When wordwrap is active, you can set the I<bodystart> parameter to define the characters that should be printed
at the beginning of each line (except the first one). You can use this to set some indentation.

=cut

sub _text {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong text tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong text tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong text tag usage") if $params->[1] != 0;
    my $options = $self->include_global_options($params->[0]);
    if ( exists $options->{wordwrap} ) {
        my $columns = delete $options->{wordwrap} || 49;
        if ( $columns !~ /^\d+$/ or $columns < 1 ) {
            return $self->{caller}->_set_error_message("wrong text tag usage: wordwrap attribute must be a positive integer");
        }

        my $body_start = exists $options->{bodystart} ? delete $options->{bodystart} : '';
        my $wrapper = Text::Wrapper->new( columns => $columns, body_start => $body_start );
        for my $line ( split /\n/ => $wrapper->wrap( $params->[2] ) ) {
            $self->{printer}->justify( $self->{justify_state} ) if $self->{justify_state};
            $self->{printer}->text($line);
        }
    }
    else {
        $self->{printer}->justify( $self->{justify_state} ) if $self->{justify_state};
        $self->{printer}->text( $params->[2] );
    }
    return 1;
}

=head2 _bold

Sets text to be printed bold.

=cut

sub _bold {
    my $self = shift;
    return $self->simple_switch( 'bold', @_ );
}

=head2 _doubleStrike

Sets text to be printed double striked.

=cut

sub _doubleStrike {
    my $self = shift;
    return $self->simple_switch( 'doubleStrike', @_ );
}

=head2 _invert

Sets text to be printed inverted.

=cut

sub _invert {
    my $self = shift;
    return $self->simple_switch( 'invert', @_ );
}

=head2 _underline

Sets text to be printed underlined.

=cut

sub _underline {
    my $self = shift;
    return $self->simple_switch( 'underline', @_ );
}

=head2 _upsideDown

Sets Upside Down Printing.

=cut

sub _upsideDown {
    my $self = shift;
    return $self->simple_switch( 'upsideDown', @_ );
}

=head2 _color

Use this tag to use the second color (if support by your printer).

=cut

sub _color {
    my $self = shift;
    return $self->simple_switch( 'color', @_ );
}

=head2 _rot90

Use this tag to use the second color (if support by your printer).

=cut

sub _rot90 {
    my $self = shift;
    return $self->simple_switch( 'rot90', @_ );
}

=head2 _qr

Prints a QR code. Possible attributes:

=head3 ecc

=head3 version

=head3 moduleSize

=cut

sub _qr {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if $params->[1] != 0;
    my $options = $self->include_global_options($params->[0]);
    if (%$options) {
        $self->{printer}->qr( $params->[2], $options->{ecc} || 'L', $options->{version} || 5, $options->{moduleSize} || 3 );
    }
    else {
        $self->{printer}->qr( $params->[2] );
    }
    return 1;
}

=head2 _barcode

Prints a barcode to the printer. See L<Printer::ESCPOS::Manual> for a list of possible options.
The barcode content should be set as the tag content like <barcode>content</barcode>. All other
options must be set as attributes.

=cut

sub _barcode {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong barcode tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong barcode tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong barcode tag usage") if $params->[1] != 0;
    my $options = $self->include_global_options($params->[0]);
    if (%$options) {
        $self->{printer}->barcode( barcode => $params->[2], map { $_ => $options->{$_} } sort keys %$options );
    }
    else {
        $self->{printer}->barcode( barcode => $params->[2] );
    }
    return 1;
}

=head2 _utf8ImagedText

Can print text with special styling. Use the parameters allowed in L<Printer::ESCPOS>'s method utf8ImagedText 
as attributes for the I<utf8ImagedText> tag. In addition you can use the attribute I<wordwrap> to set the word
wrap width. By now, it is only possible to set the maximum number of characters per line. Later we should try 
to implement a wrapping based in the maximum pixel width of a line.
When wordwrap is active, you can set the I<bodystart> parameter to define the characters that should be printed
at the beginning of each line (except the first one). You can use this to set some indentation.

=cut

sub _utf8ImagedText {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if $params->[1] != 0;
    my $options = $self->include_global_options($params->[0]);
    if (%$options) {
        if ( exists $options->{wordwrap} ) {
            my $columns = delete $options->{wordwrap} || 49;
            if ( $columns !~ /^\d+$/ or $columns < 1 ) {
                return $self->{caller}
                    ->_set_error_message("wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer");
            }

            my $body_start = exists $options->{bodystart} ? delete $options->{bodystart} : '';
            my $wrapper = Text::Wrapper->new( columns => $columns, body_start => $body_start );
            for my $line ( split /\n/ => $wrapper->wrap( $params->[2] ) ) {
                $self->{printer}->utf8ImagedText( $line, map { $_ => $options->{$_} } sort keys %$options );
            }
        }
        else {
            $self->{printer}->utf8ImagedText( $params->[2], map { $_ => $options->{$_} } sort keys %$options );
        }
    }
    else {
        $self->{printer}->utf8ImagedText( $params->[2] );
    }
    return 1;
}

=head2 _lf

Moves to the next line. If the lines attribute is given, move that number of lines.

=cut

sub _lf {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong lf tag usage") if @$params != 1;
    return $self->{caller}->_set_error_message("wrong lf tag usage") if ref $params->[0] ne 'HASH';
    my $lines = 1;
    if ( %{ $params->[0] } ) {
        my @keys = keys %{ $params->[0] };
        return $self->{caller}->_set_error_message("wrong lf tag usage") if @keys != 1;
        return $self->{caller}->_set_error_message("wrong lf tag usage") if $keys[0] ne 'lines';
        $lines = $params->[0]->{lines};
        return $self->{caller}->_set_error_message("wrong lf tag usage: lines attribute must be a positive integer")
            if $lines !~ /^\d+$/ or $lines < 1;
    }
    $self->{printer}->lf() for 1 .. $lines;
    return 1;
}

=head2 _tab

Moves the cursor to next horizontal tab position.

=cut

sub _tab {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong tab tag usage") if @$params != 1;
    return $self->{caller}->_set_error_message("wrong tab tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong tab tag usage") if %{ $params->[0] };
    $self->{printer}->tab();
    return 1;
}

=head2 _image

Print image from named file.

=cut

sub _image {
    my ( $self, $params ) = @_;

    my $filename;

    # single tag form <image filename="image.jpg" />
    if ( @$params == 1 ) {
        return $self->{caller}->_set_error_message("wrong image tag usage") if ref $params->[0] ne 'HASH';
        return $self->{caller}->_set_error_message("wrong image tag usage") if scalar keys %{ $params->[0] } != 1;
        return $self->{caller}->_set_error_message("wrong image tag usage") if not exists $params->[0]->{filename};
        $filename = $params->[0]->{filename};
    }
    else {
        # content tag form <image>image.jpg</image>
        return $self->{caller}->_set_error_message("wrong image tag usage") if @$params != 3;
        return $self->{caller}->_set_error_message("wrong image tag usage") if ref $params->[0] ne 'HASH';
        return $self->{caller}->_set_error_message("wrong image tag usage") if %{ $params->[0] };
        return $self->{caller}->_set_error_message("wrong image tag usage") if $params->[1] ne '0';
        $filename = $params->[2];
    }

    return $self->{caller}->_set_error_message("wrong image tag usage: file does not exist") if !-f $filename;

    my $image;
    if ($filename =~ m/\.png$/) {
        $image = GD::Image->newFromPng($filename) or return $self->{caller}->_set_error_message("Error loading image file $filename");
    }
    elsif ($filename =~ m/\.gif$/) {
        $image = GD::Image->newFromGif($filename) or return $self->{caller}->_set_error_message("Error loading image file $filename");
    }
    elsif ($filename =~ m/\.jpe?g$/) {
        $image = GD::Image->newFromJpeg($filename) or return $self->{caller}->_set_error_message("Error loading image file $filename");
    }
    else {
        return $self->{caller}->_set_error_message("wrong image tag usage: file format not supported");
    }

    $self->{printer}->image( $image );
    return 1;
}

=head2 _printAreaWidth

Sets the print area width.

=cut

sub _printAreaWidth {
    my ( $self, $params ) = @_;

    # single tag form <printAreaWidth width="255" />
    if ( @$params == 1 ) {
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if ref $params->[0] ne 'HASH';
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if scalar keys %{ $params->[0] } != 1;
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if not exists $params->[0]->{width};
        $self->{printer}->printAreaWidth( $params->[0]->{width} );
        $self->{global_options}->{printAreaWidth} = $params->[0]->{width};
        return 1;
    }

    # content tag form <printAreaWidth>255</printAreaWidth>
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if %{ $params->[0] };
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if $params->[1] ne '0';

    $self->{printer}->printAreaWidth( $params->[2] );
    $self->{global_options}->{printAreaWidth} = $params->[2];
    return 1;
}

=head2 _set

Sets global variables: paperWidth, wordwrap, fontFamily, fontSize, fontStyle, lineHeight, printAreaWidth

=cut

sub _set {
    my ( $self, $params ) = @_;

    return $self->{caller}->_set_error_message("wrong set tag usage") if @$params != 1 ;
    return $self->{caller}->_set_error_message("wrong set tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong set tag usage") if not scalar keys %{ $params->[0] };

    $self->{global_options} ||= {};
    for my $var (qw/paperWidth wordwrap fontFamily fontSize fontStyle lineHeight printAreaWidth/) {
        $self->{global_options}->{$var} = $params->[0]->{$var} if $params->[0]->{$var};
    }
    
    return 1;
}

=head2 _unset

Resets global variables to standard values: paperWidth, wordwrap, fontFamily, fontSize, fontStyle, lineHeight, printAreaWidth
Syntax: <unset fontStyle="" />

=cut

sub _unset {
    my ( $self, $params ) = @_;

    return $self->{caller}->_set_error_message("wrong unset tag usage") if @$params != 1 ;
    return $self->{caller}->_set_error_message("wrong unset tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong unset tag usage") if not scalar keys %{ $params->[0] };

    for my $var (keys %{ $params->[0] }) {
        delete $self->{global_options}->{$var};
    }
    
    return 1;
}

=head2 _hr

Adds a horizontal line. Use the I<thickness> attribute to set the line's thickness. Defaults to 2.

=cut

sub _hr {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong hr tag usage") if @$params != 1;
    return $self->{caller}->_set_error_message("wrong hr tag usage") if ref $params->[0] ne 'HASH';
    my $thickness = 2;
    if ( %{ $params->[0] } ) {
        my @keys = keys %{ $params->[0] };
        return $self->{caller}->_set_error_message("wrong hr tag usage") if !@keys;
        $thickness = $params->[0]->{thickness};
        return $self->{caller}->_set_error_message("wrong hr tag usage") if !$thickness;
        return $self->{caller}->_set_error_message("wrong hr tag usage: thickness attribute must be a positive integer")
            if $thickness !~ /^\d+$/ or $thickness < 1;
    }

    my $width = $params->[0]->{width} || $self->{paperWidth} || $self->{print_area_width} || 512;
    my $img = GD::Image->new( $width, $thickness );
    my $black = $img->colorAllocate( 0, 0, 0 );

    for my $line ( 1 .. $thickness ) {
        $img->line( 0, $line, $width, $line, $black );
    }

    $self->{printer}->image($img);

    return 1;
}

=head2 _tabpositions

Sets horizontal tab positions for tab stops. Syntax for XML is the following:

    <tabpositions>
      <tabposition>5</tabposition>
      <tabposition>9</tabposition>
      <tabposition>13</tabposition>
    </tabpositions>

=cut

sub _tabpositions {
    my ( $self, $tags ) = @_;

    my @elements = @$tags;
    my $hashref  = shift @elements;
    if ( ref $hashref ne 'HASH' or %$hashref ) {
        return $self->{caller}->_set_error_message('first element should be an empty hashref ({})');
    }

    my @tabpositions = ();
    while (@elements) {
        my $tag  = shift @elements;
        my $data = shift @elements;
        next if $tag eq '0' and $data =~ /^\s*$/;

        if ( $tag ne 'tabposition' ) {
            return $self->{caller}
                ->_set_error_message("wrong tabpositions tag usage: must not contain anything else than tabposition tags");
        }
        if (   ref $data ne 'ARRAY'
            or ref $data->[0] ne 'HASH'
            or keys %{ $data->[0] }
            or $data->[1] ne '0'
            or $data->[2] !~ /^\d+$/
            or $data->[2] < 1
            or @$data != 3 )
        {
            return $self->{caller}->_set_error_message("wrong tabposition tag usage: value must be a positive integer");
        }
        push @tabpositions, $data->[2];
    }

    if ( !@tabpositions ) {
        return $self->{caller}
            ->_set_error_message("wrong tabpositions tag usage: must contain at least one tabposition tag as child");
    }

    $self->{printer}->tabPositions(@tabpositions);
    return 1;
}

=head2 _repeat

Repeats the content I<n> times. Syntax:

    <repeat times="3">
        [tags to repeat]
    </repeat>

=cut

sub _repeat {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong repeat tag usage") if ref $params ne 'ARRAY';
    return $self->{caller}->_set_error_message("wrong repeat tag usage") if !@$params;
    return $self->{caller}->_set_error_message("wrong repeat tag usage") if ref $params->[0] ne 'HASH';

    my $times = 1;
    my $options = $params->[0];
    if ( exists $options->{times} ) {
        $times = $options->{times};
        return $self->{caller}->_set_error_message("wrong repeat tag usage: only positive integers are allowed") if $times =~ /\D/ or $times < 1;
    }

    for ( 1 .. $times ) {
        $self->parse( [ {}, @$params[ 1.. $#$params ] ] ) or return;
    }

    return 1;
}

=head2 _justify

Set justification to left, right or center. Syntax for XML is the following:
<justify align="right">text</justify>

=cut

sub _justify {
    my ( $self, $params ) = @_;

    return $self->{caller}->_set_error_message("wrong justify tag usage") if @$params < 3;
    return $self->{caller}->_set_error_message("wrong justify tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong justify tag usage") if !$params->[0]->{align};
    return $self->{caller}->_set_error_message("wrong justify tag usage") if keys %{ $params->[0] } != 1;
    return $self->{caller}->_set_error_message("wrong justify tag usage") if not grep { $params->[0]->{align} eq $_ } qw/left center right/;

    $self->{justify_state} ||= 'left';

    my $justify_state_before = $self->{justify_state};
    $self->{justify_state} = $params->[0]->{align};

    $params->[0] = {};
    $self->parse($params) or return;

    $self->{justify_state} = $justify_state_before;
    return 1;
}

=head1 NOT YET IMPLEMENTED TAGS

=head2 _font

Choose font a, b or c.

=cut

sub _font { }

=head2 _fontHeight

Set font height.

=cut

sub _fontHeight { }

=head2 _fontWidth

Set font width.

=cut

sub _fontWidth { }

=head2 _charSpacing

Set character spacing.

=cut

sub _charSpacing { }

=head2 _lineSpacing

Set line spacing.

=cut

sub _lineSpacing { }

=head2 _selectDefaultLineSpacing

Reverts to default line spacing for the printer.

=cut

sub _selectDefaultLineSpacing { }

=head2 _printPosition

Sets the distance from the beginning of the line to the position at which characters are to be printed.

=cut

sub _printPosition { }

=head2 _leftMargin

Sets the left margin for printing.

=cut

sub _leftMargin { }

=head2 _printNVImage

Prints bit image stored in non-volatile (NV) memory of the printer.

=cut

sub _printNVImage { }

=head2 _printImage

Prints bit image stored in volatile memory of the printer.

=cut

sub _printImage { }

1;
