#include "base64.h"
#include "bigendianprocessor.h"
#include "key.h"
#include "uid2base64urlcoder.h"
#include "uid2tokengenerator.h"

#include <uid2/uid2client.h>

#include <gtest/gtest.h>

#include <sstream>

using namespace uid2;

#define TO_VECTOR(d) (std::vector<std::uint8_t>(d, (d) + sizeof(d)))

static std::vector<std::uint8_t> GetMasterSecret();

static std::vector<std::uint8_t> GetSiteSecret();

static std::vector<std::uint8_t> MakeKeySecret(std::uint8_t v);

static IdentityType GetTokenIdentityType(const std::string& rawUid, UID2Client& client);

static std::string KeySetToJson(const std::vector<Key>& keys);

static std::string KeySetToJsonForSharing(const std::vector<Key>& keys);

static std::string KeySetToJsonForSharingWithHeader(const std::string& defaultKeyset, int callerSiteId, const std::vector<Key>& keys);

static const int MASTER_KEYSET_ID = 1;
static const int DEFAULT_KEYSET_ID = 99999;
static const std::int64_t MASTER_KEY_ID = 164;
static const std::int64_t SITE_KEY_ID = 165;
static const int SITE_ID = 9000;
static const int SITE_ID2 = 2;
static const std::uint8_t MASTER_SECRET[] = {139, 37,  241, 173, 18, 92,  36,  232, 165, 168, 23,  18,  38, 195, 123, 92,
                                             160, 136, 185, 40,  91, 173, 165, 221, 168, 16,  169, 164, 38, 139, 8,   155};
static const std::uint8_t SITE_SECRET[] = {32, 251, 7,  194, 132, 154, 250, 86, 202, 116, 104, 29,  131, 192, 139, 215,
                                           48, 164, 11, 65,  226, 110, 167, 14, 108, 51,  254, 125, 65,  24,  23,  133};
static const Timestamp NOW = Timestamp::Now();
static const Key MASTER_KEY{MASTER_KEY_ID, -1, MASTER_KEYSET_ID, NOW.AddDays(-1), NOW, NOW.AddDays(1), GetMasterSecret()};
static const Key SITE_KEY{SITE_KEY_ID, SITE_ID, DEFAULT_KEYSET_ID, NOW.AddDays(-10), NOW.AddDays(-9), NOW.AddDays(1), GetSiteSecret()};
static const std::string EXAMPLE_UID = "ywsvDNINiZOVSsfkHpLpSJzXzhr6Jx9Z/4Q0+lsEUvM=";
static const std::string CLIENT_SECRET = "ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=";

/// NOLINTNEXTLINE(readability-identifier-naming)
static void crossPlatformConsistencyCheck_Base64UrlTest(const std::vector<std::uint8_t>& rawInput, const std::string& expectedBase64URLStr);

// unit tests to ensure the base64url encoding and decoding are identical in all supported
// uid2 client sdks in different programming languages
TEST(CrossPlatformConsistencyCheck, Base64UrlTest)
{
    // the Base64 equivalent is "/+CI/+6ZmQ=="
    // and we want the Base64URL encoded to remove 2 '=' paddings at the back
    std::vector<std::uint8_t> case1 = {0xff, 0xE0, 0x88, 0xFF, 0xEE, 0x99, 0x99};
    crossPlatformConsistencyCheck_Base64UrlTest(case1, "_-CI_-6ZmQ");

    // the Base64 equivalent is "/+CI/+6ZmZk=" to remove 1 padding
    std::vector<std::uint8_t> case2 = {0xff, 0xE0, 0x88, 0xFF, 0xEE, 0x99, 0x99, 0x99};
    crossPlatformConsistencyCheck_Base64UrlTest(case2, "_-CI_-6ZmZk");

    // the Base64 equivalent is "/+CI/+6Z" which requires no padding removal
    std::vector<std::uint8_t> case3 = {0xff, 0xE0, 0x88, 0xFF, 0xEE, 0x99};
    crossPlatformConsistencyCheck_Base64UrlTest(case3, "_-CI_-6Z");
}

