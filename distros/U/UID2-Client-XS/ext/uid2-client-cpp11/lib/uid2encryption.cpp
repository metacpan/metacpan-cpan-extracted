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

#include "uid2encryption.h"

#include "aes.h"
#include "base64.h"
#include "bigendianprocessor.h"

#include <memory>
#include <stdexcept>
#include <unordered_map>

#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

namespace uid2
{
	enum
	{
		BLOCK_SIZE = 16
	};

	enum class PayloadType : std::uint8_t
	{
		ENCRYPTED_DATA = 128,
        ENCRYPTED_DATA_V3 = 96,
    };

    static const int GCM_AUTHTAG_LENGTH = 16;
    static const int GCM_IV_LENGTH = 12;

	static void Decrypt(const std::uint8_t* data, int size, const std::uint8_t* iv, const std::uint8_t* secret, std::vector<std::uint8_t>& out_decrypted);
    static int EncryptGCM(const std::uint8_t* data, int size, const std::uint8_t* iv, const std::uint8_t* secret, std::uint8_t* out_encrypted);

    static IdentityScope DecodeIdentityScopeV3(std::uint8_t value);

    static DecryptionResult DecryptTokenV2(const std::vector<std::uint8_t>& encryptedId, const KeyContainer& keys, Timestamp now, bool checkValidity);
    static DecryptionResult DecryptTokenV3(const std::vector<std::uint8_t>& encryptedId, const KeyContainer& keys, Timestamp now, IdentityScope identityScope, bool checkValidity);

    DecryptionResult DecryptToken(const std::string& token, const KeyContainer& keys, Timestamp now, IdentityScope identityScope, bool checkValidity)
	{
		try
		{
			std::vector<std::uint8_t> encodedId;
			macaron::Base64::Decode(token, encodedId);
			return DecryptToken(encodedId, keys, now, identityScope, checkValidity);
		}
		catch (...)
		{
			return DecryptionResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
		}
	}

	DecryptionResult DecryptToken(const std::vector<std::uint8_t>& encryptedId, const KeyContainer& keys, Timestamp now, IdentityScope identityScope, bool checkValidity)
    {
        if (encryptedId.size() < 2)
        {
            return DecryptionResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
        }

        if (encryptedId[0] == 2)
        {
            return DecryptTokenV2(encryptedId, keys, now, checkValidity);
        }
        else if (encryptedId[1] == 112)
        {
            return DecryptTokenV3(encryptedId, keys, now, identityScope, checkValidity);
        }

        return DecryptionResult::MakeError(DecryptionStatus::VERSION_NOT_SUPPORTED);
    }

    static DecryptionResult DecryptTokenV2(const std::vector<std::uint8_t>& encryptedId, const KeyContainer& keys, Timestamp now, bool checkValidity)
    {
		BigEndianByteReader reader(encryptedId);

		const int version = (int)reader.ReadByte();
		if (version != 2)
		{
			return DecryptionResult::MakeError(DecryptionStatus::VERSION_NOT_SUPPORTED);
		}

		const std::int32_t masterKeyId = reader.ReadInt32();

		const auto masterKey = keys.Get(masterKeyId);
		if (masterKey == nullptr)
		{
			return DecryptionResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
		}

		std::uint8_t iv[BLOCK_SIZE];
		reader.ReadBytes(iv, 0, sizeof(iv));

		std::vector<std::uint8_t> masterDecrypted;
		Decrypt(&encryptedId[21], encryptedId.size() - 21, iv, masterKey->secret.data(), masterDecrypted);

		BigEndianByteReader masterPayloadReader(masterDecrypted);

		const Timestamp expires = Timestamp::FromEpochMilli(masterPayloadReader.ReadInt64());
		const int siteKeyId = masterPayloadReader.ReadInt32();
		const auto siteKey = keys.Get(siteKeyId);
		if (siteKey == nullptr)
		{
			return DecryptionResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
		}

		masterPayloadReader.ReadBytes(iv, 0, BLOCK_SIZE);
		std::vector<std::uint8_t> identityDecrypted;
		Decrypt(&masterDecrypted[28], masterDecrypted.size() - 28, iv, siteKey->secret.data(), identityDecrypted);

		BigEndianByteReader identityPayloadReader(identityDecrypted);

		const int siteId = identityPayloadReader.ReadInt32();
		const std::int32_t idLength = identityPayloadReader.ReadInt32();

		std::string idString;
		idString.resize(idLength);
		identityPayloadReader.ReadBytes((std::uint8_t*)&idString[0], 0, idLength);

		const std::int32_t privacyBits = identityPayloadReader.ReadInt32();
		const Timestamp established = Timestamp::FromEpochMilli(identityPayloadReader.ReadInt64());

        if (checkValidity && expires < now)
        {
            return DecryptionResult::MakeError(DecryptionStatus::EXPIRED_TOKEN, established, siteId, siteKey->siteId);
        }

        return DecryptionResult::MakeSuccess(std::move(idString), established, siteId, siteKey->siteId);
	}

