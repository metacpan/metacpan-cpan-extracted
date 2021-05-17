#include "Form.h"
#include "Request.h"
#include "Client.h"

namespace panda { namespace unievent { namespace http {

void IFormItem::produce(const Chunk &chunk, Client& out) noexcept {
    out.send_chunk(chunk);
}

bool FormField::start(proto::Request &req, Client &out)  {
    produce(req.form_field(name, content), out);
    return true;
}

bool FormEmbeddedFile::start(proto::Request &req, Client &out)  {
    produce(req.form_file(name, filename, mime_type), out);
    produce(req.form_data(content), out);
    return true;
}


bool FormFile::start(proto::Request& req, Client& out)  {
    Streamer::IOutputSP out_stream = new ClientOutput(ClientSP(&out), proto::RequestSP(&req));
    streamer = new Streamer(std::move(in), out_stream, max_buf, out.loop());
    streamer->finish_event.add([&](auto& error_code){
        out.form_file_complete(error_code);
    });
    streamer->start();
    produce(req.form_file(name, filename, mime_type), out);
    return false;
}

void FormFile::stop()  {
    streamer->stop();
    streamer.reset();
}

ErrorCode FormFile::ClientOutput::write (const string& data) {
    auto chunk = req->form_data(data);
    for (auto& piece : chunk) {
        streamer::StreamOutput::write(piece);
    }
    return {};
}


}}}
