# UID2 SDK for C++

The UID 2 Project is subject to Tech Lab IPR’s Policy and is managed by the IAB Tech Lab Addressability Working Group and Privacy & Rearc Commit Group. Please review [the governance rules](https://github.com/IABTechLab/uid2-core/blob/master/Software%20Development%20and%20Release%20Procedures.md).

This SDK simplifies integration with UID2 for those using C++.

## Dependencies

This SDK requires C++ version 11.

Supported platforms:

 - Linux (tested on Ubuntu 22.04)
 - MacOS (tested on macOS 12 Monterey and macOS 13 Ventura)

Supported compilers:

 - clang (tested on versions 12 and 14)
 - gcc (tested on version 11)

Your mileage may vary with other compilers and versions.

Other dependencies:

 - CMake 3.12+
 - OpenSSL 1.1.1+
 - GoogleTest

To set up dependencies on Ubuntu 22.04:

```
sudo ./tools/install-ubuntu-devtools.sh
sudo ./tools/install-ubuntu-deps.sh
```

To set up dependencies on macOS, make sure you have latest xcode installed, then:

```
./tools/install-macos-deps.sh
```

If you want to have clang-14 installed on Mac, run these additional commands:

```
brew install llvm@14
sudo ln -s $(brew --prefix llvm@14)/bin/clang /usr/local/bin/clang-14
sudo ln -s $(brew --prefix llvm@14)/bin/clang++ /usr/local/bin/clang++-14
sudo ln -s $(brew --prefix llvm@14)/bin/clang-format /usr/local/bin/clang-format-14
sudo ln -s $(brew --prefix llvm@14)/bin/clang-tidy /usr/local/bin/clang-tidy-14
```

## Build, Test, Install

To build, run unit tests, and install under the default prefix (`/usr/local`):

```
cd <this directory>
mkdir build
cd build
cmake ..
make
make test
sudo make install
```

You can build a docker image containing the necessary tools and dependencies and then use that to build and test the SDK.

```
docker build -t uid2_client_cpp_devenv .
docker run -it --rm -v "$PWD:$PWD" -u $(id -u ${USER}):$(id -g ${USER}) -w "$PWD" uid2_client_cpp_devenv ./tools/build.sh
# or
./tools/devenv.sh ./tools/build.sh
```

## Usage

To create a UID2 client instance, use `UID2ClientFactory::Create`. For an EUID client instance, use `EUIDClientFactory::Create`.

 - `client->Refresh()` to fetch the latest keys
 - `client->Decrypt()` to decrypt a UID2 or EUID token
 - `client->Encrypt()` to encrypt a raw UID2 or EUID into a token

For an example, see [app/example.cpp](app/example.cpp). To run the example application:

```
# ./build/app/example <base-url> <api-key> <secret-key> <advertising-token>
# For example:
./build/app/example https://operator-integ.uidapi.com test-id-reader-key your-secret-key "AgAAAANz...YgSCA=="
```

## Working on codebase

The code is expected to be formatted according to clang-format rules specified at the root of the project.
Most modern IDEs should pick that up automatically. To reformat all the code, run (requires docker):

```
./tools/devenv.sh ./tools/format.sh --fix
```

By default, compiler warnings are treated as errors. To temporarily disable this behavior, set CMake `WARNING_AS_ERROR` option to `OFF`. For example:

```
cmake -DWARNING_AS_ERROR=OFF
```

Additionally the codebase is subject to clang-tidy checks. Some IDEs can pick that up automatically. Otherwise
you can run the checks by running (requires docker):

```
./tools/devenv.sh ./tools/build.sh clang-tidy
```
