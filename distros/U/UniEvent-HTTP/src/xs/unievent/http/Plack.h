#pragma once
#include <xs.h>
#include <panda/unievent/http/Server.h>

namespace xs { namespace unievent { namespace http {

using namespace panda::unievent::http;

struct Plack {
    Plack (bool multiprocess, bool multithread);

    void bind (const ServerSP&, const Sub&);

private:
    Array  psgi_version;
    Object psgi_errors;
    Io     null_io;
    Sub    string_io;
    Sub    run_app;
    Sub    plack_real_fh;
    Sub    read_real_fh;
    Scalar input_record_separator;
    bool   multiprocess;
    bool   multithread;

    Sv make_env (const ServerRequestSP&);

    ServerResponseSP create_response (Simple code, Array headers);

    void respond_now (const ServerRequestSP& request, const Array& psgi_res);

    Scalar process_delayed_response (const ServerRequestSP& request, const Array& psgi_res);
};

struct PlackWriter {
    ServerResponseSP response;

    PlackWriter (const ServerResponseSP& res) : response(res) {}

    void write (const panda::string& data) {
        response->send_chunk(data);
    }

    void close () {
        if (!response) return;
        response->send_final_chunk();
        response.reset();
    }

    ~PlackWriter () noexcept(false) {
        close();
    }
};

}}}

namespace xs {
    template <> struct Typemap<xs::unievent::http::Plack*> : TypemapObject<xs::unievent::http::Plack*, xs::unievent::http::Plack*, ObjectTypePtr, ObjectStorageMG> {
        static panda::string package () { return "UniEvent::HTTP::Plack"; }
    };
    template <> struct Typemap<xs::unievent::http::PlackWriter*> : TypemapObject<xs::unievent::http::PlackWriter*, xs::unievent::http::PlackWriter*, ObjectTypePtr, ObjectStorageMG> {
        static panda::string package () { return "UniEvent::HTTP::Plack::Writer"; }
    };
}
