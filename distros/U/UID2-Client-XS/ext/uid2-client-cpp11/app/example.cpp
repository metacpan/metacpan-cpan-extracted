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

#include <chrono>
#include <iostream>
#include <thread>

using namespace uid2;

static void StartExample(const std::string& desc)
{
	std::cout << "\nEXAMPLE: " << desc << "\n\n";
	std::cout.flush();
}

static void ExampleBasic(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string adToken)
{
	StartExample("Basic keys refresh and decrypt token");

	const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
	const auto refreshResult = client->Refresh();
	if (!refreshResult.IsSuccess())
	{
		std::cout << "Failed to refresh keys: " << refreshResult.GetReason() << "\n";
		return;
	}

	const auto result = client->Decrypt(adToken, Timestamp::Now());
	std::cout << "DecryptedSuccess=" << result.IsSuccess() << " Status=" << (int)result.GetStatus() << "\n";
	std::cout << "UID=" << result.GetUid() << "\n";
	std::cout << "EstablishedAt=" << result.GetEstablished().GetEpochSecond() << "\n";
    std::cout << "SiteId=" << result.GetSiteId() << "\n";
}

static void ExampleAutoRefresh(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string adToken)
{
	StartExample("Automatic background keys refresh");

	const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
	std::thread refreshThread([&]
		{
			for(int i = 0; i < 8; ++i)
			{
				std::this_thread::sleep_for(std::chrono::seconds(3));
				const auto refreshResult = client->Refresh();
				std::cout << "Refresh keys, success=" << refreshResult.IsSuccess() << "\n";
				std::cout.flush();
			}
		});

	for (int i = 0; i < 5; ++i)
	{
		const auto result = client->Decrypt(adToken, Timestamp::Now());
		std::cout << "DecryptSuccess=" << result.IsSuccess() << " Status=" << (int)result.GetStatus() << " UID=" << result.GetUid() << "\n";
		std::cout.flush();
		std::this_thread::sleep_for(std::chrono::seconds(5));
	}

	refreshThread.join();
}

static void ExampleEncryptDecryptData(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string adToken)
{
	StartExample("Encrypt and Decrypt Data");

	const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
	const auto refreshResult = client->Refresh();
	if (!refreshResult.IsSuccess())
	{
		std::cout << "Failed to refresh keys: " << refreshResult.GetReason() << "\n";
		return;
	}

	const std::string data = "Hello World!";
	const auto encrypted = client->EncryptData(EncryptionDataRequest((const std::uint8_t*)data.data(), data.size()).WithAdvertisingToken(adToken));
	if (!encrypted.IsSuccess())
	{
			std::cout << "Failed to encrypt data: " << (int)encrypted.GetStatus() << "\n";
	}
	else
	{
		const auto decrypted = client->DecryptData(encrypted.GetEncryptedData());
		if (!decrypted.IsSuccess())
		{
			std::cout << "Failed to decrypt data: " << (int)decrypted.GetStatus() << "\n";
		}
		else
		{
			std::cout << "Original data: " << data << "\n";
			std::cout << "Encrypted: " << encrypted.GetEncryptedData() << "\n";
			std::cout << "Decrypted: ";
			std::cout.write((const char*)decrypted.GetDecryptedData().data(), decrypted.GetDecryptedData().size());
			std::cout << "\n";
			std::cout << "Encrypted at: " << decrypted.GetEncryptedAt().GetEpochSecond() << "\n";
		}
	}
}

int main(int argc, char** argv)
{
	if(argc < 5)
	{
		std::cerr << "Usage: example <base-url> <api-key> <secret-key> <ad-token>" << std::endl;
		return 1;
	}

	const std::string baseUrl = argv[1];
	const std::string apiKey = argv[2];
    const std::string secretKey = argv[3];
	const std::string adToken = argv[4];

	ExampleBasic(baseUrl, apiKey, secretKey, adToken);
	ExampleAutoRefresh(baseUrl, apiKey, secretKey, adToken);
	ExampleEncryptDecryptData(baseUrl, apiKey, secretKey, adToken);

	return 0;
}
