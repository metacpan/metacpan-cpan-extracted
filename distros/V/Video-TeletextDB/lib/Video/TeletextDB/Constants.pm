package Video::TeletextDB::Constants;
use 5.006001;
use strict;
use warnings;
use Carp;

our $VERSION = "0.01";

use Exporter::Tidy
    # A lot more of these exist in Video::Capture::VBI, but we don't use them,
    # nor do we really want to export them since they are none of our business
    VTX		=> [qw(VTX_SUB VTX_C11)],
    VBI		=> [qw(VBI_VT)],

    PageSize	=> [qw(ROWS COLUMNS)],
    Colors	=> [qw(BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE)],
    BdbPrefixes	=> [qw(STORES PAGE_VERSIONS VERSION PAGE COUNTER)],
    Attribute	=> [qw(FLASH_BITS FLASH CONCEAL_BITS CONCEAL SIZE_BITS SIZE 
                       OPAQUE_BITS OPAQUE FG_BITS FG BG_BITS BG CHAR_BITS CHAR
                       NORMAL_SIZE DOUBLE_HEIGHT DOUBLE_WIDTH DOUBLE_SIZE)],
    Other	=> [qw(DB_VERSION)];

# use Video::Capture::VBI qw(decode_vtpage VTX_FLASH VTX_SUB);
sub VTX_SUB	() { 0x003f7f };
sub VTX_C11	() { 0x100000 };	# magazine serial

sub VBI_VT	() { 0x0001 };

sub COLUMNS	() { 40 };
sub ROWS	() { 25 };

sub BG_BITS	() { 4 };
sub BG		() { 0/BG_BITS };
sub FG_BITS	() { 4 };
sub FG		() { 4/FG_BITS };
sub SIZE_BITS	() { 2 };
sub SIZE	() { (8+0)/SIZE_BITS };
sub OPAQUE_BITS	() { 2 };
sub OPAQUE	() { (8+2)/OPAQUE_BITS };
sub CONCEAL_BITS() { 1 };
sub CONCEAL	() { (8+4)/CONCEAL_BITS };
sub FLASH_BITS	() { 1 };
sub FLASH	() { (8+5)/FLASH_BITS };
sub CHAR_BITS	() { 16 };
sub CHAR	() { 16/CHAR_BITS };

sub NORMAL_SIZE	() { 0 };
sub DOUBLE_HEIGHT(){ 1 };
sub DOUBLE_WIDTH() { 2 };
sub DOUBLE_SIZE	() { 3 };

sub BLACK	() { 0 };
sub RED		() { 1 };
sub GREEN	() { 2 };
sub YELLOW	() { 3 };
sub BLUE	() { 4 };
sub MAGENTA	() { 5 };
sub CYAN	() { 6 };
sub WHITE	() { 7 };

sub STORES	() { "s" };
sub PAGE_VERSIONS(){ "S" };
sub VERSION	() { "V" };
sub PAGE	() { "p" };
sub COUNTER	() { "c" };

sub DB_VERSION	() { 1 };

1;
__END__