void crossPlatformConsistencyCheck_Base64UrlTest(const std::vector<std::uint8_t>& rawInput, const std::string& expectedBase64URLStr)
{
    const auto rawInputLen = static_cast<int>(rawInput.size());
    // the Base64 equivalent is "/+CI/+6ZmQ=="
    // and we want the Base64URL encoded to remove the '=' padding
    std::vector<std::uint8_t> payload(rawInputLen);
    BigEndianByteWriter writer(payload.data(), static_cast<int>(payload.size()));
    for (int i = 0; i < rawInputLen; i++) {
        writer.WriteByte(rawInput[i]);
    }
    std::string base64UrlEncodedStr = uid2::UID2Base64UrlCoder::Encode(payload);
    EXPECT_EQ(expectedBase64URLStr, base64UrlEncodedStr);

    std::vector<std::uint8_t> decoded;
    uid2::UID2Base64UrlCoder::Decode(base64UrlEncodedStr, decoded);
    EXPECT_EQ(rawInputLen, decoded.size());
    for (size_t i = 0; i < decoded.size(); i++) {
        EXPECT_EQ(rawInput[i], decoded[i]);
    }
}

void ValidateAdvertisingToken(const std::string& advertisingTokenString, IdentityScope identityScope, IdentityType identityType)
{
    std::string firstChar = advertisingTokenString.substr(0, 1);
    if (identityScope == IdentityScope::UID2) {
        EXPECT_EQ(identityType == IdentityType::EMAIL ? "A" : "B", firstChar);
    } else {
        EXPECT_EQ(identityType == IdentityType::EMAIL ? "E" : "F", firstChar);
    }

    std::string secondChar = advertisingTokenString.substr(1, 1);
    EXPECT_EQ("4", secondChar);

    // No URL-unfriendly characters allowed:
    EXPECT_EQ(std::string::npos, advertisingTokenString.find('='));
    EXPECT_EQ(std::string::npos, advertisingTokenString.find('+'));
    EXPECT_EQ(std::string::npos, advertisingTokenString.find('/'));
}

std::string GenerateUid2TokenV4AndValidate(
    const std::string& identity,
    const uid2::Key& masterKey,
    int siteId,
    const uid2::Key& siteKey,
    EncryptTokenParams params = EncryptTokenParams())
{
    std::string advertisingToken = GenerateUid2TokenV4(identity, masterKey, siteId, siteKey, params);
    ValidateAdvertisingToken(advertisingToken, IdentityScope::UID2, IdentityType::EMAIL);
    return advertisingToken;
}

TEST(EncryptionTestsV4, SmokeTest)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());
    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_TRUE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(EncryptionTestsV4, EmptyKeyContainer)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());
    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::NOT_INITIALIZED, res.GetStatus());
}

TEST(EncryptionTestsV4, ExpiredKeyContainer)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());

    const Key masterKeyExpired{MASTER_KEY_ID, -1, -1, NOW, NOW.AddDays(-2), NOW.AddDays(-1), GetMasterSecret()};
    const Key siteKeyExpired{SITE_KEY_ID, SITE_ID, -1, NOW, NOW.AddDays(-2), NOW.AddDays(-1), GetSiteSecret()};
    client.RefreshJson(KeySetToJson({masterKeyExpired, siteKeyExpired}));

    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::KEYS_NOT_SYNCED, res.GetStatus());
}

TEST(EncryptionTestsV4, NotAuthorizedForKey)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());

    const Key anotherMasterKey{MASTER_KEY_ID + SITE_KEY_ID + 1, -1, -1, NOW, NOW, NOW.AddDays(1), GetMasterSecret()};
    const Key anotherSiteKey{MASTER_KEY_ID + SITE_KEY_ID + 2, SITE_ID, -1, NOW, NOW, NOW.AddDays(1), GetSiteSecret()};
    client.RefreshJson(KeySetToJson({anotherMasterKey, anotherSiteKey}));

    const auto res = client.Decrypt(advertisingToken, Timestamp::Now());
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY, res.GetStatus());
}

