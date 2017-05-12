#if defined(_WIN32) || defined(__CYGWIN__)

#include <stdlib.h>
#include <math.h>
#include <windows.h>

#include <shlobj.h>
#include <shlguid.h>
#include <objbase.h>

#else
#include <stdlib.h>
#endif

#include <win32sr.h>

#if defined(_WIN32) || defined(__CYGWIN__)

const char *resolve(const char *link_name)
{
  HRESULT hres;
  IShellLink* ilink;
  const char *answer = NULL;
  static char target_path[MAX_PATH];

  hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
                            IID_IShellLink, (void **) &ilink);
  if (SUCCEEDED(hres))
  {
    IPersistFile* ifile;
    hres = ilink->QueryInterface(IID_IPersistFile, (void **) &ifile);
    if(SUCCEEDED(hres))
    {
      wchar_t w_link_name[MAX_PATH];
      /* TODO: handle proper unicode stuff properly */
      MultiByteToWideChar(CP_ACP, 0, link_name, -1, w_link_name, MAX_PATH);
      hres = ifile->Load(w_link_name, STGM_READ);
      if(SUCCEEDED(hres))
      {
        DWORD flags = 0;
        WIN32_FIND_DATA file;
        hres = ilink->GetPath((LPSTR) target_path, MAX_PATH, &file, flags);
        if(SUCCEEDED(hres))
          answer = target_path;
      }
      ifile->Release();
    }
    ilink->Release();
  }
  return answer;
}

#else

const char *resolve(const char *link_name)
{
  return NULL;
}

#endif
