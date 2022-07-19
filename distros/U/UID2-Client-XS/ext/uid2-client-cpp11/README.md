# UID2 Client

UID2 Client for C++11

See `Dockerfile` for installation example

See `app/example.cpp` for example usage.

## Dependencies

```
CMake 3.12+

OpenSSL 1.1.1+
on Alpine: apk add libressl-dev
on Ubuntu: apt-get install libssl-dev

GTest
on Alpine: apk add gtest-dev
on Ubuntu: apt-get install libgtest-dev
```

## Install

```
cd <this directory>
mkdir build
cd build
cmake ..
make
make test
make install
```

## Running the example

```
docker build . -t uid2_client_cpp
# docker run -it uid2_client_cpp <base-url> <api-key> <secret-key> <advertising-token>
# For example:
docker run -it uid2_client_cpp https://integ.uidapi.com test-id-reader-key your-secret-key \
	AgAAAANzUr8B6CCM+WBKichZGU8iyDBSI83LXiXa1SW2i4LaVQPzlBtOhjoeUUc3Nv+aOPLwiVol0rnxwdNkJNgm710I4lKAp8kpjqZO6evjN6mVZalwzQA5Y4usQVEtwBkYr3V3MbYR1eI3n0Bc7/KVeanfBXUF4odpHNBEWTAL+YgSCA==
```

## Usage

Use `UID2ClientFactory::Create` to create a uid2 client instance.

 - `client->Refresh()` to fetch the latest keys
 - `client->Decrypt()` to decrypt an advertising token
 - `client->EncryptData()` to encrypt arbitrary data
 - `client->DecryptData()` to decrypt data encrypted with `EncryptData()`

Also see `app/example.cpp`.

## License

```
   Copyright (c) 2021 The Trade Desk, Inc

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
```
