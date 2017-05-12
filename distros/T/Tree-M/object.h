#ifndef OBJECT_H
#define OBJECT_H

#include <cstring>
#include <cstdio>

#include "PMT.h"

inline double maxDist() { return ACC->maxDist; }
inline int sizeofObject() { return ACC->ndims * ACC->elemsize; }

class Object : public GiSTobject	// the DB object class
{
	velem *k;

        static double int2double(velem i) {
          return i * ACC->max / ACC->steps + ACC->min;
        }
        static velem double2int(double d) {
          return (velem)floor ((d - ACC->min) * ACC->steps / ACC->max);
        }

public:
	Object() {
          k = new velem [NDIMS];

          for (int i = NDIMS; i--; )
            k[i] = ACC->vzero;
        }

        Object(double *pkey);

	~Object() {
          delete [] k;
        }

	Object(const Object& obj) {
          k = new velem [NDIMS];
          memcpy (k, obj.k, NDIMS * sizeof (velem));
        }

	Object& operator=(const Object& obj) {
          delete [] k;

          k = new velem [NDIMS];
          memcpy (k, obj.k, NDIMS * sizeof (velem));
        }

	double area(double r) const {
          return 0;
	}

        double *data() const;

	double distance(const Object& other) const;	// distance method (needed)

	int operator ==(const Object& obj) const
        {
          return !memcmp (k, obj.k, NDIMS * sizeof (velem));
        }

	int operator !=(const Object& obj) const
        {
          return !(*this==obj);
        }

	int CompressedLength() const {
          return sizeofObject();
        }

	Object(char *key);
	void Compress(char *key);
};

#endif
