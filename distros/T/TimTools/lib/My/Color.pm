package My::Color;

use strict;
use warnings;
use feature qw/ say /;
use parent qw/ Exporter /;

# Text Color
our $RESTORE     = "\e[0m";
our $RED         = "\e[31m";
our $GREEN       = "\e[32m";
our $YELLOW      = "\e[33m";
our $VIOLET      = "\e[35m";
our $TEAL        = "\e[36m";
our $RED_BOLD    = "\e[91m";
our $GREEN_BOLD  = "\e[92m";
our $YELLOW_BOLD = "\e[93m";
our $VIOLET_BOLD = "\e[95m";
our $TEAL_BOLD   = "\e[96m";
our $GREY        = "\e[90m";

# Background Color
our $BG_RED    = "\e[41m";
our $BG_GREEN  = "\e[42m";
our $BG_YELLOW = "\e[43m";
our $BG_BLUE   = "\e[105m";
our $BG_VIOLET = "\e[45m";
our $BG_TEAL   = "\e[46m";
our $BG_GREY   = "\e[100m";

# Properties
our $BOLD      = "\e[1m";
our $UNDERLINE = "\e[4m";
our $BLINK     = "\e[5m";

# Combinations
our $WARN = "$BLINK$YELLOW";
our $DIE  = "$BLINK$RED";

# Export
our @EXPORT    = qw/ /;
our @EXPORT_OK = qw/
  apply_color
  $RESTORE
  $RED
  $GREEN
  $YELLOW
  $VIOLET
  $TEAL
  $RED_BOLD
  $GREEN_BOLD
  $YELLOW_BOLD
  $VIOLET_BOLD
  $TEAL_BOLD
  $GREY
  $BG_RED
  $BG_GREEN
  $BG_YELLOW
  $BG_BLUE
  $BG_VILET
  $BG_TEAL
  $BG_GREY
  $BOLD
  $UNDERLINE
  $BLINK
  $WARN
  $DIE
  /;
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ], );

sub apply_color {
   my ( $whole, $parts, $opts ) = @_;
   my $is_escape_or_data = _get_is_escape_or_data();
   my @colors            = _get_custom_colors();
   my $default_color     = pop @colors;                # Last color is default
   my $case =
     $opts->{case_sensitive} ? "(?-i)" : "(?i)";   # Case Insensitive by default
   my @keys =
     map { ref() ? $_ : ( $opts->{regex} ? qr/$case$_/ : qr/$case\Q$_/ ) }
     @$parts;    # No regex by default
                 #@colors                  = _normalize_color_codes( @colors );

   our $last_esc = "";

   for my $index ( 0 .. $#keys ) {
      my $key   = $keys[$index];
      my $color = ( $index < @colors ) ? $colors[$index] : $default_color;

      $whole =~ s{$is_escape_or_data}
		{
			local $_  = $1 // "";
			$last_esc = $2 // $last_esc;
			s/($key)/$color$1$RESTORE$last_esc/g;
			$_;
		}gex;
   }

   return $whole;
}

sub _get_is_escape_or_data {
   my $esc  = qr/ \033\[ [\d;]+m    /x;
   my $data = qr/ (?: (?!$esc) . )+ /x;    # Not escape
   my $or   = qr/ ($data)|($esc\K)  /x;    # Must therefore match one of them

   $or;
}

sub _get_background_colors {
   ( $BG_RED, $BG_GREEN, $BG_YELLOW, $BG_BLUE, $BG_VIOLET, $BG_TEAL, );
}

sub _get_foreground_colors {
   (
      $RED,      $GREEN,      $YELLOW,      $VIOLET,      $TEAL,
      $RED_BOLD, $GREEN_BOLD, $YELLOW_BOLD, $VIOLET_BOLD, $TEAL_BOLD,
   );
}

sub _get_custom_colors {
   ( $BG_GREY, $RED, $GREEN, $YELLOW, $VIOLET, );
}

sub _init {

   system '';    # Enable escape code ?!
}


_init();


sub _normalize_color_codes {
   my @raw_colors = @_;

   my $front  = qr/ \\033\[ /x;
   my $end    = qr/ m       /x;
   my @colors = map {
      s/$front//g;
      s/$end//g;
      "\033[${_}m";
   } split " ", shift @raw_colors;

   @colors;
}


1;
