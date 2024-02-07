# Handle

`unievent::Handle` is a base abstract class for all handle types

The class contains methods common for all hanlde types.

# Methods

## loop
```cpp
const LoopSP& loop ()
```

Returns assigned to the handle event loop instance.

## type
```cpp
virtual const HandleType& type () const = 0;
```

Returns an integer, which uniquely identifies handle type.
You can check it against constants in handle classes (like Timer::TYPE).

Every handle class has `TYPE` constant.

## active
```cpp
virtual bool active () const = 0;
```

Returns true if the handle is "active". What "active" means depends on the concrete
handle type, i.e. for timer handle active means, that it was started, for pipe, tcp etc.
handle types "active" means that I/O operations will be performed or watched for.

Usually, if there is a `start` method, then handle is active afther the invokation
of the method, and vise versa, `stop` method deactivates handle.


## weak
```cpp
bool weak () const;
void weak (bool value);
```

If no argument is passed, returns true if handle is weak, false otherwise.

With argument, marks the handle as weak (if `value` is true) or unmarks it (if false).

Weak handles do not keep the loop from bailing out of `Loop::run()` method (regardless of whether handle is active or not). That means that if all the handles left in the loop are weak, it will return from it's `Loop::run()` method.

The freshly created handle instance is non-weak by default.

## reset
```cpp
virtual void reset () = 0;
```

Stops the handle, making it inactive, resetting it to initial state, with the exception, that
assigned callbacks and event listener are kept.


## clear
```cpp
virtual void clear () = 0;
```

Resets everything, including assigned callbacks and event listener, as if the hanle has been created anew.

## user_data
```cpp
iptr<Refcnt> user_data;
```

A public member for user purpose data. It should be refcounted to make automatic memory management possible. Unievent doesn't use this data.
