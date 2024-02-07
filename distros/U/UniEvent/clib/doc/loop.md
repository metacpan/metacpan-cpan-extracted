# Loop

unievent::Loop - The event loop object



# Synopsis
```cpp
    LoopSP loop = new Loop();

    TimerSP timer = new Timer(loop);

    loop->run(); // exits as soon as there is nothing to do

    loop->delay([]{
        std::cout << "executed once. soon, but not now\n";
    });

    loop->update_time();
    std::cout << "current unix epoch: " << loop->now() << " (milliseconds)";
```

The event loop is the central part of UniEvent's functionality.
It takes care of polling for i/o and scheduling callbacks to be run based on different sources of events.

In UniEvent it is possible to have many independent loops. If you don't want to pass Loop object everywhere you can use default_loop. It is a singelton.
When a new handle (I/O event listener) is created, if the `loop` parameter is ommited then the default_loop is used.

Event loops are **independent** each from other. That means, for example, if there are two loop instances,
```cpp
  LoopSP loop1 = new Loop();
  LoopSP loop2 = new Loop();
  //...
  loop1->run();
```
Only handles from `loop1` will be polled for I/O.

It should be noted that handles can't be transferred between different loops.
That's why it is possible to specify it in handle constructor only.

# Static Methods

```cpp
static LoopSP global_loop ();
static LoopSP default_loop ();
```
Returns a singleton loop object.

The only difference between `default_loop()` and `global_loop()` can be noted multithread application.
`default_loop()` loop is *thread-local*, i.e. it a singleton, but it is different in each thread;
while `global_loop()` loop is the same loop instance for the whole application.

`global_loop()` always returns main thread's `default_loop()`.

It is not recommended to use `global_loop()`, because loop objects are **not** thread-safe and thus using `global_loop()` may lead to undefined behaviour if used from different threads. It exists only for rare cases when you definitely know what you're doing.

For many cases, when event loop parameter is ommited, the `default_loop()` is used.

*NOTE: for single-threaded applications, `global_loop()` and `default_loop()` returns the same loop object.*


# Methods

```cpp
Loop(Backend* backend = nullptr)
```

Constructs new event loop object using the specified backend. If the `backend` is not specified, then the default backend is used.

See `unievent::default_backend()`


```cpp
bool is_default()
```

Returns `true` if the loop is the default loop (for the current thread).


```cpp
bool is_global()
```
Returns `true` if the loop is the application global loop.

```cpp
bool alive()
```
Returns `true` if there are active handles or requests in the loop.

```cpp
uint64_t now()
```
Return the current timestamp *in milliseconds*. The value is cached for each event loop iteration. The timestamp is monotonically increased at arbitrary point of time.

```cpp
void update_time()
```
Updates cached "now" value for the loop. It is useful, if in a callback or
handle there is a time-sensitive blocking I/O operation, where it is undesirable
to let the following callbacks have outdated "now" value.


```cpp
void run()
```
Runs the event loop until there are no more active and referenced handles or requests.
Returns `true` if the loop was stopped and there are still active handles or requests.

This method **MAY be non-reenterant**, i.e. must not be called from an event callback, as many backends does not support recursive `run`.


```cpp
run_once()
```
Poll for i/o once (may block until there are pending callbacks).
Returns `false` when done (no active handles or requests left), or `true` if more callbacks are expected
(meaning you should run the event loop again sometime in the future).

This method **MAY be non-reenterant**, i.e. must not be called from an event callback, as many backends does not support recursive `run`.


```cpp
run_nowait()
```
Poll for i/o once but don’t block if there are no pending callbacks.
Returns `false` if done (no active handles or requests left), or `true` if more callbacks are expected
(meaning you should run the event loop again sometime in the future).

This method **MAY be non-reenterant**, i.e. must not be called from an event callback, as many backends does not support recursive `run`.

```cpp
stop()
```
Stop the event loop, causing `run` to end as soon as possible. This will happen not
sooner than the next loop iteration. If this function was called before blocking for
i/o, the loop won't block for i/o on this iteration.


```cpp
IntrusiveChain<Handle*> handles()
```

Returns list of handles, associated with the loop. `IntrusiveChain` is an `std::list`-like class with similar API.

It is recommended for use only for debugging.


```cpp
uint64_t delay (const LoopImpl::delayed_fn& f, const iptr<Refcnt>& guard = {})
```
This is a convenient one-shot callback, which will be invoked "a little bit later". `delayed_fn` is any `void()` callable value.
"A little bit later" is somewhat unspecified, but normally it is on the next loop iteration; although, it might be invoked don't waiting the next iteration.
It is guaranteed that callback will not be called until we return from the current callback code flow (return to the loop internal code).

Returns an id of this delay call. This id can be used to cancel call by passing to `cancel_delay`.

If `guard` is passed callback is called only if `guard` object is alive. Loop keeps week reference only and skips callback call if `guard` is destroyed.
It is designed to pass pointer to some kind of listener object or transaction to cancell delay automatically if there is no listener anymore.

```cpp
cancel_delay($delay_guard)
```
Cancels previously set delay. Does nothing if it's too late (callback has already been called).


```cpp
CallbackDispatcher<void(const LoopSP&)> fork_event
```
Event will be invoked when the application `fork()`s.

See [Events](../README.md#events) for more info.

Callback is called on behalf of a child process, after all fork-related work for event loop is done (see [Unievent fork](../README.md#fork)).

```cpp
const ResolverSP& resolver()
```

Returns per-loop [Resolver](resolver.md) object.

This resolver object does not hold the loop, so if you keep a reference to it, you must not use it after it's loop death (otherwise exception will be thrown).


```cpp
void track_load_average (uint32_t for_last_n_seconds);
```

Starts tracking load average on the loop. Tracked value is the average loop busy load for last `seconds`. This value is NOT a CPU load, instead
it is somewhat more useful. It is wallclock time that was spent on calling user callbacks (and related stuff) during last `seconds` divided by
`seconds`. I.e. part of the time, the loop was not in I/O polling, in other words, part of the time the loop was busy and could not receive new events.

This value is more useful than CPU load because even in case of blocking code (waiting for blocking I/O) it will count such time as busy time.


```cpp
get_load_average()
```
Returns loop busy load (value between 0 and 1, where 1 means 100% busy). If `track_load_average()` wasn't previously enabled, returns 0.
