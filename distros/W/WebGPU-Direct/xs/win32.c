#ifdef HAS_WIN32

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <windows.h>
#include <process.h>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch(msg)
  {
    case WM_CLOSE:
      DestroyWindow(hwnd);
    break;
    case WM_DESTROY:
      PostQuitMessage(0);
    break;
    default:
      return DefWindowProc(hwnd, msg, wParam, lParam);
  }
  return 0;
}

bool win32_process_events()
{
  MSG msg;

  // PeekMessage with PM_REMOVE processes messages without blocking
  while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
  {
    if (msg.message == WM_QUIT)
    {
      return false;
    }
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return true;
}

static void cv_win32_process_events(pTHX_ CV* cv)
{
  win32_process_events();
}

bool win32_window(WGPUSurfaceSourceWindowsHWND *result, CV **pec, int xw, int yh)
{
  Zero((void*)result, 1, WGPUSurfaceSourceWindowsHWND);

  xw = xw ? xw : 640;
  yh = yh ? yh : 360;

  HINSTANCE hinstance = (HINSTANCE)GetModuleHandle(NULL);

  LPCSTR CLASS_NAME  = "WebGPU::Direct Sample Window Class";

  WNDCLASS wc = { };
  wc.lpfnWndProc   = WindowProc;
  wc.hInstance     = hinstance;
  wc.lpszClassName = CLASS_NAME;

  RegisterClass(&wc);

  // Adjust so the client area is what was requested
  // FYI - does not handle resizes well
  RECT rect = {0, 0, xw, yh};
  AdjustWindowRectEx(&rect, WS_OVERLAPPEDWINDOW, FALSE, 0);

  HWND hwnd = CreateWindowEx(
    0,
    CLASS_NAME,
    "WebGPU::Direct",
    WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, CW_USEDEFAULT,
    rect.right - rect.left, rect.bottom - rect.top,
    NULL,
    NULL,
    hinstance,
    NULL
  );

  if (hwnd == NULL)
  {
    return false;
  }

  result->hinstance = hinstance;
  result->hwnd = hwnd;
  result->chain.sType = WGPUSType_SurfaceSourceWindowsHWND;

  ShowWindow(hwnd, SW_SHOWDEFAULT);

  win32_process_events();

  // Store the processEvents xsub so it can be called on the loop
  char* func_name = "WebGPU::Direct::__ANON__::win32_process_events";
  *pec = newXS(func_name, cv_win32_process_events, __FILE__);

  return true;
}

#endif
