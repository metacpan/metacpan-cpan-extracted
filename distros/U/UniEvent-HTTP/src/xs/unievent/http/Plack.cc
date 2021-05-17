#include "Plack.h"
#include <xs/protocol/http.h>

namespace xs { namespace unievent { namespace http {

using namespace panda;
using xs::protocol::http::strings_to_sv;

Plack::Plack (bool mp, bool mt) : multiprocess(mp), multithread(mt) {
    psgi_version = Array::create({Simple(1), Simple(1)});
    psgi_errors  = Stash("UniEvent::HTTP::Plack::ErrorHandle").bless(Hash::create());

    null_io                = eval("open my $fh, '<', \\''; $fh");
    string_io              = Sub::create("open my $fh, '<', \\$_[0]; return $fh");
    run_app                = Sub("Plack::Util::run_app");
    plack_real_fh          = Sub("Plack::Util::is_real_fh");
    read_real_fh           = Sub("UniEvent::HTTP::Plack::read_real_fh");
    input_record_separator = Stash("main")["/"].scalar();
}

void Plack::bind (const ServerSP& server, const Sub& app) {
    server->request_event.add([this, app](auto& request) {
        auto env = make_env(request);
        auto psgi_res = run_app.call(Ref::create(app), env);

        if (psgi_res.is_array_ref()) {
            respond_now(request, psgi_res);
        }
        else if (psgi_res.is_sub_ref()) {
            panda::function<Scalar(Array)> fn = [this, request](const Array& psgi_array) -> Scalar {
                return process_delayed_response(request, psgi_array);
            };
            Sub(psgi_res).call(xs::out(fn));
        }
        else {
            throw "bad psgi response";
        }
    });
}

Sv Plack::make_env (const ServerRequestSP& request) {
    auto sockaddr = request->sockaddr();
    auto peeraddr = request->peeraddr();

    auto env = Hash::create({
        {"REQUEST_METHOD",       Simple(ServerRequest::method_str(request->method()))},
        {"SCRIPT_NAME",          Simple("")},
        {"PATH_INFO",            Simple(request->uri->path_info())},
        {"REQUEST_URI",          Simple(request->uri->to_string())},
        {"QUERY_STRING",         Simple(request->uri->query_string())},
        {"SERVER_PROTOCOL",      request->http_version == 11 ? Simple("HTTP/1.1") : Simple("HTTP/1.0")},
        {"SERVER_NAME",          Simple(sockaddr.ip())},
        {"SERVER_PORT",          Simple(sockaddr.port())},
        {"REMOTE_ADDR",          Simple(peeraddr.ip())},
        {"REMOTE_PORT",          Simple(peeraddr.port())},
        {"psgi.url_scheme",      request->is_secure() ? Simple("https") : Simple("http")},
        {"psgi.version",         Ref::create(psgi_version)},
        {"psgi.errors",          Ref::create(psgi_errors)},
        {"psgi.nonblocking",     &PL_sv_yes},
        {"psgix.input.buffered", &PL_sv_yes},
        {"psgi.multiprocess",    multiprocess ? &PL_sv_yes : &PL_sv_no},
        {"psgi.multithread",     multithread  ? &PL_sv_no  : &PL_sv_yes},
        {"psgi.run_once",        &PL_sv_no},
        {"psgi.streaming",       &PL_sv_yes},
    });

    env.reserve(env.size() + request->headers.size());

    for (const auto& elem : request->headers.fields) {
        auto len = elem.name.length();
        auto ptr = elem.name.data();

        char key[len+5];
        key[0] = 'H'; key[1] = 'T'; key[2] = 'T'; key[3] = 'P'; key[4] = '_';
        for (size_t i = 0; i < len; ++i) key[i+5] = ptr[i] == '-' ? '_' : ::toupper(ptr[i]);

        if (len >= 12 && key[5] == 'C' && key[6] == 'O' && key[7] == 'N' && key[8] == 'T') {
            if (string_view(key+9, len-4) == "ENT_LENGTH" || string_view(key+9, len-4) == "ENT_TYPE") {
                env.store(string_view(key+5, len), Simple(elem.value));
                continue;
            }
        }

        auto sv = env[string_view(key, len+5)];
        if (!sv.defined()) {
            sv_setpvn(sv, elem.value.data(), elem.value.length());
        } else {
            sv_catpvs(sv, ", ");
            sv_catpvn(sv, elem.value.data(), elem.value.length());
        }
    }

    env.store("psgi.input",
        request->body.length() ?
            string_io.call(strings_to_sv(request->body.parts)) :
            (Scalar)Ref::create(null_io)
    );

    return Ref::create(env);
}

ServerResponseSP Plack::create_response (Simple code, Array headers) {
    ServerResponseSP res = new ServerResponse(code);

    auto hsize = headers.size();
    for (size_t i = 0; i+1 < hsize; i += 2) {
        res->headers.add(Simple(headers[i]).as_string(), Simple(headers[i+1]).as_string());
    }

    return res;
}

void Plack::respond_now (const ServerRequestSP& request, const Array& psgi_res) {
    if (psgi_res.size() < 3) throw "bad psgi response array: should contain 3 elements";
    auto res = create_response(psgi_res[0], psgi_res[1]);

    Sv psgi_body = psgi_res[2];
    if (psgi_body.is_array_ref()) {
        Array body_list = psgi_body;
        auto& body = res->body;
        for (const auto& elem : body_list) {
            body.parts.push_back(Simple(elem).as_string());
        }
    }
    else if (plack_real_fh.call(psgi_body).is_true()) {
        //TODO async via streamer
        auto content = read_real_fh.call<Simple>(psgi_body);
        res->body.parts.push_back(content.as_string());
    }
    else if (psgi_body.is_object_ref()) {
        Object obj = psgi_body;
        Sub sub;
        if ((sub = obj.method("string_ref"))) {
            // optimize IO::String to not use its incredibly slow getline
            size_t pos = obj.call<Simple>("tell");
            auto strsv = Simple(sub.call<Ref>(obj.ref()).value());
            string_view str = strsv;
            res->body.parts.push_back(string(str.data() + pos, str.length() - pos));
        }
        else {
            auto tmp = Sv::create();
            sv_setsv(tmp, input_record_separator);
            sv_setsv(input_record_separator, Ref::create(Simple(32 * 1024)));
            string data;
            sub = obj.method("getline");
            Simple buf;
            while ((buf = sub.call(obj.ref())).defined()) {
                data += (string_view)buf;
            }
            res->body.parts.push_back(data);
            obj.call("close");
            sv_setsv(input_record_separator, tmp);
        }
    }
    else {
        throw "invalid body";
    }

    request->respond(res);
}

Scalar Plack::process_delayed_response (const ServerRequestSP& request, const Array& psgi_res) {
    if (psgi_res.size() >= 3) {
        respond_now(request, psgi_res);
        return Scalar::undef;
    }

    if (psgi_res.size() < 2) throw "bad psgi delayed response array: should contain at least 2 elements";
    auto res = create_response(psgi_res[0], psgi_res[1]);
    res->chunked = true;
    request->respond(res);
    return xs::out(new PlackWriter(res));
}

}}}
