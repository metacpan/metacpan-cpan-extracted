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

#include "keyparser.h"

#include "base64.h"
#include "json11.hpp"

namespace uid2
{
	static const std::string BODY_NAME = "body";
	static const std::string ID_NAME = "id";
	static const std::string SITE_ID_NAME = "site_id";
	static const std::string CREATED_NAME = "created";
	static const std::string ACTIVATES_NAME = "activates";
	static const std::string EXPIRES_NAME = "expires";
	static const std::string SECRET_NAME = "secret";

	template<typename TInt>
	static bool ExtractInt(const json11::Json::object& obj, const std::string& name, TInt& out_value);
	static bool ExtractTimestamp(const json11::Json::object& obj, const std::string& name, Timestamp& out_value);
	static bool ExtractString(const json11::Json::object& obj, const std::string& name, const std::string*& out_value);
	static bool ExtractArray(const json11::Json::object& obj, const std::string& name, const json11::Json::array*& out_value);

	bool KeyParser::TryParse(const std::string& jsonString, KeyContainer& out_container, std::string& out_err)
	{
		const json11::Json json = json11::Json::parse(jsonString.c_str(), out_err, json11::STANDARD);

		if (!out_err.empty())
			return false;

		if (!json.is_object())
		{
			out_err = "returned json is not an object";
			return false;
		}

		const json11::Json::array* body;
		if (!ExtractArray(json.object_items(), BODY_NAME, body))
		{
			out_err = "returned json does not contain an array body";
			return false;
		}

		for (const auto& obj : *body)
		{
			Key key;
			const auto& keyItem = obj.object_items();

			if (!ExtractInt(keyItem, ID_NAME, key.id))
			{
				out_err = "error parsing id";
				return false;
			}

			if (!ExtractInt(keyItem, SITE_ID_NAME, key.siteId))
			{
				out_err = "error parsing site id";
				return false;
			}

			if (!ExtractTimestamp(keyItem, CREATED_NAME, key.created))
			{
				out_err = "error parsing created time";
				return false;
			}

			if (!ExtractTimestamp(keyItem, ACTIVATES_NAME, key.activates))
			{
				out_err = "error parsing activation time";
				return false;
			}

			if (!ExtractTimestamp(keyItem, EXPIRES_NAME, key.expires))
			{
				out_err = "error parsing expiration time";
				return false;
			}

			const std::string* secret_string;
			if (!ExtractString(keyItem, SECRET_NAME, secret_string))
			{
				out_err = "error parsing secret";
				return false;
			}

			macaron::Base64::Decode(*secret_string, key.secret);
			out_container.Add(std::move(key));
		}

		out_container.Sort();

		return true;
	}

	template<typename TInt>
	bool ExtractInt(const json11::Json::object& obj, const std::string& name, TInt& out_value)
	{
		const auto it = obj.find(name);

		if (it == obj.end())
			return false;

		if (!it->second.is_number())
			return false;

		out_value = it->second.int_value();
		return true;
	}

	bool ExtractTimestamp(const json11::Json::object& obj, const std::string& name, Timestamp& out_value)
	{
		int value;
		if (!ExtractInt(obj, name, value))
			return false;

		out_value = Timestamp::FromEpochSecond(value);
		return true;
	}

	bool ExtractString(const json11::Json::object& obj, const std::string& name, const std::string*& out_value)
	{
		const auto it = obj.find(name);

		if (it == obj.end()) return false;
		if (!it->second.is_string()) return false;

		out_value = &it->second.string_value();
		return true;
	}

	bool ExtractArray(const json11::Json::object& obj, const std::string& name, const json11::Json::array*& out_value)
	{
		const auto it = obj.find(name);

		if (it == obj.end()) return false;
		if (!it->second.is_array()) return false;

		out_value = &it->second.array_items();
		return true;
	}
}
