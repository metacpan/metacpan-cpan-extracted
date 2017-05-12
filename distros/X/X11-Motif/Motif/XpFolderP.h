
#ifndef _XPFOLDERP_H
#define _XPFOLDERP_H

#include "XpFolder.h"

/* Define the Folder instance part */

typedef struct
{
    /* New resource fields */

    Dimension outside_margin;
    String tab_position;
    String tab_alignment;
    Boolean allow_scrolling_tabs;
    Dimension tab_height;
    Dimension tab_slant_width;
    Dimension tab_margin;
    XFontStruct *tab_font;
    Pixel foreground;
    Pixel top_folder_color;
    Pixel bottom_folder_color;

    /* New internal fields */

    GC tab_gc;
    Pixmap left_arrow_pixmap;
    Pixmap right_arrow_pixmap;
    Dimension arrow_width;
    Boolean need_left_arrow;
    Boolean need_right_arrow;
    unsigned int current_tab_offset;
}
XpFolderPart;

/* Define the full instance record */

typedef struct _XpFolderRec
{
    CorePart core;
    CompositePart composite;
    ConstraintPart constraint;
    XmManagerPart manager;
    XpFolderPart xpFolder;
}
XpFolderRec, *XpFolderWidget;

/* Define class part structure */

typedef struct _XpFolderClassPart
{
    int likeThis;
}
XpFolderClassPart;

typedef struct _XpFolderClassRec
{
    CoreClassPart core_class;
    CompositeClassPart composite_class;
    ConstraintClassPart constraint_class;
    XmManagerClassPart manager_class;
    XpFolderClassPart xpFolder_class;
}
XpFolderClassRec;

/* External definition for class record */

extern XpFolderClassRec xpFolderClassRec;

#endif /* _XPFOLDERP_H */
