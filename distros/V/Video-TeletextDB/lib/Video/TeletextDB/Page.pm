package Video::TeletextDB::Page;
use 5.006001;
use strict;
use warnings;
use Carp;
use Time::Local;

use Video::TeletextDB::Constants qw(:Colors :Attribute);

our $VERSION = "0.01";

use Exporter::Tidy
    functions => [qw(vote has_even unparity)],
    variables => [qw(%parity $even $epoch_time $scheme_re)];

our $epoch_time = timegm(0, 0, 0, 1, 0, 70);

# From URI.pm
our $scheme_re  = qr/[a-zA-Z][a-zA-Z0-9.+\-]*/;

our %parity = map { pack("C", $_) => sprintf("%b", $_) =~ tr/1// % 2 } 0..255;
our $even = join("", map $parity{pack("C", $_)} ? "" : sprintf("\\x%02x", $_), 0..255);
*has_even = eval "sub { shift =~ tr/$even// }" || die $@;
my $parity_map = join "" => map {
    my $ch = pack("C", $_);
    $parity{$ch} ? $ch & "\x7f" : "\x80";
} 0..255;
*unparity = eval "sub {
    my \$s = shift;
    \$s =~ tr//\Q$parity_map\E/c;
    return \$s;
}" || die $@;

sub fake_id {
    my ($page, $row) = @_;
    my $str = sprintf("%03x/%02x", $page->{page_nr}, $page->{subpage_nr});
    $str = sprintf(" /%04x", $page->{subpage_nr}) if length($str) > 6;
    croak "Invalid $page->{page_nr}/$page->{subpage_nr}" if length($str) != 6;
    # 0x02: Green FG
    # 0x07: White FG
    $str = "\x02$str\x07";
    # Make parity odd
    $str =~ s/(.)/$parity{$1} ? $1 : $1 ^ "\x80"/eg;
    $row =~ s/.{0,8}/$str/;
    return $row;
}

my @latin_G0 = map pack('@1C', $_), 0..127;
$latin_G0[0x24] = "\x00\xa4";
$latin_G0[0x7c] = "\x00\xa6";
$latin_G0[0x7f] = "\x00#";
# $latin_G0[0x7f] = "\x25\xa0";	# Right code, but leads to practical problems
$latin_G0[0x80] = "\x00\xfe";

my @default_mosaic_table = map "\x00#", 0..127;
$default_mosaic_table[0x00] = "\x00 ";
$default_mosaic_table[0x20] = "\x00 ";

