# YAML-yq-Helper

Wrapper for yq for various common tasks so YAML files can be
manipulated in a manner to preserver comments and version header.

## Install

### Debian

```
apt-get install cpanminus
cpanm YAML::yq::Helper
```

### FreeBSD

```
pkg install p5-App-cpanminus
cpanm YAML::yq::Helper
```

### Source

```
perl Makefile.PL
make
make test
make install
```

## yqh

```
-f <file>         Config INI file.
                  Default :: undef

-a <action>       Action to perform.
                  Default :: undef

--var <string>    Variable to set.
                  Default :: undef

--vals <string>   Comma seperate list of array values.
                  Default :: undef

--hash <string>   Comma seperate list of hash values. Each
                  value is a sub string with key/value seperate
                  by a /=/.
                  Default :: undef

--dedup <bool>    If it should dedup the data for the op.
                  Default :: 1

Action :: is_array
Description :: Returns 0 or 1 based on if it is a array.
Requires :: --var

Action :: is_hash
Description :: Returns 0 or 1 based on if it is a hash.
Requires :: --var

Action :: is_defined
Description :: Returns 0 or 1 based on if it is defined.
Requires :: --var

Action :: clear_array
Description :: Clears the specified array.
Requires :: --var

Action :: clear_hash
Description :: Clears the specified hash.
Requires :: --var

Action :: create_array
Description :: Creates the specified array if it does not exist.
Requires :: --var
Optional :: --vals

Action :: create_hash
Description :: Creates the specified hash if it does not exist.
Requires :: --var

Action :: dedup_array
Description :: Deduplicates an array.
Requires :: --var

Action :: delete
Description :: Deletes the var without checking the type.
Requires :: --var

Action :: delete_array
Description :: Deletes the specified array.
Requires :: --var

Action :: delete_hash
Description :: Deletes the specified hash.
Requires :: --var

Action :: push_array
Description :: Pushes a set of items onto an array.
Requires :: --var,--vals

Action :: set_array
Description :: Clears the array and sets it to specified values.
Requires :: --var,--vals

Action :: set_hash
Description :: Clears the hash and sets it to specified values.
Requires :: --var,--hash

Action :: set_in_array
Description :: Make sure a set of values exist in a array and if not add them.
Requires :: --var,--vals
Optional :: --dedup
```
