#pragma once
#include "BackendHandle.h"
#include "backend/FsEventImpl.h"

namespace panda { namespace unievent {

struct IFsEventListener {
    virtual void on_fs_event (const FsEventSP&, const string_view& file, int events, const std::error_code&) = 0;
};

struct IFsEventSelfListener : IFsEventListener {
    virtual void on_fs_event (const string_view& file, int events, const std::error_code&) = 0;
    void on_fs_event (const FsEventSP&, const string_view& file, int events, const std::error_code& err) override { on_fs_event(file, events, err); }
};

struct FsEvent : virtual BackendHandle, private backend::IFsEventImplListener {
    using FsEventImpl   = backend::FsEventImpl;
    using Event         = FsEventImpl::Event;
    using Flags         = FsEventImpl::Flags;
    using fs_event_fptr = void(const FsEventSP&, const string_view& file, int events, const std::error_code&);
    using fs_event_fn   = function<fs_event_fptr>;
    
    CallbackDispatcher<fs_event_fptr> event;

    FsEvent (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_fs_event(this));
    }

    const HandleType& type () const override;

    IFsEventListener* event_listener () const              { return _listener; }
    void              event_listener (IFsEventListener* l) { _listener = l; }

    const string& path () const { return _path; }

    virtual void start (const string_view& path, int flags = 0, fs_event_fn callback = nullptr);
    virtual void stop  ();

    void reset () override;
    void clear () override;

    static const HandleType TYPE;

private:
    string            _path;
    IFsEventListener* _listener;

    void handle_fs_event (const string_view& file, int events, const std::error_code&) override;

    FsEventImpl* impl () const { return static_cast<FsEventImpl*>(_impl); }
};

}}
