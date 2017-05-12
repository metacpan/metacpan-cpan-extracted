# Copyright 2001-2004, Phill Wolf.  See README. -*-Mode: fundamental;-*-
# Win32::ActAcc (Active Accessibility) C-extension source file

int
Equals(a,b)
	INPUT:
	ActAcc * a
	ActAcc * b
	CODE:
    SetLastError(0);
	RETVAL = !!((a->ia == b->ia) && (a->id == b->id));
	if (!RETVAL && a->id==CHILDID_SELF && b->id==CHILDID_SELF)
	{
		HRESULT hr;
		HWND ha, hb;
		hr = WindowFromAccessibleObject(a->ia, &ha);
		if (SUCCEEDED(hr))
		{
			hr = WindowFromAccessibleObject(b->ia, &hb);
			if (SUCCEEDED(hr))
            {
                SetLastError(0);
				RETVAL = 2*!!(ha == hb);
            }
            else
            {
                WARN_ABOUT_WINERROR();
            }
		}
        else
        {
            WARN_ABOUT_WINERROR();
        }
	}
	OUTPUT:
	RETVAL

void
Release(p)
	INPUT:
	ActAcc * p
	CODE:
    SetLastError(0);
	if (p->ia) // idempotent
	{
		IAccessible_Release(p->ia);
		p->ia = 0;
	}

void
DESTROY(p)
	INPUT:
	ActAcc * p
	CODE:
	ActAcc_free_incl_hash(p);

# testable('get_accRole')
# in: AO
# out: role (number)
void
get_accRole(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(uintAccessor(p, p->ia->lpVtbl->get_accRole, __FUNCTION__));

void
get_accState(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(uintAccessor(p, p->ia->lpVtbl->get_accState, __FUNCTION__));

# testable('get_accName')
# in: AO
# out: name (string)
void
get_accName(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accName, __FUNCTION__));

# testable('WindowFromAccessibleObject')
# in: AO
# out: HWND
# error_conditions: undef if AO represents a child-ID, or error is reported by AA
void
WindowFromAccessibleObject(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	HWND hwnd = 0;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	if (p->id == CHILDID_SELF)
	{
		hr = WindowFromAccessibleObject(p->ia, &hwnd);
		if (S_OK == hr)
        {
          XPUSHs(sv_2mortal(newSVuv((unsigned)hwnd)));
          SetLastError(0);
        }
        else
        {
            WARN_ABOUT_WINERROR();
        }
	}

# testable('get_accValue')
char *
get_accValue(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accValue, __FUNCTION__));

char *
get_accDescription(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accDescription, __FUNCTION__));

char *
get_accHelp(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accHelp, __FUNCTION__));

char *
get_accDefaultAction(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accDefaultAction, __FUNCTION__));

char *
get_accKeyboardShortcut(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accKeyboardShortcut, __FUNCTION__));

void
get_accChildCount(p)
	INPUT:
	ActAcc * p
	PREINIT:
	long cch = 0;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	if (CHILDID_SELF == p->id) 
		cch = getAccChildCount(p->ia);
    if (cch != -1)
        XPUSHs(sv_2mortal(newSViv(cch)));

void
get_accChild(p, id)
	INPUT:
	ActAcc * p
	int	id
	PREINIT:
	HRESULT hr = S_OK;
	IDispatch *pDispatch = 0;
    ActAcc *pActAcc = 0;
	VARIANT vch;
	PPCODE:
	croakIfNullIAccessible(p);
    SetLastError(0);
	if (CHILDID_SELF == p->id) 
    {
    	VariantInit_VT_I4(&vch, id);
    	hr = IAccessible_get_accChild(p->ia, vch, &pDispatch);
    	if (S_OK == hr)
    		pActAcc = ActAcc_from_IDispatch(pDispatch);
    	else if (S_FALSE == hr)
    		pActAcc = ActAcc_from_IAccessible(p->ia, id);
        else
        {
            WARN_ABOUT_WINERROR();
        }
        if (pActAcc)
        {
        	XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(pActAcc), pActAcc));
            SetLastError(0);
        }

    	if (pDispatch) IDispatch_Release(pDispatch);
    }

