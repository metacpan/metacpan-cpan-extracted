/* R_* macros, for Win32::GuiTest
 * S Liddicott 2008
 * Licensed under the same terms as Win32::GuiTest
 *
 * I wrote these based on pauld3's May 2006 patch for Win32::GuiTest impementing GetLVItem.
 * Later Win32::GuiTest use HookWindowsProcEx but because I couldn't get windows hooking to work.
 * on my cygwin installation, I'm using this technique to query some windows controls
 *
 * NOTES:
 *   See R_ListView_SetItemState below, based on the windows macro ListView_SetItemState
 * first R_DECL is used to declare a remote version of the local struct
 * then aftr all other variable declarations, R_OPEN(hWnd) is used to declare process
 * handle variables and open the remote process.
 * then R_PUT can be used to copy the local variable into the remote buffer, or,
 * if you need to pass the address of the remote buffer you can use R_USE(var)
 * which will make sure the remote buffer is allocated and return it's address.
 * after the sendmessage you can use R_GET to copy back the remote buffer and free it
 * or just use R_FREE.
 * Finally, you must call R_CLOSE
 */


#define R_ListView_SetItemState(w,i,d,m) \
{ \
        LV_ITEM _lvi;\
	R_DECL(_lvi); \
        _lvi.stateMask=m;\
        _lvi.state=d;\
	\
	R_OPEN(w); \
	R_PUT(_lvi); \
        DWORD result = SNDMSG((w),LVM_SETITEMSTATE,i,(LPARAM)R_VAR(_lvi));\
	R_GET(_lvi); \
	R_CLOSE; \
	result; \
}

#define R_ListView_GetItemText(w,i,iS,s,n) \
{ \
	LV_ITEM _lvi;\
	R_DECL(_lvi); \
	R_DECL_PTR(s, n); \
	R_OPEN(w); \
	_lvi.iSubItem=iS;\
	_lvi.cchTextMax=n;\
	_lvi.pszText=(char*)R_USE(s);\
	R_PUT(_lvi); \
	DWORD result = SNDMSG((w),LVM_GETITEMTEXT,i,(LPARAM)(LV_ITEM*)R_VAR(_lvi));\
	R_FREE(_lvi); \
	R_GET(s); \
	R_CLOSE; \
	result; \
}

/* Declares variables and opens needed handles. R_CLOSE must also be used
 * invoke R_OPEN at the end of other variable declarations including after
 * R_DECL, but before other R_ macros */
#define R_OPEN(hWnd) \
	DWORD _R_pid = 0; \
	HANDLE _R_hProcHnd = 0; \
	GetWindowThreadProcessId( hWnd, &_R_pid ); \
	_R_hProcHnd = OpenProcess( PROCESS_ALL_ACCESS, FALSE, _R_pid); \

#define R_CLOSE \
	CloseHandle(_R_hProcHnd);

/* Declare remote variables pointer */
#define R_DECL(var) \
	R_DECL_PTR(var, sizeof(var))

#define R_DECL_PTR(var, size) \
	SIZE_T copied##var= 0; \
	LPVOID R_VAR(var) = NULL; \
	DWORD R_VAR_SIZE(var) = size;

/* compute name of var containing size */
#define R_VAR_SIZE(var) _R_##var##_size

/* compute remote var name */
#define R_VAR(var) _R_##var

/* allocate remote var buffer if not already allocated */
#define R_USE(var) (R_VAR(var)?R_VAR(var):(R_ALLOC(var, R_VAR_SIZE(var))))

/* Alloc buffer without sizeof */
#define R_ALLOC(var, size) (R_VAR(var)=VirtualAllocEx(_R_hProcHnd, NULL, (size), MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE))

/* copy var to remote buffer, allocating if needed */
#define R_PUT(var) \
	WriteProcessMemory(_R_hProcHnd, R_USE(var), (LPVOID)&(var), R_VAR_SIZE(var), &copied##var );

/* fetch remote copy back, freeing remote buffer */
#define R_GET(var) \
	ReadProcessMemory(_R_hProcHnd, R_VAR(var), (LPVOID)&(var), R_VAR_SIZE(var), &copied##var ); \
	R_FREE(var)

#define R_FREE(var) \
	(R_VAR(var)?(VirtualFreeEx(_R_hProcHnd, R_VAR(var), 0, MEM_RELEASE),NULL):NULL); \

