#include <xs/catch.h>
#include <xs/Simple.h>
#include <string>
#include <vector>
#include <cxxabi.h>
#include <exception>

using std::string_view;

namespace xs {

static std::vector<CatchHandler> catch_handlers;

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

static Sv _exc2sv_default (pTHX_ const Sub&) {
    try { throw; }
    catch (SV* err)                  { return err; }
    catch (Sv& err)                  { return err; }
    catch (const char* err)          { return Simple(string_view(err)); }
    catch (const string_view& err)   { return Simple(err); }
    catch (const panda::string& err) { return Simple(err); }
    catch (const std::string& err)   { return Simple(string_view(err.data(), err.length())); }
    catch (std::exception& err) {
        auto tn = get_type_name(typeid(err));
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " ");
        sv_catpv(errsv, err.what());
        return Sv::noinc(errsv);
    }
    catch (std::exception* err) {
        auto tn = get_type_name(typeid(*err));
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " ");
        sv_catpv(errsv, err->what());
        return Sv::noinc(errsv);
    }
    catch (...) {
        auto tn = get_type_name(*abi::__cxa_current_exception_type());
        SV* errsv = newSVpv(tn.data(), 0);
        sv_catpv(errsv, " exception");
        return Sv::noinc(errsv);
    }
    return Sv();
}

static Sv _exc2sv_impl (pTHX_ const Sub& context, int i) {
    if (i < 0) return _exc2sv_default(aTHX_ context); // no 1 has catched the exception, apply defaults
    if (i >= (int)catch_handlers.size()) i = catch_handlers.size() - 1;
    try {
        auto ret = catch_handlers[i](context);
        if (ret) return ret;
    }
    catch (...) {}
    return _exc2sv_impl(aTHX_ context, i-1);
}

Sv _exc2sv (pTHX_ const Sub& context) { return _exc2sv_impl(aTHX_ context, catch_handlers.size() - 1); }

void add_catch_handler (CatchHandler h) {
    catch_handlers.push_back(h);
}

void add_catch_handler (CatchHandlerSimple h) {
    catch_handlers.push_back([h](const Sub&) -> Sv { return h(); });
}

}
