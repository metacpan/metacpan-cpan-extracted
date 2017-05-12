#ifndef REAL_H
#define REAL_H

#include <cmath>

using namespace std;

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

// This class should probably be split into Unsigned_Real and Signed_Real in
// order to give the implementation a higher upper bound for unsigned reals
// (Time, for example).

class Real
{
public:
  Real();
  Real(const double &in_value);

  // Automatic cast to real
  operator const double() const;

  virtual const Real& operator= (const double &in_value);
  virtual Real& operator+=(const Real& in_Real);

  friend bool operator== (const Real& in_first, const Real& in_second);
  friend bool operator!= (const Real& in_first, const Real& in_second);
  friend bool operator< (const Real& in_first, const Real& in_second);

  static const double EPSILON;
protected:
  // limit: reals limited to sizeof(double)
  double value;
};

inline Real::Real()
{
  value = 0;
}

inline Real::Real(const double &in_value)
{
  value = in_value;
}

inline Real::operator const double() const
{
  return value;
}

inline const Real& Real::operator=(const double& in_value)
{
  value = in_value;
  return *this;
}

inline Real& Real::operator+=(const Real& in_real)
{
  value += in_real.value;
  return *this;
}

inline bool operator==(const Real& in_first, const Real& in_second)
{
  return (fabs(in_first.value - in_second.value) < Real::EPSILON);
}

inline bool operator!=(const Real& in_first, const Real& in_second)
{
  return !(in_first == in_second);
}

inline bool operator<(const Real& in_first, const Real& in_second)
{
  return in_first.value < in_second.value;
}

#endif // REAL_H
