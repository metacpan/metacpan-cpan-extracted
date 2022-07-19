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

#include <uid2/types.h>

#include "key.h"

#include <string>

struct EncryptTokenParams
{
	EncryptTokenParams() = default;
	EncryptTokenParams& WithTokenExpiry(uid2::Timestamp expiry) { tokenExpiry = expiry; return *this; }

	uid2::Timestamp tokenExpiry = uid2::Timestamp::Now().AddSeconds(60);
    uid2::IdentityScope identityScope = uid2::IdentityScope::UID2;
    uid2::IdentityType identityType = uid2::IdentityType::Email;
};

std::string EncryptTokenV2(const std::string& identity, const uid2::Key& masterKey, int siteId, const uid2::Key& siteKey, EncryptTokenParams params = EncryptTokenParams());
std::string EncryptTokenV3(const std::string& identity, const uid2::Key& masterKey, int siteId, const uid2::Key& siteKey, EncryptTokenParams params = EncryptTokenParams());

std::string EncryptDataV2(const std::vector<std::uint8_t>& data, const uid2::Key& key, int siteId, uid2::Timestamp now);
