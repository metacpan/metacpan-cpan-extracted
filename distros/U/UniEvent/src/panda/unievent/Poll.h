#pragma once
#include "BackendHandle.h"
#include "backend/PollImpl.h"

namespace panda { namespace unievent {

struct IPollListener {
    virtual void on_poll (const PollSP&, int events, const std::error_code&) = 0;
};

struct IPollSelfListener : IPollListener {
    virtual void on_poll (int events, const std::error_code&) = 0;
    void on_poll (const PollSP&, int events, const std::error_code& err) override { on_poll(events, err); }
};

struct Poll : virtual BackendHandle, private backend::IPollImplListener {
    using poll_fptr = void(const PollSP& handle, int events, const std::error_code& err);
    using poll_fn = panda::function<poll_fptr>;

    enum {
      READABLE = 1,
      WRITABLE = 2
    };

    struct Socket { sock_t val; };
    struct Fd     { int    val; };

    CallbackDispatcher<poll_fptr> event;

    Poll (Socket sock, const LoopSP& loop = Loop::default_loop(), Ownership ownership = Ownership::TRANSFER);
    Poll (Fd       fd, const LoopSP& loop = Loop::default_loop(), Ownership ownership = Ownership::TRANSFER);

    const HandleType& type () const override;

    IPollListener* event_listener () const           { return _listener; }
    void           event_listener (IPollListener* l) { _listener = l; }

    virtual void start (int events, poll_fn callback = nullptr);
    virtual void stop  ();

    void reset () override;
    void clear () override;

    void call_now (int events, const std::error_code& err = {}) { handle_poll(events, err); }

    optional<fh_t> fileno () const { return _impl ? impl()->fileno() : optional<fh_t>(); }

    static const HandleType TYPE;

private:
    IPollListener* _listener;

    void handle_poll (int events, const std::error_code& err) override;

    backend::PollImpl* impl () const { return static_cast<backend::PollImpl*>(_impl); }
};

}}
