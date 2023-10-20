#include "base64.h"
#include "key.h"
#include "uid2tokengenerator.h"

#include <uid2/uid2client.h>

#include <gtest/gtest.h>

#include <sstream>

using namespace uid2;

static std::vector<std::uint8_t> GetMasterSecret();
static std::vector<std::uint8_t> GetSiteSecret();
static std::string KeySetToJson(const std::vector<Key>& keys);
static std::vector<std::uint8_t> Base64Decode(const std::string& str);

static const std::int64_t MASTER_KEY_ID = 164;
static const std::int64_t SITE_KEY_ID = 165;
static const int SITE_ID = 9000;
static const std::uint8_t MASTER_SECRET[] = {139, 37,  241, 173, 18, 92,  36,  232, 165, 168, 23,  18,  38, 195, 123, 92,
                                             160, 136, 185, 40,  91, 173, 165, 221, 168, 16,  169, 164, 38, 139, 8,   155};
static const std::uint8_t SITE_SECRET[] = {32, 251, 7,  194, 132, 154, 250, 86, 202, 116, 104, 29,  131, 192, 139, 215,
                                           48, 164, 11, 65,  226, 110, 167, 14, 108, 51,  254, 125, 65,  24,  23,  133};
static const Timestamp NOW = Timestamp::Now();
static const Key MASTER_KEY{MASTER_KEY_ID, -1, -1, NOW.AddDays(-1), NOW, NOW.AddDays(1), GetMasterSecret()};
static const Key SITE_KEY{SITE_KEY_ID, SITE_ID, -1, NOW.AddDays(-10), NOW.AddDays(-9), NOW.AddDays(1), GetSiteSecret()};
static const std::string EXAMPLE_UID = "ywsvDNINiZOVSsfkHpLpSJzXzhr6Jx9Z/4Q0+lsEUvM=";
static const std::string CLIENT_SECRET = "ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=";

TEST(EncryptionTestsV2, SmokeTest)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY);
    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_TRUE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(EncryptionTestsV2, EmptyKeyContainer)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY);
    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::NOT_INITIALIZED, res.GetStatus());
}

TEST(EncryptionTestsV2, ExpiredKeyContainer)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY);

    const Key masterKeyExpired{MASTER_KEY_ID, -1, -1, NOW, NOW.AddDays(-2), NOW.AddDays(-1), GetMasterSecret()};
    const Key siteKeyExpired{SITE_KEY_ID, SITE_ID, -1, NOW, NOW.AddDays(-2), NOW.AddDays(-1), GetSiteSecret()};
    client.RefreshJson(KeySetToJson({masterKeyExpired, siteKeyExpired}));

    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::KEYS_NOT_SYNCED, res.GetStatus());
}

TEST(EncryptionTestsV2, NotAuthorizedForKey)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY);

    const Key anotherMasterKey{MASTER_KEY_ID + SITE_KEY_ID + 1, -1, -1, NOW, NOW, NOW.AddDays(1), GetMasterSecret()};
    const Key anotherSiteKey{MASTER_KEY_ID + SITE_KEY_ID + 2, SITE_ID, -1, NOW, NOW, NOW.AddDays(1), GetSiteSecret()};
    client.RefreshJson(KeySetToJson({anotherMasterKey, anotherSiteKey}));

    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY, res.GetStatus());
}

TEST(EncryptionTestsV2, InvalidPayload)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY);
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, client.Decrypt(advertisingToken.substr(0, advertisingToken.size() - 1), NOW).GetStatus());
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, client.Decrypt(advertisingToken.substr(0, advertisingToken.size() - 4), NOW).GetStatus());
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, client.Decrypt(advertisingToken.substr(0, 4), NOW).GetStatus());
}

TEST(EncryptionTestsV2, TokenExpiryAndCustomNow)
{
    const Timestamp expiry = NOW.AddDays(-6);
    const auto params = EncryptTokenParams().WithTokenExpiry(expiry);

    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV2(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, params);

    auto res = client.Decrypt(advertisingToken, expiry.AddSeconds(1));
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::EXPIRED_TOKEN, res.GetStatus());

    res = client.Decrypt(advertisingToken, expiry.AddSeconds(-1));
    EXPECT_TRUE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(DecryptDataTestsV2, DecryptData)
{
    const std::vector<std::uint8_t> data = {1, 2, 3, 4, 5, 6};
    const auto encrypted = EncryptDataV2(data, SITE_KEY, 12345, NOW);
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({SITE_KEY}));
    const auto decrypted = client.DecryptData(encrypted);
    EXPECT_TRUE(decrypted.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, decrypted.GetStatus());
    EXPECT_EQ(data, decrypted.GetDecryptedData());
    EXPECT_EQ(NOW, decrypted.GetEncryptedAt());
}