# testable('AccessibleChildren.all')
# testable('AccessibleChildren.default')
# in: AO, optional: state-bits, state-bit-values, optional: maximum entries in returned list
# out: list of AO
void
AccessibleChildren(p, ...)
	INPUT:
	ActAcc * p
	PREINIT:
	VARIANT childIdSelf;
	HRESULT hrAC = S_OK;
	long nChildrenDescribed = 0;
	long nChildren = 0;
	VARIANT *varCh = 0;
	int i;
	ActAcc *aa = 0;
	// By default, find only all visible windows: where STATE_SYSTEM_INVISIBLE is not set.
	int sigStateBits = STATE_SYSTEM_INVISIBLE|STATE_SYSTEM_OFFSCREEN;
	int cmpStateBits = 0;
	int max = -1;
	PPCODE:
    SetLastError(0);
	if (items > 2)
	{
		sigStateBits = SvIV(ST(1));
		cmpStateBits = SvIV(ST(2)); 
	}
	if (items > 3)
	{
		max = SvIV(ST(3));
	}
	croakIfNullIAccessible(p);
	if (CHILDID_SELF == p->id) 
	{
		VariantInit_VT_I4(&childIdSelf, CHILDID_SELF);
		nChildren = (max<1)? getAccChildCount(p->ia) : max; 

		New(7, varCh, nChildren, VARIANT); 
		for (i = 0; i < nChildren; i++)
		{
			VariantInit(&varCh[i]);
			varCh[i].vt = VT_DISPATCH;
		}
		hrAC = AccessibleChildren(p->ia, 0, nChildren, varCh, &nChildrenDescribed);
		// Note: S_FALSE is documented as a potential problem sign,
		// but it occurs pretty often so probably is not exceptional
		if (SUCCEEDED(hrAC))
		{
			for (i = 0; i < nChildrenDescribed; i++)
			{
				aa = 0;

				// Find or make Accessible Object
				if(VT_DISPATCH == varCh[i].vt)
				{
					aa = ActAcc_from_IDispatch(varCh[i].pdispVal);
				}
				else if (VT_I4 == varCh[i].vt)
				{
					aa = ActAcc_from_IAccessible(p->ia, varCh[i].lVal);
				}

				// Eliminate Accessible Object if it fails the test
				if ((sigStateBits != 0) && aa)
				{
					VARIANT vs;
					VARIANT idChild;
					int isOk = 0;
					HRESULT hr = S_OK;
					VariantInit(&vs);
					VariantInit_VT_I4(&idChild, aa->id);
					hr = IAccessible_get_accState(aa->ia, idChild, &vs);
                    if (S_OK != hr)
                    {
                        WARN_ABOUT_WINERROR();
                    }
					if ((S_OK == hr) && (VT_I4 == vs.vt))
					{
						long L = vs.lVal;
						if ((L & sigStateBits) == cmpStateBits)
						{
							isOk = 1;
						}
					}
					if (!isOk)
					{
						ActAcc_free_incl_hash(aa);
						aa = 0;
					}
				}
				
				// Add Accessible Object to the return list
				if (aa)
					XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));

				VariantClear(&varCh[i]);
			}
            SetLastError(0);
		}
        else
        {
            WARN_ABOUT_WINERROR();
        }
        Safefree(varCh);
	}

