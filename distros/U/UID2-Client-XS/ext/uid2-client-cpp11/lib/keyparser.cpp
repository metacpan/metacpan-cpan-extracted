#include "keyparser.h"

#include "base64.h"
#include "json11.hpp"

namespace uid2 {
static const std::string BODY_NAME = "body";
static const std::string ID_NAME = "id";
static const std::string KEYS_NAME = "keys";
static const std::string CALLER_SITE_ID_NAME = "caller_site_id";
static const std::string MASTER_KEYSET_ID_NAME = "master_keyset_id";
static const std::string DEFAULT_KEYSET_ID_NAME = "default_keyset_id";
static const std::string TOKEN_EXPIRY_SECONDS_NAME = "token_expiry_seconds";
static const std::string SITE_ID_NAME = "site_id";
static const std::string KEYSET_ID_NAME = "keyset_id";
static const std::string CREATED_NAME = "created";
static const std::string ACTIVATES_NAME = "activates";
static const std::string EXPIRES_NAME = "expires";
static const std::string SECRET_NAME = "secret";

template <typename TInt>
static bool ExtractInt(const json11::Json::object& obj, const std::string& name, TInt& out_value);

static bool ExtractTimestamp(const json11::Json::object& obj, const std::string& name, Timestamp& out_value);

static bool ExtractString(const json11::Json::object& obj, const std::string& name, const std::string*& out_value);

static bool ExtractArray(const json11::Json::object& obj, const std::string& name, const json11::Json::array*& out_value);

static bool ExtractObject(const json11::Json::object& obj, const std::string& name, const json11::Json::object*& out_value);

bool KeyParser::TryParse(const std::string& jsonString, KeyContainer& out_container, std::string& out_err)
{
    const json11::Json json = json11::Json::parse(jsonString.c_str(), out_err, json11::STANDARD);

    if (!out_err.empty()) {
        return false;
    }

    if (!json.is_object()) {
        out_err = "returned json is not an object";
        return false;
    }

    const json11::Json::object* body;
    const json11::Json::array* keys;

    if (ExtractObject(json.object_items(), BODY_NAME, body)) {
        int callerSiteId;
        if (!ExtractInt(*body, CALLER_SITE_ID_NAME, callerSiteId)) {
            out_err = "returned json does not contain a caller site id";
            return false;
        }
        out_container.SetCallerSiteId(callerSiteId);

        int masterKeysetId;
        if (!ExtractInt(*body, MASTER_KEYSET_ID_NAME, masterKeysetId)) {
            out_err = "returned json does not contain a master keyset id";
            return false;
        }
        out_container.SetMasterKeySetId(masterKeysetId);

        int defaultKeysetId;
        if (!ExtractInt(*body, DEFAULT_KEYSET_ID_NAME, defaultKeysetId)) {
            defaultKeysetId = NO_KEYSET;
        }
        out_container.SetDefaultKeySetId(defaultKeysetId);

        int tokenExpirySeconds;
        if (!ExtractInt(*body, TOKEN_EXPIRY_SECONDS_NAME, tokenExpirySeconds)) {
            tokenExpirySeconds = 30 * 24 * 60 * 60;
        }
        out_container.SetTokenExpirySeconds(tokenExpirySeconds);

        if (!ExtractArray(*body, KEYS_NAME, keys)) {
            out_err = "returned json does not contain a keys array";
            return false;
        }
    } else if (!ExtractArray(json.object_items(), BODY_NAME, keys)) {
        out_err = "returned json does not contain a keys array";
        return false;
    }

    for (const auto& obj : *keys) {
        Key key;
        const auto& keyItem = obj.object_items();

        if (!ExtractInt(keyItem, ID_NAME, key.id_)) {
            out_err = "error parsing id";
            return false;
        }

        if (!ExtractInt(keyItem, SITE_ID_NAME, key.siteId_)) {
            out_err = "error parsing site id";
        }

        if (!ExtractInt(keyItem, KEYSET_ID_NAME, key.keysetId_)) {
            key.keysetId_ = -1;
        }

        if (!ExtractTimestamp(keyItem, CREATED_NAME, key.created_)) {
            out_err = "error parsing created time";
            return false;
        }

        if (!ExtractTimestamp(keyItem, ACTIVATES_NAME, key.activates_)) {
            out_err = "error parsing activation time";
            return false;
        }

        if (!ExtractTimestamp(keyItem, EXPIRES_NAME, key.expires_)) {
            out_err = "error parsing expiration time";
            return false;
        }

        const std::string* secretString;
        if (!ExtractString(keyItem, SECRET_NAME, secretString)) {
            out_err = "error parsing secret";
            return false;
        }

        macaron::Base64::Decode(*secretString, key.secret_);
        out_container.Add(std::move(key));
    }

    out_container.Sort();

    return true;
}

template <typename TInt>
bool ExtractInt(const json11::Json::object& obj, const std::string& name, TInt& out_value)
{
    const auto it = obj.find(name);

    if (it == obj.end()) {
        return false;
    }

    if (!it->second.is_number()) {
        return false;
    }

    out_value = it->second.int_value();
    return true;
}

bool ExtractTimestamp(const json11::Json::object& obj, const std::string& name, Timestamp& out_value)
{
    int value;
    if (!ExtractInt(obj, name, value)) {
        return false;
    }

    out_value = Timestamp::FromEpochSecond(value);
    return true;
}

bool ExtractString(const json11::Json::object& obj, const std::string& name, const std::string*& out_value)
{
    const auto it = obj.find(name);

    if (it == obj.end()) {
        return false;
    }
    if (!it->second.is_string()) {
        return false;
    }

    out_value = &it->second.string_value();
    return true;
}

bool ExtractArray(const json11::Json::object& obj, const std::string& name, const json11::Json::array*& out_value)
{
    const auto it = obj.find(name);

    if (it == obj.end()) {
        return false;
    }
    if (!it->second.is_array()) {
        return false;
    }

    out_value = &it->second.array_items();
    return true;
}

bool ExtractObject(const json11::Json::object& obj, const std::string& name, const json11::Json::object*& out_value)
{
    const auto it = obj.find(name);

    if (it == obj.end()) {
        return false;
    }
    if (!it->second.is_object()) {
        return false;
    }

    out_value = &it->second.object_items();
    return true;
}
}  // namespace uid2