TEST(EncryptionTestsV4, InvalidPayload)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    std::vector<uint8_t> payload;
    uid2::UID2Base64UrlCoder::Decode(GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams()), payload);
    payload.pop_back();
    const auto advertisingToken = uid2::UID2Base64UrlCoder::Encode(payload);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    EXPECT_EQ(DecryptionStatus::INVALID_PAYLOAD, client.Decrypt(advertisingToken, NOW).GetStatus());
}

TEST(EncryptionTestsV4, TokenExpiryAndCustomNow)
{
    const Timestamp expiry = NOW.AddDays(-6);
    const auto params = EncryptTokenParams().WithTokenExpiry(expiry);

    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, params);

    auto res = client.Decrypt(advertisingToken, expiry.AddSeconds(1));
    EXPECT_FALSE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::EXPIRED_TOKEN, res.GetStatus());

    res = client.Decrypt(advertisingToken, expiry.AddSeconds(-1));
    EXPECT_TRUE(res.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(EncryptDataTestsV4, SiteIdFromToken)
{
    const std::uint8_t data[] = {1, 2, 3, 4, 5, 6};
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());
    const auto encrypted = client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken));
    EXPECT_TRUE(encrypted.IsSuccess());
    EXPECT_EQ(EncryptionStatus::SUCCESS, encrypted.GetStatus());
    client.RefreshJson(KeySetToJson({SITE_KEY}));
    const auto decrypted = client.DecryptData(encrypted.GetEncryptedData());
    EXPECT_TRUE(decrypted.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, decrypted.GetStatus());
    EXPECT_EQ(TO_VECTOR(data), decrypted.GetDecryptedData());
}

TEST(EncryptDataTestsV4, SiteIdFromTokenCustomSiteKeySiteId)
{
    const std::uint8_t data[] = {1, 2, 3, 4, 5, 6};
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID2, SITE_KEY, EncryptTokenParams());
    const auto encrypted = client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken));
    EXPECT_EQ(EncryptionStatus::SUCCESS, encrypted.GetStatus());
    const auto decrypted = client.DecryptData(encrypted.GetEncryptedData());
    EXPECT_TRUE(decrypted.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, decrypted.GetStatus());
    EXPECT_EQ(TO_VECTOR(data), decrypted.GetDecryptedData());
}

TEST(EncryptDataTestsV4, SiteIdAndTokenSet)
{
    const std::uint8_t data[] = {1, 2, 3, 4, 5, 6};
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());
    EXPECT_THROW(
        client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken).WithSiteId(SITE_ID)), std::invalid_argument);
}

TEST(EncryptDataTestsV4, TokenDecryptKeyExpired)
{
    const std::uint8_t data[] = {1, 2, 3, 4, 5, 6};
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    const Key key{SITE_KEY_ID, SITE_ID2, -1, NOW, NOW, NOW.AddDays(-1), GetSiteSecret()};
    client.RefreshJson(KeySetToJson({MASTER_KEY, key}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, key);
    const auto encrypted = client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken));
    EXPECT_FALSE(encrypted.IsSuccess());
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

