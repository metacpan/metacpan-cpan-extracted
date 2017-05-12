/*
 * 10 January 2002
 * rcsid = $Id: rmacros.h,v 1.1 2007/09/28 16:57:07 mmundry Exp $
 */

#ifndef RMACROS_H
#define RMACROS_H

#define VECTOR_SQR_LENGTH(a) (a.x * a.x + a.y * a.y + a.z * a.z)

#define VECTOR_LENGTH(a) sqrt(a.x * a.x + a.y * a.y + a.z * a.z)

#define SCALAR_PRODUCT(a, b) (a.x * b.x + a.y * b.y + a.z * b.z)

#define VECTOR_PRODUCT(a, b, c) \
  c.x = a.y * b.z - b.y * a.z; \
  c.y = a.z * b.x - b.z * a.x; \
  c.z = a.x * b.y - b.x * a.y

#define VECTOR_DIFFERENCE(a, b, c) \
  c.x = a.x - b.x; \
  c.y = a.y - b.y; \
  c.z = a.z - b.z

#define VECTOR_SUM(a, b, c) \
  c.x = a.x + b.x; \
  c.y = a.y + b.y; \
  c.z = a.z + b.z

  
#define SQR_DISTANCE(a, b) \
   ((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) + (a.z-b.z)*(a.z-b.z))

#define DISTANCE(a, b) \
   sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) + (a.z-b.z)*(a.z-b.z))

#endif /* RMACROS_H */
