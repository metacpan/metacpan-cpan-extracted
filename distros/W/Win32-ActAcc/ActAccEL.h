/*
Copyright 2000-2004, Phill Wolf.  See README.

Win32::ActAcc (Active Accessibility)
*/
extern bool oriented;
extern bool live;
extern HANDLE hMx;
extern HANDLE hFM;
extern struct aaevbuf * pEvBuf;

#ifdef __cplusplus
extern "C" {
#endif

void orient();

long emGetCounter();

bool emLock();

void emUnlock();

void emGetEventPtr(const long readCursorQume, const int max, int *actual, struct aaevt **pp);

long emSynch();

#ifdef __cplusplus
}
#endif
