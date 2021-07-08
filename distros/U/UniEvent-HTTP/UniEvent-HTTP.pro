TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

INCLUDEPATH += src/ ../UniEvent/src ../Protocol-HTTP/src/

SOURCES += \
    t/client/test-client-live.cc \
    t/client/test-client-pipeline.cc \
    t/client/test-client-pool.cc \
    t/client/test-client.cc \
    t/lib/MyTest.cc \
    t/lib/test.cc \
    src/panda/unievent/http/Client.cc \
    src/panda/unievent/http/compose.cc \
    src/panda/unievent/http/Pool.cc \
    src/panda/unievent/http/Server.cc \
    src/panda/unievent/http/ServerConnection.cc \
    src/xs/unievent/http.cc \
    t/client/basic.cc \
    t/client/keep-alive.cc \
    t/client/live.cc \
    t/client/partial.cc \
    t/client/pool.cc \
    t/client/redirect.cc \
    t/lib/test.cc \
    t/server/basic.cc \
    t/server/keep-alive.cc \
    t/server/partial.cc \
    t/server/pipeline.cc \
    t/server/version.cc

DISTFILES += \
    t/lib/MyTest.pm \
    t/client.t \
    t/pool.t \
    t/lib/MyTest.xs \
    HTTP.xs \
    HTTP.xsi \
    Request.xsi \
    Response.xsi \
    src/panda/unievent/http/Error.icc \
    src/panda/unievent/http/Request.icc \
    src/panda/unievent/http/ServerRequest.icc \
    src/panda/unievent/http/ServerResponse.icc \
    t/client/basic.t \
    t/client/keep-alive.t \
    t/client/live.t \
    t/client/partial.t \
    t/client/pool.t \
    t/client/redirect.t \
    t/client/regression.t \
    t/lib/MyTest.pm \
    t/server/basic.t \
    t/server/keep-alive.t \
    t/server/partial.t \
    t/server/pipeline.t \
    t/server/version.t \
    t/lib/MyTest.xs \
    Client.xsi \
    HTTP.xs \
    Pool.xsi \
    Response.xsi \
    ServerResponse.xsi

HEADERS += \
    src/panda/unievent/http.h \
    src/xs/unievent/http/client/XSRequest.h \
    src/xs/unievent/http.h \
    t/lib/test.h \
    src/panda/unievent/http/common/Response.h \
    src/panda/unievent/http/Client.h \
    src/panda/unievent/http/Error.h \
    src/panda/unievent/http/msg.h \
    src/panda/unievent/http/Pool.h \
    src/panda/unievent/http/Request.h \
    src/panda/unievent/http/Response.h \
    src/panda/unievent/http/Server.h \
    src/panda/unievent/http/ServerConnection.h \
    src/panda/unievent/http/ServerRequest.h \
    src/panda/unievent/http/ServerResponse.h \
    src/panda/unievent/http.h \
    src/xs/unievent/http.h \
    t/lib/test.h \
    Error.xsi \
    Request.xsi \
    Server.xsi \
    ServerRequest.xsi
