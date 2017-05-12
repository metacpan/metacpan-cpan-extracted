#include <cstdlib>

#include "MT/MT.h"
#include "MT/MTpredicate.h"
#include "PMT.h"

const PMT *current_pmt;
int IOread, IOwrite;
dist2sim hfunction; // argl. using c++ without any clue.

/*
static double *
kdup (double *k, int ndims)
{
  double *n = new double [ndims];

  memcpy (n, k, ndims * sizeof (double));
  return n;
}
*/

double *Object::data() const
{
  double *d = new double [NDIMS];

  for (int i = NDIMS; i--; )
     d[i] = int2double(k[i]);

  return d;
}

double Object::distance(const Object& other) const
{
  if (ACC->distfast)
    {
      velem dist = 0;

      for (int i = NDIMS; i--; )
        {
          long d = other.k[i] - k[i];

          dist += (velem)(d*d);
        }

      return dist * ACC->distmul;
    }
  else 
    {
      double dist = 0.;

      for (int i = NDIMS; i--; )
        {
          double d = int2double(other.k[i]) - int2double(k[i]);

          dist += (velem)(d*d);
        }

      return dist;
    }
}


Object::Object(double *pkey)
{
  k = new velem[NDIMS];

  // discretize the vector
  for (int i = NDIMS; i--; )
     k[i] = double2int (pkey[i]);

  free (pkey);
}

Object::Object(char *key)
{
  unsigned char *c = (unsigned char *)key;

  k = new velem [NDIMS];

  for (int i = 0; i < NDIMS; i++)
    {
      velem elem = 0;

      switch (ACC->elemsize)
        {
          case 4: elem |= *c++ << 24;
          case 3: elem |= *c++ << 16;
          case 2: elem |= *c++ <<  8;
          case 1: elem |= *c++ <<  0;
            break;
          default:
            abort ();
        }

      k[i] = elem;
    }
}

void Object::Compress(char *key)
{
  unsigned char *c = (unsigned char *)key;

  for (int i = 0; i < NDIMS; i++)
    {
      velem elem = k[i];

      switch (ACC->elemsize)
        {
          case 4: *c++ = (elem >> 24) & 0xff;
          case 3: *c++ = (elem >> 16) & 0xff;
          case 2: *c++ = (elem >>  8) & 0xff;
          case 1: *c++ = (elem >>  0) & 0xff;
            break;
          default:
            abort ();
        }
    }
}

#define SETCUR current_pmt = this

PMT::PMT(int ndims, double min, double max, double steps, unsigned int pagesize)
{
  steps--;

  assert (min <= 0);

  this->ndims = ndims;
  this->min   = min;
  this->max   = max;
  this->steps = steps;

  this->vzero = (velem)floor (- min * steps / max);

  if (steps < (1<<8))
    elemsize = 1;
  else if (steps < (1<<16))
    elemsize = 2;
  else if (steps < (1<<24))
    elemsize = 3;
  else
    elemsize = 4;

  maxDist = (max - min) * (max - min) * ndims;

  if (elemsize <= 2
      && floor (steps * steps * 0.5 + 1) < velem(1<<31) / velem(ndims))
    {
      distfast = 1;
      distmul = maxDist / double(steps * steps * ndims);
    }
  else
    distfast = 0;

  SETCUR;
  mt = new MT (pagesize);
}

PMT::~PMT()
{
  SETCUR;
  mt->Sync();
  delete mt;
}

void PMT::create(const char *path)
{
  SETCUR;
  mt->Create(path);
}

void PMT::open(const char *path)
{
  SETCUR;
  mt->Open(path);
}

void PMT::insert(double *k, int data)
{
  SETCUR;
  Object o(k);
  const MTkey key(o, 0, 0);
  const MTentry entry(key, data);
  mt->Insert(entry);
}

void PMT::sync()
{
  SETCUR;
  mt->Sync();
}

double PMT::distance(double *k1, double *k2) const
{
  SETCUR;
  Object o1(k1), o2(k2);
  return o1.distance(o2);
}


void PMT::range(double *k, double r) const
{
  SETCUR;
  Object o(k);
  Pred p(o);
  SimpleQuery q(&p, r);
  GiSTlist<MTentry *> res = mt->RangeSearch(q);

  while(!res.IsEmpty())
    {
      MTentry *e = res.RemoveFront ();
      double *data = e->Key()->obj.data ();
      add_result(e->Ptr(), data, ndims);
      delete data;
      delete e;
    }
}

void PMT::top(double *k, int n) const
{
  SETCUR;
  Object o(k);
  Pred p(o);
  TopQuery q(&p, n);
  MTentry **res = mt->TopSearch(q);

  for (int i=0; i < n; i++)
    {
      MTentry *e = res[i];
      add_result(e->Ptr(), e->Key()->obj.data(), ndims);
      delete e;
   }
}

int PMT::maxlevel() const
{
  SETCUR;
  return mt->MaxLevel();
}
