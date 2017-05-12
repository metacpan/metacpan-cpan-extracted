# Copyright 2001-2004, Phill Wolf.  See README. -*-Mode: c;-*-
# Win32::ActAcc (Active Accessibility) C-extension source file

void
getEventCount(h)
	INPUT:
	EventMonitor *h
    PREINIT:
    int ec = -1;
	PPCODE:
	if (!h->cons)
		croak("EventMonitor not active");
	SetLastError(0);
	ec = emGetCounter();
	if (ec != -1)
        XPUSHs(sv_2mortal(newSViv(ec)));

void
getEvent(h)
	INPUT:
	EventMonitor *h
	PREINIT:
	HWINEVENTHOOK hhook;
	PPCODE:
    SetLastError(0);
	if (!h->cons)
		croak("EventMonitor not active");
	hhook = h->cons->hhook;
	if (emLock())
	{
		int actual = 0;
		struct aaevt *pEventsInBuf = 0;
		for (;;) 
		{
			emGetEventPtr(h->readCursorQume, 1, &actual, &pEventsInBuf);
			if (!actual)
				break;
			h->readCursorQume += actual;
			if (hhook == pEventsInBuf->hWinEventHook)
				break;
		}
		if (actual) 
		{
			SV *perlevent = 0;
			HV *hvEventStash = 0;
			HV* hv = 0;
			hv = newHV();
			hv_store(hv, "event", sizeof("event")-1, 
                     newSViv(pEventsInBuf->event), 0);
			hv_store(hv, "hwnd", sizeof("hwnd")-1, 
                     newSViv((long) pEventsInBuf->hwnd), 0);
			hv_store(hv, "idObject", sizeof("idObject")-1, 
                     newSViv(pEventsInBuf->idObject), 0);
			hv_store(hv, "idChild", sizeof("idChild")-1, 
                     newSViv(pEventsInBuf->idChild), 0);
			hv_store(hv, "dwmsEventTime", sizeof("dwmsEventTime")-1, 
                     newSViv(pEventsInBuf->dwmsEventTime), 0);
			hv_store(hv, "hWinEventHook", sizeof("hWinEventHook")-1, 
                     newSViv((unsigned long)pEventsInBuf->hWinEventHook), 0);

			perlevent = newRV_noinc((SV*) hv);
			hvEventStash = gv_stashpv("Win32::ActAcc::Event", 0);
			sv_bless(perlevent, hvEventStash);

			XPUSHs(perlevent);
		}
		emUnlock();
	}

void
dropHistory(h, msHistoryToKeep)
	INPUT:
	EventMonitor *h
        int msHistoryToKeep
	PREINIT:
	HWINEVENTHOOK hhook;
        unsigned int crntTime;
        unsigned int cutoffTime;
	PPCODE:
    SetLastError(0);
        crntTime = GetTickCount();
        cutoffTime = crntTime - msHistoryToKeep;
	if (!h->cons)
		croak("EventMonitor not active");
	hhook = h->cons->hhook;
	if (emLock())
	{
		int actual = 0;
		struct aaevt *pEventsInBuf = 0;
		for (;;) 
		{
			emGetEventPtr(h->readCursorQume, 1, &actual, &pEventsInBuf);
			if (!actual)
				break;
            if (pEventsInBuf->dwmsEventTime >= cutoffTime)
                break; // BEFORE incrementing counter
			h->readCursorQume += actual;
			if (hhook == pEventsInBuf->hWinEventHook)
				break;
		}
		emUnlock();
        XPUSHs(&PL_sv_yes);
	}

void
clear(h)
	INPUT:
	EventMonitor *h
	PPCODE:
    SetLastError(0);
	if (!h->cons)
		croak("EventMonitor not active");
	EventMonitor_synch(h);
    if (!GetLastError()) 
        XPUSHs(&PL_sv_yes);


void
DESTROY(h)
	INPUT:
	EventMonitor *h
	CODE:
	EventMonitor_deactivate(h);
	Safefree(h);

void
synch(hThis,hOther)
	INPUT:
	EventMonitor *hThis
	EventMonitor *hOther
	PPCODE:
    SetLastError(0);
	if (!hThis->cons)
		croak("EventMonitor not active");
	if (!hOther->cons)
		croak("EventMonitor not active");
	hThis->readCursorQume = hOther->readCursorQume;
    XPUSHs(&PL_sv_yes);

int
isActive(h)
	INPUT:
	EventMonitor *h
	CODE:
	RETVAL = !!(h->cons);
	OUTPUT:
	RETVAL

void
activate(h, a)
	INPUT:
	EventMonitor *h
	int a
	PPCODE:
    SetLastError(0);
	if (a && !h->cons)
	{
		EventMonitor_activate(h);
        if (!GetLastError())
          EventMonitor_synch(h);
	}
	else if (!a && h->cons)
	{
		EventMonitor_deactivate(h);
	}
    if (!GetLastError()) 
        XPUSHs(&PL_sv_yes);
