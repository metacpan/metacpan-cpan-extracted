#pragma once
#include <panda/string.h>
#include <memory>
#include "../../../ragel/inputdata.h"
#include "../../../ragel/parsedata.h"

namespace panda { namespace uri { namespace router {

struct RagelHelper {
    RagelHelper(panda::string_view in);
    ~RagelHelper();
    using InputDataSP = std::unique_ptr<InputData>;
    InputDataSP input_data;

    ParseData *parse_data;
};

}}}
