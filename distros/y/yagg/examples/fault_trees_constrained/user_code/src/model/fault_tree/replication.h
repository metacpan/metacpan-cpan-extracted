#ifndef REPLICATION_H
#define REPLICATION_H

#include "model/basic_types/natural.h"

class Replication : public Natural
{
public:
  Replication();
  Replication(const unsigned long int &in_value);
};

inline Replication::Replication() : Natural()
{
}

inline Replication::Replication(const unsigned long int &in_value) : Natural(in_value)
{
}

#endif // REPLICATION_H
