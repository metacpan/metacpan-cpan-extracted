#pragma once
#include "base64.h"

#include <string>
#include <vector>

namespace uid2 {

class UID2Base64UrlCoder {
public:
    static std::string Encode(const std::vector<uint8_t>& input) { return macaron::Base64::EncodeBase64URL(input); }

    static void Decode(const std::string& input, std::vector<uint8_t>& out) { return macaron::Base64::DecodeBase64URL(input, out); }
};
}  // namespace uid2
