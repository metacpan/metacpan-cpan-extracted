#pragma once
#include "memory.h"
#include "string.h"
#include "varint.h"
#include "refcnt.h"
#include "expected.h"
#include <iosfwd>
#include <system_error>

namespace panda { namespace error {

struct ErrorCode : AllocatedObject<ErrorCode> {
    ErrorCode () noexcept {}

    ErrorCode (const ErrorCode& o) noexcept : data(o.data)            {}
    ErrorCode (ErrorCode&&      o) noexcept : data(std::move(o.data)) {}

    ErrorCode (int ec, const std::error_category& cat) noexcept { if (ec) set(std::error_code(ec, cat)); }

    ErrorCode (const std::error_code& ec) noexcept { if (ec) set(ec); }

    template <class N, typename = std::enable_if_t<std::is_error_code_enum<N>::value, void>>
    ErrorCode (N e) noexcept : ErrorCode(std::error_code(e)) {}

    ErrorCode (const std::error_code& ec, const std::error_code& next) noexcept { set(ec, next); }
    ErrorCode (const std::error_code& ec, const ErrorCode&       next) noexcept { set(ec, next); }

    ErrorCode& operator= (const ErrorCode& o) noexcept { data = o.data; return *this; }
    ErrorCode& operator= (ErrorCode&& o)      noexcept { data = std::move(o.data); return *this; }

    ErrorCode& operator= (const std::error_code& ec) {
        if (ec) set(ec);
        else clear();
        return *this;
    }

    template <class N, typename = std::enable_if_t<std::is_error_code_enum<N>::value, void>>
    ErrorCode& operator= (N e) noexcept {
        set(std::error_code(e));
        return *this;
    }

    void clear () noexcept {
        data.reset();
    }

    explicit operator bool () const noexcept { return data; }

    std::error_code code () const noexcept {
        if (!data) return {};
        return std::error_code(data->codes.top(), data->cat->self);
    };

    int value () const noexcept {
        if (!data) return 0;
        return data->codes.top();
    }

    const std::error_category& category () const noexcept {
        if (!data) return std::system_category();
        return data->cat->self;
    }

    std::error_condition default_error_condition () const noexcept {
        return code().default_error_condition();
    }

    std::string message () const;

    ErrorCode next () const noexcept;

    string what () const;

    bool contains (const std::error_code& c) const {
        if (!data) {
            return !c;
        }
        return contains_impl(c);
    }

    // any user can add specialization for his own result and get any data
    template <typename T = void, typename... Args>
    T private_access(Args...);

    template <typename T = void, typename... Args>
    T private_access(Args...) const;

    struct NestedCategory {
        const std::error_category& self;
        const NestedCategory*      next;
    };

private:
    struct Data : Refcnt, AllocatedObject<Data> {
        using CodeStack = VarIntStack;
        CodeStack codes;
        const NestedCategory* cat;
    };

    iptr<Data> data;

    void init ();
    void set  (const std::error_code& ec);
    void set  (const std::error_code& ec, const std::error_code& next);
    void set  (const std::error_code& ec, const ErrorCode& next);
    void push (const std::error_code&);
    bool contains_impl (const std::error_code& c) const;
};

inline bool operator== (const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return lhs.code() == rhs.code(); }
inline bool operator== (const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() == rhs; }
inline bool operator== (const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs == rhs.code(); }
inline bool operator== (const ErrorCode& lhs, const std::error_condition& rhs) noexcept { return lhs.code() == rhs; }
inline bool operator== (const std::error_condition& lhs, const ErrorCode& rhs) noexcept { return lhs == rhs.code(); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator== (const ErrorCode& ec, E e) noexcept { return ec.code() == make_error_code(e); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator== (E e, const ErrorCode& ec) noexcept { return ec.code() == make_error_code(e); }

inline bool operator!= (const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return lhs.code() != rhs.code(); }
inline bool operator!= (const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() != rhs; }
inline bool operator!= (const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs != rhs.code(); }
inline bool operator!= (const ErrorCode& lhs, const std::error_condition& rhs) noexcept { return lhs.code() != rhs; }
inline bool operator!= (const std::error_condition& lhs, const ErrorCode& rhs) noexcept { return lhs != rhs.code(); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator!= (const ErrorCode& ec, E e) noexcept { return ec.code() != make_error_code(e); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator!= (E e, const ErrorCode& ec) noexcept { return ec.code() != make_error_code(e); }

inline bool operator< (const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return lhs.code() < rhs.code(); }
inline bool operator< (const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() < rhs; }
inline bool operator< (const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs < rhs.code(); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator< (const ErrorCode& ec, E e) noexcept { return ec.code() < make_error_code(e); }
template <class E, typename = std::enable_if_t<std::is_error_code_enum<E>::value || std::is_error_condition_enum<E>::value, void>>
inline bool operator< (E e, const ErrorCode& ec) noexcept { return make_error_code(e) < ec.code(); }

std::ostream& operator<< (std::ostream&, const ErrorCode&);

namespace details {
    inline string error_message(const ErrorCode& e) {
        return e.what();
    }

    inline string error_message(const std::error_code& e) {
        auto r = e.message();
        return string(r.data(), r.size());
    }

    template <typename E>
    struct bad_expected_access_code : std::exception {
        explicit bad_expected_access_code (E e) : _val(std::move(e)) {}

        virtual const char* what () const noexcept override {
            if (_message.empty()) {
                _message = "Bad expected access: " + error_message(_val);
            }
            return _message.c_str();
        }

        const E&  error () const &  { return _val; }
        const E&& error () const && { return std::move(_val); }

        E&  error () &  { return _val; }
        E&& error () && { return std::move(_val); }

    private:
        E _val;
        mutable std::string _message;
    };
}

}}

namespace panda {
    using ErrorCode = error::ErrorCode;

    template <>
    struct bad_expected_access<ErrorCode> : error::details::bad_expected_access_code<ErrorCode> {
        using bad_expected_access_code::bad_expected_access_code;
    };

    template <>
    struct bad_expected_access<std::error_code> : error::details::bad_expected_access_code<std::error_code> {
        using bad_expected_access_code::bad_expected_access_code;
    };
}

namespace std {
    template<> struct hash<panda::ErrorCode> {
        typedef panda::ErrorCode argument_type;
        typedef std::size_t result_type;

        result_type operator()(argument_type const& c) const noexcept { return std::hash<std::error_code>{}(c.code()); }
    };
}
