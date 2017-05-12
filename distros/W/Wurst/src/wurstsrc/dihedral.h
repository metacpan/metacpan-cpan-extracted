/*
 * 26 April 2001
 * This can only be #included after struct RPoint is defined, so
 * one has to #include "coord.h".
 * $Id: dihedral.h,v 1.1 2007/09/28 16:57:08 mmundry Exp $
 */

#ifndef DIHEDRAL_H
#define DIHEDRAL_H
float
dihedral (const struct RPoint i, const struct RPoint j,
          const struct RPoint k, const struct RPoint l);
#endif /*  DIHEDRAL_H */
