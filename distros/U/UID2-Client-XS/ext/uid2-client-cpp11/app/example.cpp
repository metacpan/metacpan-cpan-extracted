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

static void ExampleBasic(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string& adToken)
{
    StartExample("Basic keys refresh and decrypt token");

    const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
    const auto refreshResult = client->Refresh();
    if (!refreshResult.IsSuccess()) {
        std::cout << "Failed to refresh keys: " << refreshResult.GetReason() << "\n";
        return;
    }

    const auto result = client->Decrypt(adToken);
    std::cout << "DecryptedSuccess=" << result.IsSuccess() << " Status=" << static_cast<int>(result.GetStatus()) << "\n";
    std::cout << "UID=" << result.GetUid() << "\n";
    std::cout << "EstablishedAt=" << result.GetEstablished().GetEpochSecond() << "\n";
    std::cout << "SiteId=" << result.GetSiteId() << "\n";
}

static void ExampleAutoRefresh(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string& adToken)
{
    StartExample("Automatic background keys refresh");

    const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
    std::thread refreshThread([&] {
        for (int i = 0; i < 8; ++i) {
            std::this_thread::sleep_for(std::chrono::seconds(3));
            const auto refreshResult = client->Refresh();
            std::cout << "Refresh keys, success=" << refreshResult.IsSuccess() << "\n";
            std::cout.flush();
        }
    });

    for (int i = 0; i < 5; ++i) {
        const auto result = client->Decrypt(adToken);
        std::cout << "DecryptSuccess=" << result.IsSuccess() << " Status=" << static_cast<int>(result.GetStatus()) << " UID=" << result.GetUid() << "\n";
        std::cout.flush();
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    refreshThread.join();
}

static void ExampleEncryptDecryptData(const std::string& baseUrl, const std::string& apiKey, const std::string& secretKey, const std::string& adToken)
{
    StartExample("Encrypt and Decrypt Data");

    const auto client = UID2ClientFactory::Create(baseUrl, apiKey, secretKey);
    const auto refreshResult = client->Refresh();
    if (!refreshResult.IsSuccess()) {
        std::cout << "Failed to refresh keys: " << refreshResult.GetReason() << "\n";
        return;
    }

    const std::string data = "Hello World!";
    const auto encrypted =
        client->EncryptData(EncryptionDataRequest(reinterpret_cast<const std::uint8_t*>(data.data()), data.size()).WithAdvertisingToken(adToken));
    if (!encrypted.IsSuccess()) {
        std::cout << "Failed to encrypt data: " << static_cast<int>(encrypted.GetStatus()) << "\n";
    } else {
        const auto decrypted = client->DecryptData(encrypted.GetEncryptedData());
        if (!decrypted.IsSuccess()) {
            std::cout << "Failed to decrypt data: " << static_cast<int>(decrypted.GetStatus()) << "\n";
        } else {
            std::cout << "Original data: " << data << "\n";
            std::cout << "Encrypted: " << encrypted.GetEncryptedData() << "\n";
            std::cout << "Decrypted: ";
            std::cout.write(
                reinterpret_cast<const char*>(decrypted.GetDecryptedData().data()), static_cast<std::streamsize>(decrypted.GetDecryptedData().size()));
            std::cout << "\n";
            std::cout << "Encrypted at: " << decrypted.GetEncryptedAt().GetEpochSecond() << "\n";
        }
    }
}

int main(int argc, char** argv)
{
    if (argc < 5) {
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
