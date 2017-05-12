	
// THE FOLLOWING FUNCTION IS COMPOSED BY conster.plx
static double
constant(char *namep, int len, int arg)
{

	if (((sizeof("STATE_SYSTEM_MIXED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_MIXED",sizeof("STATE_SYSTEM_MIXED")-1)) return (int)0x20;

	if (((sizeof("SELFLAG_TAKESELECTION")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_TAKESELECTION",sizeof("SELFLAG_TAKESELECTION")-1)) return (int)0x2;

	if (((sizeof("EVENT_CONSOLE_START_APPLICATION")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_START_APPLICATION",sizeof("EVENT_CONSOLE_START_APPLICATION")-1)) return (int)0x4006;

	if (((sizeof("ROLE_SYSTEM_CHART")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CHART",sizeof("ROLE_SYSTEM_CHART")-1)) return (int)0x11;

	if (((sizeof("ROLE_SYSTEM_CELL")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CELL",sizeof("ROLE_SYSTEM_CELL")-1)) return (int)0x1d;

	if (((sizeof("STATE_SYSTEM_SELECTABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_SELECTABLE",sizeof("STATE_SYSTEM_SELECTABLE")-1)) return (int)0x200000;

	if (((sizeof("SELFLAG_TAKEFOCUS")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_TAKEFOCUS",sizeof("SELFLAG_TAKEFOCUS")-1)) return (int)0x1;

	if (((sizeof("ROLE_SYSTEM_SEPARATOR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SEPARATOR",sizeof("ROLE_SYSTEM_SEPARATOR")-1)) return (int)0x15;

	if (((sizeof("OBJID_NATIVEOM")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_NATIVEOM",sizeof("OBJID_NATIVEOM")-1)) return (int)0xfffffff0;

	if (((sizeof("NAVDIR_NEXT")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_NEXT",sizeof("NAVDIR_NEXT")-1)) return (int)0x5;

	if (((sizeof("EVENT_OBJECT_SELECTIONADD")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_SELECTIONADD",sizeof("EVENT_OBJECT_SELECTIONADD")-1)) return (int)0x8007;

	if (((sizeof("ROLE_SYSTEM_SPINBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SPINBUTTON",sizeof("ROLE_SYSTEM_SPINBUTTON")-1)) return (int)0x34;

	if (((sizeof("SELFLAG_REMOVESELECTION")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_REMOVESELECTION",sizeof("SELFLAG_REMOVESELECTION")-1)) return (int)0x10;

	if (((sizeof("ROLE_SYSTEM_PAGETABLIST")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PAGETABLIST",sizeof("ROLE_SYSTEM_PAGETABLIST")-1)) return (int)0x3c;

	if (((sizeof("STATE_SYSTEM_FOCUSED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_FOCUSED",sizeof("STATE_SYSTEM_FOCUSED")-1)) return (int)0x4;

	if (((sizeof("EVENT_OBJECT_DESCRIPTIONCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_DESCRIPTIONCHANGE",sizeof("EVENT_OBJECT_DESCRIPTIONCHANGE")-1)) return (int)0x800d;

	if (((sizeof("EVENT_SYSTEM_SOUND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_SOUND",sizeof("EVENT_SYSTEM_SOUND")-1)) return (int)0x1;

	if (((sizeof("STATE_SYSTEM_PRESSED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_PRESSED",sizeof("STATE_SYSTEM_PRESSED")-1)) return (int)0x8;

	if (((sizeof("EVENT_SYSTEM_CAPTURESTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_CAPTURESTART",sizeof("EVENT_SYSTEM_CAPTURESTART")-1)) return (int)0x8;

	if (((sizeof("ROLE_SYSTEM_DIAL")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_DIAL",sizeof("ROLE_SYSTEM_DIAL")-1)) return (int)0x31;

	if (((sizeof("ROLE_SYSTEM_GROUPING")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_GROUPING",sizeof("ROLE_SYSTEM_GROUPING")-1)) return (int)0x14;

	if (((sizeof("EVENT_OBJECT_PARENTCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_PARENTCHANGE",sizeof("EVENT_OBJECT_PARENTCHANGE")-1)) return (int)0x800f;

	if (((sizeof("ROLE_SYSTEM_CARET")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CARET",sizeof("ROLE_SYSTEM_CARET")-1)) return (int)0x7;

	if (((sizeof("CHILDID_SELF")-1)==len) && !memcmp((void*)namep,(void*)"CHILDID_SELF",sizeof("CHILDID_SELF")-1)) return (int)0x0;

	if (((sizeof("STATE_SYSTEM_HASPOPUP")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_HASPOPUP",sizeof("STATE_SYSTEM_HASPOPUP")-1)) return (int)0x40000000;

	if (((sizeof("NAVDIR_MAX")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_MAX",sizeof("NAVDIR_MAX")-1)) return (int)0x9;

	if (((sizeof("ROLE_SYSTEM_GRAPHIC")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_GRAPHIC",sizeof("ROLE_SYSTEM_GRAPHIC")-1)) return (int)0x28;

	if (((sizeof("ROLE_SYSTEM_MENUBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_MENUBAR",sizeof("ROLE_SYSTEM_MENUBAR")-1)) return (int)0x2;

	if (((sizeof("ROLE_SYSTEM_COMBOBOX")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_COMBOBOX",sizeof("ROLE_SYSTEM_COMBOBOX")-1)) return (int)0x2e;

	if (((sizeof("SELFLAG_VALID")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_VALID",sizeof("SELFLAG_VALID")-1)) return (int)0x1f;

	if (((sizeof("ROLE_SYSTEM_EQUATION")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_EQUATION",sizeof("ROLE_SYSTEM_EQUATION")-1)) return (int)0x37;

	if (((sizeof("OBJID_HSCROLL")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_HSCROLL",sizeof("OBJID_HSCROLL")-1)) return (int)0xfffffffa;

	if (((sizeof("STATE_SYSTEM_SELECTED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_SELECTED",sizeof("STATE_SYSTEM_SELECTED")-1)) return (int)0x2;

	if (((sizeof("STATE_SYSTEM_TRAVERSED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_TRAVERSED",sizeof("STATE_SYSTEM_TRAVERSED")-1)) return (int)0x800000;

	if (((sizeof("ROLE_SYSTEM_GRIP")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_GRIP",sizeof("ROLE_SYSTEM_GRIP")-1)) return (int)0x4;

	if (((sizeof("EVENT_SYSTEM_MINIMIZEEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MINIMIZEEND",sizeof("EVENT_SYSTEM_MINIMIZEEND")-1)) return (int)0x17;

	if (((sizeof("STATE_SYSTEM_INDETERMINATE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_INDETERMINATE",sizeof("STATE_SYSTEM_INDETERMINATE")-1)) return (int)0x20;

	if (((sizeof("STATE_SYSTEM_MULTISELECTABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_MULTISELECTABLE",sizeof("STATE_SYSTEM_MULTISELECTABLE")-1)) return (int)0x1000000;

	if (((sizeof("ROLE_SYSTEM_ROWHEADER")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_ROWHEADER",sizeof("ROLE_SYSTEM_ROWHEADER")-1)) return (int)0x1a;

	if (((sizeof("ROLE_SYSTEM_OUTLINEBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_OUTLINEBUTTON",sizeof("ROLE_SYSTEM_OUTLINEBUTTON")-1)) return (int)0x40;

	if (((sizeof("EVENT_CONSOLE_END_APPLICATION")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_END_APPLICATION",sizeof("EVENT_CONSOLE_END_APPLICATION")-1)) return (int)0x4007;

	if (((sizeof("EVENT_OBJECT_DEFACTIONCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_DEFACTIONCHANGE",sizeof("EVENT_OBJECT_DEFACTIONCHANGE")-1)) return (int)0x8011;

	if (((sizeof("NAVDIR_DOWN")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_DOWN",sizeof("NAVDIR_DOWN")-1)) return (int)0x2;

	if (((sizeof("EVENT_SYSTEM_SWITCHEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_SWITCHEND",sizeof("EVENT_SYSTEM_SWITCHEND")-1)) return (int)0x15;

	if (((sizeof("OBJID_WINDOW")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_WINDOW",sizeof("OBJID_WINDOW")-1)) return (int)0x0;

	if (((sizeof("ROLE_SYSTEM_TITLEBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_TITLEBAR",sizeof("ROLE_SYSTEM_TITLEBAR")-1)) return (int)0x1;

	if (((sizeof("EVENT_OBJECT_HIDE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_HIDE",sizeof("EVENT_OBJECT_HIDE")-1)) return (int)0x8003;

	if (((sizeof("NAVDIR_MIN")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_MIN",sizeof("NAVDIR_MIN")-1)) return (int)0x0;

	if (((sizeof("ROLE_SYSTEM_CLOCK")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CLOCK",sizeof("ROLE_SYSTEM_CLOCK")-1)) return (int)0x3d;

	if (((sizeof("EVENT_OBJECT_DESTROY")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_DESTROY",sizeof("EVENT_OBJECT_DESTROY")-1)) return (int)0x8001;

	if (((sizeof("SELFLAG_ADDSELECTION")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_ADDSELECTION",sizeof("SELFLAG_ADDSELECTION")-1)) return (int)0x8;

	if (((sizeof("SELFLAG_EXTENDSELECTION")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_EXTENDSELECTION",sizeof("SELFLAG_EXTENDSELECTION")-1)) return (int)0x4;

	if (((sizeof("SM_CYSCREEN")-1)==len) && !memcmp((void*)namep,(void*)"SM_CYSCREEN",sizeof("SM_CYSCREEN")-1)) return (int)0x1;

	if (((sizeof("OBJID_CARET")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_CARET",sizeof("OBJID_CARET")-1)) return (int)0xfffffff8;

	if (((sizeof("NAVDIR_FIRSTCHILD")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_FIRSTCHILD",sizeof("NAVDIR_FIRSTCHILD")-1)) return (int)0x7;

	if (((sizeof("ROLE_SYSTEM_LINK")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_LINK",sizeof("ROLE_SYSTEM_LINK")-1)) return (int)0x1e;

	if (((sizeof("ROLE_SYSTEM_TOOLBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_TOOLBAR",sizeof("ROLE_SYSTEM_TOOLBAR")-1)) return (int)0x16;

	if (((sizeof("EVENT_OBJECT_SELECTIONWITHIN")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_SELECTIONWITHIN",sizeof("EVENT_OBJECT_SELECTIONWITHIN")-1)) return (int)0x8009;

	if (((sizeof("ROLE_SYSTEM_BUTTONDROPDOWNGRID")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_BUTTONDROPDOWNGRID",sizeof("ROLE_SYSTEM_BUTTONDROPDOWNGRID")-1)) return (int)0x3a;

	if (((sizeof("STATE_SYSTEM_MARQUEED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_MARQUEED",sizeof("STATE_SYSTEM_MARQUEED")-1)) return (int)0x2000;

	if (((sizeof("ROLE_SYSTEM_COLUMN")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_COLUMN",sizeof("ROLE_SYSTEM_COLUMN")-1)) return (int)0x1b;

	if (((sizeof("STATE_SYSTEM_LINKED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_LINKED",sizeof("STATE_SYSTEM_LINKED")-1)) return (int)0x400000;

	if (((sizeof("OBJID_CLIENT")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_CLIENT",sizeof("OBJID_CLIENT")-1)) return (int)0xfffffffc;

	if (((sizeof("ROLE_SYSTEM_SLIDER")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SLIDER",sizeof("ROLE_SYSTEM_SLIDER")-1)) return (int)0x33;

	if (((sizeof("EVENT_SYSTEM_MENUPOPUPSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MENUPOPUPSTART",sizeof("EVENT_SYSTEM_MENUPOPUPSTART")-1)) return (int)0x6;

	if (((sizeof("EVENT_SYSTEM_CAPTUREEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_CAPTUREEND",sizeof("EVENT_SYSTEM_CAPTUREEND")-1)) return (int)0x9;

	if (((sizeof("ROLE_SYSTEM_PAGETAB")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PAGETAB",sizeof("ROLE_SYSTEM_PAGETAB")-1)) return (int)0x25;

	if (((sizeof("ROLE_SYSTEM_WHITESPACE")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_WHITESPACE",sizeof("ROLE_SYSTEM_WHITESPACE")-1)) return (int)0x3b;

	if (((sizeof("EVENT_CONSOLE_UPDATE_SCROLL")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_UPDATE_SCROLL",sizeof("EVENT_CONSOLE_UPDATE_SCROLL")-1)) return (int)0x4004;

	if (((sizeof("ROLE_SYSTEM_LISTITEM")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_LISTITEM",sizeof("ROLE_SYSTEM_LISTITEM")-1)) return (int)0x22;

	if (((sizeof("EVENT_SYSTEM_DRAGDROPEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_DRAGDROPEND",sizeof("EVENT_SYSTEM_DRAGDROPEND")-1)) return (int)0xf;

	if (((sizeof("ROLE_SYSTEM_COLUMNHEADER")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_COLUMNHEADER",sizeof("ROLE_SYSTEM_COLUMNHEADER")-1)) return (int)0x19;

	if (((sizeof("EVENT_OBJECT_HELPCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_HELPCHANGE",sizeof("EVENT_OBJECT_HELPCHANGE")-1)) return (int)0x8010;

	if (((sizeof("STATE_SYSTEM_SIZEABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_SIZEABLE",sizeof("STATE_SYSTEM_SIZEABLE")-1)) return (int)0x20000;

	if (((sizeof("ROLE_SYSTEM_ALERT")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_ALERT",sizeof("ROLE_SYSTEM_ALERT")-1)) return (int)0x8;

	if (((sizeof("EVENT_OBJECT_NAMECHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_NAMECHANGE",sizeof("EVENT_OBJECT_NAMECHANGE")-1)) return (int)0x800c;

	if (((sizeof("STATE_SYSTEM_READONLY")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_READONLY",sizeof("STATE_SYSTEM_READONLY")-1)) return (int)0x40;

	if (((sizeof("STATE_SYSTEM_SELFVOICING")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_SELFVOICING",sizeof("STATE_SYSTEM_SELFVOICING")-1)) return (int)0x80000;

	if (((sizeof("EVENT_SYSTEM_MINIMIZESTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MINIMIZESTART",sizeof("EVENT_SYSTEM_MINIMIZESTART")-1)) return (int)0x16;

	if (((sizeof("EVENT_OBJECT_SELECTIONREMOVE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_SELECTIONREMOVE",sizeof("EVENT_OBJECT_SELECTIONREMOVE")-1)) return (int)0x8008;

	if (((sizeof("ROLE_SYSTEM_CHECKBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CHECKBUTTON",sizeof("ROLE_SYSTEM_CHECKBUTTON")-1)) return (int)0x2c;

	if (((sizeof("STATE_SYSTEM_OFFSCREEN")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_OFFSCREEN",sizeof("STATE_SYSTEM_OFFSCREEN")-1)) return (int)0x10000;

	if (((sizeof("OBJID_SYSMENU")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_SYSMENU",sizeof("OBJID_SYSMENU")-1)) return (int)0xffffffff;

	if (((sizeof("OBJID_ALERT")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_ALERT",sizeof("OBJID_ALERT")-1)) return (int)0xfffffff6;

	if (((sizeof("STATE_SYSTEM_CHECKED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_CHECKED",sizeof("STATE_SYSTEM_CHECKED")-1)) return (int)0x10;

	if (((sizeof("ROLE_SYSTEM_TEXT")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_TEXT",sizeof("ROLE_SYSTEM_TEXT")-1)) return (int)0x2a;

	if (((sizeof("SM_CXSCREEN")-1)==len) && !memcmp((void*)namep,(void*)"SM_CXSCREEN",sizeof("SM_CXSCREEN")-1)) return (int)0x0;

	if (((sizeof("STATE_SYSTEM_HOTTRACKED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_HOTTRACKED",sizeof("STATE_SYSTEM_HOTTRACKED")-1)) return (int)0x80;

	if (((sizeof("ROLE_SYSTEM_IPADDRESS")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_IPADDRESS",sizeof("ROLE_SYSTEM_IPADDRESS")-1)) return (int)0x3f;

	if (((sizeof("EVENT_SYSTEM_CONTEXTHELPSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_CONTEXTHELPSTART",sizeof("EVENT_SYSTEM_CONTEXTHELPSTART")-1)) return (int)0xc;

	if (((sizeof("ROLE_SYSTEM_RADIOBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_RADIOBUTTON",sizeof("ROLE_SYSTEM_RADIOBUTTON")-1)) return (int)0x2d;

	if (((sizeof("EVENT_SYSTEM_MOVESIZEEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MOVESIZEEND",sizeof("EVENT_SYSTEM_MOVESIZEEND")-1)) return (int)0xb;

	if (((sizeof("ROLE_SYSTEM_PROGRESSBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PROGRESSBAR",sizeof("ROLE_SYSTEM_PROGRESSBAR")-1)) return (int)0x30;

	if (((sizeof("STATE_SYSTEM_INVISIBLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_INVISIBLE",sizeof("STATE_SYSTEM_INVISIBLE")-1)) return (int)0x8000;

	if (((sizeof("STATE_SYSTEM_ANIMATED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_ANIMATED",sizeof("STATE_SYSTEM_ANIMATED")-1)) return (int)0x4000;

	if (((sizeof("EVENT_SYSTEM_DRAGDROPSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_DRAGDROPSTART",sizeof("EVENT_SYSTEM_DRAGDROPSTART")-1)) return (int)0xe;

	if (((sizeof("OBJID_SIZEGRIP")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_SIZEGRIP",sizeof("OBJID_SIZEGRIP")-1)) return (int)0xfffffff9;

	if (((sizeof("EVENT_SYSTEM_SWITCHSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_SWITCHSTART",sizeof("EVENT_SYSTEM_SWITCHSTART")-1)) return (int)0x14;

	if (((sizeof("EVENT_SYSTEM_MENUPOPUPEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MENUPOPUPEND",sizeof("EVENT_SYSTEM_MENUPOPUPEND")-1)) return (int)0x7;

	if (((sizeof("EVENT_CONSOLE_UPDATE_REGION")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_UPDATE_REGION",sizeof("EVENT_CONSOLE_UPDATE_REGION")-1)) return (int)0x4002;

	if (((sizeof("STATE_SYSTEM_UNAVAILABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_UNAVAILABLE",sizeof("STATE_SYSTEM_UNAVAILABLE")-1)) return (int)0x1;

	if (((sizeof("EVENT_OBJECT_CREATE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_CREATE",sizeof("EVENT_OBJECT_CREATE")-1)) return (int)0x8000;

	if (((sizeof("EVENT_OBJECT_REORDER")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_REORDER",sizeof("EVENT_OBJECT_REORDER")-1)) return (int)0x8004;

	if (((sizeof("EVENT_CONSOLE_CARET")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_CARET",sizeof("EVENT_CONSOLE_CARET")-1)) return (int)0x4001;

	if (((sizeof("ROLE_SYSTEM_SPLITBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SPLITBUTTON",sizeof("ROLE_SYSTEM_SPLITBUTTON")-1)) return (int)0x3e;

	if (((sizeof("EVENT_SYSTEM_FOREGROUND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_FOREGROUND",sizeof("EVENT_SYSTEM_FOREGROUND")-1)) return (int)0x3;

	if (((sizeof("ROLE_SYSTEM_MENUPOPUP")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_MENUPOPUP",sizeof("ROLE_SYSTEM_MENUPOPUP")-1)) return (int)0xb;

	if (((sizeof("ROLE_SYSTEM_BUTTONMENU")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_BUTTONMENU",sizeof("ROLE_SYSTEM_BUTTONMENU")-1)) return (int)0x39;

	if (((sizeof("EVENT_CONSOLE_LAYOUT")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_LAYOUT",sizeof("EVENT_CONSOLE_LAYOUT")-1)) return (int)0x4005;

	if (((sizeof("ROLE_SYSTEM_DIAGRAM")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_DIAGRAM",sizeof("ROLE_SYSTEM_DIAGRAM")-1)) return (int)0x35;

	if (((sizeof("EVENT_SYSTEM_DIALOGEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_DIALOGEND",sizeof("EVENT_SYSTEM_DIALOGEND")-1)) return (int)0x11;

	if (((sizeof("EVENT_OBJECT_STATECHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_STATECHANGE",sizeof("EVENT_OBJECT_STATECHANGE")-1)) return (int)0x800a;

	if (((sizeof("EVENT_SYSTEM_MENUEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MENUEND",sizeof("EVENT_SYSTEM_MENUEND")-1)) return (int)0x5;

	if (((sizeof("NAVDIR_PREVIOUS")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_PREVIOUS",sizeof("NAVDIR_PREVIOUS")-1)) return (int)0x6;

	if (((sizeof("ROLE_SYSTEM_BORDER")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_BORDER",sizeof("ROLE_SYSTEM_BORDER")-1)) return (int)0x13;

	if (((sizeof("ROLE_SYSTEM_TOOLTIP")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_TOOLTIP",sizeof("ROLE_SYSTEM_TOOLTIP")-1)) return (int)0xd;

	if (((sizeof("EVENT_OBJECT_VALUECHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_VALUECHANGE",sizeof("EVENT_OBJECT_VALUECHANGE")-1)) return (int)0x800e;

	if (((sizeof("ROLE_SYSTEM_CHARACTER")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CHARACTER",sizeof("ROLE_SYSTEM_CHARACTER")-1)) return (int)0x20;

	if (((sizeof("ROLE_SYSTEM_SCROLLBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SCROLLBAR",sizeof("ROLE_SYSTEM_SCROLLBAR")-1)) return (int)0x3;

	if (((sizeof("NAVDIR_LASTCHILD")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_LASTCHILD",sizeof("NAVDIR_LASTCHILD")-1)) return (int)0x8;

	if (((sizeof("EVENT_CONSOLE_UPDATE_SIMPLE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_CONSOLE_UPDATE_SIMPLE",sizeof("EVENT_CONSOLE_UPDATE_SIMPLE")-1)) return (int)0x4003;

	if (((sizeof("ROLE_SYSTEM_HELPBALLOON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_HELPBALLOON",sizeof("ROLE_SYSTEM_HELPBALLOON")-1)) return (int)0x1f;

	if (((sizeof("ROLE_SYSTEM_WINDOW")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_WINDOW",sizeof("ROLE_SYSTEM_WINDOW")-1)) return (int)0x9;

	if (((sizeof("ROLE_SYSTEM_PANE")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PANE",sizeof("ROLE_SYSTEM_PANE")-1)) return (int)0x10;

	if (((sizeof("STATE_SYSTEM_MOVEABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_MOVEABLE",sizeof("STATE_SYSTEM_MOVEABLE")-1)) return (int)0x40000;

	if (((sizeof("ROLE_SYSTEM_CLIENT")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CLIENT",sizeof("ROLE_SYSTEM_CLIENT")-1)) return (int)0xa;

	if (((sizeof("ROLE_SYSTEM_MENUITEM")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_MENUITEM",sizeof("ROLE_SYSTEM_MENUITEM")-1)) return (int)0xc;

	if (((sizeof("STATE_SYSTEM_FLOATING")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_FLOATING",sizeof("STATE_SYSTEM_FLOATING")-1)) return (int)0x1000;

	if (((sizeof("STATE_SYSTEM_COLLAPSED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_COLLAPSED",sizeof("STATE_SYSTEM_COLLAPSED")-1)) return (int)0x400;

	if (((sizeof("ROLE_SYSTEM_DROPLIST")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_DROPLIST",sizeof("ROLE_SYSTEM_DROPLIST")-1)) return (int)0x2f;

	if (((sizeof("EVENT_SYSTEM_SCROLLINGSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_SCROLLINGSTART",sizeof("EVENT_SYSTEM_SCROLLINGSTART")-1)) return (int)0x12;

	if (((sizeof("EVENT_SYSTEM_MENUSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MENUSTART",sizeof("EVENT_SYSTEM_MENUSTART")-1)) return (int)0x4;

	if (((sizeof("SELFLAG_NONE")-1)==len) && !memcmp((void*)namep,(void*)"SELFLAG_NONE",sizeof("SELFLAG_NONE")-1)) return (int)0x0;

	if (((sizeof("ROLE_SYSTEM_PROPERTYPAGE")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PROPERTYPAGE",sizeof("ROLE_SYSTEM_PROPERTYPAGE")-1)) return (int)0x26;

	if (((sizeof("ROLE_SYSTEM_DOCUMENT")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_DOCUMENT",sizeof("ROLE_SYSTEM_DOCUMENT")-1)) return (int)0xf;

	if (((sizeof("OBJID_VSCROLL")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_VSCROLL",sizeof("OBJID_VSCROLL")-1)) return (int)0xfffffffb;

	if (((sizeof("ROLE_SYSTEM_BUTTONDROPDOWN")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_BUTTONDROPDOWN",sizeof("ROLE_SYSTEM_BUTTONDROPDOWN")-1)) return (int)0x38;

	if (((sizeof("STATE_SYSTEM_BUSY")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_BUSY",sizeof("STATE_SYSTEM_BUSY")-1)) return (int)0x800;

	if (((sizeof("STATE_SYSTEM_ALERT_MEDIUM")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_ALERT_MEDIUM",sizeof("STATE_SYSTEM_ALERT_MEDIUM")-1)) return (int)0x8000000;

	if (((sizeof("CCHILDREN_FRAME")-1)==len) && !memcmp((void*)namep,(void*)"CCHILDREN_FRAME",sizeof("CCHILDREN_FRAME")-1)) return (int)0x7;

	if (((sizeof("STATE_SYSTEM_ALERT_HIGH")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_ALERT_HIGH",sizeof("STATE_SYSTEM_ALERT_HIGH")-1)) return (int)0x10000000;

	if (((sizeof("OBJID_TITLEBAR")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_TITLEBAR",sizeof("OBJID_TITLEBAR")-1)) return (int)0xfffffffe;

	if (((sizeof("ROLE_SYSTEM_ANIMATION")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_ANIMATION",sizeof("ROLE_SYSTEM_ANIMATION")-1)) return (int)0x36;

	if (((sizeof("NAVDIR_RIGHT")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_RIGHT",sizeof("NAVDIR_RIGHT")-1)) return (int)0x4;

	if (((sizeof("STATE_SYSTEM_EXTSELECTABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_EXTSELECTABLE",sizeof("STATE_SYSTEM_EXTSELECTABLE")-1)) return (int)0x2000000;

	if (((sizeof("STATE_SYSTEM_EXPANDED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_EXPANDED",sizeof("STATE_SYSTEM_EXPANDED")-1)) return (int)0x200;

	if (((sizeof("NAVDIR_UP")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_UP",sizeof("NAVDIR_UP")-1)) return (int)0x1;

	if (((sizeof("EVENT_SYSTEM_DIALOGSTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_DIALOGSTART",sizeof("EVENT_SYSTEM_DIALOGSTART")-1)) return (int)0x10;

	if (((sizeof("OBJID_SOUND")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_SOUND",sizeof("OBJID_SOUND")-1)) return (int)0xfffffff5;

	if (((sizeof("EVENT_SYSTEM_ALERT")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_ALERT",sizeof("EVENT_SYSTEM_ALERT")-1)) return (int)0x2;

	if (((sizeof("OBJID_CURSOR")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_CURSOR",sizeof("OBJID_CURSOR")-1)) return (int)0xfffffff7;

	if (((sizeof("ROLE_SYSTEM_CURSOR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_CURSOR",sizeof("ROLE_SYSTEM_CURSOR")-1)) return (int)0x6;

	if (((sizeof("STATE_SYSTEM_VALID")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_VALID",sizeof("STATE_SYSTEM_VALID")-1)) return (int)0x3fffffff;

	if (((sizeof("ROLE_SYSTEM_DIALOG")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_DIALOG",sizeof("ROLE_SYSTEM_DIALOG")-1)) return (int)0x12;

	if (((sizeof("EVENT_OBJECT_ACCELERATORCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_ACCELERATORCHANGE",sizeof("EVENT_OBJECT_ACCELERATORCHANGE")-1)) return (int)0x8012;

	if (((sizeof("EVENT_SYSTEM_MOVESIZESTART")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_MOVESIZESTART",sizeof("EVENT_SYSTEM_MOVESIZESTART")-1)) return (int)0xa;

	if (((sizeof("STATE_SYSTEM_FOCUSABLE")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_FOCUSABLE",sizeof("STATE_SYSTEM_FOCUSABLE")-1)) return (int)0x100000;

	if (((sizeof("STATE_SYSTEM_DEFAULT")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_DEFAULT",sizeof("STATE_SYSTEM_DEFAULT")-1)) return (int)0x100;

	if (((sizeof("ROLE_SYSTEM_TABLE")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_TABLE",sizeof("ROLE_SYSTEM_TABLE")-1)) return (int)0x18;

	if (((sizeof("ROLE_SYSTEM_STATICTEXT")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_STATICTEXT",sizeof("ROLE_SYSTEM_STATICTEXT")-1)) return (int)0x29;

	if (((sizeof("OBJID_MENU")-1)==len) && !memcmp((void*)namep,(void*)"OBJID_MENU",sizeof("OBJID_MENU")-1)) return (int)0xfffffffd;

	if (((sizeof("EVENT_SYSTEM_SCROLLINGEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_SCROLLINGEND",sizeof("EVENT_SYSTEM_SCROLLINGEND")-1)) return (int)0x13;

	if (((sizeof("NAVDIR_LEFT")-1)==len) && !memcmp((void*)namep,(void*)"NAVDIR_LEFT",sizeof("NAVDIR_LEFT")-1)) return (int)0x3;

	if (((sizeof("ROLE_SYSTEM_OUTLINEITEM")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_OUTLINEITEM",sizeof("ROLE_SYSTEM_OUTLINEITEM")-1)) return (int)0x24;

	if (((sizeof("ROLE_SYSTEM_PUSHBUTTON")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_PUSHBUTTON",sizeof("ROLE_SYSTEM_PUSHBUTTON")-1)) return (int)0x2b;

	if (((sizeof("ROLE_SYSTEM_ROW")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_ROW",sizeof("ROLE_SYSTEM_ROW")-1)) return (int)0x1c;

	if (((sizeof("STATE_SYSTEM_ALERT_LOW")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_ALERT_LOW",sizeof("STATE_SYSTEM_ALERT_LOW")-1)) return (int)0x4000000;

	if (((sizeof("ROLE_SYSTEM_STATUSBAR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_STATUSBAR",sizeof("ROLE_SYSTEM_STATUSBAR")-1)) return (int)0x17;

	if (((sizeof("ROLE_SYSTEM_APPLICATION")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_APPLICATION",sizeof("ROLE_SYSTEM_APPLICATION")-1)) return (int)0xe;

	if (((sizeof("ROLE_SYSTEM_LIST")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_LIST",sizeof("ROLE_SYSTEM_LIST")-1)) return (int)0x21;

	if (((sizeof("EVENT_OBJECT_FOCUS")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_FOCUS",sizeof("EVENT_OBJECT_FOCUS")-1)) return (int)0x8005;

	if (((sizeof("EVENT_OBJECT_SELECTION")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_SELECTION",sizeof("EVENT_OBJECT_SELECTION")-1)) return (int)0x8006;

	if (((sizeof("ROLE_SYSTEM_SOUND")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_SOUND",sizeof("ROLE_SYSTEM_SOUND")-1)) return (int)0x5;

	if (((sizeof("ROLE_SYSTEM_INDICATOR")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_INDICATOR",sizeof("ROLE_SYSTEM_INDICATOR")-1)) return (int)0x27;

	if (((sizeof("EVENT_OBJECT_SHOW")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_SHOW",sizeof("EVENT_OBJECT_SHOW")-1)) return (int)0x8002;

	if (((sizeof("EVENT_SYSTEM_CONTEXTHELPEND")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_SYSTEM_CONTEXTHELPEND",sizeof("EVENT_SYSTEM_CONTEXTHELPEND")-1)) return (int)0xd;

	if (((sizeof("EVENT_OBJECT_LOCATIONCHANGE")-1)==len) && !memcmp((void*)namep,(void*)"EVENT_OBJECT_LOCATIONCHANGE",sizeof("EVENT_OBJECT_LOCATIONCHANGE")-1)) return (int)0x800b;

	if (((sizeof("STATE_SYSTEM_PROTECTED")-1)==len) && !memcmp((void*)namep,(void*)"STATE_SYSTEM_PROTECTED",sizeof("STATE_SYSTEM_PROTECTED")-1)) return (int)0x20000000;

	if (((sizeof("ROLE_SYSTEM_HOTKEYFIELD")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_HOTKEYFIELD",sizeof("ROLE_SYSTEM_HOTKEYFIELD")-1)) return (int)0x32;

	if (((sizeof("ROLE_SYSTEM_OUTLINE")-1)==len) && !memcmp((void*)namep,(void*)"ROLE_SYSTEM_OUTLINE",sizeof("ROLE_SYSTEM_OUTLINE")-1)) return (int)0x23;

    errno = EINVAL;
    return 0;
}


