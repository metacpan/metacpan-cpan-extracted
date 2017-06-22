package XML::Printer::ESCPOS::Tags;

use strict;
use warnings;
use Text::Wrapper;
use Text::Wrap;
use GD;
use List::Util;
use List::MoreUtils;
use Array::Utils;


our $VERSION = '0.06';

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
        table
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
    my ($self, $options, $tag) = @_;
    return {} if !$tag;

    my %options_allowed = (
        text            => [qw/
                                bodystart
                                wordwrap
                            /],
        qr              => [qw/
                                ecc
                                moduleSize
                                version
                            /],
        barcode         => [qw/
                                barcode
                                font
                                height
                                HRIPosition
                                lineHeight
                                system
                                width
                            /],
        utf8ImagedText  => [qw/
                                bodystart
                                fontFamily
                                fontSize
                                fontStyle
                                lineHeight
                                paperWidth
                                wordwrap
                            /],
        table           => [qw/
                                align
                                colspan
                                fontFamily
                                fontSize
                                fontStyle
                                leftBorder
                                lineHeight
                                paperWidth
                                rightBorder
                                separator
                                width
                                wordwrap
                            /],
    );

    my $tag_allowed = !!grep { $tag eq $_ } keys %options_allowed;
    return {} if !$tag_allowed;

    $options = {
        %{ $self->{global_options} // {} },
        %$options,
    };

    return {
        map { $_ => $options->{$_} } Array::Utils::intersect(@{$options_allowed{$tag}}, @{[keys %$options]})
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
    my $options = $self->include_global_options($params->[0], 'text');
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
    my $options = $self->include_global_options($params->[0], 'qr');
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
    my $options = $self->include_global_options($params->[0], 'barcode');
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
    my $options = $self->include_global_options($params->[0], 'utf8ImagedText');
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

    my $width = $params->[0]->{width} || $self->{global_options}->{paperWidth} || $self->{global_options}->{printAreaWidth} || 512;
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

=head2 _table

Prints text in table format. By now, this tool is only helpful for monospaced fonts.
Possible cell parameters are width (only in pattern row), colspan and align (right, left, center).
Possible line parameters are fontStyle and align.
Possible table parameters are fontSize, wordwrap, lineHeight, paperWidth, separator,
leftBorder, rightBorder and fontStyle.

=cut

sub _table {
    my ( $self, $params ) = @_;

    return if not $self->check_table_validity($params);

    # get cell options from pattern row
    my @pattern = grep { ref $params->[$_-1] eq '' && $params->[$_-1] eq 'pattern' } 1..@$params; # index
    my @cell_options = ();
    if (@pattern) {
        @pattern = @{$params->[$pattern[0]]} if @pattern; # first pattern row
        my $pattern_options = $pattern[0]; # pattern row options
        my @cell_option_indices = grep { ref $pattern[$_-1] eq '' && $pattern[$_-1] eq 'td' } 1 .. @pattern;
        @cell_options = map { {
            %$pattern_options,
            %{$pattern[$_]->[0]}
        } } @cell_option_indices;
    }

    # get rows and cells
    my @lines = get_rows_and_cells($params, @cell_options);

    my $separator       = $params->[0]->{separator}     || ' ';
    my $left_border     = $params->[0]->{leftBorder}    || '';
    my $right_border    = $params->[0]->{rightBorder}   || '';

    # calculate column widths
    my $options = $self->include_global_options($params->[0], 'table');
    my @column_widths = calculate_table_column_widths({
        lines           => \@lines,
        cell_options    => \@cell_options,
        linewidth       => $options->{wordwrap} || 60,
        separator       => $separator,
        left_border     => $left_border,
        right_border    => $right_border,
    });

    # break lines
    @lines = break_table_lines({
        lines           => \@lines,
        column_widths   => \@column_widths,
        separator       => $separator,
    });

    # print table
    for my $line (@lines) {
        my %line_options = (
            %$options,
            %{$line->[0] || {}},
        );
        my $tag = $line->[0]->{tag};
        if ($tag eq 'tr') {
            my $i = 0;
            my $string = $left_border . join($separator, map {
                my $colspan = exists $_->{options}->{colspan} ? $_->{options}->{colspan} : 1;
                my $columnwidth = length($separator) * ($colspan - 1);
                for my $c (1..$colspan) {
                    $columnwidth += $column_widths[$i++];
                }
                my $text = $_ && $_->{text} ? $_->{text} : '';
                my $align = $_ && $_->{options} && $_->{options}->{align}
                    ? $_->{options}->{align} : $line->[0]->{align} || 'left';
                $align eq 'left'
                    ? sprintf("%-" . $columnwidth . "s", $text) # left
                    : $align eq 'right'
                    ? sprintf("%" . $columnwidth . "s", $text) # right
                    : sprintf("%-" . $columnwidth . "s", ' ' x int(($columnwidth - length($text)) / 2) . $text) # center                    
            } @$line[ 1 .. @$line - 1 ]) . $right_border;
            $self->{printer}->utf8ImagedText( $string, %line_options );
        }
        elsif ($tag eq 'hr') {
            $self->_hr([{thickness => 2, width => $options->{paperWidth} // undef}]);
        }
    }

    return 1;
}

=head2 check_table_validity

Checks validity of table tags and attributes. (Helper for table tag.)

=cut

sub check_table_validity {
    my $self    = shift;
    my $params  = shift;

    return $self->{caller}->_set_error_message('wrong table tag usage: not enough parameters given') if @$params < 7;
    return $self->{caller}->_set_error_message('wrong table tag usage: first parameter needs to be hash') if ref $params->[0] ne 'HASH';
    
    # table parameters
    if (my @attributes = keys %{$params->[0]}) {
        my @allowed_attributes = ('fontSize', 'wordwrap', 'lineHeight', 'paperWidth', 'separator',
            'leftBorder', 'rightBorder', 'fontStyle');
        return $self->{caller}->_set_error_message('wrong table tag usage: some attributes are not allowed') if Array::Utils::array_minus(@attributes, @allowed_attributes);
        my %digit_attributes = map { $_ => 1 } qw(fontSize wordwrap lineHeight paperWidth);
        for my $attribute (@attributes) {
            return $self->{caller}->_set_error_message("wrong table tag usage: attribute $attribute must be a number")
                if exists $digit_attributes{$attribute} && $params->[0]->{$attribute} =~ m/\D/;
        }
    }

    # first level (tr, hr, pattern)
    if (my @tags = List::MoreUtils::uniq(grep { ref($_) eq '' && $_ =~ m/^[a-zA-Z]+$/ } @$params)) {
        my @allowed_tags = ('tr', 'hr', 'pattern');
        return $self->{caller}->_set_error_message('wrong table tag usage: some tags are not allowed') if Array::Utils::array_minus(@tags, @allowed_tags);
        my @line_options = map { $_->[0] } grep { ref $_ eq 'ARRAY' } @$params;
        my @attributes = List::MoreUtils::uniq( map { keys %$_ } @line_options );
        my @allowed_attributes = ('fontStyle', 'align');
        return $self->{caller}->_set_error_message('wrong table tag usage: some tags are not allowed') if Array::Utils::array_minus(@tags, @allowed_tags);
        for my $attribute (@attributes) {
            my @values = List::MoreUtils::uniq( map { $_->{$attribute} } grep { $_->{$attribute} } @line_options );
            my @allowed_vals = $attribute eq 'align'
                ? ('left', 'right', 'center') # align
                : ('Bold', 'Normal', 'Italic'); # fontStyle
            return $self->{caller}->_set_error_message("wrong table tag usage: attribute $attribute has unallowed value")
                if Array::Utils::array_minus(@values, @allowed_vals);
        }
    }

    # second level (td)
    if (my @attributes = grep { ref($_) eq '' && $_ =~ m/^[a-zA-Z]+$/ } map { @$_ } grep { ref($_) eq 'ARRAY' } @$params) {
        return $self->{caller}->_set_error_message('wrong table tag usage: some attributes are not allowed') if grep { $_ ne 'td' } @attributes;
        my @lines = grep { ref $_ eq 'ARRAY' } @$params;
        my @cell_options = map { $_->[0] } map { my $line = $_; grep { ref $_ eq 'ARRAY' } @$line } @lines;
        @attributes = List::MoreUtils::uniq( map { keys %$_ } @cell_options );
        my @allowed_attributes = ('width', 'align', 'colspan');
        return $self->{caller}->_set_error_message('wrong table tag usage: some attributes are not allowed') if Array::Utils::array_minus(@attributes, @allowed_attributes);
        for my $attribute (@attributes) {
            my @values = List::MoreUtils::uniq( map { $_->{$attribute} } grep { exists $_->{$attribute} } @cell_options );
            if ($attribute eq 'align') {
                return $self->{caller}->_set_error_message("wrong table tag usage: attribute $attribute has unallowed value")
                    if grep { my $val = $_; not grep { $_ eq $val } ('left', 'right', 'center') } @values;
            }
            else {
                # width and colspan: only positive digits
                return $self->{caller}->_set_error_message("wrong table tag usage: attribute $attribute must be a positive number")
                    if grep { m/\D/ || !$_ } @values;
            }
        }
    }

    return 1;
}

=head2 get_rows_and_cells

Returns table rows and cells (options and content). (Helper for table tag.)

=cut

sub get_rows_and_cells {
    my ($params, @cell_options) = @_;

    my @line_param_indices = List::MoreUtils::indexes { !ref $_ && ($_ eq 'tr' || $_ eq 'hr') } @$params;
    my @lines = map {
        my $index = $_ + 1;
        my @cell_param_indices = List::MoreUtils::indexes { !ref $_ && $_ eq 'td' } @{$params->[$index]};
        my $i = -1;
        [
            {
                tag => $params->[$index-1],
                %{ $params->[$index]->[0] } # line options
            },
            @cell_param_indices
                ? map {
                        my $td_params = $params->[$index]->[$_ + 1];
                        {
                            options => {
                                @cell_options && $cell_options[++$i] ? %{$cell_options[$i]} : (), # include pattern options
                                %{$td_params->[0] || {}},
                            },
                            text    => $td_params->[2],
                        }
                    } @cell_param_indices #cells
                : ()
        ]
    } @line_param_indices;

    return @lines;
}

=head2 calculate_table_column_widths

Calculates the width for each table column. (Helper for table tag.)

=cut

sub calculate_table_column_widths {
    my $params = shift;

    # write index in each cell
    my @lines = map {
        my $line = $_;
        my $i = -1;
        ref $line ne 'ARRAY' ? $line : [map {
            $_->{index} = $i if ($i != -1);
            $i += $_->{options} && $_->{options}->{colspan} ? $_->{options}->{colspan} : 1;
            $_
        } @$line]
    } @{$params->{lines}};

    # get number of columns
    my $max_index = List::Util::max( map { map { $_->{index} || 0 } @$_ } @lines ); 

    # get columns' maximum text lengths
    my @column_widths = map {
        my $column_index = $_;
        my $max_cell_width = 0;
        if (@{$params->{cell_options}} && $params->{cell_options}->[$_]->{width}) {
            # return width from pattern row if given
            $max_cell_width = $params->{cell_options}->[$_]->{width};
        }
        else {
            my @column_cells = grep { $_ } map {
                my $line = $_;
                my @cell = ref $line eq 'ARRAY'
                    ? grep { defined $_->{index} && $_->{index} == $column_index } @$line
                    : ();
                @cell ? $cell[0] : undef
            } @lines;
            $max_cell_width = List::Util::max( map { $_->{options}->{colspan} ? 0 : length $_->{text} } @column_cells );
        }
        $max_cell_width
    } 0 .. $max_index;

    # calculate column widths
    my $available_length = $params->{linewidth}
        - length($params->{left_border} . $params->{right_border})
        - (@column_widths - 1) * length($params->{separator});
    my @modifiable_column_indices = grep { !@{$params->{cell_options}} || !$params->{cell_options}->[$_]->{width} } 0 .. $#column_widths;
    while (List::Util::sum(@column_widths) > $available_length) {
        my $max_width = List::Util::max(@column_widths[@modifiable_column_indices]);
        my $max_index = List::MoreUtils::first_index {
            my $index = $_;
            $column_widths[$index] eq $max_width && grep { $_ == $index } @modifiable_column_indices
        } 0 .. $#column_widths;
        my $lineout = List::Util::sum(@column_widths) - $available_length;
        $column_widths[$max_index] = List::Util::max(int($column_widths[$max_index] / 2), $column_widths[$max_index] - $lineout);
    }

    return @column_widths;
}

=head2 break_table_lines

Breaks cell content if it doesn't fit column width and returns table rows and cells (options and content). (Helper for table tag.)

=cut

sub break_table_lines {
    my $params = shift;

    my @lines           = @{$params->{lines}};
    my @column_widths   = @{$params->{column_widths}};

    LINE: for (my $i=@lines-1; $i>=0; $i--){
        next LINE if (ref($lines[$i]) ne 'ARRAY');
        my @add_lines = ();
        my $j = 0;
        my $linecolspan = 0; # colspan included until current cell
        my @cells = @{$lines[$i]}[1 .. @{$lines[$i]} - 1];
        CELL: for my $cell (@cells) {
            my $columnwidth = $column_widths[$j + $linecolspan];
            # add column width for colspan columns
            my $colspan = $cell->{options} && $cell->{options}->{colspan} ? $cell->{options}->{colspan} : 1;
            for (2..$colspan) {
                $linecolspan++;
                $columnwidth += length($params->{separator}) + $column_widths[$j + $linecolspan];
            }
            $j++ and next CELL if (!$cell->{text});
            # break lines
            $Text::Wrap::columns = $columnwidth + 1;
            my $line_count = 0;
            my @wrap_lines = split /\n/ => Text::Wrap::wrap('', '', $cell->{text} || '');
            for my $line ( @wrap_lines ) {
                if (!$line_count) {
                    $cell->{text} = $line;
                }
                else {
                    $add_lines[$line_count-1] ||= [$lines[$i]->[0], map { {$_->{options} ? (options => $_->{options}) : ()} } @cells];
                    $add_lines[$line_count-1]->[$j+1] = {
                        %$cell,
                        text => $line,
                    };
                }
                $line_count++;
            }
            $j++;
        }
        if (@add_lines) {
            splice(@lines, $i+1, 0, @add_lines);
        }
    }

    return @lines;
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
