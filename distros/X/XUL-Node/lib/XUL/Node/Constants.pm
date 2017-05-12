package XUL::Node::Constants;

use strict;
use warnings;
use Carp;

use base 'Exporter';

our @EXPORT = qw(
	FLEX ALIGN_START ALIGN_CENTER ALIGN_END ALIGN_BASELINE ALIGN_STRETCH
	ALIGN_LEFT ALIGN_CENTER ALIGN_RIGHT PACK_START PACK_CENTER PACK_END
	ORIENT_HORIZONTAL ORIENT_VERTICAL DIR_FORWARD DIR_REVERSE CROP_START
	CROP_CENTER CROP_END SIZE_TO_CONTENT DISABLED ENABLED TYPE_CHECKBOX
	TYPE_RADIO TYPE_MENU TYPE_MENU_BUTTON TYPE_BUTTON TYPE_PASSWORD FILL
);

use constant FLEX              => (flex => 1);

use constant ALIGN_START       => (align => 'start');
use constant ALIGN_CENTER      => (align => 'center');
use constant ALIGN_END         => (align => 'end');
use constant ALIGN_BASELINE    => (align => 'baseline');
use constant ALIGN_STRETCH     => (align => 'stretch');
use constant ALIGN_LEFT        => (align => 'left');
use constant ALIGN_RIGHT       => (align => 'right');

use constant PACK_START        => (pack => 'start');
use constant PACK_CENTER       => (pack => 'center');
use constant PACK_END          => (pack => 'end');

use constant ORIENT_HORIZONTAL => (orient => 'horizontal');
use constant ORIENT_VERTICAL   => (orient => 'vertical');

use constant DIR_FORWARD       => (dir => 'forward');
use constant DIR_REVERSE       => (dir => 'reverse');

use constant CROP_START        => (crop => 'start');
use constant CROP_CENTER       => (crop => 'center');
use constant CROP_END          => (crop => 'end');

use constant SIZE_TO_CONTENT   => (sizeToContent => 1);

use constant DISABLED          => (disabled => 1);
use constant ENABLED           => (disabled => 0);

use constant TYPE_CHECKBOX     => (type => 'checkbox');
use constant TYPE_RADIO        => (type => 'radio');
use constant TYPE_MENU         => (type => 'menu');
use constant TYPE_MENU_BUTTON  => (type => 'menu-button');
use constant TYPE_BUTTON       => (type => 'button');
use constant TYPE_PASSWORD     => (type => 'password');

use constant FILL              => (ALIGN_STRETCH, FLEX);

1;
