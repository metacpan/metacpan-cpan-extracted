# refcnt

refcnt.h contains group of tools for reference counting memory management.

# Synopsis

# iptr

iptr is a smart pointer with intrusive reference counter. It is very similar to intrusive_ptr from Boost.
Every new iptr instance increments the reference count by using an unqualified call to the function refcnt_inc, passing it the pointer as an argument.  Every destruction of iptr call refcnt_dec.
These functions should be provided by class or any class user. The simplest way to do so is to inherit your class from Refcnt. If you want to have pointers in different threads use AtomicRefcnt.





