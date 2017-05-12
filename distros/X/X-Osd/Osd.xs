#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xosd.h>

#define CVS_VERSION "$Id: Osd.xs,v 1.7 2003/07/01 12:51:18 gozer Exp $"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static int
constant(char *name, int len, int arg)
{
    errno = 0;
	if (strEQ(name + 0, "XOSD_top")) {	
	return XOSD_top;
    }
	else if (strEQ(name + 0, "XOSD_bottom")) {
	return XOSD_bottom;
    }
	else if (strEQ(name + 0, "XOSD_middle")) {
		return XOSD_middle;
	}
	else if (strEQ(name + 0, "XOSD_left")) {
		return XOSD_left;
	}
	else if (strEQ(name + 0, "XOSD_center")) {
		return XOSD_center;
	}
	else if (strEQ(name + 0, "XOSD_right")) {
		return XOSD_right;
	}
	
    errno = EINVAL;
    return 0;
}

MODULE = X::Osd		PACKAGE = X::Osd		PREFIX = xosd_

PROTOTYPES: DISABLES
		
double
constant(sv,arg)
    PREINIT:
	STRLEN		len;

    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg

    CODE:
	RETVAL = constant(s,len,arg);

    OUTPUT:
	RETVAL
		
int			
xosd_string(osd,line,string)
	xosd *	osd
	int		line
	char *	string
	
	CODE:
	RETVAL = xosd_display(osd,line,XOSD_string,string);
	
	OUTPUT:
	RETVAL	

int
xosd_printf(osd,line,string)
	xosd *	osd
	int		line
	char *	string

	CODE:
		RETVAL = xosd_display(osd,line,XOSD_printf,string);

	OUTPUT:
		RETVAL


int
xosd_percentage(osd,line,percent)
	xosd *	osd
	int		line
	int		percent
	
	CODE:
	RETVAL = xosd_display(osd,line,XOSD_percentage,percent);

	OUTPUT:
	RETVAL		

int
xosd_slider(osd,line,percent)
	xosd *	osd
	int		line
	int		percent
	
	CODE:
	RETVAL = xosd_display(osd,line,XOSD_slider,percent);
	
	OUTPUT:
	RETVAL
			
int
xosd_is_onscreen(osd)
	xosd *	osd

int 
xosd_wait_until_no_display(osd)
	xosd *  osd

int
xosd_scroll(osd, lines)
	xosd *  osd
	int	lines
	
int
xosd_get_number_lines(osd)
	xosd * osd
	
int
xosd_get_colour(osd, red, green, blue)
	xosd *	osd
	int *	red
	int *	green
	int *	blue

#if 0

int
xosd_get_shadow_colour(osd, red, green, blue)
	xosd *	osd
	int *	red
	int *	green
	int *	blue

#endif

#if 0

int
xosd_get_outline_colour(osd, red, green, blue)
	xosd *	osd
	int *	red
	int *	green
	int *	blue

#endif

int
xosd_hide(osd)
	xosd *	osd

xosd *
xosd_create(num_lines)
	int	num_lines

int
xosd_set_bar_length(osd, length)
	xosd *	osd
	int	length

int
xosd_set_colour(osd, colour)
	xosd *	osd
	char *	colour

int
xosd_set_shadow_colour(osd, colour)
	xosd *	osd
	char *	colour

int
xosd_set_outline_colour(osd, colour)
	xosd *	osd
	char *	colour

int
xosd_set_font(osd, font)
	xosd *	osd
	char *	font

int
xosd_set_horizontal_offset(osd, offset)
	xosd *	osd
	int	offset

int
xosd_set_vertical_offset(osd, offset)
	xosd *	osd
	int	offset

int
xosd_set_pos(osd, pos)
	xosd *	osd
	int	pos

int
xosd_set_align(osd, align)
	xosd *	osd
	int	align

int
xosd_set_shadow_offset(osd, shadow_offset)
	xosd *	osd
	int	shadow_offset

int
xosd_set_outline_offset(osd, outline_offset)
	xosd *	osd
	int	outline_offset

int
xosd_set_timeout(osd, timeout)
	xosd *	osd
	int	timeout

int
xosd_show(osd)
	xosd *	osd

int
xosd_destroy(osd)
	xosd *	osd
    ALIAS:
    DESTROY = 1