# testable('get_accParent.window')
# testable('get_accParent.desktop')
# testable('get_accParent.child_id')
# EITHER:
# in: AO that has CHILDID_SELF
# out: AO that the in:AO reports as its parent
# OR:
# in: AO that has a child ID
# out: AO that has the same IAccessible but CHILDID_SELF
# --
# error_conditions: undef
void
get_accParent(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	if (CHILDID_SELF != p->id) 
	{
		ActAcc *aa = ActAcc_from_IAccessible(p->ia, CHILDID_SELF);
		XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
	}
	else
	{
		IDispatch *pDispatch = 0;
		hr = IAccessible_get_accParent(p->ia, &pDispatch);
		if (S_OK == hr)
		{
			ActAcc *aa = ActAcc_from_IDispatch(pDispatch);
            if (aa)
            {
			    XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
                SetLastError(0);
            }
			IDispatch_Release(pDispatch);
		}
        else
        {
            WARN_ABOUT_WINERROR();
        }
	}

void
get_accFocus(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	VARIANT v;//IDispatch *pDispatch = 0;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	VariantInit(&v);
	if (CHILDID_SELF == p->id) 
	{
		hr = IAccessible_get_accFocus(p->ia, &v);
		if (S_OK == hr)
		{
			if (VT_DISPATCH == v.vt)
			{
				ActAcc *aa = ActAcc_from_IDispatch(v.pdispVal);
                if (aa)
				    XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
			}
			else if (VT_I4 == v.vt)
			{
				ActAcc *aa = ActAcc_from_IAccessible(p->ia, v.lVal);
                if (aa)
                {
				    XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
                    SetLastError(0);
                }
			}
		}
        else if (DISP_E_MEMBERNOTFOUND != hr)
        {
            WARN_ABOUT_WINERROR();
        }
	}
	VariantClear(&v);

void
accDoDefaultAction_(p)
	INPUT:
	ActAcc * p
	PREINIT:
	VARIANT childId;
	HRESULT hrAC = S_OK;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hrAC = IAccessible_accDoDefaultAction(p->ia, childId);
    if (SUCCEEDED(hrAC))
    {
        XPUSHs(&PL_sv_yes);
        SetLastError(0);
    }
    else if (DISP_E_MEMBERNOTFOUND == hrAC)
        SetLastError(0);
    else
    {
        WARN_ABOUT_WINERROR();
    }

int
get_itemID(p)
	INPUT:
	ActAcc * p
	CODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	RETVAL = p->id;
	OUTPUT:
	RETVAL

# testable('accSelect')
void
accSelect(p, flags)
	INPUT:
	ActAcc * p
	long flags
	PREINIT:
	VARIANT childId;
	HRESULT hrAC = S_OK;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hrAC = IAccessible_accSelect(p->ia, flags, childId);
    if (SUCCEEDED(hrAC))
    {
        XPUSHs(&PL_sv_yes);
        SetLastError(0);
    }
    else if (DISP_E_MEMBERNOTFOUND==hrAC)
        SetLastError(0);
    else
    {
        WARN_ABOUT_WINERROR();
    }

void
accLocation(p)
	INPUT:
	ActAcc * p
	PREINIT:
	long left, top, width, height;
	VARIANT childId;
	HRESULT hr;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hr = IAccessible_accLocation(p->ia, &left, &top, &width, &height, childId);
	if (SUCCEEDED(hr))
	{
		XPUSHs(sv_2mortal(newSViv(left)));
		XPUSHs(sv_2mortal(newSViv(top)));
		XPUSHs(sv_2mortal(newSViv(width)));
		XPUSHs(sv_2mortal(newSViv(height)));
        SetLastError(0);
	}
    else if (DISP_E_MEMBERNOTFOUND == hr)
        SetLastError(0);
    else
    {
        WARN_ABOUT_WINERROR();
    }

# testable('accNavigate')
void
accNavigate(p, navDir)
	INPUT:
	ActAcc * p
	long navDir
	PREINIT:
	VARIANT varStart;
	VARIANT varEnd;
	HRESULT hr;
	ActAcc *rv = 0;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&varStart, p->id);
	hr = IAccessible_accNavigate(p->ia, navDir, varStart, &varEnd);
    if (!SUCCEEDED(hr) && (DISP_E_MEMBERNOTFOUND != hr))
    {
        SetLastError(hr);
        WARN_ABOUT_WINERROR();
    }
    else
        SetLastError(0);
	if (S_OK==hr)
	{
		if (VT_DISPATCH == varEnd.vt)
			rv = ActAcc_from_IDispatch(varEnd.pdispVal);
		else if (VT_I4 == varEnd.vt)
			rv = ActAcc_from_IAccessible(p->ia, varEnd.lVal);
    	if (rv)
        {
		    XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(rv), rv));
            SetLastError(0);
        }
	}
	VariantClear(&varEnd);

