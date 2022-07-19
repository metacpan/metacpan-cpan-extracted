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

#include "keycontainer.h"

#include <uid2/timestamp.h>
#include <uid2/types.h>

#include <cstdint>
#include <vector>

namespace uid2
{
	DecryptionResult DecryptToken(
		const std::string& token,
		const KeyContainer& keys,
		Timestamp now,
        IdentityScope identityScope,
		bool checkValidity);
	DecryptionResult DecryptToken(
		const std::vector<std::uint8_t>& encryptedId,
		const KeyContainer& keys,
		Timestamp now,
        IdentityScope identityScope,
		bool checkValidity);

	EncryptionDataResult EncryptData(
		const EncryptionDataRequest& req,
		const KeyContainer* keys,
        IdentityScope identityScope);

	DecryptionDataResult DecryptData(
		const std::vector<std::uint8_t>& encryptedBytes,
		const KeyContainer& keys,
        IdentityScope identityScope);

    void RandomBytes(std::uint8_t* out, int count);

    int EncryptGCM(const std::uint8_t* data, int size, const std::uint8_t* secret, std::uint8_t* out_encrypted);
    int DecryptGCM(const std::uint8_t* encrypted, int size, const std::uint8_t* secret, std::uint8_t* out_decrypted);
}