# Derived from vbi_format_vt_page() in teletext.c in the zvbi package
# Every screen position gets represented as 4 bytes
# fg(4 bits), bg(4 bits)
# link(1) reserved(1) flash(1) conceal(1) opaq(2 bits) size(2 bits)
# char (2 bytes, ucs2)
sub decode {
    my $page = shift;
    my ($double, $double_and_mask, $double_or_mask);
    my $lang_map = \@latin_G0;
    my $row_nr = -1;
    my $mosaic_table = $page->{mosaic} || \@default_mosaic_table;
    my @rows;
    for (@{$page->{raw_rows}}) {
        $row_nr++;
        if ($double) {
            $double = undef;
            next;
        }
        my $cur_font = 0;
        my $lang_map = $page->{font}[$cur_font] || \@latin_G0;
        my $mosaic_type = 0;	# contiguous
        my $held_mosaic = $mosaic_table->[$mosaic_type+0x20];
        my ($hold, $mosaic);
        my $attr = pack("CC", WHITE*16+BLACK, 0);
        my $out = "";
        for (unpack "C*", unparity($row_nr ? $_ : $page->fake_id($_))) {
            if ($_ < 0x20) {
                # At spacing attributes
                if ($_ == 0x09) {
                    # Steady
                    vec($attr, FLASH, FLASH_BITS) = 0;
                } elsif ($_ == 0x0C) {
                    # Normal size
                    vec($attr, SIZE, SIZE_BITS) = NORMAL_SIZE;
                } elsif ($_ == 0x18) {
                    # Conceal
                    vec($attr, CONCEAL, CONCEAL_BITS) = 1;
                } elsif ($_ == 0x19) {
                    # contiguous mosaics
                    $mosaic_type = 0;
                } elsif ($_ == 0x1A) {
                    # separated mosaics
                    $mosaic_type = -0x20;
                } elsif ($_ == 0x1C) {
                    # black background
                    vec($attr, BG, BG_BITS) = BLACK;
                } elsif ($_ == 0x1D) {
                    # new background
                    vec($attr, BG, BG_BITS) = vec($attr, FG, FG_BITS);
                } elsif ($_ == 0x1E) {
                    # hold mosaic
                    $hold = 1;
                }

                $out .= $attr .
                    ($hold && $mosaic ? $held_mosaic : $lang_map->[0x20]);

                # After spacing attributes
                if (0x00 <= $_ && $_ <= 0x07) {
                    vec($attr, FG, FG_BITS) = $_;
                    vec($attr, CONCEAL, CONCEAL_BITS) = 0;
                    $mosaic = undef;
                } elsif ($_ == 0x08) {
                    # flash
                    vec($attr, FLASH, FLASH_BITS) = 1;
                } elsif ($_ == 0x0A) {
                    # end box
                    # Should only do this if next char is also 0x0a
                    vec($attr, OPAQUE, OPAQUE_BITS) =
                        $page->{opacity}[$row_nr ? 1 : 0];
                } elsif ($_ == 0x0B) {
                    # Should only do this if next char is also 0x0b
                    # start box
                    vec($attr, OPAQUE, OPAQUE_BITS) =
                        $page->{boxed_opacity}[$row_nr ? 1 : 0];
                } elsif ($_ == 0x0D) {
                    # double height
                    vec($attr, SIZE, SIZE_BITS) = DOUBLE_HEIGHT;
                    $double = 1;
                } elsif ($_ == 0x0E) {
                    # double width
                    vec($attr, SIZE, SIZE_BITS) = DOUBLE_WIDTH;
                } elsif ($_ == 0x0F) {
                    # double size
                    vec($attr, SIZE, SIZE_BITS) = DOUBLE_SIZE;
                    $double = 1;
                } elsif (0x10 <= $_ && $_ <= 0x17) {
                    # mosaic + foreground color
                    vec($attr, FG, FG_BITS) = $_ & 7;
                    vec($attr, CONCEAL, CONCEAL_BITS) = 0;
                    $mosaic = 1;
                } elsif ($_ == 0x1F) {
                    # release mosaic
                    $hold = undef;
                } elsif ($_ == 0x1B) {
                    # ESC
                    $cur_font = $cur_font ? 0 : 1;
                    $lang_map = $page->{font}[$cur_font] || \@latin_G0;
                }
            } elsif ($mosaic && ($_ & 0x20)) {
                $held_mosaic = $mosaic_table->[$mosaic_type + $_];
                $out .= $attr . $held_mosaic;
            } else {
                $out .= $attr . $lang_map->[$_];
            }
        }
        push @rows, $out;
        next unless $double;
        unless ($double_and_mask) {
            $double_and_mask = "\x00" x 4;
            vec($double_and_mask, FG, FG_BITS) = (1 << FG_BITS)-1;
            vec($double_and_mask, BG, BG_BITS) = (1 << BG_BITS)-1;
            vec($double_and_mask, CONCEAL, CONCEAL_BITS) = (1 << CONCEAL_BITS)-1;
            vec($double_and_mask, FLASH, FLASH_BITS) = (1 << FLASH_BITS)-1;
            $double_or_mask = "\x00" x 2 . $lang_map->[0x20];
        }
        $out =~ s/(.{4})/$1 & $double_and_mask | $double_or_mask/egs;
        push @rows, $out;
    }
    $page->{rows} = \@rows;
}

sub text {
    my $page = shift;
    $page->decode unless $page->{rows};
    return wantarray ? 
        map pack('U*', unpack('(@2n)*', $_), ord "\n"), @{$page->{rows}} : 
        pack('U*', map {unpack('(@2n)*', $_), ord "\n"} @{$page->{rows}});
}

# Lifted from CGI.pm
sub simple_escape {
    my $toencode = shift;
    $toencode =~ s/&/&amp;/g;
    $toencode =~ s/</&lt;/g;
    $toencode =~ s/>/&gt;/g;
    $toencode =~ s/"/&quot;/g; # "
    return $toencode;
}

