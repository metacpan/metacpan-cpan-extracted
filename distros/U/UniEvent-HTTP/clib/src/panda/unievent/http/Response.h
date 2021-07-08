#pragma once
#include "msg.h"

namespace panda { namespace unievent { namespace http {

struct Response : protocol::http::Response {
    Response () {}

    bool is_done () { return _is_done; }

private:
    friend struct Client;

    bool _is_done = false;
};
using ResponseSP = iptr<Response>;

}}}
