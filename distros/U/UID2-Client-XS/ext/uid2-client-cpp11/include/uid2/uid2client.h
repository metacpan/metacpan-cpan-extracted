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

#include <uid2/timestamp.h>
#include <uid2/types.h>

#include <cstdint>
#include <memory>
#include <string>

namespace uid2
{
	class IUID2Client
	{
	public:
		virtual ~IUID2Client() = default;

		virtual RefreshResult Refresh() = 0;
		virtual DecryptionResult Decrypt(const std::string& token, Timestamp now) = 0;
		virtual EncryptionDataResult EncryptData(const EncryptionDataRequest& request) = 0;
		virtual DecryptionDataResult DecryptData(const std::string& encryptedData) = 0;
	};

	class UID2Client : public IUID2Client
	{
	public:
		UID2Client(std::string endpoint, std::string authKey, std::string secretKey, IdentityScope identityScope);
		~UID2Client();

		RefreshResult Refresh() override;
		DecryptionResult Decrypt(const std::string& token, Timestamp now) override;
		EncryptionDataResult EncryptData(const EncryptionDataRequest& request) override;
		DecryptionDataResult DecryptData(const std::string& encryptedData) override;

		RefreshResult RefreshJson(const std::string& json);

	private:
		// Disable copy and move
		UID2Client(const UID2Client&) = delete;
		UID2Client(UID2Client&&) = delete;
		UID2Client& operator=(const UID2Client&) = delete;
		UID2Client& operator=(UID2Client&&) = delete;

		struct Impl;
		std::unique_ptr<Impl> mImpl;
	};

	class UID2ClientFactory
	{
	public:
		static std::shared_ptr<IUID2Client> Create(std::string endpoint, std::string authKey, std::string secretKey)
		{
			return std::make_shared<UID2Client>(endpoint, authKey, secretKey, IdentityScope::UID2);
		}
	};

    class EUIDClientFactory
    {
    public:
        static std::shared_ptr<IUID2Client> Create(std::string endpoint, std::string authKey, std::string secretKey)
        {
            return std::make_shared<UID2Client>(endpoint, authKey, secretKey, IdentityScope::EUID);
        }
    };
}
