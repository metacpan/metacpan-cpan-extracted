/*
 * 24 October 2001
 * Secondary structure routines. Definitions for internal use.
 * Interface defined in sec_s_i.h
 * rcsid = $Id: sec_s.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#ifndef SEC_S_H
#define SEC_S_H

enum sec_typ {                          /* The type of secondary */
    HELIX,                              /* structure. Defined by */
    EXTEND,                             /* DSSP */
    BEND,
    B_BRIDGE,                           /* Isolated B-bridge */
    PI_HELIX,
    TT_HELIX,                           /* Three - ten Helix */
    TURN,
    NO_SEC,
    ERROR
};


struct sec_s_data {
    struct sec_datum {
        size_t resnum;
        enum sec_typ sec_typ;
        unsigned char rely;
    } *data ;
    size_t n;
};

#endif