TEST(EncryptDataTestsV4, TokenExpired)
{
    const Timestamp expiry = NOW.AddDays(-6);
    const auto params = EncryptTokenParams().WithTokenExpiry(expiry);

    const std::uint8_t data[] = {1, 2, 3, 4, 5, 6};
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));
    const auto advertisingToken = GenerateUid2TokenV4AndValidate(EXAMPLE_UID, MASTER_KEY, SITE_ID, SITE_KEY, params);
    auto encrypted = client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken));
    EXPECT_FALSE(encrypted.IsSuccess());
    EXPECT_EQ(EncryptionStatus::TOKEN_DECRYPT_FAILURE, encrypted.GetStatus());

    const auto now = expiry.AddSeconds(-1);
    encrypted = client.EncryptData(EncryptionDataRequest(data, sizeof(data)).WithAdvertisingToken(advertisingToken).WithNow(now));
    EXPECT_TRUE(encrypted.IsSuccess());
    EXPECT_EQ(EncryptionStatus::SUCCESS, encrypted.GetStatus());
    const auto decrypted = client.DecryptData(encrypted.GetEncryptedData());
    EXPECT_TRUE(decrypted.IsSuccess());
    EXPECT_EQ(DecryptionStatus::SUCCESS, decrypted.GetStatus());
    EXPECT_EQ(TO_VECTOR(data), decrypted.GetDecryptedData());
}

TEST(EncryptDataTestsV4, RawUidProducesCorrectIdentityTypeInToken)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(KeySetToJson({MASTER_KEY, SITE_KEY}));

    // see UID2-79+Token+and+ID+format+v3 . Also note EUID does not support v2 or phone
    EXPECT_EQ(
        IdentityType::EMAIL,
        GetTokenIdentityType(
            "Q4bGug8t1xjsutKLCNjnb5fTlXSvIQukmahYDJeLBtk=",
            client));  // v2 +12345678901. Although this was generated from a phone number, it's a v2 raw UID which doesn't encode this information, so token
                       // assumes email by default.
    EXPECT_EQ(IdentityType::PHONE, GetTokenIdentityType("BEOGxroPLdcY7LrSiwjY52+X05V0ryELpJmoWAyXiwbZ", client));  // v3 +12345678901
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("oKg0ZY9ieD/CGMEjAA0kcq+8aUbLMBG0MgCT3kWUnJs=", client));  // v2 test@example.com
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("AKCoNGWPYng/whjBIwANJHKvvGlGyzARtDIAk95FlJyb", client));  // v3 test@example.com
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("EKCoNGWPYng/whjBIwANJHKvvGlGyzARtDIAk95FlJyb", client));  // v3 EUID test@example.com
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

//////////////////////  Sharing tests //////////////////////////////////////////////////////////////////

TEST(SharingTests, CanEncryptAndDecryptSharing)
{
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(json);
    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::SUCCESS, advertisingToken.GetStatus());

    auto res = client.Decrypt(advertisingToken.GetEncryptedData(), NOW);

    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(SharingTests, CanDecryptAnotherClientsEncryptedToken)
{
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(json);
    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::SUCCESS, advertisingToken.GetStatus());

    UID2Client receivingClient("endpoint1", "authkey2", CLIENT_SECRET, IdentityScope::UID2);
    auto json2 = KeySetToJsonForSharingWithHeader("\"default_keyset_id\": 12345,", 4874, {MASTER_KEY, SITE_KEY});

    receivingClient.RefreshJson(json2);

    auto res = receivingClient.Decrypt(advertisingToken.GetEncryptedData(), NOW);
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());
}

TEST(SharingTests, SharingTokenIsV4)
{
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(json);
    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW).GetEncryptedData();

    const bool containsBase64SpecialChars = advertisingToken.find_first_of("+/=") == std::string::npos;
    EXPECT_TRUE(containsBase64SpecialChars);
}

TEST(SharingTests, Uid2ClientProducesUid2Token)
{
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::UID2);
    client.RefreshJson(json);
    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::SUCCESS, advertisingToken.GetStatus());

    EXPECT_EQ("A", advertisingToken.GetEncryptedData().substr(0, 1));
}

TEST(SharingTests, EuidClientProducesEuidToken)
{
    UID2Client client("ep", "ak", CLIENT_SECRET, IdentityScope::EUID);
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    client.RefreshJson(json);

    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW).GetEncryptedData();

    EXPECT_EQ("E", advertisingToken.substr(0, 1));
}

