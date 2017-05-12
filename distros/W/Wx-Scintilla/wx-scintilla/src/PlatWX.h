
/* Versions before 2.8.11 dont' have wxIntPtr defined */

#ifndef wxIntPtr
#if SIZEOF_LONG >= SIZEOF_VOID_P && SIZEOF_LONG >= SIZEOF_SIZE_T
    /* normal case */
    typedef unsigned long wxUIntPtr;
    typedef long wxIntPtr;
#elif SIZEOF_SIZE_T >= SIZEOF_VOID_P
    /* Win64 case */
    typedef size_t wxUIntPtr;
    #define wxIntPtr ssize_t
#else
    /*
       This should never happen for the current architectures but if you're
       using one where it does, please contact wx-dev@lists.wxwidgets.org.
     */
    #error "Pointers can't be stored inside integer types."
#endif
#endif


wxRect wxRectFromPRectangle(PRectangle prc);
PRectangle PRectangleFromwxRect(wxRect rc);
wxColour wxColourFromCA(const ColourDesired& ca);

