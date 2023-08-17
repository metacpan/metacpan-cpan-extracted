# memory

It is a collection of memory pools and different tools to use it.

# AllocatedObject

Base class using [CRTP](https://en.wikipedia.org/wiki/Curiously_recurring_template_pattern) that provides `new` operator overloading to allocate objects in [DynamicMemoryPool::instance](#dynamicmemorypool). It makes object creation much faster. Look [DynamicMemoryPool::instance](#dynamicmemorypool) for details such as thread-safty guarantees and etc.

# DynamicMemoryPool

A set of [MemoryPools](#memorypool) of different sizes. It uses the best fitting pool according to allocating size.

Instances are **not thread-safe**. That is why it is recommended to use a thread local static `instance()` or creating and using a pool in one thread only.

Access to static instances are thread-safe. See [more about thread-safety](#threads).

## Methods

### instance
```cpp
static DynamicMemoryPool* instance()
```

A thread-local instance of DynamicMemoryPool. Usually there is no need of creating of any other instances. More users of a pool - more efficient it is.

### allocate
```cpp
void* allocate (size_t size)
```

Returns a free chunk of memory that is at least `size` bytes big.

The minimum chunk is 8 bytes. For smaller sizees DynamicMemoryPool uses the pool for size 8.

The maximum size is 262144 bytes. In case of requesting of bigger allocation `std::invalid_argument` would be thrown.


### deallocate
```cpp
void deallocate (void* ptr, size_t size)
```

Returns a chunk of memory back to the pool. `size` should be the same that was passed to [allocate](#allocate) call that returns `ptr`.

If `size` is different from `allocate` call then behavior is undefined.

If the `ptr` was allocated in any other instance of pool it goes to the pool the `deallocate` call is done on. It is not an error to return to another pool but it is highly recommended to avoid this. This is a violation of ownership and such a disbalance of allocating and deallocating can lead to a situation like memory leak. If you take from one pool and put into another then the former grows and the memory chunks are not reused by the latter. It is an actual memory leak.


## Threads

Using a thread local pool does not mean that allocated object cannot be passed to another thread. If `deallocate` is called in another thread then the object was created then no error happens. Nevertheless it can be bad. If one thread allocates and another deallocates then the pool from the first grows and never reuses its objects and the second thread has a full pool of objects. If allocation and deallocation is balanced between threads then the situation is theoretically normal. It is still better to avoid such usage.

# MemoryPool

A simple pool of object of the same size. Size is the only constructor parameter.
