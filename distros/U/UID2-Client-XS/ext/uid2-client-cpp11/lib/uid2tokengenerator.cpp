#include "uid2tokengenerator.h"

#include "aes.h"
#include "base64.h"
#include "bigendianprocessor.h"
#include "uid2base64urlcoder.h"
#include "uid2encryption.h"

#include <algorithm>
#include <cstring>
#include <functional>
#include <random>
#include <vector>

namespace uid2 {

static void AddPkcs7Padding(std::vector<std::uint8_t>& data)
{
    const auto padlen = 16 - static_cast<int>(data.size() % 16);
    for (int i = 0; i < padlen; ++i) {
        data.push_back(static_cast<std::uint8_t>(padlen));
    }
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

std::string GenerateUid2TokenV2(const std::string& identity, const Key& masterKey, int siteId, const Key& siteKey, EncryptTokenParams params)
{
    std::random_device rd;
    std::vector<std::uint8_t> identityBuffer(4 + 4 + identity.size() + 4 + 8);
    BigEndianByteWriter identityWriter(identityBuffer.data(), static_cast<int>(identityBuffer.size()));
    identityWriter.WriteInt32(siteId);
    identityWriter.WriteInt32(static_cast<std::int32_t>(identity.size()));
    identityWriter.WriteBytes(reinterpret_cast<const std::uint8_t*>(identity.data()), 0, static_cast<int>(identity.size()));
    identityWriter.WriteInt32(0);
    identityWriter.WriteInt64(Timestamp::Now().AddSeconds(-60).GetEpochMilli());
    std::uint8_t identityIv[16];
    std::generate(identityIv, identityIv + sizeof(identityIv), std::ref(rd));
    const auto encryptedIdentity = EncryptImpl(identityBuffer, identityIv, siteKey.secret_);

    std::vector<std::uint8_t> masterBuffer(8 + 4 + encryptedIdentity.size());
    BigEndianByteWriter masterWriter(masterBuffer.data(), static_cast<int>(masterBuffer.size()));
    masterWriter.WriteInt64(params.tokenExpiry_.GetEpochMilli());
    masterWriter.WriteInt32(static_cast<std::int32_t>(siteKey.id_));
    masterWriter.WriteBytes(encryptedIdentity.data(), 0, static_cast<int>(encryptedIdentity.size()));

    std::uint8_t masterIv[16];
    std::generate(masterIv, masterIv + sizeof(masterIv), std::ref(rd));
    const auto encryptedMaster = EncryptImpl(masterBuffer, masterIv, masterKey.secret_);

    std::vector<std::uint8_t> rootBuffer(1 + 4 + encryptedMaster.size());
    BigEndianByteWriter rootWriter(rootBuffer.data(), static_cast<int>(rootBuffer.size()));
    rootWriter.WriteByte(2);
    rootWriter.WriteInt32(static_cast<std::int32_t>(masterKey.id_));
    rootWriter.WriteBytes(encryptedMaster.data(), 0, static_cast<int>(encryptedMaster.size()));

    return macaron::Base64::Encode(rootBuffer);
}

std::string GenerateUid2TokenV3(const std::string& identity, const uid2::Key& masterKey, int siteId, const uid2::Key& siteKey, EncryptTokenParams params)
{
    return GenerateUID2TokenWithDebugInfo(identity, masterKey, siteId, siteKey, params, AdvertisingTokenVersion::V3);
}

std::string GenerateUid2TokenV4(const std::string& identity, const uid2::Key& masterKey, int siteId, const uid2::Key& siteKey, EncryptTokenParams params)
{
    return GenerateUID2TokenWithDebugInfo(identity, masterKey, siteId, siteKey, params, AdvertisingTokenVersion::V4);
}

std::string GenerateUID2TokenWithDebugInfo(
    const std::string& uid,
    const Key& masterKey,
    int siteId,
    const Key& siteKey,
    EncryptTokenParams params,
    AdvertisingTokenVersion adTokenVersion)
{
    std::uint8_t sitePayload[128];
    BigEndianByteWriter sitePayloadWriter(sitePayload, sizeof(sitePayload));

    // publisher data
    sitePayloadWriter.WriteInt32(siteId);
    sitePayloadWriter.WriteInt64(0);  // publisher id
    sitePayloadWriter.WriteInt32(0);  // client key id

    // user identity data
    sitePayloadWriter.WriteInt32(0);                                                 // privacy bits
    sitePayloadWriter.WriteInt64(Timestamp::Now().AddSeconds(-60).GetEpochMilli());  // established
    sitePayloadWriter.WriteInt64(Timestamp::Now().AddSeconds(-40).GetEpochMilli());  // refreshed
    std::vector<std::uint8_t> identityBytes;
    macaron::Base64::Decode(uid, identityBytes);
    sitePayloadWriter.WriteBytes(identityBytes.data(), 0, static_cast<int>(identityBytes.size()));

    std::uint8_t masterPayload[256];
    BigEndianByteWriter masterPayloadWriter(masterPayload, sizeof(masterPayload));

    masterPayloadWriter.WriteInt64(params.tokenExpiry_.GetEpochMilli());
    masterPayloadWriter.WriteInt64(Timestamp::Now().GetEpochMilli());  // token created

    // operator data
    masterPayloadWriter.WriteInt32(0);  // site id
    masterPayloadWriter.WriteByte(0);   // operator type
    masterPayloadWriter.WriteInt32(0);  // operator version
    masterPayloadWriter.WriteInt32(0);  // operator key id

    masterPayloadWriter.WriteInt32(static_cast<std::int32_t>(siteKey.id_));
    const auto masterPayloadLen =
        masterPayloadWriter.GetPosition() +
        EncryptGCM(sitePayload, sitePayloadWriter.GetPosition(), siteKey.secret_.data(), masterPayload + masterPayloadWriter.GetPosition());

    std::vector<std::uint8_t> rootPayload(256);
    BigEndianByteWriter writer(rootPayload);

    const char firstChar = uid[0];
    const IdentityType identityType = (firstChar == 'F' || firstChar == 'B') ? IdentityType::PHONE : IdentityType::EMAIL;  // see UID2-79+Token+and+ID+format+v3

    writer.WriteByte(((static_cast<std::uint8_t>(params.identityScope_) << 4) | (static_cast<std::uint8_t>(identityType) << 2)) | 3);
    writer.WriteByte(static_cast<uint8_t>(adTokenVersion));
    writer.WriteInt32(static_cast<std::int32_t>(masterKey.id_));

    const auto rootPayloadLen =
        writer.GetPosition() + EncryptGCM(masterPayload, masterPayloadLen, masterKey.secret_.data(), rootPayload.data() + writer.GetPosition());
    rootPayload.resize(rootPayloadLen);

    return adTokenVersion == AdvertisingTokenVersion::V4 ? uid2::UID2Base64UrlCoder::Encode(rootPayload) : macaron::Base64::Encode(rootPayload);
}

std::string EncryptDataV2(const std::vector<std::uint8_t>& data, const uid2::Key& key, int siteId, uid2::Timestamp now)
{
    std::random_device rd;
    std::uint8_t iv[16];
    std::generate(iv, iv + sizeof(iv), std::ref(rd));

    auto dataBytes = data;
    const auto encrypted = EncryptImpl(dataBytes, iv, key.secret_);

    std::vector<std::uint8_t> rootPayload(encrypted.size() + 64);
    BigEndianByteWriter writer(rootPayload);
    writer.WriteByte(128);  // payload type
    writer.WriteByte(1);    // version
    writer.WriteInt64(now.GetEpochMilli());
    writer.WriteInt32(siteId);
    writer.WriteInt32(static_cast<std::int32_t>(key.id_));
    writer.WriteBytes(encrypted.data(), 0, static_cast<int>(encrypted.size()));
    rootPayload.resize(writer.GetPosition());

    return macaron::Base64::Encode(rootPayload);
}

}  // namespace uid2