    static DecryptionResult DecryptTokenV3(const std::vector<std::uint8_t>& encryptedId, const KeyContainer& keys, Timestamp now, IdentityScope identityScope, bool checkValidity)
    {
        BigEndianByteReader reader(encryptedId);

        const auto prefix = reader.ReadByte();
        if (DecodeIdentityScopeV3(prefix) != identityScope)
        {
            return DecryptionResult::MakeError(DecryptionStatus::INVALID_IDENTITY_SCOPE);
        }

        const auto version = reader.ReadByte();

        const std::int32_t masterKeyId = reader.ReadInt32();
        const auto masterKey = keys.Get(masterKeyId);
        if (masterKey == nullptr)
        {
            return DecryptionResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
        }

        std::uint8_t masterPayload[256];
        if (reader.GetRemainingSize() > sizeof(masterPayload))
        {
            return DecryptionResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
        }
        const int masterPayloadLen = DecryptGCM(reader.GetCurrentData(), reader.GetRemainingSize(), masterKey->secret.data(), masterPayload);

        BigEndianByteReader masterPayloadReader(masterPayload, masterPayloadLen);

        const Timestamp expires = Timestamp::FromEpochMilli(masterPayloadReader.ReadInt64());
        const Timestamp created = Timestamp::FromEpochMilli(masterPayloadReader.ReadInt64());

        const auto operatorSiteId = masterPayloadReader.ReadInt32();
        const auto operatorType = masterPayloadReader.ReadByte();
        const auto operatorVersion = masterPayloadReader.ReadInt32();
        const auto operatorClientKeyId = masterPayloadReader.ReadInt32();

        const auto siteKeyId = masterPayloadReader.ReadInt32();
        const auto siteKey = keys.Get(siteKeyId);
        if (siteKey == nullptr)
        {
            return DecryptionResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
        }

        std::uint8_t sitePayload[128];
        if (masterPayloadReader.GetRemainingSize() > sizeof(sitePayload))
        {
            return DecryptionResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
        }
        const auto sitePayloadLen = DecryptGCM(masterPayloadReader.GetCurrentData(), masterPayloadReader.GetRemainingSize(), siteKey->secret.data(), sitePayload);

        BigEndianByteReader sitePayloadReader(sitePayload, sitePayloadLen);

        const auto siteId = sitePayloadReader.ReadInt32();
        const auto publisherId = sitePayloadReader.ReadInt64();
        const auto publisherKeyId = sitePayloadReader.ReadInt32();

        const auto privacyBits = sitePayloadReader.ReadInt32();
        const Timestamp established = Timestamp::FromEpochMilli(sitePayloadReader.ReadInt64());
        const Timestamp refreshed = Timestamp::FromEpochMilli(sitePayloadReader.ReadInt64());

        if (checkValidity && expires < now)
        {
            return DecryptionResult::MakeError(DecryptionStatus::EXPIRED_TOKEN, established, siteId, siteKey->siteId);
        }

        const std::vector<std::uint8_t> identityBytes(sitePayloadReader.GetCurrentData(), sitePayloadReader.GetCurrentData() + sitePayloadReader.GetRemainingSize());
        auto idString = macaron::Base64::Encode(identityBytes);

        return DecryptionResult::MakeSuccess(std::move(idString), established, siteId, siteKey->siteId);
    }

