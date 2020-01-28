#include <xs/catch.h>
#include <xs/Simple.h>
#include <string>
#include <vector>
#include <cxxabi.h>
#include <exception>

using panda::string_view;

namespace xs {

static std::vector<CatchHandler>       catch_handlers;
static std::vector<ExceptionProcessor> exception_processors;

static std::string get_type_name (const std::type_info& ti) {
    int status;
    char* class_name = abi::__cxa_demangle(ti.name(), NULL, NULL, &status);
    std::string ret = "[";
    if (status == 0) {
        ret += class_name;
        free(class_name);
    }
    else ret = "<unknown type>";
    ret += "]";
    return ret;
}

static Sv _exc2sv_default (const Sub&) {
    try { throw; }
    catch (SV* err)                  { return err; }
    catch (Sv& err)                  { return err; }
    catch (const char* err)          { return Simple(string_view(err)); }
    catch (const string_view& err)   { return Simple(err); }
    catch (const panda::string& err) { return Simple(err); }
    catch (const std::string& err)   { return Simple(string_view(err.data(), err.length())); }
    catch (std::exception& err) {
        dTHX;
        auto tn = get_type_name(typeid(err));
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " ");
        sv_catpv(errsv, err.what());
        return Sv::noinc(errsv);
    }
    catch (std::exception* err) {
        dTHX;
        auto tn = get_type_name(typeid(*err));
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " ");
        sv_catpv(errsv, err->what());
        return Sv::noinc(errsv);
    }
    catch (...) {
        dTHX;
        auto tn = get_type_name(*abi::__cxa_current_exception_type());
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " exception");
        return Sv::noinc(errsv);
    }
    return Sv();
}

static Sv _exc2sv_impl (const Sub& context, int i) {
    if (i < 0) return _exc2sv_default(context); // no 1 has catched the exception, apply defaults
    if (i >= (int)catch_handlers.size()) i = catch_handlers.size() - 1;
    try {
        auto ret = catch_handlers[i](context);
        if (ret) return ret;
    }
    catch (...) {}
    return _exc2sv_impl(context, i-1);
}

Sv _exc2sv (const Sub& context) {
    auto ex_sv = _exc2sv_impl(context, catch_handlers.size() - 1);
    for (auto& processor: exception_processors) {
        ex_sv = processor(ex_sv, context);
    }
    return ex_sv;
}

void add_catch_handler (CatchHandler h) {
    catch_handlers.push_back(h);
}

void add_catch_handler (CatchHandlerSimple h) {
    catch_handlers.push_back([h](const Sub&) -> Sv { return h(); });
}

void add_exception_processor(ExceptionProcessor f) {
    exception_processors.push_back(f);
}

void add_exception_processor(ExceptionProcessorSimple f) {
    exception_processors.push_back([f](Sv& ex, const Sub&) -> Sv { return f(ex); });
}


}