TEST(SharingTests, RawUidProducesCorrectIdentityTypeInToken)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    auto json = KeySetToJsonForSharing({MASTER_KEY, SITE_KEY});
    client.RefreshJson(json);

    EXPECT_EQ(
        IdentityType::EMAIL,
        GetTokenIdentityType(
            "Q4bGug8t1xjsutKLCNjnb5fTlXSvIQukmahYDJeLBtk=",
            client));  // v2 +12345678901. Although this was generated from a phone number, it's a v2 raw UID which doesn't encode this information, so token
                       // assumes email by default.
    EXPECT_EQ(IdentityType::PHONE, GetTokenIdentityType("BEOGxroPLdcY7LrSiwjY52+X05V0ryELpJmoWAyXiwbZ", client));  // v3 +12345678901
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("oKg0ZY9ieD/CGMEjAA0kcq+8aUbLMBG0MgCT3kWUnJs=", client));  // v2 test@example.com
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("AKCoNGWPYng/whjBIwANJHKvvGlGyzARtDIAk95FlJyb", client));  // v3 test@example.com
    EXPECT_EQ(IdentityType::EMAIL, GetTokenIdentityType("EKCoNGWPYng/whjBIwANJHKvvGlGyzARtDIAk95FlJyb", client));  // v3 EUID test@example.com
}

TEST(SharingTests, MultipleKeysPerKeyset)
{
    Key masterKey2{
        264, -1, MASTER_KEYSET_ID, NOW.AddSeconds(-2LL * 60 * 60), NOW.AddSeconds(-1LL * 60 * 60), NOW.AddSeconds(-1LL * 60 * 60), GetMasterSecret()};
    Key siteKey2{
        265, SITE_ID, DEFAULT_KEYSET_ID, NOW.AddSeconds(-10LL * 24 * 60 * 60), NOW.AddSeconds(-1LL * 60 * 60), NOW.AddSeconds(-1LL * 60 * 60), GetSiteSecret()};

    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    auto json = KeySetToJsonForSharing({MASTER_KEY, masterKey2, SITE_KEY, siteKey2});
    client.RefreshJson(json);

    auto advertisingToken = client.Encrypt(EXAMPLE_UID, NOW).GetEncryptedData();

    EXPECT_EQ(DecryptionStatus::SUCCESS, client.Decrypt(advertisingToken, NOW).GetStatus());
    EXPECT_EQ(EXAMPLE_UID, client.Decrypt(advertisingToken, NOW).GetUid());
}

TEST(SharingTests, CannotEncryptIfNoKeyFromTheDefaultKeyset)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    auto json = KeySetToJsonForSharing({MASTER_KEY});
    client.RefreshJson(json);

    auto encrypted = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

TEST(SharingTests, CannotEncryptIfTheresNoDefaultKeysetHeader)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    auto json = KeySetToJsonForSharingWithHeader("", SITE_ID, {MASTER_KEY, SITE_KEY});
    client.RefreshJson(json);

    auto encrypted = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

TEST(SharingTests, ExpiryInTokenMatchesExpiryInResponse)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    auto json = KeySetToJsonForSharingWithHeader(R"("default_keyset_id": 99999, "token_expiry_seconds": 2,)", SITE_ID, {MASTER_KEY, SITE_KEY});
    client.RefreshJson(json);

    auto encryptedAt = NOW;
    auto encrypted = client.Encrypt(EXAMPLE_UID, encryptedAt);
    EXPECT_EQ(EncryptionStatus::SUCCESS, encrypted.GetStatus());

    auto res = client.Decrypt(encrypted.GetEncryptedData(), encryptedAt.AddSeconds(1));
    EXPECT_EQ(DecryptionStatus::SUCCESS, res.GetStatus());
    EXPECT_EQ(EXAMPLE_UID, res.GetUid());

    auto futureDecryption = client.Decrypt(encrypted.GetEncryptedData(), NOW.AddSeconds(3));
    EXPECT_EQ(DecryptionStatus::EXPIRED_TOKEN, futureDecryption.GetStatus());
}