sub html_attr {
    my ($page, $base_urls, $piece, $old_attr, $attr) = @_;
    my $out = "";
    # Link scanning should be moved into decode --Ton
    # Maybe generate pure text there too
    $out .= sprintf('%s<a href="%s">%s</a>',
                    HTML::Entities::encode_entities($1),
                    simple_escape
                    ($4 ? sprintf($base_urls->{subpage} || "../%03x/%02x%s", 
                                  hex $3, hex $5, @{$base_urls->{args}}) : 
                     $6 ? sprintf($base_urls->{uri} || "%s",
                                  $6, @{$base_urls->{args}}) :
                     $7 ? sprintf($base_urls->{uri} || "%s",
                                  "http://$7/", @{$base_urls->{args}}) :
                     sprintf($base_urls->{page} || "../%03x/%s", 
                             hex $3, @{$base_urls->{args}})),
                    HTML::Entities::encode_entities($2)) while 
                    $piece =~ m!(.*?)\b(([1-8]\d\d)(/(\d+)|)\b|($scheme_re://[a-zA-Z0-9_%&/=?+~:;.\@_-]*[a-zA-Z0-9_/])|(www(?:\.[a-zA-Z0-9-]+)+))!csg;
    $out .= HTML::Entities::encode_entities($1) if $piece =~ /(.*)/gs;
    if (substr($attr, 0, 1) ne substr($old_attr, 0, 1)) {
        # color change
        $out .= "</span>" if $old_attr;
        $out .= sprintf("<span class=c%02x>", unpack("C", $attr)) if $attr;
    }
    return $out;
}

sub html {
    my ($page, %params) = @_;
    my %base_urls = (page	=> delete $params{page_link}, 
                     subpage	=> delete $params{subpage_link},
                     uri	=> delete $params{uri},
                     args	=> delete $params{link_args});
    croak("Unknown parameters ", join(", ", keys %params)) if %params;
    $base_urls{args} = [""] unless defined $base_urls{args};
    $base_urls{args} = [$base_urls{args}] unless ref $base_urls{args};

    require HTML::Entities;

    $page->decode unless $page->{rows};

    my $out = '<pre class="vt">';
    for (@{$page->{rows}}) {
        # Need untainting due to a bug in applying regexes to utf8, 
        # fixed in perl 5.8.5
        /(.*)/s;
        my @row = unpack("(a2n)*", $1);
        my $old_attr = "";
        my $piece = "";
        while (@row) {
            my $attr = shift @row;
            if ($attr ne $old_attr) {
                $out .= $page->html_attr(\%base_urls, $piece, $old_attr, $attr);
                $piece = "";
                $old_attr = $attr;
            }
            $piece .= chr(shift @row);
        }
        $out .= $page->html_attr(\%base_urls, $piece, $old_attr, "") if 
            $piece;
        # Add newline and recover taint
        $out .= "\n" . substr($_, 0, 0);
    }
    return $out . "</pre>";
}

sub time : method {
    return shift->{time};
}

sub page_nr : method {
    return shift->{page_nr};
}

sub subpage_nr : method {
    return shift->{subpage_nr};
}

sub vote {
    # Save position and time
    return unless @_ > 3;
    my $page = bless {
        channel	=> shift,
        page_nr	=> shift,
        subpage_nr => shift,
        raw_rows=> \my @rows,
    }, "Video::TeletextDB::Page";

    my ($time, @first_screen) = unpack("N(C/a)*", shift);
    $page->{time} = $time + $epoch_time;

    # Decode all screens
    my @screens = map [unpack("x4(C/a)*", $_)], @_;

    # Determine biggest screen
    my $max_row = @first_screen;
    for (@screens) {
        $max_row = @$_ if @$_ > $max_row;
    }

    # Find first odd parity contents
    for my $row (0..$max_row-1) {
        if ($first_screen[$row] && !has_even($first_screen[$row])) {
            push @rows, $first_screen[$row];
            next;
        }
        push @rows, $first_screen[$row] || "\0" x 40;
        substr($rows[-1], 0, 8) = " " x 8 if $row == 0;
        $rows[-1] =~ s{[$even]}{
            my $pos = $-[0];
            my $str = "\x00";
            for (@screens) {
                next unless $_->[$row];
                if ($parity{substr($_->[$row], $pos, 1)}) {
                    $str = substr($_->[$row], $pos, 1);
                    last;
                }
            }
            $str;
        }ego;
        $rows[-1] = " "x 40 unless $rows[-1] =~ /[^\0]/;
    }
    return $page;
}

# This stylesheet is taken from alevtd
sub html_style {
    return <<'EOF';
body		{ background-color: white; color: black }

pre.vt		{ border: 0.1em solid black; padding: 1.1em }
pre.vt		{ background-color: #c0c0c0; width: auto; float: left }
pre.vt		{ white-space: pre }

div.quick	{ clear: both }

/* please don't re-color my links (underline is fine) */
/* it would be that simple in theory,
   but Mozilla/4 does not understand "inherit"  *grumble*
span a		{ color: inherit; background-color: inherit }
*/

/* videotext colors */
span.c00	{ color: #000000; background-color: #000000 }
span.c10	{ color: #ff0000; background-color: #000000 }
span.c20	{ color: #00ff00; background-color: #000000 }
span.c30	{ color: #ffff00; background-color: #000000 }
span.c40	{ color: #0000ff; background-color: #000000 }
span.c50	{ color: #ff00ff; background-color: #000000 }
span.c60	{ color: #00ffff; background-color: #000000 }
span.c70	{ color: #ffffff; background-color: #000000 }

span.c01	{ color: #000000; background-color: #ff0000 }
span.c11	{ color: #ff0000; background-color: #ff0000 }
span.c21	{ color: #00ff00; background-color: #ff0000 }
span.c31	{ color: #ffff00; background-color: #ff0000 }
span.c41	{ color: #0000ff; background-color: #ff0000 }
span.c51	{ color: #ff00ff; background-color: #ff0000 }
span.c61	{ color: #00ffff; background-color: #ff0000 }
span.c71	{ color: #ffffff; background-color: #ff0000 }

span.c02	{ color: #000000; background-color: #00ff00 }
span.c12	{ color: #ff0000; background-color: #00ff00 }
span.c22	{ color: #00ff00; background-color: #00ff00 }
span.c32	{ color: #ffff00; background-color: #00ff00 }
span.c42	{ color: #0000ff; background-color: #00ff00 }
span.c52	{ color: #ff00ff; background-color: #00ff00 }
span.c62	{ color: #00ffff; background-color: #00ff00 }
span.c72	{ color: #ffffff; background-color: #00ff00 }

span.c03	{ color: #000000; background-color: #ffff00 }
span.c13	{ color: #ff0000; background-color: #ffff00 }
span.c23	{ color: #00ff00; background-color: #ffff00 }
span.c33	{ color: #ffff00; background-color: #ffff00 }
span.c43	{ color: #0000ff; background-color: #ffff00 }
span.c53	{ color: #ff00ff; background-color: #ffff00 }
span.c63	{ color: #00ffff; background-color: #ffff00 }
span.c73	{ color: #ffffff; background-color: #ffff00 }

span.c04	{ color: #000000; background-color: #0000ff }
span.c14	{ color: #ff0000; background-color: #0000ff }
span.c24	{ color: #00ff00; background-color: #0000ff }
span.c34	{ color: #ffff00; background-color: #0000ff }
span.c44	{ color: #0000ff; background-color: #0000ff }
span.c54	{ color: #ff00ff; background-color: #0000ff }
span.c64	{ color: #00ffff; background-color: #0000ff }
span.c74	{ color: #ffffff; background-color: #0000ff }

span.c05	{ color: #000000; background-color: #ff00ff }
span.c15	{ color: #ff0000; background-color: #ff00ff }
span.c25	{ color: #00ff00; background-color: #ff00ff }
span.c35	{ color: #ffff00; background-color: #ff00ff }
span.c45	{ color: #0000ff; background-color: #ff00ff }
span.c55	{ color: #ff00ff; background-color: #ff00ff }
span.c65	{ color: #00ffff; background-color: #ff00ff }
span.c75	{ color: #ffffff; background-color: #ff00ff }

span.c06	{ color: #000000; background-color: #00ffff }
span.c16	{ color: #ff0000; background-color: #00ffff }
span.c26	{ color: #00ff00; background-color: #00ffff }
span.c36	{ color: #ffff00; background-color: #00ffff }
span.c46	{ color: #0000ff; background-color: #00ffff }
span.c56	{ color: #ff00ff; background-color: #00ffff }
span.c66	{ color: #00ffff; background-color: #00ffff }
span.c76	{ color: #ffffff; background-color: #00ffff }

span.c07	{ color: #000000; background-color: #ffffff }
span.c17	{ color: #ff0000; background-color: #ffffff }
span.c27	{ color: #00ff00; background-color: #ffffff }
span.c37	{ color: #ffff00; background-color: #ffffff }
span.c47	{ color: #0000ff; background-color: #ffffff }
span.c57	{ color: #ff00ff; background-color: #ffffff }
span.c67	{ color: #00ffff; background-color: #ffffff }
span.c77	{ color: #ffffff; background-color: #ffffff }

/* The same again for all the links... */
span.c00 a	{ color: #000000; background-color: #000000 }
span.c10 a	{ color: #ff0000; background-color: #000000 }
span.c20 a	{ color: #00ff00; background-color: #000000 }
span.c30 a	{ color: #ffff00; background-color: #000000 }
span.c40 a	{ color: #0000ff; background-color: #000000 }
span.c50 a	{ color: #ff00ff; background-color: #000000 }
span.c60 a	{ color: #00ffff; background-color: #000000 }
span.c70 a	{ color: #ffffff; background-color: #000000 }

span.c01 a	{ color: #000000; background-color: #ff0000 }
span.c11 a	{ color: #ff0000; background-color: #ff0000 }
span.c21 a	{ color: #00ff00; background-color: #ff0000 }
span.c31 a	{ color: #ffff00; background-color: #ff0000 }
span.c41 a	{ color: #0000ff; background-color: #ff0000 }
span.c51 a	{ color: #ff00ff; background-color: #ff0000 }
span.c61 a	{ color: #00ffff; background-color: #ff0000 }
span.c71 a	{ color: #ffffff; background-color: #ff0000 }

span.c02 a	{ color: #000000; background-color: #00ff00 }
span.c12 a	{ color: #ff0000; background-color: #00ff00 }
span.c22 a	{ color: #00ff00; background-color: #00ff00 }
span.c32 a	{ color: #ffff00; background-color: #00ff00 }
span.c42 a	{ color: #0000ff; background-color: #00ff00 }
span.c52 a	{ color: #ff00ff; background-color: #00ff00 }
span.c62 a	{ color: #00ffff; background-color: #00ff00 }
span.c72 a	{ color: #ffffff; background-color: #00ff00 }

span.c03 a	{ color: #000000; background-color: #ffff00 }
span.c13 a	{ color: #ff0000; background-color: #ffff00 }
span.c23 a	{ color: #00ff00; background-color: #ffff00 }
span.c33 a	{ color: #ffff00; background-color: #ffff00 }
span.c43 a	{ color: #0000ff; background-color: #ffff00 }
span.c53 a	{ color: #ff00ff; background-color: #ffff00 }
span.c63 a	{ color: #00ffff; background-color: #ffff00 }
span.c73 a	{ color: #ffffff; background-color: #ffff00 }

span.c04 a	{ color: #000000; background-color: #0000ff }
span.c14 a	{ color: #ff0000; background-color: #0000ff }
span.c24 a	{ color: #00ff00; background-color: #0000ff }
span.c34 a	{ color: #ffff00; background-color: #0000ff }
span.c44 a	{ color: #0000ff; background-color: #0000ff }
span.c54 a	{ color: #ff00ff; background-color: #0000ff }
span.c64 a	{ color: #00ffff; background-color: #0000ff }
span.c74 a	{ color: #ffffff; background-color: #0000ff }

span.c05 a	{ color: #000000; background-color: #ff00ff }
span.c15 a	{ color: #ff0000; background-color: #ff00ff }
span.c25 a	{ color: #00ff00; background-color: #ff00ff }
span.c35 a	{ color: #ffff00; background-color: #ff00ff }
span.c45 a	{ color: #0000ff; background-color: #ff00ff }
span.c55 a	{ color: #ff00ff; background-color: #ff00ff }
span.c65 a	{ color: #00ffff; background-color: #ff00ff }
span.c75 a	{ color: #ffffff; background-color: #ff00ff }

span.c06 a	{ color: #000000; background-color: #00ffff }
span.c16 a	{ color: #ff0000; background-color: #00ffff }
span.c26 a	{ color: #00ff00; background-color: #00ffff }
span.c36 a	{ color: #ffff00; background-color: #00ffff }
span.c46 a	{ color: #0000ff; background-color: #00ffff }
span.c56 a	{ color: #ff00ff; background-color: #00ffff }
span.c66 a	{ color: #00ffff; background-color: #00ffff }
span.c76 a	{ color: #ffffff; background-color: #00ffff }

span.c07 a	{ color: #000000; background-color: #ffffff }
span.c17 a	{ color: #ff0000; background-color: #ffffff }
span.c27 a	{ color: #00ff00; background-color: #ffffff }
span.c37 a	{ color: #ffff00; background-color: #ffffff }
span.c47 a	{ color: #0000ff; background-color: #ffffff }
span.c57 a	{ color: #ff00ff; background-color: #ffffff }
span.c67 a	{ color: #00ffff; background-color: #ffffff }
span.c77 a	{ color: #ffffff; background-color: #ffffff }
EOF
}

1;
__END__

=head1 NAME

Video::TeletextDB::Page - Postprocessing Video::TeletextDB pages

=head1 SYNOPSIS

  use Video::TeletextDB;
  $tele_db	= Video::TeletextDB->new(...);
  $access	= $tele_db->access(...);
  $page		= $access->fetch_page($page_nr, $subpage_nr);
  @pages	= $access->fetch_page_versions($page_nr, $subpage_nr);

  $text		= $page->text;
  @text		= $page->text;
  $html		= $page->html(%parameters);
  $style	= Video::TeletextDB::Page->html_style;

  $time		= $page->time;
  $page_nr	= $page->page_nr;
  $subpage_nr	= $page->subpage_nr;

=head1 DESCRIPTION

A Video::TeletextDB::Page object represents one presentable page. Each 
character on the page has attributes like foreground color, size etc.
Here you'll find methods to extract this information.

=head1 METHODS

All presentation methods by default present mosaic (the name used for a set of
very primitive 3x2 grapics blocks occupying one character position) as C<#> 
except for the empty mosaic which is shown as C< >.

Currently only does level 1 Teletext. More may get added later.

=over

=item X<text>$text = $page->text

=item @text = $page->text

Returns the page as pure text with all attributes removed. In list context
it returns one element per line (each line will have a newline at the 
end). In scalar context it returns the concatenation of all lines.

=item X<html>$html = $page->html(%parameters)

Returns a block of html text representing the page. Currently the only
attributes used to build the html are colors and links. Ranges with a certain
attribute are wrapped in E<lt>spanE<gt> tags. You still have to apply a 
style sheet to make them do something. A default style sheet is available
as the L<html_style method|"html_style">.

Parameters are name/value pairs, which can be:

=over

=item X<link_args>link_args => $value

=item X<link_args>link_args => \@value

Extra arguments passed to the formats described below. Typically used to
propagate a query string.

Defaults to "" if not given.

=item X<page_link>page_link => $page_format

Whenever a link to a teletext page (without a subpage number) is recognized, 
it's run through L<sprintf|perlfunc/sprintf> with $page_format as format and 
the decimal page number (followed by any L<linkargs|"linkargs">) as argument.
The result is then html escaped and used in a quoted href.

Defaults to C<../%03x/%s> if not given.

=item X<subpage_link>subpage_link => $subpage_format

Whenever a link to a teletext page with a subpage number is recognized, 
it's run through L<sprintf|perlfunc/sprintf> with $subpage_format as format and
the decimal page and subpage number (followed by any L<linkargs|"linkargs">) 
as arguments. The result is then html escaped and used in a quoted href.

Defaults to C<../%03x/%02x%s> if not given.

=item X<uri>uri => $uri_format

Whenever an URI is recognized in the teletext page, it's run through 
L<sprintf|perlfunc/sprintf> with $uri_format as format and the URI (followed by
any L<linkargs|"linkargs">) as arguments. The result is then html escaped and 
used in a quoted href.

Defaults to C<%s> if not given.

=back

=item $style = Video::TeletextDB::Page->html_style

Returns a default stylesheet (without headers) intended to be used with the
L<html|"html"> method. It's basically the style sheet from L<alevtd|alevtd(1)>.

=item X<time>$time = $page->time

Returns the time associated with this page (meant to be the time the
page was extracted from the teletext stream).

=item X<page_nr>$page_nr = $page->page_nr

Returns the decimal page number of this page.

=item X<subpage_nr>$subpage_nr = $page->subpage_nr

Returns the decimal subpage number of this page

=back

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Video::TeletextDB>,
L<Video::TeletextDB::Access>,
L<alevtd(1)>,
http://zapping.sourceforge.net/cgi-bin/view/ZVBI/WebHome

=head1 AUTHOR

Ton Hospel, E<lt>Video-TeletextDB@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
