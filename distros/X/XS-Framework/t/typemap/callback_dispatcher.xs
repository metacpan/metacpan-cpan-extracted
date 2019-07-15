#include <xs.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;

using panda::string;
using std::string_view;
using panda::CallbackDispatcher;
template <class T> using iptr = panda::iptr<T>;

struct NoTmStruct {
    string val;
};

struct SomeClass  : panda::Refcnt {};
struct SomeClass2 : panda::Refcnt {};

using cdVS      = CallbackDispatcher<void(string)>;
using cdIS      = CallbackDispatcher<int(string)>;
using cdIV      = CallbackDispatcher<int(void)>;
using cdVIref   = CallbackDispatcher<void(const int&)>;
using cdVPtrref = CallbackDispatcher<void(const panda::iptr<SomeClass>&)>;
using cdVV      = CallbackDispatcher<void()>;
using cdPtrPtr  = CallbackDispatcher<void(iptr<SomeClass>, iptr<SomeClass2>)>;
using cdNoTm    = CallbackDispatcher<NoTmStruct(NoTmStruct)>;

struct DispatchingObject {
    cdVS      vs;
    cdIV      iv;
    cdVIref   viref;
    cdVPtrref vptrref;
    cdIS      is;
    cdVV      vv;
    cdNoTm    notm;
    cdPtrPtr  ptrptr;
};

namespace xs {
    template <class TYPE> struct Typemap<DispatchingObject*,TYPE> : TypemapObject<DispatchingObject*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "MyTest::DispatchingObject"; }
    };

    template <class TYPE> struct Typemap<SomeClass*,TYPE> : TypemapObject<SomeClass*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "MyTest::SomeClass"; }
    };

    template <class TYPE> struct Typemap<SomeClass2*,TYPE> : TypemapObject<SomeClass2*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "MyTest::SomeClass2"; }
    };
}

MODULE = MyTest::Typemap::CD                PACKAGE = MyTest::DispatchingObject
PROTOTYPES: DISABLE

DispatchingObject* new (SV*)

XSCallbackDispatcher* DispatchingObject::vs (string_view type = string_view()) {
    if (type == "")
        RETVAL = XSCallbackDispatcher::create(THIS->vs);
    else if (type == "nullptr")
        RETVAL = XSCallbackDispatcher::create(THIS->vs, nullptr);
    else if (type == "pair_inout")
        RETVAL = XSCallbackDispatcher::create(THIS->vs, std::make_pair(
            [](string str)   { return Simple(str + " custom_out"); },
            [](const Sv& sv) { return xs::in<string>(sv) + " custom_in"; }
        ));
    else if (type == "pair_out")
        RETVAL = XSCallbackDispatcher::create(THIS->vs, std::make_pair(
            [](string str) { return Simple(str + " custom_out"); },
            nullptr
        ));
    else if (type == "pair_in")
        RETVAL = XSCallbackDispatcher::create(THIS->vs, std::make_pair(
            nullptr,
            [](const Sv& sv) { return xs::in<string>(sv) + " custom_in"; }
        ));
    else throw "wtf";
}

cdIV* DispatchingObject::iv () {
    RETVAL = &THIS->iv;
}

XSCallbackDispatcher* DispatchingObject::viref () {
    RETVAL = XSCallbackDispatcher::create(THIS->viref, std::make_pair(
        [](const int& v) { return xs::out<int>(v); },
        [](const Sv& sv) { return xs::in<int>(sv); }
    ));
}

cdVPtrref* DispatchingObject::vptrref () {
    RETVAL = &THIS->vptrref;
}

XSCallbackDispatcher* DispatchingObject::is (string_view type = string_view()) {
    if (type == "")
        RETVAL = XSCallbackDispatcher::create(THIS->is);
    else if (type == "nullptr")
        RETVAL = XSCallbackDispatcher::create(THIS->is, nullptr);
    else if (type == "ret_inout")
        RETVAL = XSCallbackDispatcher::create(THIS->is, std::make_pair(
            [](panda::optional<int> val) { return val ? Simple(*val + 100) : Simple::undef; },
            [](const Sv& sv)             { return xs::in<int>(sv) + 10; }
        ));
    else if (type == "ret_arg_inout")
        RETVAL = XSCallbackDispatcher::create(THIS->is, std::make_pair(
            [](panda::optional<int> val) { return val ? Simple(*val + 100) : Simple::undef; },
            [](const Sv& sv)             { return xs::in<int>(sv) + 10; }
        ), std::make_pair(
            [](string str)   { return Simple(str + " custom_out"); },
            [](const Sv& sv) { return xs::in<string>(sv) + " custom_in"; }
        ));
    else throw "wtf";
}

cdVV* DispatchingObject::vv () {
    RETVAL = &THIS->vv;
}

XSCallbackDispatcher* DispatchingObject::notm () {
    auto caster = std::make_pair(
        [](panda::optional<NoTmStruct> a) { return a ? Simple(a.value().val + "o") : Simple::undef; },
        [](const Sv& arg)                 { return NoTmStruct { xs::in<string>(arg) + "i" }; }
    );
    RETVAL = XSCallbackDispatcher::create(THIS->notm, caster, caster);
}

cdPtrPtr* DispatchingObject::ptrptr () {
    RETVAL = &THIS->ptrptr;
}