TEST(DecryptDataTestsV2, BadPayloadType)
{
    const std::vector<std::uint8_t> data = {1, 2, 3, 4, 5, 6};
    const auto encrypted = EncryptDataV2(data, SITE_KEY, 12345, NOW);
    auto encryptedBytes = Base64Decode(encrypted);
    encryptedBytes[0] = 0;
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({SITE_KEY}));
    const auto decrypted = client.DecryptData(macaron::Base64::Encode(encryptedBytes));
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD_TYPE, decrypted.GetStatus());
}

TEST(DecryptDataTestsV2, BadVersion)
{
    const std::vector<std::uint8_t> data = {1, 2, 3, 4, 5, 6};
    const auto encrypted = EncryptDataV2(data, SITE_KEY, 12345, NOW);
    auto encryptedBytes = Base64Decode(encrypted);
    encryptedBytes[1] = 0;
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({SITE_KEY}));
    const auto decrypted = client.DecryptData(macaron::Base64::Encode(encryptedBytes));
    EXPECT_EQ(DecryptionStatus::VERSION_NOT_SUPPORTED, decrypted.GetStatus());
}

TEST(DecryptDataTestsV2, BadPayload)
{
    const std::vector<std::uint8_t> data = {1, 2, 3, 4, 5, 6};
    const auto encrypted = EncryptDataV2(data, SITE_KEY, 12345, NOW);
    const auto encryptedBytes = Base64Decode(encrypted);

    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({SITE_KEY}));

    auto encryptedBytesLarger = encryptedBytes;
    encryptedBytesLarger.push_back(1);
    auto decrypted = client.DecryptData(macaron::Base64::Encode(encryptedBytesLarger));
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, decrypted.GetStatus());

    auto encryptedBytesSmaller = encryptedBytes;
    encryptedBytesSmaller.pop_back();
    decrypted = client.DecryptData(macaron::Base64::Encode(encryptedBytesSmaller));
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, decrypted.GetStatus());

    decrypted = client.DecryptData(encrypted.substr(0, 4));
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, decrypted.GetStatus());

    decrypted = client.DecryptData(encrypted + "0");
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, decrypted.GetStatus());
}

TEST(DecryptDataTestsV2, NoDecryptionKey)
{
    const std::vector<std::uint8_t> data = {1, 2, 3, 4, 5, 6};
    const auto encrypted = EncryptDataV2(data, SITE_KEY, 12345, NOW);
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY}));
    const auto decrypted = client.DecryptData(encrypted);
    EXPECT_EQ(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY, decrypted.GetStatus());
}

std::string KeySetToJson(const std::vector<Key>& keys)
{
    std::stringstream ss;
    ss << "{\"body\": [";
    bool needComma = false;
    for (const auto& k : keys) {
        if (!needComma) {
            needComma = true;
        } else {
            ss << ", ";
        }

        ss << R"({"id": )" << k.id_ << R"(, "site_id": )" << k.siteId_ << R"(, "created": )" << k.created_.GetEpochSecond() << R"(, "activates": )"
           << k.activates_.GetEpochSecond() << R"(, "expires": )" << k.expires_.GetEpochSecond() << R"(, "secret": ")" << macaron::Base64::Encode(k.secret_)
           << "\""
           << "}";
    }
    ss << "]}";
    return ss.str();
}

std::vector<std::uint8_t> GetMasterSecret()
{
    return {MASTER_SECRET, MASTER_SECRET + sizeof(MASTER_SECRET)};
}

std::vector<std::uint8_t> GetSiteSecret()
{
    return {SITE_SECRET, SITE_SECRET + sizeof(SITE_SECRET)};
}

std::vector<std::uint8_t> Base64Decode(const std::string& str)
{
    std::vector<std::uint8_t> result;
    macaron::Base64::Decode(str, result);
    return result;
}
