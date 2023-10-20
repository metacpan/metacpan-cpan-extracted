#pragma once

#include <uid2/timestamp.h>

#include <cstdint>
#include <vector>

namespace uid2 {
const int NO_KEYSET = -1;
struct Key {
    std::int64_t id_;
    int siteId_;
    int keysetId_;
    Timestamp created_;
    Timestamp activates_;
    Timestamp expires_;
    std::vector<std::uint8_t> secret_;

    bool IsActive(Timestamp asOf) const { return activates_ <= asOf && asOf < expires_; }
};
}  // namespace uid2
