#include "base64.h"

#include <gtest/gtest.h>

#include <set>

// for testing base64/base64url encoding/decoding in "base64.h"

static void VerifyEncodingDecodingTables(
    const std::string& expectedEncodingTable,
    const char encodingTable[],
    const unsigned int encodingTableLen,
    const unsigned char decodingTable[],
    const unsigned int decodingTableLen)
{
    std::set<unsigned int> decodedValues;
    EXPECT_EQ(expectedEncodingTable.size(), 64);
    EXPECT_EQ(expectedEncodingTable.size(), encodingTableLen);
    for (int i = 0; i < static_cast<int>(expectedEncodingTable.size()); i++) {
        EXPECT_EQ(expectedEncodingTable[i], encodingTable[i]);
        const char chr = expectedEncodingTable[i];
        const auto decoderTableIndex = static_cast<unsigned char>(chr);
        const unsigned int decodedValue = decodingTable[decoderTableIndex];
        EXPECT_EQ(decodedValue, i);
        decodedValues.insert(decoderTableIndex);
    }

    // verify all the non-base64/base64url chars must have decoding value of 64 (b1000000)
    EXPECT_EQ(decodingTableLen, 256);
    for (unsigned int i = 0; i < decodingTableLen; i++) {
        if (decodedValues.find(i) == decodedValues.end()) {
            std::cout << i << std::endl;
            EXPECT_EQ(decodingTable[i], 64);
        }
    }
}

TEST(Base64Encoding, SameEncodingDecodingTables)
{
    VerifyEncodingDecodingTables(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
        macaron::base64EncodingTable,
        sizeof(macaron::base64EncodingTable) / sizeof(char),
        macaron::base64DecodingTable,
        sizeof(macaron::base64DecodingTable) / sizeof(unsigned char));
}

TEST(Base64URLEncoding, SameEncodingDecodingTables)
{
    VerifyEncodingDecodingTables(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
        macaron::base64URLEncodingTable,
        sizeof(macaron::base64URLEncodingTable) / sizeof(char),
        macaron::base64URLDecodingTable,
        sizeof(macaron::base64URLDecodingTable) / sizeof(unsigned char));
}
