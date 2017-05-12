/*
 * 26 March 2002
 * Vector operations which we need in more than one place.
 * $Id: vec.c,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */

#include <math.h>
#include <stdlib.h>

#include "coord.h"
#include "vec_i.h"

/* ---------------- vector_difference -------------------------
 */
struct RPoint *
vector_difference(struct RPoint *res, const struct RPoint *a,
                  const struct RPoint *b)
{
    res->x = a->x - b->x;
    res->y = a->y - b->y;
    res->z = a->z - b->z;
    return res;
}

/* ---------------- vector_add   ------------------------------
 */
struct RPoint *
vector_add (struct RPoint *res, const struct RPoint *a,
                  const struct RPoint *b)
{
    res->x = a->x + b->x;
    res->y = a->y + b->y;
    res->z = a->z + b->z;
    return res;
}

/* ---------------- scalar_product ----------------------------
 */
float
scalar_product(const struct RPoint *a, const struct RPoint *b)
{
  return (a->x * b->x + a->y * b->y + a->z * b->z);
}

/* ---------------- vec_scl   ---------------------------------
 */
struct RPoint *
vec_scl (struct RPoint *res, const struct RPoint *v, const float a)
{
    *res = *v;
    res->x = v->x * a;
    res->y = v->y * a;
    res->z = v->z * a;
    return (res);
}

/* ---------------- vector_length -----------------------------
 */
float
vector_length (const struct RPoint *v)
{
    return sqrt (v->x * v->x + v->y * v->y + v->z * v->z);
}


/* ---------------- vector_sqr_length -------------------------
 */
float
vector_sqr_length (const struct RPoint *v)
{
    return (v->x * v->x + v->y * v->y + v->z * v->z);
}

/* ---------------- vec_nrm   ---------------------------------
 */
struct RPoint *
vec_nrm (struct RPoint *res, const struct RPoint *v, const float r)
{
    float scl = r / vector_length (v);
    return ( vec_scl (res, v, scl));
}
/* ---------------- vector_product ----------------------------
 */
struct RPoint *
vector_product (struct RPoint *res, const struct RPoint *u,
                const struct RPoint *v)
{
    res->x = u->y * v->z - u->z * v->y;
    res->y = u->z * v->x - u->x * v->z;
    res->z = u->x * v->y - u->y * v->x;
    return (res);
}
