$Tk::ImageButton::VERSION = '1.0';

package ImageButton;

use strict;
use Tk;

require Tk::Label;
use base qw(Tk::Derived Tk::Label);

Construct Tk::Widget 'ImageButton';

sub ClassInit
{
	my ($class, $mw) = @_;
	$class->SUPER::ClassInit($mw);

	$mw->bind($class, '<Enter>', \&_IBEnter);		# Call _IBEnter when the mouse moves over the button.
	$mw->bind($class, '<Leave>', \&_IBLeave);		# Call _IBLeave when the mouse moves off the button.
	$mw->bind($class, '<ButtonPress-1>', \&_IBPress);	# Call _IBPress when the left mouse button is pressed over the button.
	$mw->bind($class, '<ButtonRelease-1>', \&_IBRelease);	# Call _IBRelease when the left mouse button is released.
}

sub Populate
{
	my ($widget, $args) = @_;

	# -imagedisplay  - Required - This option is used to define the image that will be used as the default image for the button.
	#                             This is also the fallback option should none of the other images be set.
	#                             Needs to be passed a Tk::Photo
	# -imageover     - Optional - This option is used to define the image that is used when the mouse pointer is over the button.
	#                             If this is not set then -imagedisplay will be used.
	#                             Needs to be passed a Tk::Photo
	# -imageclick    - Optional - This option is used to define the image that is used when the left mouse button is clicked
	#                             over the button. If this is not set then -imagedisplay will be set.
	#                             Needs to be passed a Tk::Photo
	# -imagedisabled - Optional - This option is used to define the image that will be used when the button is disabled.
	#                             If this is not set then -imagedisplay will be used.
	#                             Needs to be passed a Tk::Photo
	# -state         - Optional - This stores the state of the button, either 'normal' or 'disabled'. This defaults to 'normal'
	#                             which is why I've called it optional. Changing the state will automatically update the button.
	# -command       - Optional - When you set the command, when the mouse button is released then the command is run. If you're
	#                             going to be using a button, then you really should set a command!

	$widget->ConfigSpecs(
				-imagedisplay => [qw/METHOD imageDisplay ImageDisplay/, 0],
				-imageover => [qw/METHOD imageOver ImageOver/, 0],
				-imageclick => [qw/METHOD imageClick ImageClick/, 0],
				-imagedisabled => [qw/METHOD imageDisabled ImageDisabled/, 0],
				-state => [qw/METHOD state State/, 'normal'],
				-command => ["CALLBACK", "command", "Command", undef]
	);

	$widget->configure(-borderwidth => 0);
	$widget->SUPER::Populate;

	# This section sets up the variables we'll be using in this widget. They are pretty self-explanatory, each one corresponds
	# to an option (listed above). The 'image_*' vars store Tk::Photo data. The 'state' var stores the state of the button.

	$widget->{image_display} = 0;
	$widget->{image_click} = 0;
	$widget->{image_over} = 0;
	$widget->{image_disabled} = 0;
	$widget->{state} = 'normal';
}

# When the mouse pointer moves over the button, if the button is enabled and -imageover has been set then we change the
# visible image to that of the -imageover option. If -imageover isn't set or the button is disabled then we don't change
# the image from that of the default.

sub _IBEnter
{
	my ($widget, $args) = @_;

	if ($widget->{state} ne 'disabled')
	{
		if ($widget->{image_over} != 0)
		{
			$widget->configure(-image => $widget->{image_over});
			$widget->update;
		}
	}
}

# When the mouse pointer moves from over the button to somewhere else, if the button isn't disabled then we
# set the button image back to the -imagedisplay Tk::Photo.

sub _IBLeave
{
	my ($widget, $args) = @_;

	if ($widget->{state} ne 'disabled')
	{
		if ($widget->{image_display} != 0)
		{
			$widget->configure(-image => $widget->{image_display});
			$widget->update;
		}
	}
}

# When the mouse pointer is clicked over the button, if -imageclick has been set and the button is not disabled
# then we change the button image to that of the -imageclick option.

sub _IBPress
{
	my ($widget, $args) = @_;

	if ($widget->{state} ne 'disabled')
	{
		if ($widget->{image_click} != 0)
		{
			$widget->configure(-image => $widget->{image_click});
			$widget->update;
		}
	}
}

# When the mouse button is released, if the button is not disabled and the option -imageover has been set then
# the button image is changed to that of the -imageover option. If the -imageover option has not been set then
# the button image is changed to that of the -imagedisplay option. The -command option is then called.

sub _IBRelease
{
	my ($widget, $args) = @_;

	if ($widget->{state} ne 'disabled')
	{
		if ($widget->{image_over} != 0)
		{
			$widget->configure(-image => $widget->{image_over});
			$widget->update;
		}
		elsif ($widget->{image_display} != 0)
		{
			$widget->configure(-image => $widget->{image_display});
			$widget->update;
		}

		$widget->Callback(-command => $widget);
	}
}

# This sets the -imagedisplay option. It takes a Tk::Photo as it's argument.
# It then sets the initial image of the button to that Tk::Photo.
# If cget is called on the option then it's setting is returned.

sub imagedisplay
{
	my ($widget, $args) = @_;

	if ($#_ > 0)
	{
		$widget->{image_display} = $args;
		$widget->configure(-image => $widget->{image_display});
		$widget->update;
	}
	else
	{
		$widget->{image_display};
	}
}

# This sets the -imageover option. It takes a Tk::Photo as it's argument.
# If cget is called on the option then it's setting is returned.

sub imageover
{
	my ($widget, $args) = @_;

	if ($#_ > 0)
	{
		$widget->{image_over} = $args;
	}
	else
	{
		$widget->{image_over};
	}
}

# This sets the -imageclick option. It takes a Tk::Photo as it's argument.
# If cget is called on the option then it's setting is returned.

sub imageclick
{
	my ($widget, $args) = @_;

	if ($#_ > 0)
	{
		$widget->{image_click} = $args;
	}
	else
	{
		$widget->{image_click};
	}
}

# This sets the -imagedisabled option. It takes a Tk::Photo as it's argument.
# If cget is called on the option then it's setting is returned.

sub imagedisabled
{
	my ($widget, $args) = @_;

	if ($#_ > 0)
	{
		$widget->{image_disabled} = $args;
	}
	else
	{
		$widget->{image_disabled};
	}
}

# This sets the -state option. If the button is set to 'normal' then the -imagedisplay
# image is set as the button image. If the button is set to 'disabled' then the
# -imagedisabled option is set as the button image (if the option has been set).
# If cget is called on the option then it's setting is returned.

sub state
{
	my ($widget, $args) = @_;

	if ($#_ > 0)
	{
		$widget->{state} = $args;

		if ($widget->{state} eq 'normal')
		{
			if ($widget->{image_display} != 0)
			{
				$widget->configure(-image => $widget->{image_display});
				$widget->update;
			}
		}
		elsif ($widget->{state} eq 'disabled')
		{
			if ($widget->{image_disabled} != 0)
			{
				$widget->configure(-image => $widget->{image_disabled});
				$widget->update;
			}
		}
	}
	else
	{
		$widget->{state};
	}
}

1;


