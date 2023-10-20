#include <uid2/timestamp.h>

#include <chrono>

namespace uid2 {
Timestamp Timestamp::Now()
{
    return Timestamp(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count());
}
}  // namespace uid2
