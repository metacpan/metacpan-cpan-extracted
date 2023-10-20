#pragma once

#include <cstdint>
#include <vector>

namespace uid2 {
class BigEndianByteReader {
public:
    BigEndianByteReader(const std::uint8_t* byteArray, int size) : bytes_(byteArray), size_(size), position_(0) {}

    explicit BigEndianByteReader(const std::vector<std::uint8_t>& byteArray) : bytes_(byteArray.data()), size_(static_cast<int>(byteArray.size())), position_(0)
    {
    }

    BigEndianByteReader(const BigEndianByteReader&) = delete;
    BigEndianByteReader& operator=(const BigEndianByteReader&) = delete;

    int GetPosition() const { return position_; }
    int GetRemainingSize() const { return size_ - position_; }
    const std::uint8_t* GetCurrentData() const { return bytes_ + GetPosition(); }

    uint8_t ReadByte()
    {
        CheckCanRead(1);
        return bytes_[position_++];
    }

    void ReadBytes(std::uint8_t* buf, int start, int len)
    {
        CheckCanRead(len);
        while (len-- > 0) {
            buf[start++] = bytes_[position_++];
        }
    }

    std::int32_t ReadInt32()
    {
        CheckCanRead(sizeof(std::int32_t));
        std::int32_t value = bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        return value;
    }

    std::int64_t ReadInt64()
    {
        CheckCanRead(sizeof(std::int64_t));
        std::int64_t value = bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        value <<= 8;
        value |= bytes_[position_++];
        return value;
    }

private:
    void CheckCanRead(int n) const
    {
        if (size_ - position_ < n) {
            throw "insufficient bytes_ to read";
        }
    }

    const std::uint8_t* bytes_;
    int size_;
    int position_;
};

class BigEndianByteWriter {
public:
    BigEndianByteWriter(std::uint8_t* byteArray, int size) : bytes_(byteArray), size_(size), position_(0) {}

    explicit BigEndianByteWriter(std::vector<std::uint8_t>& byteArray) : bytes_(byteArray.data()), size_(static_cast<int>(byteArray.size())), position_(0) {}

    BigEndianByteWriter(const BigEndianByteWriter&) = delete;
    BigEndianByteWriter& operator=(const BigEndianByteWriter&) = delete;

    int GetPosition() const { return position_; }

    void WriteByte(std::uint8_t value)
    {
        CheckCanWrite(1);
        bytes_[position_++] = value;
    }

    void WriteBytes(const std::uint8_t* buf, int start, int len)
    {
        CheckCanWrite(len);
        while (len-- > 0) {
            bytes_[position_++] = buf[start++];
        }
    }

    void WriteInt32(std::int32_t value)
    {
        CheckCanWrite(sizeof(std::int32_t));
        if (bytes_ != nullptr) {
            bytes_[position_++] = (value >> 24) & 0xFF;
            bytes_[position_++] = (value >> 16) & 0xFF;
            bytes_[position_++] = (value >> 8) & 0xFF;
            bytes_[position_++] = (value)&0xFF;
        }
    }

    void WriteInt64(std::int64_t value)
    {
        CheckCanWrite(sizeof(std::int64_t));
        if (bytes_ != nullptr) {
            bytes_[position_++] = (value >> 56) & 0xFF;
            bytes_[position_++] = (value >> 48) & 0xFF;
            bytes_[position_++] = (value >> 40) & 0xFF;
            bytes_[position_++] = (value >> 32) & 0xFF;
            bytes_[position_++] = (value >> 24) & 0xFF;
            bytes_[position_++] = (value >> 16) & 0xFF;
            bytes_[position_++] = (value >> 8) & 0xFF;
            bytes_[position_++] = (value)&0xFF;
        }
    }

private:
    void CheckCanWrite(int n) const
    {
        if (size_ - position_ < n) {
            throw "insufficient bytes_ to write";
        }
    }

    std::uint8_t* bytes_;
    int size_;
    int position_;
};
}  // namespace uid2
