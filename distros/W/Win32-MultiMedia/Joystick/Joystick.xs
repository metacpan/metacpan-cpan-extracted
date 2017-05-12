#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mmsystem.h>

MMRESULT JOY_error=0;

MODULE = Win32::MultiMedia::Joystick		PACKAGE = Win32::MultiMedia::Joystick		PREFIX = joy


UINT
joyGetNumDevs()

SV*
joyGetThreshold(uJoyID)
	 UINT uJoyID
	CODE:
		UINT puThreshold;
		MMRESULT ret;
		ret = joyGetThreshold(uJoyID, &puThreshold);
		if (ret)
		{
			JOY_error=ret;
			RETVAL=&PL_sv_undef;
		}
		else
		{
			JOY_error=ret;
			RETVAL = newSViv(puThreshold);
		}
	OUTPUT:
		RETVAL

SV*
joySetThreshold(uJoyID, uThreshold)
	 UINT uJoyID
	 UINT uThreshold
	CODE:
		MMRESULT ret;
		ret = joySetThreshold(uJoyID, uThreshold);
		if (ret)
		{
			JOY_error=ret;
			RETVAL=&PL_sv_undef;
		}
		else
		{
			JOY_error=ret;
			RETVAL = newSViv(1);
		}
	OUTPUT:
		RETVAL


SV*
joyReleaseCapture(uJoyID)
	 UINT uJoyID
	CODE:
		MMRESULT ret;
		ret =	joyReleaseCapture(uJoyID);
		if (ret)
		{
			JOY_error=ret;
			RETVAL=&PL_sv_undef;
		}
		else
		{
			JOY_error=ret;
			RETVAL = newSViv(1);
		}
	OUTPUT:
		RETVAL


SV*
joySetCapture(hwnd, uJoyID, uPeriod, fChanged)
	 HWND hwnd
	 UINT uJoyID
	 UINT uPeriod
	 long fChanged
	CODE:
		MMRESULT ret;
		ret = joySetCapture(hwnd, uJoyID, uPeriod, fChanged);
		if (ret)
		{
			JOY_error=ret;
			RETVAL=&PL_sv_undef;
		}
		else
		{
			JOY_error=ret;
			RETVAL = newSViv(1);
		}
	OUTPUT:
		RETVAL


