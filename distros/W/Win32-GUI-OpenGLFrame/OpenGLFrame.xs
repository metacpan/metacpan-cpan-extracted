/* 
 * Copyright (c) Robert May 2006..2009
 */

#define WIN32_LEAN_AND_MEAN
#define STRICT
#define WINVER 0x0400       /* NOT 0x0501 for VC6 compatibility */
#define _WIN32_WINNT 0x0400 /* NOT 0x0501 for VC6 compatibility */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#include <gl/Gl.h>

MODULE = Win32::GUI::OpenGLFrame        PACKAGE = Win32::GUI::OpenGLFrame

PROTOTYPES: ENABLE

     ##########################################################################
     # (@)INTERNAL:_SetOpenGLPixelFormat([DOUBLEBUFFER=0, [DEPTH=0]])
     # Set a suitable pixel format for OpenGL rendering
     # If DOUBLEBUFFER is true, then sets PFD_DOUBLEBUFFER
     # Returns a HDC on success (0 on failure)
HDC _SetOpenGLPixelFormat(hWnd, doubleBuffer=0, depth=0)
    HWND hWnd
    BOOL doubleBuffer
    BOOL depth
PREINIT:
    int best_format;
    PIXELFORMATDESCRIPTOR pfd = { sizeof(PIXELFORMATDESCRIPTOR) };
CODE:
    /* Initialise the PIXELFORMATDESCRIPTOR structure */
    pfd.nVersion        = 1;
    pfd.dwFlags         = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL;
    pfd.iPixelType      = PFD_TYPE_RGBA;
    pfd.cColorBits      = 24;
    pfd.cDepthBits      = (depth ? 32 : 0);
    pfd.iLayerType      = PFD_MAIN_PLANE;  /* ignored */

    if(doubleBuffer)
        pfd.dwFlags |= PFD_DOUBLEBUFFER;

    /* choose the most appropriate format for the DC */
    if(RETVAL = GetDC(hWnd)) {
       if((best_format = ChoosePixelFormat(RETVAL, &pfd)) && SetPixelFormat(RETVAL, best_format, &pfd)) {
            /* success - we don't need to release the DC, as our class has a private DC (CS_OWNDC) */
        }
        else {
            ReleaseDC(hWnd, RETVAL); /* Not necessary, but good form */
            RETVAL = NULL;
        }
    }
OUTPUT:
    RETVAL

     ##########################################################################
     # (@)WIN32API:wglCreateContext(HDC)
     # Create a new OpenGL rendering context suitable for use with
     # Device Context hdc.
     # returns the handle to the rendering context on success, false on failure
     # See OpenGLFrame.pm for full documentation
HGLRC wglCreateContext(hdc)
    HDC hdc

     ##########################################################################
     # (@)WIN32API:wglDeleteContext(HDC)
     # Delete an OpenGL rendering context
     # returns true on success, false on failure
     # See OpenGLFrame.pm for full documentation
BOOL wglDeleteContext(hglrc)
    HGLRC hglrc

     ##########################################################################
     # (@)WIN32API:wglMakeCurrent([HDC, [HGLRC]])
     # Makes HGLRC the active rendering context for the current thread, and
     # causes all drawing to HGLRC to be directed to HDC.
     # If HDC and HGLRC are omitted, de-activates the thread's currently active
     # rendering context, if any.
     # returns true on success, false on failure
     # See OpenGLFrame.pm for full documentation
BOOL wglMakeCurrent(hdc=NULL,hglrc=NULL)
    HDC hdc
    HGLRC hglrc

     ##########################################################################
     # (@)WIN32API:wglGetCurrentDC()
     # returns a handle to the DC for the threads currently active OpenGL
     # rendering context, or false if the thread does not have an active
     # rendering context.
     # See OpenGLFrame.pm for full documentation
HDC wglGetCurrentDC()

     ##########################################################################
     # (@)WIN32API:SwapBuffers(HDC)
     # Swaps the front and back buffers of the device context if it has a
     # current pixel format that supports double buffering, otherwise
     # does nothing.
     # Returns true on success or false on failure
     # See OpenGLFrame.pm for full documentation
BOOL SwapBuffers(hdc)
    HDC hdc

     ##########################################################################
     # (@)WIN32API:glFlush()
     # Force execution of OpenGL functions in a finite time
     # See OpenGLFrame.pm for full documentation
void glFlush()

     ##########################################################################
     # (@)WIN32API:glViewport(X,Y,W,H)
     # Set the viewport dimenstions
     # See OpenGLFrame.pm for full documentation
void glViewport(x,y,w,h)
    GLint x
    GLint y
    GLsizei w
    GLsizei h

     ##########################################################################
     # (@)WIN32API:glClear()
     # Clear all the buffers using preset(default) values.
     # See OpenGLFrame.pm for full documentation
void glClear(mask=GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_ACCUM_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)
    GLbitfield mask

