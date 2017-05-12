# Copyright 2001-2004, Phill Wolf.  See README. -*-Mode: fundamental;-*-
# Win32::ActAcc (Active Accessibility) C-extension source file

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

char *
GetOleaccVersionInfo()
    PREINIT:
    WORD w[4];
    char dddd[50];
    CODE:
    SetLastError(0);
    GetOleaccVersionInfo((DWORD*)&w[0], (DWORD*)&w[2]);
    wsprintf(dddd, "%d.%d.%d.%d", w[1], w[0], w[3], w[2]);
    RETVAL = dddd; 
    OUTPUT:
    RETVAL

HWND
GetDesktopWindow()
	CODE:
    SetLastError(0);
	RETVAL = GetDesktopWindow();
	OUTPUT:
	RETVAL

void
mouse_button(x,y, ops)
	int x
	int y
	char *ops
	CODE:
    SetLastError(0);
	mouse_button(x, y, ops);

void
AccessibleObjectFromEvent(hwnd, objectId, childId)
	INPUT:
	HWND	hwnd
	int	objectId
	int	childId
	PREINIT:
	HRESULT hr = S_OK;
	IAccessible *pAccessible = 0;
	ActAcc *pActAcc = 0;
	VARIANT varChild;
	PPCODE:
    SetLastError(0);
	VariantInit(&varChild);
	hr = AccessibleObjectFromEvent(hwnd, 
                            objectId, 
                            childId, 
                            &pAccessible, 
                            &varChild);
    if (SUCCEEDED(hr))
    {
        if (VT_I4 != varChild.vt) 
        {
            SetLastError(ERROR_WRONG_DISK);
        }
        else
        {
    	    pActAcc = ActAcc_from_IAccessible(pAccessible, varChild.lVal);
            if (pActAcc)
            {   
    	        XPUSHs(sv_setref_pv(sv_newmortal(), 
                    packageForAO(pActAcc), pActAcc));
                SetLastError(0);
            }
        }
   	    IAccessible_Release(pAccessible);
    }
    else
    {
        SetLastError(hr);
        WARN_ABOUT_WINERROR();
    }

# testable('AccessibleObjectFromWindow')
void
AccessibleObjectFromWindow(hwnd, ...)
	INPUT:
	HWND	hwnd
	PREINIT:
	I32	objectId = CHILDID_SELF;
	HRESULT hr = S_OK;
	IAccessible *pAccessible = 0;
	ActAcc *pActAcc = 0;
	PPCODE:
    SetLastError(0);
	if (items > 1)
		objectId = SvIV(ST(1));
	if (!IsWindow(hwnd)) 
        SetLastError(OLE_E_INVALIDHWND);
    else
    {
	    hr = AccessibleObjectFromWindow(hwnd, 
            objectId, USEGUID(IID_IAccessible), (void**)&pAccessible);
	    if (S_OK == hr)
        {
        	pActAcc = ActAcc_from_IAccessible(pAccessible, objectId);
            if (pActAcc)
            {
    	        XPUSHs(sv_setref_pv(sv_newmortal(), 
                        packageForAO(pActAcc), pActAcc));
                SetLastError(0);
            }
	        IAccessible_Release(pAccessible);
        }
        else
        {
            WARN_ABOUT_WINERROR();
        }
    }

void
AccessibleObjectFromPoint(x, y)
	INPUT:
	long x
	long y
	PREINIT:
	VARIANT childId;
	HRESULT hr;
	POINT point;
	IAccessible *ia = 0;
	ActAcc *pActAcc = 0;
	PPCODE:
    SetLastError(0);
	VariantInit(&childId);
	point.x = x;
	point.y = y;
	hr = AccessibleObjectFromPoint(point, &ia, &childId);
    if (SUCCEEDED(hr))
    {
	    pActAcc = ActAcc_from_IAccessible(ia, childId.lVal);
	    IAccessible_Release(ia);
	    if (pActAcc)
        {
            XPUSHs(sv_setref_pv(sv_newmortal(), 
                    packageForAO(pActAcc), pActAcc));
            SetLastError(0);
        }
    }
    else
    {
        WARN_ABOUT_WINERROR();
    }

char *
GetRoleText(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	char w[100];
	CODE:
    SetLastError(0);
	ZeroMemory(w, sizeof(w));
	if (GetRoleText(i, w, sizeof(w)-1))
    {
    	RETVAL = w;
        SetLastError(0);
    }
    else
    {
        WARN_ABOUT_WINERROR();
        RETVAL = NULL;
    }
	OUTPUT:
	RETVAL

char *
GetRolePackage(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	CODE:
    SetLastError(0);
	RETVAL = packageForRole(i);
	OUTPUT:
	RETVAL

# testable('GetStateText')
# in: state number
# out: string
# error_conditions: croak
char *
GetStateText(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	char w[40];
	CODE:
    SetLastError(0);
	ZeroMemory(w, sizeof(w));
	if (GetStateText(i, w, sizeof(w)-1))
    {
        SetLastError(0);
    	RETVAL = w;
    }
    else
    {
        WARN_ABOUT_WINERROR();
        RETVAL = NULL;
    }
	OUTPUT:
	RETVAL

EventMonitor *
events_register(active)
	INPUT:
	int active
	PREINIT:
	CODE:
    SetLastError(0);
	RETVAL = EventMonitor_new();
	if (active)
	{
		EventMonitor_activate(RETVAL);
        if (!GetLastError())
		    EventMonitor_synch(RETVAL);
        if (GetLastError())
            RETVAL = NULL;
	}
	OUTPUT:
	RETVAL

int 
GetSystemMetrics(mnum)
	INPUT:
    int mnum
	CODE:
    SetLastError(0);
    RETVAL = GetSystemMetrics(mnum);
	OUTPUT:
	RETVAL

long
GetDoubleClickTime()
    CODE:
    SetLastError(0);
    RETVAL = GetDoubleClickTime();
    OUTPUT:
    RETVAL

SV*
GetDesktopName()
    CODE:
    SetLastError(0);
    RETVAL = getDesktopName_();
    OUTPUT:
    RETVAL

SV*
GetInputDesktopName()
    CODE:
    SetLastError(0);
    RETVAL = getInputDesktopName_();
    OUTPUT:
    RETVAL

void
ErrPlay(b, e)
    INPUT:
    unsigned int b
    unsigned int e
    PREINIT:
    SV *sv;
    PPCODE:
    // Set the value of global $f
    sv = get_sv("f", TRUE);
    sv_setuv(sv, 5);
    SvIOK_only_UV(sv);
    // Set the value of $^E
    SetLastError(0x800401f0);
    // Set $!
    sv = get_sv("!", TRUE);
    //SvPOK(sv);
    //SvIOK(sv);
    sv_setiv(sv, 2);
    //sv_setpv(sv, "penguin error");
    SvPOK_off(sv);
    //SvIOK_on(sv);
    //SvNOK_off(sv);
    //SvROK_off(sv);

