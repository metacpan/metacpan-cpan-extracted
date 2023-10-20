#pragma once

#include "keycontainer.h"
#include "uid2tokengenerator.h"

#include <uid2/timestamp.h>
#include <uid2/types.h>

#include <cstdint>
#include <vector>

namespace uid2 {
DecryptionResult DecryptToken(const std::string& token, const KeyContainer& keys, Timestamp now, IdentityScope identityScope, bool checkValidity);

EncryptionDataResult EncryptData(const EncryptionDataRequest& req, const KeyContainer* keys, IdentityScope identityScope);

DecryptionDataResult DecryptData(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys, IdentityScope identityScope);

void RandomBytes(std::uint8_t* out, int count);

EncryptionResult EncryptUID(const std::string& uid, const KeyContainer& keys, Timestamp now, IdentityScope identityScope);

int EncryptGCM(const std::uint8_t* data, int size, const std::uint8_t* secret, std::uint8_t* out_encrypted);
int DecryptGCM(const std::uint8_t* encrypted, int size, const std::uint8_t* secret, std::uint8_t* out_decrypted);
}  // namespace uid2
