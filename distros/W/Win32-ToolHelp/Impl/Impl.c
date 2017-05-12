#include <windows.h>
#include <tlhelp32.h>


HANDLE GetFirstProcess(PROCESSENTRY32* pe32)
{
	HANDLE h;

	if (pe32 == 0)
		return INVALID_HANDLE_VALUE;

	ZeroMemory(pe32, sizeof(*pe32));
	pe32->dwSize = sizeof(*pe32); 

	h = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (h == INVALID_HANDLE_VALUE)
		return INVALID_HANDLE_VALUE;

	if (!Process32First(h, pe32))
	{
		CloseHandle(h);
		return INVALID_HANDLE_VALUE;
	}

	return h;
}


HANDLE GetNextProcess(HANDLE h, PROCESSENTRY32* pe32)
{
	if (h == INVALID_HANDLE_VALUE)
		return INVALID_HANDLE_VALUE;
	if (pe32 == 0)
		return INVALID_HANDLE_VALUE;

	ZeroMemory(pe32, sizeof(*pe32));
	pe32->dwSize = sizeof(*pe32); 

	if (!Process32Next(h, pe32))
	{
		CloseHandle(h);
		return INVALID_HANDLE_VALUE;
	}

	return h;
}


HANDLE GetFirstModule(DWORD pid, MODULEENTRY32* me32)
{
	HANDLE h;

	if (me32 == 0)
		return INVALID_HANDLE_VALUE;

	ZeroMemory(me32, sizeof(*me32));
	me32->dwSize = sizeof(*me32); 

	h = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pid);
	if (h == INVALID_HANDLE_VALUE)
		return INVALID_HANDLE_VALUE;

	if (!Module32First(h, me32))
	{
		CloseHandle(h);
		return INVALID_HANDLE_VALUE;
	}

	return h;
}


HANDLE GetNextModule(HANDLE h, MODULEENTRY32* me32)
{
	if (h == INVALID_HANDLE_VALUE)
		return INVALID_HANDLE_VALUE;
	if (me32 == 0)
		return INVALID_HANDLE_VALUE;

	ZeroMemory(me32, sizeof(*me32));
	me32->dwSize = sizeof(*me32); 

	if (!Module32Next(h, me32))
	{
		CloseHandle(h);
		return INVALID_HANDLE_VALUE;
	}

	return h;
}
