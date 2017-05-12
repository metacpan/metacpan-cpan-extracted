
#ifndef _XPSTACKP_H
#define _XPSTACKP_H

#include "XpStack.h"

/* Define the Stack instance part */

typedef struct
{
    /* New resource fields */

    Dimension outside_margin;
    XtCallbackList now_displayed_cb;
    XtCallbackList now_hidden_cb;

    /* New internal fields */

    int active_child;
    int last_active_child;
}
XpStackPart;

/* Define the full instance record */

typedef struct _StackRec
{
    CorePart core;
    CompositePart composite;
    ConstraintPart constraint;
    XmManagerPart manager;
    XpStackPart xpStack;
}
XpStackRec, *XpStackWidget;

/* Define class part structure */

typedef struct _StackClassPart
{
    int likeThis;
}
XpStackClassPart;

typedef struct _StackClassRec
{
    CoreClassPart core_class;
    CompositeClassPart composite_class;
    ConstraintClassPart constraint_class;
    XmManagerClassPart manager_class;
    XpStackClassPart xpStack_class;
}
XpStackClassRec;

typedef struct _StackConstraintPart
{
    String layer_name;
    Boolean layer_active;

    Dimension tab_position;
    Dimension tab_length;
    Dimension tab_starting_line;

    String name_1;
    int length_1;
    String name_2;
    int length_2;
}
XpStackConstraintPart;

typedef struct _StackConstraintRec
{
    XpStackConstraintPart xpStack;
}
XpStackConstraintRec, *XpStackConstraint;

/* External definition for class record */

extern XpStackClassRec xpStackClassRec;

#endif /* _STACKP_H */