    EncryptionDataResult EncryptData(const EncryptionDataRequest& req, const KeyContainer* keys, IdentityScope identityScope)
	{
		if (req.GetData() == nullptr) throw std::invalid_argument("data to encrypt must not be null");

		const auto now = req.GetNow();
		const Key* key = req.GetKey();
		int siteId = -1;
		if (key == nullptr)
		{
            int siteKeySiteId = -1;
			if (keys == nullptr)
			{
				return EncryptionDataResult::MakeError(EncryptionStatus::NOT_INITIALIZED);
			}
			else if (!keys->IsValid(now))
			{
				return EncryptionDataResult::MakeError(EncryptionStatus::KEYS_NOT_SYNCED);
            }
			else if (req.GetSiteId() > 0 && !req.GetAdvertisingToken().empty())
			{
				throw std::invalid_argument("only one of siteId or advertisingToken can be specified");
			}
			else if (req.GetSiteId() > 0)
			{
				siteId = req.GetSiteId();
                siteKeySiteId = siteId;
			}
			else
			{
				const auto decryptedToken = DecryptToken(req.GetAdvertisingToken(), *keys, now, identityScope, true);
				if (!decryptedToken.IsSuccess())
				{
					return EncryptionDataResult::MakeError(EncryptionStatus::TOKEN_DECRYPT_FAILURE);
				}
				siteId = decryptedToken.GetSiteId();
                siteKeySiteId = decryptedToken.GetSiteKeySiteId();
			}

			key = keys->GetActiveSiteKey(siteKeySiteId, now);
			if (key == nullptr)
			{
				return EncryptionDataResult::MakeError(EncryptionStatus::NOT_AUTHORIZED_FOR_KEY);
			}
		}
		else if (!key->IsActive(now))
		{
			return EncryptionDataResult::MakeError(EncryptionStatus::KEY_INACTIVE);
		}
		else
		{
			siteId = key->siteId;
		}

		const std::uint8_t* iv = req.GetInitializationVector();
		if (iv != nullptr && req.GetInitializationVectorSize() != GCM_IV_LENGTH)
		{
			throw std::invalid_argument("initialization vector size must be " + std::to_string(GCM_IV_LENGTH));
		}

		std::vector<std::uint8_t> payload(req.GetDataSize() + 12);
        BigEndianByteWriter payloadWriter(payload);
        payloadWriter.WriteInt64(now.GetEpochMilli());
        payloadWriter.WriteInt32(siteId);
        payloadWriter.WriteBytes(req.GetData(), 0, req.GetDataSize());

        std::vector<std::uint8_t> encryptedBytes(payload.size() + GCM_IV_LENGTH + GCM_AUTHTAG_LENGTH + 6);
        BigEndianByteWriter writer(encryptedBytes);
        writer.WriteByte((std::uint8_t)PayloadType::ENCRYPTED_DATA_V3 | ((std::uint8_t)identityScope << 4) | 0xB);
        writer.WriteByte((std::uint8_t)112); // version
        writer.WriteInt32(key->id);
        EncryptGCM(payload.data(), payload.size(), iv, key->secret.data(), encryptedBytes.data() + writer.GetPosition());

		return EncryptionDataResult::MakeSuccess(macaron::Base64::Encode(encryptedBytes));
	}

    static DecryptionDataResult DecryptDataV2(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys);
    static DecryptionDataResult DecryptDataV3(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys, IdentityScope identityScope);

