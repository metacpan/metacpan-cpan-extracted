#pragma once
#include <type_traits>

namespace panda {

template <typename T> struct optional {
    ~optional() { reset(); }

    optional() : nullable_val(nullptr) {}
    
    optional(const T& val) : nullable_val(new (storage) T(val)) {}
    
    optional(const optional& oth) : nullable_val(oth ? new (storage) T(*oth) : nullptr) {}
    
    optional& operator=(optional const& oth) {
        if (&oth != this) {
            reset();
            if (oth)
                nullable_val = new (storage) T(*oth);
        }
        return *this;
    }
    
    optional& operator=(const T& val) {
        reset();
        nullable_val = new (storage) T(val);
        return *this;
    }

    void reset() {
        if (nullable_val)
            nullable_val->~T();
        nullable_val = nullptr;
    }

    T&       operator*() { return *nullable_val; }
    const T& operator*() const { return *nullable_val; }
    T*       operator->() { return nullable_val; }
    const T* operator->() const { return nullable_val; }

    T value_or(const T& default_val) const { return nullable_val ? *nullable_val : default_val; }

    T value() const { return *nullable_val; }

    explicit operator bool() const { return nullable_val != nullptr; }

    template< class F >
    constexpr auto and_then( F&& f ) const {
        if (nullable_val) {
            return f(*nullable_val);
        } else {
            return decltype(f(*nullable_val)){};
        }
    }

    template< class F >
    constexpr auto transform( F&& f ) const {
        using Ret = optional<typename std::remove_cv<decltype(f(*nullable_val))>::type>;
        if (nullable_val) {
            return Ret(f(*nullable_val));
        } else {
            return Ret();
        }
    }

    template< class F >
    constexpr optional or_else( F&& f ) const {
        if (nullable_val) {
            return *nullable_val;
        } else {
            return f();
        }
    }

private:
    T* nullable_val;
    alignas(alignof(T)) char storage[sizeof(T)];
};

template <typename T> struct optional_tools {
    using type = optional<T>;
    static type default_value () { return type{}; }
};

template <> struct optional_tools<void> {
    using type = void;
    static void default_value () {}
};

template <class T, class U> inline constexpr bool operator== (const optional<T>& lhs, const optional<U>& rhs) {
    return (lhs && rhs) ? (*lhs == *rhs) : (lhs || rhs ? false : true);
}
template <class T, class U> inline constexpr bool operator!= (const optional<T>& lhs, const optional<U>& rhs) { return !operator==(lhs, rhs); }

template <class T, class U>
inline constexpr bool operator< (const optional<T>& lhs, const optional<U>& rhs) {
    return (lhs && rhs) ? (*lhs < *rhs) : (rhs ? true : false);
}

template <class T, class U>
constexpr bool operator<= (const optional<T>& lhs, const optional<U>& rhs) {
    return (lhs && rhs) ? (*lhs < *rhs) : (lhs ? false : true);
}

template <class T, class U>
constexpr bool operator> (const optional<T>& lhs, const optional<U>& rhs) {
    return (lhs && rhs) ? (*lhs < *rhs) : (lhs ? true : false);
}

template <class T, class U>
constexpr bool operator>= (const optional<T>& lhs, const optional<U>& rhs) {
    return (lhs && rhs) ? (*lhs < *rhs) : (rhs ? false : true);
}

template <class T, class U> constexpr bool operator== (const optional<T>& opt, const U& value) { return opt && *opt == value; }
template <class T, class U> constexpr bool operator== (const T& value, const optional<U>& opt) { return opt && value == *opt; }
template <class T, class U> constexpr bool operator!= (const optional<T>& opt, const U& value) { return !operator==(opt, value); }
template <class T, class U> constexpr bool operator!= (const T& value, const optional<U>& opt) { return !operator==(value, opt); }
template <class T, class U> constexpr bool operator<  (const optional<T>& opt, const U& value) { return opt ? *opt < value : true; }
template <class T, class U> constexpr bool operator<  (const T& value, const optional<U>& opt) { return opt && value < *opt; }
template <class T, class U> constexpr bool operator<= (const optional<T>& opt, const U& value) { return opt ? *opt <= value : true; }
template <class T, class U> constexpr bool operator<= (const T& value, const optional<U>& opt) { return opt && value <= *opt; }
template <class T, class U> constexpr bool operator>  (const optional<T>& opt, const U& value) { return opt && *opt > value; }
template <class T, class U> constexpr bool operator>  (const T& value, const optional<U>& opt) { return opt ? value > *opt : true; }
template <class T, class U> constexpr bool operator>= (const optional<T>& opt, const U& value) { return opt && *opt >= value; }
template <class T, class U> constexpr bool operator>= (const T& value, const optional<U>& opt) { return opt ? value >= *opt : true; }

}
