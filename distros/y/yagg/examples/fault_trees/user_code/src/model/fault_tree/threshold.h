#ifndef THRESHOLD_H
#define THRESHOLD_H

#include "model/basic_types/natural.h"

class Threshold : public Natural
{
public:
  Threshold();
  Threshold(const unsigned long int &in_value);
};

inline Threshold::Threshold() : Natural()
{
}

inline Threshold::Threshold(const unsigned long int &in_value) : Natural(in_value)
{
}

#endif // THRESHOLD_H
