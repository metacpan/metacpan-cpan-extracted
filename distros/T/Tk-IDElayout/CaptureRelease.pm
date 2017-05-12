package Tk::CaptureRelease;

our ($VERSION) = ('0.33');

use Tk;
require DynaLoader;

use base  qw(DynaLoader);

bootstrap Tk::CaptureRelease;

package Tk;
use Tk::Submethods ( '_wm' => [qw(capture release)] );
package Tk::CaptureRelease;

{ 
	# Alias our _wmCapture to wmCapture and _wmRelease to wmRelease
	#   This will replace the ones in the stock Tk that are missing (on win32) or dont work (on unix)

	no warnings;  # Warnings are expected here, so we turn them off
	*Tk::Widget::wmRelease = \&Tk::_wmRelease;
	*Tk::Widget::wmCapture = \&Tk::_wmCapture;
}

1;
