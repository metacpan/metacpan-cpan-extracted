#pragma once

#include "key.h"

#include <algorithm>
#include <unordered_map>
#include <vector>

namespace uid2 {
class KeyContainer {
public:
    KeyContainer() = default;

    KeyContainer(int callerSiteId, int masterKeysetId, int defaultKeysetId, std::int64_t tokenExpirySeconds)
        : callerSiteId_(callerSiteId), masterKeySetId_(masterKeysetId), defaultKeySetId_(defaultKeysetId), tokenExpirySeconds_(tokenExpirySeconds)
    {
    }

    KeyContainer(const KeyContainer&) = delete;
    KeyContainer& operator=(const KeyContainer&) = delete;

    void Add(Key&& key)
    {
        auto& k = idMap_[key.id_];
        k = std::move(key);
        if (k.siteId_ > 0) {
            keysBySite_[k.siteId_].push_back(&k);
        }
        if (k.keysetId_ != NO_KEYSET) {
            keysByKeyset_[k.keysetId_].push_back(&k);
        }
        if (latestKeyExpiry_ < k.expires_) {
            latestKeyExpiry_ = k.expires_;
        }
    }

    void Sort()
    {
        const auto end = keysBySite_.end();
        for (auto it = keysBySite_.begin(); it != end; ++it) {
            auto& siteKeys = it->second;
            std::sort(siteKeys.begin(), siteKeys.end(), [](const Key* a, const Key* b) { return a->activates_ < b->activates_; });
        }
    }

    const Key* Get(std::int64_t id) const
    {
        const auto it = idMap_.find(id);
        return it == idMap_.end() ? nullptr : &it->second;
    }

    const Key* GetActiveSiteKey(int siteId, Timestamp now) const
    {
        const auto itK = keysBySite_.find(siteId);
        if (itK == keysBySite_.end() || itK->second.empty()) {
            return nullptr;
        }
        const auto& siteKeys = itK->second;
        auto it = std::upper_bound(siteKeys.begin(), siteKeys.end(), now, [](Timestamp ts, const Key* k) { return ts < k->activates_; });
        while (it != siteKeys.begin()) {
            --it;
            const auto* const key = *it;
            if (key->IsActive(now)) {
                return key;
            }
        }
        return nullptr;
    }

    const Key* GetActiveKeysetKey(int keysetId, Timestamp now) const
    {
        const auto itK = keysByKeyset_.find(keysetId);
        if (itK == keysByKeyset_.end() || itK->second.empty()) {
            return nullptr;
        }
        const auto& siteKeys = itK->second;
        auto it = std::upper_bound(siteKeys.begin(), siteKeys.end(), now, [](Timestamp ts, const Key* k) { return ts < k->activates_; });
        while (it != siteKeys.begin()) {
            --it;
            const auto* const key = *it;
            if (key->IsActive(now)) {
                return key;
            }
        }
        return nullptr;
    }

    inline bool IsValid(Timestamp now) const { return latestKeyExpiry_ > now; }

    int GetCallerSiteId() const { return callerSiteId_; }

    void SetCallerSiteId(int callerSiteId) { KeyContainer::callerSiteId_ = callerSiteId; }

    int GetMasterKeySetId() const { return masterKeySetId_; }

    const Key* GetMasterKey(Timestamp now) const { return GetActiveKeysetKey(masterKeySetId_, now); }

    void SetMasterKeySetId(int masterKeySetId) { KeyContainer::masterKeySetId_ = masterKeySetId; }

    int GetDefaultKeySetId() const { return defaultKeySetId_; }

    void SetDefaultKeySetId(int defaultKeySetId) { KeyContainer::defaultKeySetId_ = defaultKeySetId; }

    const Key* GetDefaultKey(Timestamp now) const { return GetActiveKeysetKey(defaultKeySetId_, now); }

    std::int64_t GetTokenExpirySeconds() const { return tokenExpirySeconds_; }

    void SetTokenExpirySeconds(int64_t tokenExpirySeconds) { KeyContainer::tokenExpirySeconds_ = tokenExpirySeconds; }

private:
    std::unordered_map<std::int64_t, Key> idMap_;
    std::unordered_map<int, std::vector<const Key*>> keysBySite_;
    std::unordered_map<int, std::vector<const Key*>> keysByKeyset_;
    Timestamp latestKeyExpiry_;
    int callerSiteId_ = -1;
    int masterKeySetId_ = -1;
    int defaultKeySetId_ = -1;
    std::int64_t tokenExpirySeconds_ = -1;
};
}  // namespace uid2
