#pragma once
#include <vector>
#include <panda/memory.h>
#include <panda/string.h>
#include <panda/optional.h>
#include <panda/string_view.h>

namespace panda { namespace uri { namespace router {

using Captures = std::vector<string_view, DynamicInstanceAllocator<string_view>>;

struct Dfa {
    struct Result {
        size_t   nmatch;
        Captures captures;
    };

    Dfa() {}

    void compile(const std::vector<string>&);

    optional<Result> find(string_view);

private:
    struct CaptureBundle {
        uint16_t captures[8];
        uint16_t count;
    };

    struct CaptureRange {
        size_t from;
        size_t to;
    };

    struct State {
        struct Trans {
            uint16_t state;   // index in states
            uint16_t capture; // index in capture_bundles
        };
        uint16_t id;
        bool     final;
        uint16_t path;
        uint16_t eof_capture;
        Trans    trans[256];
    };

    void  fill_states(string_view ragel_machine);
    void  dump_states() const;

    std::vector<State>         states;
    uint16_t                   start_state;
    size_t                     captures_count;
    std::vector<CaptureBundle> capture_bundles;
    std::vector<CaptureRange>  capture_ranges;
};

}}}
