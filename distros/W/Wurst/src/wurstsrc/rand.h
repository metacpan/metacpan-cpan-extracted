/*
 * 16 nov 2005
 * rcsid = $Id: rand.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */
#ifndef RAND_H
#define RAND_H

void ini_rand (long int seed);
float g_rand (const float mean, const float std_dev);

#endif /* RAND_H */
