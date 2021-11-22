# CallbackDispatcher
CallbackDispatcher implements pattern Event Listener.

# Synopsis
```cpp
CallbackDispatcher<void()> d1;
string output;
function<void()> hello = [&]() { output += "Hello,"; };
function<void()> world = [&]() { output += " World!"; };
d1.add(hello);
d1.add(world);
d1(); // both callback are called in the same order they were added
assert(output == "Hello, World!");

d1.remove(world);
d1(); // only hello remains
assert(output == "Hello, World!Hello,");

using IntInt = CallbackDispatcher<int(int)>;
IntInt d2;
d2.add_event_listener([](IntInt::Event& event, int val) {
    return event.next(val).value_or(val) * 2; // do what you want with other listeners result
});
d2.add_event_listener([](IntInt::Event& /*event*/, int val) {
    return val + 1; // or event skip calling others
});
d2.add_event_listener([](IntInt::Event& /*event*/, int /*val*/) -> int {
    throw std::exception(); // never called
});

optional<int> result = d2(42); // 2 * (42 + 1) == 86
assert(result.value() == 86);
```

# Usage
Usage of CallbackDispatcher is similar to boost::signals2. Each object of class CallbackDispatcher is like a signal. Class has template parameters for arguments and return value. Call method `add()` to add new listener, and call operator () on object to call all listeners.
```cpp
CallbackDispatcher<void()> dispatcher;
bool called = false;
auto f = [&](){called = true;};
dispatcher.add(f);
dispatcher();
REQUIRE(called);
```
To remove existing listener call remove with the same argument as add()
```cpp
called = false;
dispatcher.remove(f);
dispatcher();
REQUIRE(!called);
```

Removing by function itself without any additional objects is the main feature of CallbackDispatcher.

# Return value

Boost library provides aggregation functionality. CallbackDispatcher works differently. You can add a listener with one additional argument. The argument is called event and has type CallbackDispatcher::Event&. It does not contain data. It is some kind of iterator pointing to the next listener. You should call the method event->next() to pass control to the next listener.
```cpp
using Dispatcher = CallbackDispatcher<int(int)>;

Dispatcher dispatcher;
function<panda::optional<int> (Dispatcher::Event&, int)> cb = [](Event& e, int a) -> int {
    return 1 + e.next(a).value_or(0);
};
dispatcher.add_event_listener(cb);
dispatcher.add_event_listener([](Event& e, int a) -> int {
    return a + e.next(a).value_or(0);
});
REQUIRE(dispatcher(2).value_or(0) == 3);
```

Such listeners have control on arguments they pass to others and can do anything with return value. You can change arguments, aggregate return value, throw it away or even skip calling next.

There are no priorities. Listeners are called in order of storing. By default listeners are added to the end of the list so they are called in the same order they were added. You can change this by adding to the front of the list. To do so pass the second argument false to method add.

# Safe iteration

You can do anything  in listeners, e.g. remove itself from the callback dispatcher to prevent it from calling next time an event occurs. Also you can remove any other listeners. Special class called owning_list is used to store listeners. It guarantees that iterators are valid after removing any elements.


