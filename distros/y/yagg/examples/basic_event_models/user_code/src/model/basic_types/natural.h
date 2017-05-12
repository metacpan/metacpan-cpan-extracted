#ifndef NATURAL_H
#define NATURAL_H

class Natural
{
public:
  Natural();
  Natural(const unsigned long int &in_value);

  // Automatic cast to unsigned long int
  operator unsigned long int () const;

  const Natural& operator= (const unsigned long int &in_value);
  const Natural& operator++ ();
  const Natural operator++ (int something);
  Natural& operator+=(const Natural& in_natural);

  friend bool operator== (const Natural& in_first, const Natural& in_second);
  friend bool operator< (const Natural& in_first, const Natural& in_second);
  friend bool operator> (const Natural& in_first, const Natural& in_second);

protected:
  // limit: sizeof(unsigned long int)
  unsigned long int value;
};

inline Natural::Natural()
{
  value = 0;
}

inline Natural::Natural(const unsigned long int &in_value)
{
  value = in_value;
}

inline Natural::operator unsigned long int () const
{
  return value;
}

inline const Natural& Natural::operator=(const unsigned long int& in_value)
{
  value = in_value;
  return *this;
}

inline const Natural& Natural::operator++()
{
  value++;
  return *this;
}

inline const Natural Natural::operator++(int something)
{
  Natural temporary = *this;
  value++;
  return temporary;
}

inline Natural& Natural::operator+=(const Natural& in_natural)
{
  value += in_natural.value;
  return *this;
}

inline bool operator==(const Natural& in_first, const Natural& in_second)
{
  return in_first.value == in_second.value;
}

inline bool operator<(const Natural& in_first, const Natural& in_second)
{
  return in_first.value < in_second.value;
}

inline bool operator>(const Natural& in_first, const Natural& in_second)
{
  return in_first.value > in_second.value;
}

#endif // NATURAL_H
