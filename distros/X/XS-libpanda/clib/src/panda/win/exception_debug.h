// adopted from https://github.com/boostorg/stacktrace/tree/develop/include/boost/stacktrace/detail
#pragma once

struct IDebugSymbols;
struct IDebugClient;
struct IDebugControl;

namespace panda {

class com_global_initer {
    bool _ok;

public:
    com_global_initer() noexcept;
    com_global_initer(const com_global_initer&) = delete;

    ~com_global_initer();
};

template <class T>
class com_holder {
    T* holder_;

public:
    com_holder(const com_global_initer&) noexcept : holder_(nullptr) {}

    T* operator->() const noexcept { return holder_; }

    void** to_void_ptr_ptr() noexcept {
        return reinterpret_cast<void**>(&holder_);
    }

    bool is_inited() const noexcept { return !!holder_; }

    ~com_holder() noexcept { if (holder_) { holder_->Release(); } }
};


class debugging_symbols{
private:
    debugging_symbols(const debugging_symbols&) = delete;

    static void try_init_com(com_holder< ::IDebugSymbols>& idebug, const com_global_initer& com) noexcept;

    static com_holder< ::IDebugSymbols>& get_thread_local_debug_inst() noexcept;

protected:
    com_holder< ::IDebugSymbols>& idebug_;
public:
    bool is_inited() const noexcept;
    debugging_symbols() noexcept;

};

}