    DecryptionDataResult DecryptData(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys, IdentityScope identityScope)
	{
        if (encryptedBytes.empty())
        {
            return DecryptionDataResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
        }

        if ((encryptedBytes[0] & 224) == (std::uint8_t)PayloadType::ENCRYPTED_DATA_V3)
        {
            return DecryptDataV3(encryptedBytes, keys, identityScope);
        }
        else
        {
            return DecryptDataV2(encryptedBytes, keys);
        }
    }

    static DecryptionDataResult DecryptDataV2(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys)
    {
		BigEndianByteReader reader(encryptedBytes);

		if (reader.ReadByte() != (std::uint8_t)PayloadType::ENCRYPTED_DATA)
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::INVALID_PAYLOAD_TYPE);
		}
		else if (reader.ReadByte() != 1)
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::VERSION_NOT_SUPPORTED);
		}

		const auto encryptedAt = Timestamp::FromEpochMilli(reader.ReadInt64());
		const int siteId = reader.ReadInt32();
		const std::int64_t keyId = reader.ReadInt32();
		const auto key = keys.Get(keyId);
		if (key == nullptr)
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
		}

		std::uint8_t iv[BLOCK_SIZE];
		reader.ReadBytes(iv, 0, sizeof(iv));
		std::vector<std::uint8_t> decryptedBytes;
		Decrypt(&encryptedBytes[34], encryptedBytes.size() - 34, iv, key->secret.data(), decryptedBytes);

		return DecryptionDataResult::MakeSuccess(std::move(decryptedBytes), encryptedAt);
	}

    static DecryptionDataResult DecryptDataV3(const std::vector<std::uint8_t>& encryptedBytes, const KeyContainer& keys, IdentityScope identityScope)
    {
        BigEndianByteReader reader(encryptedBytes);
        const auto payloadScope = DecodeIdentityScopeV3(reader.ReadByte());
        if (payloadScope != identityScope)
        {
            return DecryptionDataResult::MakeError(DecryptionStatus::INVALID_IDENTITY_SCOPE);
        }
        if (reader.ReadByte() != 112)
        {
            return DecryptionDataResult::MakeError(DecryptionStatus::VERSION_NOT_SUPPORTED);
        }

        const auto keyId = reader.ReadInt32();
        const auto key = keys.Get(keyId);
        if (key == nullptr)
        {
            return DecryptionDataResult::MakeError(DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
        }

        std::vector<std::uint8_t> payload(reader.GetRemainingSize());
        const auto payloadLen = DecryptGCM(reader.GetCurrentData(), reader.GetRemainingSize(), key->secret.data(), payload.data());

        BigEndianByteReader payloadReader(payload.data(), payloadLen);
        const auto encryptedAt = Timestamp::FromEpochMilli(payloadReader.ReadInt64());
        const int siteId = payloadReader.ReadInt32();

        return DecryptionDataResult::MakeSuccess({payloadReader.GetCurrentData(), payloadReader.GetCurrentData() + payloadReader.GetRemainingSize()}, encryptedAt);
    }

	void Decrypt(const std::uint8_t* data, int size, const std::uint8_t* iv, const std::uint8_t* secret, std::vector<std::uint8_t>& out_decrypted)
	{
		AES256 aes;
		const int paddedSize = (int)aes.GetPaddingLength(size);
		if (paddedSize != size || size < 16) throw "invalid input";
		out_decrypted.resize(paddedSize);
		aes.DecryptCBC(data, size, secret, iv, &out_decrypted[0]);
		// Remove PKCS7 padding
		const int padlen = out_decrypted[size-1];
		if (padlen < 1 || padlen > 16) throw "invalid pkcs7 padding";
		out_decrypted.resize(size - padlen);
	}

    template<typename T, typename D>
    using CleanupPtr = std::unique_ptr<T, D>;
    template<typename T, typename D>
    CleanupPtr<T, D> MakeCleanupPtr(T* ptr, D deleter)
    {
        return CleanupPtr<T, D>(ptr, deleter);
    }

    void RandomBytes(std::uint8_t* out, int count)
    {
        const int rc = RAND_bytes(out, count);
        if (rc <= 0)
        {
            throw std::runtime_error("failed to generate random bytes: " + std::to_string(ERR_get_error()));
        }
    }

    int EncryptGCM(const std::uint8_t* data, int size, const std::uint8_t* secret, std::uint8_t* out_encrypted)
    {
        return EncryptGCM(data, size, nullptr, secret, out_encrypted);
    }

    static int EncryptGCM(const std::uint8_t* data, int size, const std::uint8_t* iv, const std::uint8_t* secret, std::uint8_t* out_encrypted)
    {
        int totalLen = 0;
        if (iv == nullptr)
        {
            const int rc = RAND_bytes(out_encrypted, GCM_IV_LENGTH);
            if (rc <= 0) {
                throw std::runtime_error("failed to generate iv: " + std::to_string(ERR_get_error()));
            }
        }
        else
        {
            std::memcpy(out_encrypted, iv, GCM_IV_LENGTH);
        }
        totalLen += GCM_IV_LENGTH;

        auto ctx = MakeCleanupPtr(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
        if (!ctx) {
            throw std::runtime_error("failed to allocate new cipher context");
        }

        if (!EVP_EncryptInit_ex(ctx.get(), EVP_aes_256_gcm(), nullptr, secret, out_encrypted)) {
            throw std::runtime_error("failed to init encryption");
        }

        int outLen = 0;
        if (!EVP_EncryptUpdate(ctx.get(), out_encrypted + totalLen, &outLen, data, size))
        {
            throw std::runtime_error("failed to encrypt");
        }
        totalLen += outLen;

        if (!EVP_EncryptFinal_ex(ctx.get(), out_encrypted + totalLen, &outLen))
        {
            throw std::runtime_error("failed to finalize encrypt");
        }
        totalLen += outLen;

        if (!EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_GET_TAG, GCM_AUTHTAG_LENGTH, out_encrypted + totalLen)) {
            throw std::runtime_error("failed to get tag");
        }
        totalLen += GCM_AUTHTAG_LENGTH;

        return totalLen;
    }

    int DecryptGCM(const std::uint8_t* encrypted, int size, const std::uint8_t* secret, std::uint8_t* out_decrypted)
    {
        if (size < GCM_IV_LENGTH + GCM_AUTHTAG_LENGTH)
        {
            throw std::runtime_error("invalid ciphertext");
        }

        auto ctx = MakeCleanupPtr(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
        if (!ctx) {
            throw std::runtime_error("failed to allocate new cipher context");
        }

        if (!EVP_DecryptInit_ex(ctx.get(), EVP_aes_256_gcm(), nullptr, secret, encrypted)) {
            throw std::runtime_error("failed to init decryption");
        }

        int outLen = 0;
        if (!EVP_DecryptUpdate(ctx.get(), out_decrypted, &outLen, encrypted + GCM_IV_LENGTH, size - (GCM_IV_LENGTH + GCM_AUTHTAG_LENGTH)))
        {
            throw std::runtime_error("failed to decrypt");
        }
        const int totalLen = outLen;

        if (!EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_TAG, GCM_AUTHTAG_LENGTH, (void*)(encrypted + (size - GCM_AUTHTAG_LENGTH))))
        {
            throw std::runtime_error("failed to set auth tag for decrypt");
        }

        if (0 >= EVP_DecryptFinal_ex(ctx.get(), out_decrypted, &outLen))
        {
            throw std::runtime_error("auth data check failed");
        }

        return totalLen;
    }

    static IdentityScope DecodeIdentityScopeV3(std::uint8_t value)
    {
        return (IdentityScope)((value >> 4) & 1);
    }
}
