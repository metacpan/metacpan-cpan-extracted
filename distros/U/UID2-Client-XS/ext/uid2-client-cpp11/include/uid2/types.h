#pragma once

#include <uid2/timestamp.h>

#include <cstdint>
#include <string>
#include <vector>

namespace uid2 {
struct Key;

enum class IdentityScope {
    UID2 = 0,
    EUID = 1,
};

enum class IdentityType {
    EMAIL = 0,
    PHONE = 1,
};

enum class AdvertisingTokenVersion {
    // showing as "AHA..." in the Base64 Encoding (Base64 'H' is 000111 and 112 is 01110000)
    V3 = 112,
    // showing as "AIA..." in the Base64URL Encoding ('H' is followed by 'I' hence
    // this choice for the next token version) (Base64 'I' is 001000 and 128 is 10000000)
    V4 = 128,
};

enum class DecryptionStatus {
    SUCCESS,
    NOT_AUTHORIZED_FOR_KEY,
    NOT_INITIALIZED,
    INVALID_PAYLOAD,
    EXPIRED_TOKEN,
    KEYS_NOT_SYNCED,
    VERSION_NOT_SUPPORTED,
    INVALID_PAYLOAD_TYPE,
    INVALID_IDENTITY_SCOPE,
};

enum class EncryptionStatus {
    SUCCESS,
    NOT_AUTHORIZED_FOR_KEY,
    NOT_AUTHORIZED_FOR_MASTER_KEY,
    NOT_INITIALIZED,
    KEYS_NOT_SYNCED,
    TOKEN_DECRYPT_FAILURE,
    KEY_INACTIVE,
    ENCRYPTION_FAILURE,
};

class RefreshResult {
public:
    static RefreshResult MakeSuccess() { return {true, std::string()}; }

    static RefreshResult MakeError(std::string&& reason) { return {false, std::move(reason)}; }

    bool IsSuccess() const { return success_; }

    const std::string& GetReason() const { return reason_; }

private:
    RefreshResult(bool success, std::string&& reason) : success_(success), reason_(reason) {}

    bool success_;
    std::string reason_;
};

class DecryptionResult {
public:
    static DecryptionResult MakeSuccess(std::string&& identity, Timestamp established, int siteId, int siteKeySiteId)
    {
        return {DecryptionStatus::SUCCESS, std::move(identity), established, siteId, siteKeySiteId};
    }

    static DecryptionResult MakeError(DecryptionStatus status) { return {status, std::string(), Timestamp(), -1, -1}; }

    static DecryptionResult MakeError(DecryptionStatus status, Timestamp established, int siteId, int siteKeySiteId)
    {
        return {status, std::string(), established, siteId, siteKeySiteId};
    }

    bool IsSuccess() const { return status_ == DecryptionStatus::SUCCESS; }

    DecryptionStatus GetStatus() const { return status_; }

    const std::string& GetUid() const { return identity_; }

    Timestamp GetEstablished() const { return established_; }

    int GetSiteId() const { return siteId_; }

    int GetSiteKeySiteId() const { return siteKeySiteId_; }

private:
    DecryptionResult(DecryptionStatus status, std::string&& identity, Timestamp established, int siteId, int siteKeySiteId)
        : status_(status), identity_(std::move(identity)), established_(established), siteId_(siteId), siteKeySiteId_(siteKeySiteId)
    {
    }

    DecryptionStatus status_;
    std::string identity_;
    Timestamp established_;
    int siteId_;
    int siteKeySiteId_;
};

class EncryptionResult {
public:
    static EncryptionResult MakeSuccess(std::string&& encryptedData) { return {EncryptionStatus::SUCCESS, std::move(encryptedData)}; }

    static EncryptionResult MakeError(EncryptionStatus status) { return {status, std::string()}; }

    bool IsSuccess() const { return status_ == EncryptionStatus::SUCCESS; }

    EncryptionStatus GetStatus() const { return status_; }

