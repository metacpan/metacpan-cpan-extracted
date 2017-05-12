#ifndef INTEGER_H
#define INTEGER_H

class Integer
{
public:
  Integer();
  Integer(const unsigned long int &in_value);

  // Automatic cast to unsigned long int
  operator unsigned long int () const;

  const Integer& operator= (const unsigned long int &in_value);
  const Integer& operator++ ();
  const Integer operator++ (int something);

  friend bool operator== (const Integer& in_first, const Integer& in_second);
  friend bool operator< (const Integer& in_first, const Integer& in_second);

protected:
  // limit: sizeof(long int)
  long int value;
};

inline Integer::Integer()
{
  value = 0;
}

inline Integer::Integer(const unsigned long int &in_value)
{
  value = in_value;
}

inline Integer::operator unsigned long int () const
{
  return value;
}

inline const Integer& Integer::operator=(const unsigned long int& in_value)
{
  value = in_value;
  return *this;
}

inline const Integer& Integer::operator++()
{
  value++;
  return *this;
}

inline const Integer Integer::operator++(int something)
{
  Integer temporary = *this;
  value++;
  return temporary;
}

inline bool operator==(const Integer& in_first, const Integer& in_second)
{
  return in_first.value == in_second.value;
}

inline bool operator<(const Integer& in_first, const Integer& in_second)
{
  return in_first.value < in_second.value;
}

#endif // INTEGER_H
