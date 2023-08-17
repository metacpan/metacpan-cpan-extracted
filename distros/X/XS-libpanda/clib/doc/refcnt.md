# refcnt.h

refcnt.h contains group of tools for reference counting memory management.

# Synopsis

```cpp
class MyType : public Refcnt {
    double my_data;
};

class MyCustomType : public MyType {};

{
    iptr<MyType> p = new MyType();
} // ~MyType and delete here automatically

weak_ptr<MyType> w;
{
    iptr<MyType> p = new MyType();
    w = p;
    pass_somewhere(p);
} // ~MyType and delete here automatically

if (iptr<MyType> tmp = w.lock()) { // if object exists lock() returns a strong pointer to it
    // do anything with tmp
}
iptr<MyType> p = new MyCustomType();
iptr<MyCustomType> cp = dynamic_pointer_cast<MyCustomType>(p);

```


# iptr

`iptr` is a smart pointer with intrusive reference counter. It is very similar to intrusive_ptr from Boost.
Every new iptr instance increments the reference count by using an unqualified call to the function refcnt_inc, passing it the pointer as an argument.  Every destruction of iptr call refcnt_dec.
These functions should be provided by class or any class user. The simplest way to do so is to inherit your class from [Refcnt](#refcnt). If you want to have pointers in different threads use AtomicRefcnt.
Another way is implementing of `refcnt_inc` and `refcnt_dec`. `iptr` makes am unqualified call so [ADL](https://en.cppreference.com/w/cpp/language/adl) can finds it in the namespace of the target type. It makes possible to use `iptr` for any type that provides internal reference counting (i.e. COM objects).

```cpp
void refcnt_inc(IUnknown* p) {
    p->AddRef();
}
void refcnt_def(IUnknown* p) {
    p->Release();
}
```

# weak_ptr

Similar to [std::weak_ptr](https://en.cppreference.com/w/cpp/memory/weak_ptr) but it to works with `iptr`. A weak pointer that can provide access to a stored object if any `iptr` to that object exists.
`weak_ptr<T>` uses a weak pointer counter that is provided by `T::weak_storage_type`. Actually `weak_ptr` contains a `iptr<T::weak_storage_type>` that provides lifetime control over weak counter.

# Refcnt

A base class implementing a storage for a reference counter. The simplest way to make `iptr` work with your custom classes is to inherit them from `Refcnt`

```cpp
class MyType : public Refcnt {
    double my_data;
};

class MyCustomType : public MyType {};

{
    iptr<MyType> p = new MyType();
} // ~MyType and delete here automatically
```

# pointer_cast
```cpp
template <typename T1, typename T2> inline iptr<T1> static_pointer_cast  (const iptr<T2>& ptr) { return iptr<T1>(static_cast<T1*>(ptr.get())); }
template <typename T1, typename T2> inline iptr<T1> const_pointer_cast   (const iptr<T2>& ptr) { return iptr<T1>(const_cast<T1*>(ptr.get())); }
template <typename T1, typename T2> inline iptr<T1> dynamic_pointer_cast (const iptr<T2>& ptr) { return iptr<T1>(dyn_cast<T1*>(ptr.get())); }
```

All cast functions for `iptr<T>` that returns `iptr<>` with requested type.
