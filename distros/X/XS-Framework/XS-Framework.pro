TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

INCLUDEPATH += src/ ../CPP-panda-lib/src/

SOURCES += main.cc \
    src/xs/Array.cc \
    src/xs/basic.cc \
    src/xs/CallProxy.cc \
    src/xs/catch.cc \
    src/xs/Glob.cc \
    src/xs/Hash.cc \
    src/xs/KeyProxy.cc \
    src/xs/Object.cc \
    src/xs/Scalar.cc \
    src/xs/Simple.cc \
    src/xs/Stash.cc \
    src/xs/Sub.cc \
    src/xs/Sv.cc \
    t/Array.cc \
    t/CallProxy.cc \
    t/catch.cc \
    t/Glob.cc \
    t/Hash.cc \
    t/Object.cc \
    t/Ref.cc \
    t/Scalar.cc \
    t/Simple.cc \
    t/Stash.cc \
    t/Sub.cc \
    t/Sv.cc \
    Framework.cc

DISTFILES += \
    t/lib/PXSTest.pm \
    t/src/test.xsi \
    t/src/typemap-child.xsi \
    t/src/typemap-mg-avhv.xsi \
    t/src/typemap-mg-join.xsi \
    t/src/typemap-mg-mixin.xsi \
    t/src/typemap-mg-threads.xsi \
    t/src/typemap-primitives.xsi \
    t/src/typemap-refcnt-shared.xsi \
    t/src/typemap-refs.xsi \
    t/src/typemap-single.xsi \
    t/src/typemap-static_cast.xsi \
    t/src/typemap-svapi.xsi \
    t/src/typemap-xsbackref.xsi \
    Changes \
    Framework.bs \
    Framework.xs \
    typemap \
    typemap32 \
    typemap64 \
    t/00-XS-Framework.t \
    t/01-payload.t \
    t/02-upgrade.t \
    t/03-typemap-primitives.t \
    t/04-typemap-refs.t \
    t/06-typemap-obj-single.t \
    t/07-typemap-obj-child.t \
    t/08-typemap-obj-refcnt-shared.t \
    t/09-typemap-obj-static_cast.t \
    t/10-typemap-oext-join.t \
    t/11-typemap-oext-mixin.t \
    t/12-typemap-oext-avhv.t \
    t/13-typemap-oext-threads.t \
    t/15-typemap-obj-xsbackref.t \
    t/17-typemap-xsbackref-threads.t \
    t/19-typemap-svapi.t \
    t/cpp.t \
    XSCallbackDispatcher.xsi \
    t/src/callback_dispatcher.xsi \
    t/function.xsi \
    src/xs/function.t \
    t/function.t

HEADERS += \
    src/xs/Array.h \
    src/xs/Backref.h \
    src/xs/basic.h \
    src/xs/CallProxy.h \
    src/xs/catch.h \
    src/xs/Glob.h \
    src/xs/Hash.h \
    src/xs/HashEntry.h \
    src/xs/KeyProxy.h \
    src/xs/Object.h \
    src/xs/ppport.h \
    src/xs/Ref.h \
    src/xs/Scalar.h \
    src/xs/Simple.h \
    src/xs/Stash.h \
    src/xs/Sub.h \
    src/xs/Sv.h \
    src/xs/typemap.h \
    src/xs/CallbackDispatcher.h \
    src/xs.h \
    t/src/backref.h \
    t/src/mixin.h \
    t/src/mybase.h \
    t/src/myother.h \
    t/src/myrefcounted.h \
    t/src/mystatic.h \
    t/src/mythreads.h \
    t/src/test.h \
    t/src/xstest.h \
    t/src/callback_dispatcher.h
