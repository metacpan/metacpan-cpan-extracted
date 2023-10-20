#pragma once

#include <cstdint>
#include <ostream>

namespace uid2 {
class Timestamp {
public:
    Timestamp() = default;

    static Timestamp Now();
    static Timestamp FromEpochSecond(std::int64_t epochSeconds) { return FromEpochMilli(epochSeconds * 1000); }
    static Timestamp FromEpochMilli(std::int64_t epochMilli) { return Timestamp(epochMilli); }

    std::int64_t GetEpochSecond() const { return epochMilli_ / 1000; }
    std::int64_t GetEpochMilli() const { return epochMilli_; }
    bool IsZero() const { return epochMilli_ == 0; }

    Timestamp AddSeconds(std::int64_t seconds) const { return Timestamp(epochMilli_ + seconds * 1000); }
    Timestamp AddDays(int days) const { return AddSeconds(static_cast<std::int64_t>(days) * 24 * 60 * 60); }

    bool operator==(Timestamp other) const { return epochMilli_ == other.epochMilli_; }
    bool operator!=(Timestamp other) const { return !operator==(other); }
    bool operator<(Timestamp other) const { return epochMilli_ < other.epochMilli_; }
    bool operator<=(Timestamp other) const { return !other.operator<(*this); }
    bool operator>(Timestamp other) const { return other.operator<(*this); }
    bool operator>=(Timestamp other) const { return !operator<(other); }

private:
    explicit Timestamp(std::int64_t epochMilli) : epochMilli_(epochMilli) {}

    std::int64_t epochMilli_ = 0;

    inline friend std::ostream& operator<<(std::ostream& os, Timestamp ts) { return (os << ts.epochMilli_); }
};
}  // namespace uid2