TEST(SharingTests, EncryptKeyExpired)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    Key key{SITE_KEY_ID, SITE_ID, DEFAULT_KEYSET_ID, NOW, NOW, NOW.AddSeconds(-1LL * 24 * 60 * 60), MakeKeySecret(9)};
    client.RefreshJson(KeySetToJsonForSharing({MASTER_KEY, key}));
    auto encrypted = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

TEST(SharingTests, EncryptKeyInactive)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    Key key{SITE_KEY_ID, SITE_ID, DEFAULT_KEYSET_ID, NOW, NOW.AddSeconds(1LL * 24 * 60 * 60), NOW.AddSeconds(2LL * 24 * 60 * 60), MakeKeySecret(9)};
    client.RefreshJson(KeySetToJsonForSharing({MASTER_KEY, key}));
    auto encrypted = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

TEST(SharingTests, EncryptSiteKeyExpired)
{
    UID2Client client("endpoint", "authkey", CLIENT_SECRET, IdentityScope::UID2);
    Key key{SITE_KEY_ID, SITE_ID, DEFAULT_KEYSET_ID, NOW, NOW, NOW.AddSeconds(-1LL * 24 * 60 * 60), MakeKeySecret(9)};
    client.RefreshJson(KeySetToJsonForSharing({MASTER_KEY, key}));
    auto encrypted = client.Encrypt(EXAMPLE_UID, NOW);
    EXPECT_EQ(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY, encrypted.GetStatus());
}

std::string KeySetToJsonForSharingWithHeader(const std::string& defaultKeyset, int callerSiteId, const std::vector<Key>& keys)
{
    std::stringstream ss;
    ss << R"({"body": {)";
    ss << R"("caller_site_id": )" << callerSiteId << ",";
    ss << R"("master_keyset_id": )" << MASTER_KEYSET_ID << ",";
    ss << defaultKeyset;
    ss << R"("keys": [)";
    bool needComma = false;
    for (const auto& k : keys) {
        if (!needComma) {
            needComma = true;
        } else {
            ss << ", ";
        }

        ss << R"({"id": )" << k.id_;
        if (k.keysetId_ > 0) {
            ss << R"(, "keyset_id": )" << k.keysetId_;
        }
        ss << R"(, "created": )" << k.created_.GetEpochSecond() << R"(, "activates": )" << k.activates_.GetEpochSecond() << R"(, "expires": )"
           << k.expires_.GetEpochSecond() << R"(, "secret": ")" << macaron::Base64::Encode(k.secret_) << "\""
           << "}";
    }
    ss << "]}}";
    return ss.str();
}

std::string KeySetToJsonForSharing(const std::vector<Key>& keys)
{
    return KeySetToJsonForSharingWithHeader(R"("default_keyset_id": 99999,)", SITE_ID, keys);
}

IdentityType GetTokenIdentityType(const std::string& rawUid, UID2Client& client)
{
    auto token = GenerateUid2TokenV4(rawUid, MASTER_KEY, SITE_ID, SITE_KEY, EncryptTokenParams());
    EXPECT_EQ(rawUid, client.Decrypt(token, Timestamp::Now()).GetUid());

    char firstChar = token[0];
    if ('A' == firstChar || 'E' == firstChar)  // from UID2-79+Token+and+ID+format+v3
    {
        return IdentityType::EMAIL;
    }
    if ('F' == firstChar || 'B' == firstChar) {
        return IdentityType::PHONE;
    }

    throw "unknown IdentityType";
}

std::vector<std::uint8_t> GetMasterSecret()
{
    return {MASTER_SECRET, MASTER_SECRET + sizeof(MASTER_SECRET)};
}

std::vector<std::uint8_t> GetSiteSecret()
{
    return {SITE_SECRET, SITE_SECRET + sizeof(SITE_SECRET)};
}

std::vector<std::uint8_t> MakeKeySecret(std::uint8_t v)
{
    return std::vector<std::uint8_t>(sizeof(SITE_SECRET), v);  // NOLINT
}
