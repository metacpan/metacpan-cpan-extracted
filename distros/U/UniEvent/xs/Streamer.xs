#include <xs/export.h>
#include <xs/unievent/Streamer.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace panda::unievent;
using namespace panda::unievent::streamer;
using panda::string;
using panda::string_view;

struct PerlStreamerInput : Streamer::IInput, Backref {
    using Super = Streamer::IInput;
    
    ErrorCode start (const LoopSP& loop) override {
        Object o = xs::out(this);
        return xs::in<ErrorCode>(o.call("start", xs::out(loop)));
    }
    
    void stop () override {
        Object o = xs::out(this);
        o.call("stop");
    }

    ErrorCode start_reading () override {
        Object o = xs::out(this);
        return xs::in<ErrorCode>(o.call("start_reading"));
    }
    
    void stop_reading () override {
        Object o = xs::out(this);
        o.call("stop_reading");
    }
    
    void handle_read (const string& data, const ErrorCode& err) { Super::handle_read(data, err); }
    void handle_eof  ()                                         { Super::handle_eof(); }
    
    ~PerlStreamerInput () { Backref::dtor(); }
};

struct PerlStreamerOutput : Streamer::IOutput, Backref {
    using Super = Streamer::IOutput;
    
    ErrorCode start (const LoopSP& loop) override {
        Object o = xs::out(this);
        return xs::in<ErrorCode>(o.call("start", xs::out(loop)));
    }
    
    void stop () override {
        Object o = xs::out(this);
        o.call("stop");
    }
    
    ErrorCode write (const string& data) override {
        Object o = xs::out(this);
        return xs::in<ErrorCode>(o.call("write", xs::out(data)));
    }
    
    size_t write_queue_size () const override {
        Object o = xs::out(this);
        return xs::in<size_t>(o.call("write_queue_size"));
    }
    
    void handle_write (const ErrorCode& err) { Super::handle_write(err); }
    
    ~PerlStreamerOutput () { Backref::dtor(); }
};

namespace xs {
    template <class TYPE> struct Typemap<PerlStreamerInput*, TYPE> : Typemap<panda::unievent::Streamer::IInput*, TYPE> {
        static panda::string package () { return "UniEvent::Streamer::Input"; }
    };
    template <class TYPE> struct Typemap<PerlStreamerOutput*, TYPE> : Typemap<panda::unievent::Streamer::IOutput*, TYPE> {
        static panda::string package () { return "UniEvent::Streamer::Output"; }
    };
}




MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer
PROTOTYPES: DISABLE

BOOT {
}

Streamer* Streamer::new (const Streamer::IInputSP& input, const Streamer::IOutputSP& output, size_t max_buf = 10000000, LoopSP loop = {}) {
    if (!loop) loop = Loop::default_loop();
    RETVAL = new Streamer(input, output, max_buf, loop);
}

void Streamer::start ()

void Streamer::stop ()

XSCallbackDispatcher* Streamer::finish_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->finish_event);
}

void Streamer::finish_callback (Streamer::finish_fn cb) {
    THIS->finish_event.remove_all();
    if (cb) THIS->finish_event.add(cb);
}




MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::Input
PROTOTYPES: DISABLE

BOOT {
     Stash(__PACKAGE__).inherit("UniEvent::Streamer::IInput");
}

PerlStreamerInput* PerlStreamerInput::new () {
    PROTO = Stash::from_name(CLASS).bless(Hash::create());
    RETVAL = new PerlStreamerInput();
}

void PerlStreamerInput::handle_read (string data, ErrorCode err = ErrorCode())

void PerlStreamerInput::handle_eof ()




MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::Output
PROTOTYPES: DISABLE

BOOT {
     Stash(__PACKAGE__).inherit("UniEvent::Streamer::IOutput");
}

PerlStreamerOutput* PerlStreamerOutput::new () {
    PROTO = Stash::from_name(CLASS).bless(Hash::create());
    RETVAL = new PerlStreamerOutput();
}


void PerlStreamerOutput::handle_write (ErrorCode err = ErrorCode())




MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::FileInput
PROTOTYPES: DISABLE

FileInput* FileInput::new (string_view path, size_t chunk_size = 1000000)



MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::FileOutput
PROTOTYPES: DISABLE

FileOutput* FileOutput::new (string_view path)




MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::StreamInput
PROTOTYPES: DISABLE

StreamInput* StreamInput::new (const StreamSP& s)



MODULE = UniEvent::Streamer                PACKAGE = UniEvent::Streamer::StreamOutput
PROTOTYPES: DISABLE

StreamOutput* StreamOutput::new (const StreamSP& s)
