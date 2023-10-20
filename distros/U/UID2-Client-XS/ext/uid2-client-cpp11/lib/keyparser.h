#pragma once

#include "keycontainer.h"

#include <string>

namespace uid2 {
class KeyParser {
public:
    static bool TryParse(const std::string& jsonString, KeyContainer& out_container, std::string& out_err);
};
}  // namespace uid2
