#include "Error.h"

namespace panda { namespace unievent { namespace websocket {

class WSErrorCategory : public std::error_category
{
public:
    const char * name() const noexcept override {return "unievent::websocket::Error";}
    std::string message(int ev) const override {
        switch (ev) {
        case (int)errc::READ_ERROR:    return "read error";
        case (int)errc::WRITE_ERROR:   return "write error";
        case (int)errc::CONNECT_ERROR: return "connect error";
        default: return "unknown ws error";
        }
    }
};

const std::error_category& ws_error_category = WSErrorCategory();

log::Module panda_log_module("UniEvent::WebSocket", log::Level::Notice);

}}}
