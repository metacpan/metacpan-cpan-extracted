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
pkg install p5-App-cpanminus p5-File-Slurp
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

### SYNOPSIS

```shell
yqh -f <yaml> -a clear_array --var <var>
yqh -f <yaml> -a clear_hash<--var <var>
yqh -f <yaml> -a create_array --var <var> [--vals <vals>]
yqh -f <yaml> -a create_hash --var <var>
yqh -f <yaml> -a dedup_array --var <var>
yqh -f <yaml> -a delete B<--var> <var>
yqh -f <yaml> -a delete_array --var <var>
yqh -f <yaml> -a delete_hash --var <var>
yqh -f <yaml> -a ensure
yqh -f <yaml> -a is_array --var <var>
yqh -f <yaml> -a is_hash --var <var>
yqh -f <yaml> -a is_defined --var <var>
yqh -f <yaml> -a merge_yaml --yaml <yaml> [--mode <mode>]
yqh -f <yaml> -a push_array --var <var> --vals <vals>
yqh -f <yaml> -a set_array --var <var> --vals <vals>
yqh -f <yaml> -a set_hash --var <var> --hash <hash>
yqh -f <yaml> -a set_in_array --var <var> --vals <vals> [--dedup <0/1>]
yqh -f <yaml> -a yaml_diff --yaml <yaml_file_2>
```

### FLAGS

#### -f file

YAML file to operate on.

Default :: undef

#### -a action

Action to perform.

Default :: undef

#### --var string

Variable to set.

Default :: undef

#### --vals string

Comma seperate list of array values.

Default :: undef

#### --hash <string>

Comma seperate list of hash values. Each
value is a sub string with key/value seperate
by a /=/.

Default :: undef

#### --dedup 0/1

If it should dedup the data for the op.

Default :: 1

#### --yaml file

Another YAML file to use with like the merge_yaml
action or the like.

Default :: undef

#### --mode mode

Merge mode to use.

Default :: deeply

### ACTIONS

#### clear_array

Clears the specified array.

Requires :: --var

#### clear_hash

Clears the specified hash.

Requires :: --var

#### create_array

Creates the specified array if it does not exist.

Requires :: --var

Optional :: --vals

#### create_hash

Creates the specified hash if it does not exist.

Requires :: --var

#### dedup_array

Deduplicates an array.

Requires :: --var

#### delete

Deletes the var without checking the type.

Requires :: --var

#### delete_array

Deletes the specified array.

Requires :: --var

#### delete_hash

Deletes the specified hash.

Requires :: --var

#### ensure

Ensures that the YAML starts with

    %YAML $version
    ---

This is largely for use with stuff used by
LibYAML as that sometimes does not play nice
when that is missing.

Version 1.1 is used if it is not set.

#### is_array

Returns 0 or 1 based on if it is a array.

Requires :: --var

#### is_hash

Returns 0 or 1 based on if it is a hash.

Requires :: --var

#### is_defined

Returns 0 or 1 based on if it is defined.

Requires :: --var

#### merge_yaml

Merges the specified YAML into the YAML.

Requires :: --yaml

Optional :: --mode

#### push_array

Pushes a set of items onto an array.

Requires :: --var, --vals

#### set_array

Clears the array and sets it to specified values.

Requires :: --var, --vals

#### set_hash

Clears the hash and sets it to specified values.

Requires :: --var, --hash

#### set_in_array

Make sure a set of values exist in a array and if not add them.

Requires :: --var, --vals

Optional :: --dedup

#### yaml_diff

Diffs the two YAMLs.

Requires :: --yaml
