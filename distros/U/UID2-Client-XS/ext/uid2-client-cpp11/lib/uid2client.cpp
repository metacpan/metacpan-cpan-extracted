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

#include <uid2/uid2client.h>

#include "base64.h"
#include "bigendianprocessor.h"
#include "httplib.h"
#include "keycontainer.h"
#include "keyparser.h"
#include "uid2encryption.h"

#include <functional>
#include <mutex>

namespace uid2
{
	struct UID2Client::Impl
	{
		std::string endpoint;
		std::string authKey;
        std::vector<std::uint8_t> secretKey;
        IdentityScope identityScope;
		httplib::Client httpClient;
		std::shared_ptr<KeyContainer> container;
		mutable std::recursive_mutex refreshMutex;
		mutable std::mutex containerMutex;

		Impl(std::string endpoint, std::string authKey, std::string secretKey, IdentityScope identityScope)
			: endpoint(endpoint)
            , authKey(authKey)
            , identityScope(identityScope)
			, httpClient(endpoint.c_str())
		{
            macaron::Base64::Decode(secretKey, this->secretKey);

			if (endpoint.find("https") != 0)
			{
				// TODO: non-https endpoint warning
			}

			httpClient.set_default_headers({
				{ "Authorization",  "Bearer " + authKey }
				});
		}

		~Impl();

		std::string GetLatestKeys(std::string& out_err);
		RefreshResult RefreshJson(const std::string& json);
		void SwapKeyContainer(const std::shared_ptr<KeyContainer>& newContainer);
		std::shared_ptr<KeyContainer> GetKeyContainer() const;
	};

	UID2Client::UID2Client(std::string endpoint, std::string authKey, std::string secretKey, IdentityScope identityScope)
		: mImpl(new Impl(endpoint, authKey, secretKey, identityScope))
	{
	}

	UID2Client::~UID2Client()
	{
		mImpl.reset();
	}

	RefreshResult UID2Client::Refresh()
	{
		const std::lock_guard<std::recursive_mutex> lock(mImpl->refreshMutex);

		std::string err;
		std::string jsonResponse = mImpl->GetLatestKeys(err);
		if (!err.empty())
		{
			return RefreshResult::MakeError(std::move(err));
		}
		return mImpl->RefreshJson(jsonResponse);
	}

	DecryptionResult UID2Client::Decrypt(const std::string& token, Timestamp now)
	{
		// hold reference to container so it's not disposed by refresh
		const auto activeContainer = mImpl->GetKeyContainer();
		if (activeContainer == nullptr)
		{
			return DecryptionResult::MakeError(DecryptionStatus::NOT_INITIALIZED);
		}
		else if (!activeContainer->IsValid(now))
		{
			return DecryptionResult::MakeError(DecryptionStatus::KEYS_NOT_SYNCED);
		}

		return DecryptToken(token, *activeContainer, now, mImpl->identityScope, /*checkValidity*/true);
	}

	EncryptionDataResult UID2Client::EncryptData(const EncryptionDataRequest& req)
	{
		// hold reference to container so it's not disposed by refresh
		const auto activeContainer = mImpl->GetKeyContainer();
		return uid2::EncryptData(req, activeContainer.get(), mImpl->identityScope);
	}

	DecryptionDataResult UID2Client::DecryptData(const std::string& encryptedData)
	{
		// hold reference to container so it's not disposed by refresh
		const auto activeContainer = mImpl->GetKeyContainer();
		if (activeContainer == nullptr)
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::NOT_INITIALIZED);
		}
		else if (!activeContainer->IsValid(Timestamp::Now()))
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::KEYS_NOT_SYNCED);
		}

		try
		{
			std::vector<std::uint8_t> encryptedBytes;
			macaron::Base64::Decode(encryptedData, encryptedBytes);
			return uid2::DecryptData(encryptedBytes, *activeContainer, mImpl->identityScope);
		}
		catch (...)
		{
			return DecryptionDataResult::MakeError(DecryptionStatus::INVALID_PAYLOAD);
		}


		return DecryptionDataResult::MakeError(DecryptionStatus::SUCCESS);
	}

	RefreshResult UID2Client::RefreshJson(const std::string& json)
	{
		const std::lock_guard<std::recursive_mutex> lock(mImpl->refreshMutex);

		return mImpl->RefreshJson(json);
	}

	UID2Client::Impl::~Impl()
	{
		httpClient.stop();
	}

    static const int V2_NONCE_LEN = 8;
    static std::string MakeV2Request(const std::uint8_t* secret, Timestamp now, std::uint8_t* nonce)
    {
        std::uint8_t payload[16];
        BigEndianByteWriter writer(payload, sizeof(payload));
        writer.WriteInt64(now.GetEpochMilli());
        RandomBytes(nonce, V2_NONCE_LEN);
        writer.WriteBytes(nonce, 0, sizeof(nonce));

        std::vector<std::uint8_t> envelope(64);
        envelope[0] = 1;
        const int envelopeLen = 1 + EncryptGCM(payload, writer.GetPosition(), secret, envelope.data() + 1);
        envelope.resize(envelopeLen);

        return macaron::Base64::Encode(envelope);
    }
    static std::string ParseV2Response(const std::string& envelope, const std::uint8_t* secret, const std::uint8_t* nonce)
    {
        std::vector<std::uint8_t> envelopeBytes;
        macaron::Base64::Decode(envelope, envelopeBytes);
        std::vector<std::uint8_t> payload(envelopeBytes.size());
        const int payloadLen = DecryptGCM(envelopeBytes.data(), envelopeBytes.size(), secret, payload.data());
        if (payloadLen < 16)
        {
            throw std::runtime_error("invalid payload");
        }

        if (0 != std::memcmp(nonce, payload.data() + 8, V2_NONCE_LEN))
        {
            throw std::runtime_error("nonce mismatch");
        }

        return {(const char*)payload.data() + 16, std::size_t(payloadLen - 16)};
    }

	std::string UID2Client::Impl::GetLatestKeys(std::string& out_err)
	{
        std::uint8_t nonce[V2_NONCE_LEN];
        const auto request = MakeV2Request(secretKey.data(), Timestamp::Now(), nonce);
		if (auto res = httpClient.Post("/v2/key/latest", request, "text/plain"))
		{
			if (res->status >= 200 && res->status < 300)
			{
				return ParseV2Response(res->body, secretKey.data(), nonce);
			}
			else
			{
				out_err = "bad http response, status code: " + std::to_string(res->status);
			}
		}
		else
		{
			std::stringstream ss;
			ss << "error code: " << res.error();
			auto result = httpClient.get_openssl_verify_result();
			if (result)
			{
				ss << ", verify error: " << X509_verify_cert_error_string(result);
			}
			out_err = ss.str();
		}

		return "[]";
	}

	RefreshResult UID2Client::Impl::RefreshJson(const std::string& json)
	{
		std::string err;
		auto container = std::make_shared<KeyContainer>();
		if (KeyParser::TryParse(json, *container, err))
		{
			SwapKeyContainer(container);
			return RefreshResult::MakeSuccess();
		}
		else
		{
			return RefreshResult::MakeError(std::move(err));
		}
	}

	void UID2Client::Impl::SwapKeyContainer(const std::shared_ptr<KeyContainer>& newContainer)
	{
		const std::lock_guard<std::mutex> lock(containerMutex);
		this->container = std::shared_ptr<KeyContainer>{ newContainer };
	}

	std::shared_ptr<KeyContainer> UID2Client::Impl::GetKeyContainer() const
	{
		const std::lock_guard<std::mutex> lock(containerMutex);
		return this->container;
	}
}
