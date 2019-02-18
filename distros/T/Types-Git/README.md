# NAME

Types::Git - Type::Tiny types for git stuff.

# SYNOPSIS

    package Foo;
    
    use Types::Git -types;
    
    use Moo;
    use strictures 1;
    use namespace::clean;
    
    has ref => (
      is  => 'ro',
      isa => GitRef,
    );

# DESCRIPTION

This module provides several [Type::Tiny](https://metacpan.org/pod/Type::Tiny) types for some of
git's data types.

# TYPES

## GitSHA

A SHA1 hex, must be 40 characters or less long and contain
only hex characters.

## GitLooseRef

Just like ["GitRef"](#gitref) except one-level refs (those without any forward slashes)
are allowed.  This is useful for validating a branch or tag name.

## GitRef

Matches a ref against the same rules that
[git-check-ref-format](http://git-scm.com/docs/git-check-ref-format) uses.

## GitBranchRef

A ["GitRef"](#gitref) which begins with `refs/heads/` and ends with a
["GitLooseRef"](#gitlooseref).

## GitTagRef

A ["GitRef"](#gitref) which begins with `refs/tags/` and ends with a
["GitLooseRef"](#gitlooseref).

## GitObject

This is a union type of ["GitSHA"](#gitsha) and ["GitLooseRef"](#gitlooseref).  In the future
this type may be expanded to include other types as more of
[gitrevisions](http://git-scm.com/docs/gitrevisions) is incorporated
with this module.

## GitRevision

Currenlty this is an alias for ["GitObject"](#gitobject) but may be extended in
the future to include other types as more of
[gitrevisions](http://git-scm.com/docs/gitrevisions) is incorporated
with this module.

This type is meant to be the same as ["GitObject"](#gitobject) except with extended
rules for date ranges and such.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
