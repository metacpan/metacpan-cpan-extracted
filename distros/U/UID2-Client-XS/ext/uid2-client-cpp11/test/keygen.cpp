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

#include "keygen.h"

#include "aes.h"
#include "base64.h"
#include "bigendianprocessor.h"
#include "uid2encryption.h"

#include <algorithm>
#include <cstring>
#include <functional>
#include <random>
#include <vector>

using namespace uid2;

static void AddPkcs7Padding(std::vector<std::uint8_t>& data)
{
	const std::uint8_t padlen = 16 - (std::uint8_t)(data.size() % 16);
	for (std::uint8_t i = 0; i < padlen; ++i) data.push_back(padlen);
}

static std::vector<std::uint8_t> EncryptImpl(std::vector<std::uint8_t>& data, const std::uint8_t* iv, const std::vector<std::uint8_t>& secret)
{
	AddPkcs7Padding(data);
	std::vector<std::uint8_t> result(16 + data.size());
	std::memcpy(result.data(), iv, 16);
	AES256 aes;
	aes.EncryptCBC(data.data(), data.size(), secret.data(), iv, result.data() + 16);
	return result;
}

std::string EncryptTokenV2(const std::string& identity, const Key& masterKey, int siteId, const Key& siteKey, EncryptTokenParams params)
{
	std::random_device rd;
	std::vector<std::uint8_t> identityBuffer(4 + 4 + identity.size() + 4 + 8);
	BigEndianByteWriter identityWriter(identityBuffer.data(), identityBuffer.size());
	identityWriter.WriteInt32(siteId);
	identityWriter.WriteInt32(identity.size());
	identityWriter.WriteBytes((const std::uint8_t*)identity.data(), 0, identity.size());
	identityWriter.WriteInt32(0);
	identityWriter.WriteInt64(Timestamp::Now().AddSeconds(-60).GetEpochMilli());
	std::uint8_t identityIv[16];
	std::generate(identityIv, identityIv + sizeof(identityIv), std::ref(rd));
	const auto encryptedIdentity = EncryptImpl(identityBuffer, identityIv, siteKey.secret);

	std::vector<std::uint8_t> masterBuffer(8 + 4 + encryptedIdentity.size());
	BigEndianByteWriter masterWriter(masterBuffer.data(), masterBuffer.size());
	masterWriter.WriteInt64(params.tokenExpiry.GetEpochMilli());
	masterWriter.WriteInt32((std::int32_t)siteKey.id);
	masterWriter.WriteBytes(encryptedIdentity.data(), 0, encryptedIdentity.size());

	std::uint8_t masterIv[16];
	std::generate(masterIv, masterIv + sizeof(masterIv), std::ref(rd));
	const auto encryptedMaster = EncryptImpl(masterBuffer, masterIv, masterKey.secret);

	std::vector<std::uint8_t> rootBuffer(1 + 4 + encryptedMaster.size());
	BigEndianByteWriter rootWriter(rootBuffer.data(), rootBuffer.size());
	rootWriter.WriteByte(2);
	rootWriter.WriteInt32((std::int32_t)masterKey.id);
	rootWriter.WriteBytes(encryptedMaster.data(), 0, encryptedMaster.size());

	return macaron::Base64::Encode(rootBuffer);
}

std::string EncryptTokenV3(const std::string& identity, const Key& masterKey, int siteId, const Key& siteKey, EncryptTokenParams params)
{
    std::uint8_t sitePayload[128];
    BigEndianByteWriter sitePayloadWriter(sitePayload, sizeof(sitePayload));

    // publisher data
    sitePayloadWriter.WriteInt32(siteId);
    sitePayloadWriter.WriteInt64(0); // publisher id
    sitePayloadWriter.WriteInt32(0); // client key id

    // user identity data
    sitePayloadWriter.WriteInt32(0); // privacy bits
    sitePayloadWriter.WriteInt64(Timestamp::Now().AddSeconds(-60).GetEpochMilli()); // established
    sitePayloadWriter.WriteInt64(Timestamp::Now().AddSeconds(-40).GetEpochMilli()); // refreshed
    std::vector<std::uint8_t> identityBytes;
    macaron::Base64::Decode(identity, identityBytes);
    sitePayloadWriter.WriteBytes(identityBytes.data(), 0, identityBytes.size());

    std::uint8_t masterPayload[256];
    BigEndianByteWriter masterPayloadWriter(masterPayload, sizeof(masterPayload));

    masterPayloadWriter.WriteInt64(params.tokenExpiry.GetEpochMilli());
    masterPayloadWriter.WriteInt64(Timestamp::Now().GetEpochMilli()); // token created

    // operator data
    masterPayloadWriter.WriteInt32(0); // site id
    masterPayloadWriter.WriteByte(0); // operator type
    masterPayloadWriter.WriteInt32(0); // operator version
    masterPayloadWriter.WriteInt32(0); // operator key id

    masterPayloadWriter.WriteInt32((std::int32_t)siteKey.id);
    const auto masterPayloadLen = masterPayloadWriter.GetPosition()
            + EncryptGCM(sitePayload, sitePayloadWriter.GetPosition(), siteKey.secret.data(), masterPayload + masterPayloadWriter.GetPosition());

    std::vector<std::uint8_t> rootPayload(256);
    BigEndianByteWriter writer(rootPayload);

    writer.WriteByte((((std::uint8_t)params.identityScope << 4) | ((std::uint8_t)params.identityType << 2)));
    writer.WriteByte(112);
    writer.WriteInt32(masterKey.id);

    const auto rootPayloadLen = writer.GetPosition()
            + EncryptGCM(masterPayload, masterPayloadLen, masterKey.secret.data(), rootPayload.data() + writer.GetPosition());
    rootPayload.resize(rootPayloadLen);

    return macaron::Base64::Encode(rootPayload);
}

std::string EncryptDataV2(const std::vector<std::uint8_t>& data, const uid2::Key& key, int siteId, uid2::Timestamp now)
{
    std::random_device rd;
    std::uint8_t iv[16];
    std::generate(iv, iv + sizeof(iv), std::ref(rd));

    auto dataBytes = data;
    const auto encrypted = EncryptImpl(dataBytes, iv, key.secret);

    std::vector<std::uint8_t> rootPayload(encrypted.size() + 64);
    BigEndianByteWriter writer(rootPayload);
    writer.WriteByte(128); // payload type
    writer.WriteByte(1); // version
    writer.WriteInt64(now.GetEpochMilli());
    writer.WriteInt32(siteId);
    writer.WriteInt32((std::int32_t)key.id);
    writer.WriteBytes(encrypted.data(), 0, encrypted.size());
    rootPayload.resize(writer.GetPosition());

    return macaron::Base64::Encode(rootPayload);
}