SV*
GetInfo(uJoyID, raw=0)
	 UINT uJoyID
	 int raw
	PREINIT:
		JOYINFOEX jinfo;
		MMRESULT ret;
		HV* hash;
	CODE:
		jinfo.dwSize = sizeof(jinfo);
		jinfo.dwFlags = JOY_RETURNALL;
		if (raw)
		{
		  jinfo.dwFlags = (jinfo.dwFlags | JOY_RETURNRAWDATA);
		}
		
		hash = newHV();
		if ((ret=joyGetPosEx(uJoyID,&jinfo))==JOYERR_NOERROR)
		{
			hv_store(hash,"X",1,newSViv(jinfo.dwXpos),0);
			hv_store(hash,"Y",1,newSViv(jinfo.dwYpos),0);
			hv_store(hash,"Z",1,newSViv(jinfo.dwZpos),0);
			hv_store(hash,"R",1,newSViv(jinfo.dwRpos),0);
			hv_store(hash,"U",1,newSViv(jinfo.dwUpos),0);
			hv_store(hash,"V",1,newSViv(jinfo.dwVpos),0);
			hv_store(hash,"ButtonNumber",12,newSViv(jinfo.dwButtonNumber),0);

			hv_store(hash,"Buttons",7,newSViv(jinfo.dwButtons),0);
			hv_store(hash,"POV",3,newSViv(jinfo.dwPOV),0);

			hv_store(hash,"B1",2,newSViv(jinfo.dwButtons & JOY_BUTTON1),0);
			hv_store(hash,"B2",2,newSViv(jinfo.dwButtons & JOY_BUTTON2),0);
			hv_store(hash,"B3",2,newSViv(jinfo.dwButtons & JOY_BUTTON3),0);
			hv_store(hash,"B4",2,newSViv(jinfo.dwButtons & JOY_BUTTON4),0);
			hv_store(hash,"B5",2,newSViv(jinfo.dwButtons & JOY_BUTTON5),0);
			hv_store(hash,"B6",2,newSViv(jinfo.dwButtons & JOY_BUTTON6),0);
			hv_store(hash,"B7",2,newSViv(jinfo.dwButtons & JOY_BUTTON7),0);
			hv_store(hash,"B8",2,newSViv(jinfo.dwButtons & JOY_BUTTON8),0);
			hv_store(hash,"B9",2,newSViv(jinfo.dwButtons & JOY_BUTTON9),0);
			hv_store(hash,"B10",3,newSViv(jinfo.dwButtons & JOY_BUTTON10),0);
			hv_store(hash,"B11",3,newSViv(jinfo.dwButtons & JOY_BUTTON11),0);
			hv_store(hash,"B12",3,newSViv(jinfo.dwButtons & JOY_BUTTON12),0);
			hv_store(hash,"B13",3,newSViv(jinfo.dwButtons & JOY_BUTTON13),0);
			hv_store(hash,"B14",3,newSViv(jinfo.dwButtons & JOY_BUTTON14),0);
			hv_store(hash,"B15",3,newSViv(jinfo.dwButtons & JOY_BUTTON15),0);
			hv_store(hash,"B16",3,newSViv(jinfo.dwButtons & JOY_BUTTON16),0);
			hv_store(hash,"B17",3,newSViv(jinfo.dwButtons & JOY_BUTTON17),0);
			hv_store(hash,"B18",3,newSViv(jinfo.dwButtons & JOY_BUTTON18),0);
			hv_store(hash,"B19",3,newSViv(jinfo.dwButtons & JOY_BUTTON19),0);
			hv_store(hash,"B20",3,newSViv(jinfo.dwButtons & JOY_BUTTON20),0);
			hv_store(hash,"B21",3,newSViv(jinfo.dwButtons & JOY_BUTTON21),0);
			hv_store(hash,"B22",3,newSViv(jinfo.dwButtons & JOY_BUTTON22),0);
			hv_store(hash,"B23",3,newSViv(jinfo.dwButtons & JOY_BUTTON23),0);
			hv_store(hash,"B24",3,newSViv(jinfo.dwButtons & JOY_BUTTON24),0);
			hv_store(hash,"B25",3,newSViv(jinfo.dwButtons & JOY_BUTTON25),0);
			hv_store(hash,"B26",3,newSViv(jinfo.dwButtons & JOY_BUTTON26),0);
			hv_store(hash,"B27",3,newSViv(jinfo.dwButtons & JOY_BUTTON27),0);
			hv_store(hash,"B28",3,newSViv(jinfo.dwButtons & JOY_BUTTON28),0);
			hv_store(hash,"B29",3,newSViv(jinfo.dwButtons & JOY_BUTTON29),0);
			hv_store(hash,"B30",3,newSViv(jinfo.dwButtons & JOY_BUTTON30),0);
			hv_store(hash,"B31",3,newSViv(jinfo.dwButtons & JOY_BUTTON31),0);
			hv_store(hash,"B32",3,newSViv(jinfo.dwButtons & JOY_BUTTON32),0);

			hv_store(hash,"POVCENTERED",12,newSViv(jinfo.dwPOV & JOY_POVFORWARD),0);
			hv_store(hash,"POVFORWARD",10,newSViv(jinfo.dwPOV & JOY_POVFORWARD),0);
			hv_store(hash,"POVRIGHT",8,newSViv(jinfo.dwPOV & JOY_POVRIGHT),0);
			hv_store(hash,"POVBACKWARD",11,newSViv(jinfo.dwPOV & JOY_POVBACKWARD),0);
			hv_store(hash,"POVLEFT",7,newSViv(jinfo.dwPOV & JOY_POVLEFT),0);

			JOY_error=ret;
			RETVAL = newRV_noinc((SV*)hash);
		}
		else
		{
			JOY_error=ret;
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL


SV*
GetDevCaps(uJoyID)
	 UINT uJoyID
	PREINIT:
		JOYCAPS pjc;
		MMRESULT ret;
		HV* hash;
	CODE:
		hash = newHV();
		if ((ret=joyGetDevCaps(uJoyID, &pjc, sizeof(pjc)))==JOYERR_NOERROR)
		{
			hv_store(hash,"Xmin",4,newSViv(pjc.wXmin),0);
			hv_store(hash,"Xmax",4,newSViv(pjc.wXmax),0);

			hv_store(hash,"Ymin",4,newSViv(pjc.wYmin),0);
			hv_store(hash,"Ymax",4,newSViv(pjc.wYmax),0);

			hv_store(hash,"Zmin",4,newSViv(pjc.wZmin),0);
			hv_store(hash,"Zmax",4,newSViv(pjc.wZmax),0);

			hv_store(hash,"Rmin",4,newSViv(pjc.wRmin),0);
			hv_store(hash,"Rmax",4,newSViv(pjc.wRmax),0);

			hv_store(hash,"Umin",4,newSViv(pjc.wUmin),0);
			hv_store(hash,"Umax",4,newSViv(pjc.wUmax),0);

			hv_store(hash,"Vmin",4,newSViv(pjc.wVmin),0);
			hv_store(hash,"Vmax",4,newSViv(pjc.wVmax),0);

			hv_store(hash,"NumButtons",10,newSViv(pjc.wNumButtons),0);
			hv_store(hash,"MaxButtons",10,newSViv(pjc.wMaxButtons),0);
			hv_store(hash,"MaxAxes",7,newSViv(pjc.wMaxAxes),0);
			hv_store(hash,"NumAxes",7,newSViv(pjc.wNumAxes),0);

			hv_store(hash,"PeriodMin",9,newSViv(pjc.wPeriodMin),0);
			hv_store(hash,"PeriodMax",9,newSViv(pjc.wPeriodMax),0);

			hv_store(hash,"hasZ",4,newSViv(pjc.wCaps & JOYCAPS_HASZ),0);
			hv_store(hash,"hasR",4,newSViv(pjc.wCaps & JOYCAPS_HASR),0);
			hv_store(hash,"hasU",4,newSViv(pjc.wCaps & JOYCAPS_HASU),0);
			hv_store(hash,"hasV",4,newSViv(pjc.wCaps & JOYCAPS_HASV),0);
			hv_store(hash,"hasPOV",6,newSViv(pjc.wCaps & JOYCAPS_HASPOV),0);
			hv_store(hash,"hasPOV4DIR",10,newSViv(pjc.wCaps & JOYCAPS_POV4DIR),0);
			hv_store(hash,"hasPOVCTS",9,newSViv(pjc.wCaps & JOYCAPS_POVCTS),0);

			hv_store(hash,"Name",4,newSVpv(pjc.szPname,0),0);

			hv_store(hash,"ManufacturerID",14,newSViv(pjc.wMid),0);
			hv_store(hash,"ProductID",9,newSViv(pjc.wPid),0);

			JOY_error=ret;
			RETVAL = newRV_noinc((SV*)hash);

		}
		else
		{
			JOY_error=ret;
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL


MMRESULT
GetError()
	CODE:
		RETVAL=JOY_error;
	OUTPUT:
		RETVAL



