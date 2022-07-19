// Copyright (c) 2021 The Trade Desk, Inc
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#pragma once

#include <cstdint>
#include <ostream>

namespace uid2
{
	class Timestamp
	{
	public:
		Timestamp() {}

		static Timestamp Now();
		static Timestamp FromEpochSecond(std::int64_t epochSeconds) { return FromEpochMilli(epochSeconds * 1000); }
		static Timestamp FromEpochMilli(std::int64_t epochMilli) { return Timestamp(epochMilli); }

		std::int64_t GetEpochSecond() const { return EpochMilli / 1000; }
		std::int64_t GetEpochMilli() const { return EpochMilli; }
		bool IsZero() const { return EpochMilli == 0; }

		Timestamp AddSeconds(int seconds) const { return Timestamp(EpochMilli + seconds * 1000); }
		Timestamp AddDays(int days) const { return AddSeconds(days * 24 * 60 * 60); }

		bool operator==(Timestamp other) const { return EpochMilli == other.EpochMilli; }
		bool operator!=(Timestamp other) const { return !operator==(other); }
		bool operator< (Timestamp other) const { return EpochMilli < other.EpochMilli; }
		bool operator<=(Timestamp other) const { return !other.operator<(*this); }
		bool operator> (Timestamp other) const { return other.operator<(*this); }
		bool operator>=(Timestamp other) const { return !operator<(other); }

	private:
		explicit Timestamp(std::int64_t epochMilli) : EpochMilli(epochMilli) {}

		std::int64_t EpochMilli = 0;

		inline friend std::ostream& operator<<(std::ostream& os, Timestamp ts) { return (os << ts.EpochMilli); }
	};
}
