#ifndef PMT_H
#define PMT_H

#include <GiSTlist.h>

typedef unsigned long velem;

class MT;

class PMT {
  MT *mt;

public: // easier. I don't care anyways
  int ndims;
  double min;
  double max;
  double steps;

  double maxDist;
  int elemsize;
  velem vzero;

  int distfast; // can distance be computed fast (integer arithmetic)
  double distmul; // then use this corrective factor

public:
  PMT(int ndims,
      double min,
      double max,
      double steps,
      unsigned int pagesize);
  ~PMT();
  void sync();
  void create(const char *path);
  void open(const char *path);
  void insert(double *k, int data);
  double distance(double *k1, double *k2) const;
  void range(double *k, double r) const;
  void top(double *k, int n) const;
  int maxlevel() const;
  //bulkload(PKey *o, int count);
};

#define ACC (current_pmt)
#define NDIMS (ACC->ndims)

extern const PMT *current_pmt;

extern void add_result(int data, double *k, int ndims);

#endif