    std::string GetEncryptedData() const { return encryptedData_; }

private:
    EncryptionResult(EncryptionStatus status, std::string&& encryptedData) : status_(status), encryptedData_(std::move(encryptedData)) {}

    EncryptionStatus status_;
    std::string encryptedData_;
};

class EncryptionDataRequest {
public:
    EncryptionDataRequest() = default;

    EncryptionDataRequest(const std::uint8_t* data, std::size_t size) : data_(data), dataSize_(size) {}

    EncryptionDataRequest& WithSiteId(int siteId)
    {
        siteId_ = siteId;
        return *this;
    }

    EncryptionDataRequest& WithKey(const Key& key)
    {
        explicitKey_ = &key;
        return *this;
    }

    template <typename T>
    EncryptionDataRequest& WithAdvertisingToken(T&& token)
    {
        advertisingToken_ = std::forward<T>(token);
        return *this;
    }

    EncryptionDataRequest& WithInitializationVector(const std::uint8_t* iv, std::size_t size)
    {
        initializationVector_ = iv;
        initializationVectorSize_ = size;
        return *this;
    }

    EncryptionDataRequest& WithNow(Timestamp now)
    {
        now_ = now;
        return *this;
    }

    const std::uint8_t* GetData() const { return data_; }

    std::size_t GetDataSize() const { return dataSize_; }

    int GetSiteId() const { return siteId_; }

    const Key* GetKey() const { return explicitKey_; }

    const std::string& GetAdvertisingToken() const { return advertisingToken_; }

    const std::uint8_t* GetInitializationVector() const { return initializationVector_; }

    std::size_t GetInitializationVectorSize() const { return initializationVectorSize_; }

    Timestamp GetNow() const { return now_.IsZero() ? Timestamp::Now() : now_; }

private:
    const std::uint8_t* data_ = nullptr;
    std::size_t dataSize_ = 0;
    int siteId_ = 0;
    const Key* explicitKey_ = nullptr;
    std::string advertisingToken_;
    const std::uint8_t* initializationVector_ = nullptr;
    std::size_t initializationVectorSize_ = 0;
    Timestamp now_;
};

class EncryptionDataResult {
public:
    static EncryptionDataResult MakeSuccess(std::string&& encryptedData) { return {EncryptionStatus::SUCCESS, std::move(encryptedData)}; }

    static EncryptionDataResult MakeError(EncryptionStatus status) { return {status, std::string()}; }

    bool IsSuccess() const { return status_ == EncryptionStatus::SUCCESS; }

    EncryptionStatus GetStatus() const { return status_; }

    const std::string& GetEncryptedData() const { return encryptedData_; }

private:
    EncryptionDataResult(EncryptionStatus status, std::string&& encryptedData) : status_(status), encryptedData_(std::move(encryptedData)) {}

    EncryptionStatus status_;
    std::string encryptedData_;
};

class DecryptionDataResult {
public:
    static DecryptionDataResult MakeSuccess(std::vector<std::uint8_t>&& decryptedData, Timestamp encryptedAt)
    {
        return {DecryptionStatus::SUCCESS, std::move(decryptedData), encryptedAt};
    }

    static DecryptionDataResult MakeError(DecryptionStatus status) { return {status, {}, Timestamp()}; }

    bool IsSuccess() const { return status_ == DecryptionStatus::SUCCESS; }

    DecryptionStatus GetStatus() const { return status_; }

    const std::vector<std::uint8_t>& GetDecryptedData() const { return decryptedData_; }

    Timestamp GetEncryptedAt() const { return encryptedAt_; }

private:
    DecryptionDataResult(DecryptionStatus status, std::vector<std::uint8_t>&& data, Timestamp encryptedAt)
        : status_(status), decryptedData_(std::move(data)), encryptedAt_(encryptedAt)
    {
    }

    DecryptionStatus status_;
    std::vector<std::uint8_t> decryptedData_;
    Timestamp encryptedAt_;
};
}  // namespace uid2
