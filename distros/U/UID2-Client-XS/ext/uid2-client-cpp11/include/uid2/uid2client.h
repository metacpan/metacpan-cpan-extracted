#pragma once

#include <uid2/timestamp.h>
#include <uid2/types.h>

#include <cstdint>
#include <memory>
#include <string>

namespace uid2 {
class IUID2Client {
public:
    virtual ~IUID2Client() = default;

    /// Refreshes encryption keys. Call this regularly (eg every hour) to ensure keys are up to date.
    virtual RefreshResult Refresh() = 0;

    virtual DecryptionResult Decrypt(const std::string& token) = 0;

    virtual EncryptionResult Encrypt(const std::string& uid) = 0;

    /// @deprecated
    virtual EncryptionDataResult EncryptData(const EncryptionDataRequest& request) = 0;

    /// @deprecated
    virtual DecryptionDataResult DecryptData(const std::string& encryptedData) = 0;
};

class UID2Client : public IUID2Client {
public:
    UID2Client(std::string endpoint, std::string authKey, std::string secretKey, IdentityScope identityScope);

    ~UID2Client() override;

    // Disable copy and move
    UID2Client(const UID2Client&) = delete;
    UID2Client(UID2Client&&) = delete;
    UID2Client& operator=(const UID2Client&) = delete;
    UID2Client& operator=(UID2Client&&) = delete;

    RefreshResult Refresh() override;

    DecryptionResult Decrypt(const std::string& token) override;

    DecryptionResult Decrypt(const std::string& token, Timestamp now);

    EncryptionResult Encrypt(const std::string& uid) override;

    EncryptionResult Encrypt(const std::string& uid, Timestamp now);

    EncryptionDataResult EncryptData(const EncryptionDataRequest& request) override;

    DecryptionDataResult DecryptData(const std::string& encryptedData) override;

    RefreshResult RefreshJson(const std::string& json);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

class UID2ClientFactory {
public:
    static std::shared_ptr<IUID2Client> Create(std::string endpoint, std::string authKey, std::string secretKey)
    {
        return std::make_shared<UID2Client>(std::move(endpoint), std::move(authKey), std::move(secretKey), IdentityScope::UID2);
    }
};

class EUIDClientFactory {
public:
    static std::shared_ptr<IUID2Client> Create(std::string endpoint, std::string authKey, std::string secretKey)
    {
        return std::make_shared<UID2Client>(std::move(endpoint), std::move(authKey), std::move(secretKey), IdentityScope::EUID);
    }
};
}  // namespace uid2