# testable('baggage')
# in: AO
# out: HASH ref
# side_effect: allocates new hash if this AO didn't already have one
void
baggage_get(p)
	INPUT:
	ActAcc * p
	PPCODE:
    SetLastError(0);
	if (p->bag)
      XPUSHs( baggage_return(p) );

void
baggage_put(p,v)
	INPUT:
	ActAcc * p
    SV *v
	PPCODE:
    SetLastError(0);
    baggage_free(p);
    baggage_alloc(p, v);

# in: AO
# out: IDispatch as 'unsigned' number (useless?)
# error_conditions: undef
void
get_nativeOM(p)
	INPUT:
	ActAcc * p
	PREINIT:
	int	id = OBJID_NATIVEOM;
	HRESULT hr = S_OK;
	IDispatch *pUnk = 0;
	VARIANT vch;
	PPCODE:
    SetLastError(0);
	croakIfNullIAccessible(p);
	if (CHILDID_SELF == p->id) 
	{
		VariantInit_VT_I4(&vch, id);
		hr = IAccessible_get_accChild(p->ia, vch, &pUnk);
        if (SUCCEEDED(hr))
           SetLastError(0);
        else
        {
            WARN_ABOUT_WINERROR();
        }
		if (S_OK == hr)
			XPUSHs(sv_2mortal(newSVuv((unsigned)pUnk)));
		if (pUnk) IUnknown_Release(pUnk);
	}

# testable('get_accSelection.1')
# testable('get_accSelection.multiple')
void
get_accSelection(p)
    INPUT:
    ActAcc * p
    PREINIT:
    VARIANT v1;
    HRESULT hr = S_OK;
    ActAcc * r;
    IEnumVARIANT *iev=0;
    long fetched=0;
    PPCODE:
    SetLastError(0);
    VariantInit(&v1);
	croakIfNullIAccessible(p);
    hr = IAccessible_get_accSelection(p->ia, &v1);
    if (SUCCEEDED(hr) || DISP_E_MEMBERNOTFOUND==hr)
        SetLastError(0);
    else
    {
        WARN_ABOUT_WINERROR();
    }
    if (S_OK == hr)
    {
    // four success cases:
    //  VT_EMPTY - no selected children
    //  VT_DISPATCH - one selected child, in pdispVal.
    //  VT_I4 - one selected child, whose id is in lVal; may be CHILDID_SELF.
    //  VT_UNKNOWN - get list from IEnumVARIANT in punkVal.
        // spec doesn't say what's in the enum'd variants...
        // we allow for I4, Dispatch, and Unknown(if IAccessible).
    switch (v1.vt)
    {
    case VT_EMPTY:
        break;
    case VT_DISPATCH:
    case VT_I4:
        if (ActAcc_from_VARIANT(p, &v1, &r))
        {
            XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(r), r));
            SetLastError(0);
        }
        VariantClear(&v1);
        break;
    case VT_UNKNOWN:
    	hr = IUnknown_QueryInterface(v1.punkVal, USEGUID(IID_IEnumVARIANT), (void**)&iev);
        if (E_NOINTERFACE == hr)
          SetLastError(hr);
        VariantClear(&v1);
        if (SUCCEEDED(hr))
        {
        SetLastError(0);
        for (;;)
        {
            hr = IEnumVARIANT_Next(iev, 1, &v1, &fetched);
            if (S_FALSE == hr || 0==fetched)
                break;
            if (S_OK != hr)
            {
                break;
            }
            if (ActAcc_from_VARIANT(p, &v1, &r))
            {
                XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(r), r));
            }
        }
        IEnumVARIANT_Release(iev);
        }
        else
        {
            WARN_ABOUT_WINERROR();
        }
    }
    }
