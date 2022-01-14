# NAME

uSAC::MIME - MIME Type database with concise lookups

# SYNOPSIS

```perl
    use uSAC::MIME;

    #Create a new DB using inbuild data
    my $db=uSAC::MIME->new;         

    #Database with no entries
    my $db=uSAC::MIME->new_empty;

    #Create data base from contents of file
    my $db=uSAC::MIME->new_from_file("path_to_nginx_or_apache_mime");

    #Create default from internal database and then add a custom entry
    my $db=uSAC::MIME->new("xyz"=>"special/type");


    #Add a custom entry to an existing database
    $db->add("abc"=>"another/type");

    #Remove a file extension from a mime type
    $db->rem("abc"=>"another/type");


    #Index the database. Forward only mapping in scalar context
    my $forward=$db->index;
    
    #Index the database. Forward and reverse mapping in list context
    my ($forward,$reverse)=$db->index;



    #Do Lookups 
    $forward->{txt};           #return  "text/plain"
    $backward->{"text/plain"}; #returns a array ref of extension
```

# DESCRIPTION

Provides concise file extension to MIME type (forward) mapping and MIME type to
file extension set (backwards) mapping.

Features include:

- Internal Default Database

    Internally it has its own MIME database source, however when you create a new
    instance you receive a copy which you can add or remove entries as you please.

- Load and Save from file

    An external MIME type database in nginx or Apache formats can be used to create
    an instance

- Low overhead

    The database in indexed into a anonymous hash ref for direct lookup

# Motivation

Performance. The indexed database is a straight perl hash so no method or
subroutine overheads. When responding to as many HTTP requests as possible,
this seemed like easy pickings to improve performance.

# What this module doesn't do

It is not a general purpose MIME type manipulator or generator. Module such as
[MIME::Type](https://metacpan.org/pod/MIME%3A%3AType) more suited for that purpose.

It also doesn't export and lookup methods/subs. All lookups are done via the hashes returned from calling the `index` method

File paths are not really handled. You need to split them off before hand.

# API

## Constructors

### `new(%mappings_to_add)`

Creates a new mime database from the internal database. Adds the optional
mappings to it The `index` method needs to be called on the returned object to
perform lookups

### `new_empty(%mappings_to_add)`

Creates a new empty database. Adds the optional mappings to it The `index`
method needs to be called on the returned object to perform lookups

## File IO

### `load_from_handle`

Reads the contents of a handle and adds it to the db

### `save_to_handle`

Writes out the DB as a text to the specified handle

## Indexing

### `index`

Generates the hash tables for forward (extension to mime) mappings, and
backwards(mime to extension set) mapping.

```perl
    my ($forward,$backward)=$db->index; $forward->{"txt");
```

## Database Manipulation

### `add`

Adds a single mapping from file extension to mime type. The  `index` method
will need to be called after to construct a new lookup hashes

### `rem`

Removes a single mapping from file extension to mime type. The  `index` method
will need to be called after to construct a new lookup hashes

## Forward Lookups

Once indexed, lookups are simply done via hash reference:

```perl
    my $forward=$db->index; #Previously index db to $forward
    
    $forward->{ext};        #Direct hash lookup
```

A single MIME type will be returned in the forward lookup. If the hash doesn't
contain the extension to MIME mapping, undef is returned.

## Reverse Lookups

To get the reverse lookup table, list context must be used when indexing:

```perl
    my ($forward, $revsere)=$db->index; #previously index

    $reverse->{mime};       #Direct hash lookup
```

An anonymous array of extension types are returned with zero or more file extensions

## Default/Fallback 

When forward lookups fails to locate a MIME type for the extension, use the 'defined or' operator to specify a fallback.

```perl
    $forward->{unkown_extension}//"my_default/type";
```

For reverse lookup failure, an empty anonymous array is returned.

```perl
    my @exts=$reverse->{unkown_mime}->@*||qw<my_default>;
```

# PERFORMANCE

A very basic benchmark of performing a forward lookup of a "txt" extension.
Comparing this modules to [Plack::MIME](https://metacpan.org/pod/Plack%3A%3AMIME) and [MIME::Detect](https://metacpan.org/pod/MIME%3A%3ADetect) locally on my
laptop give the following lookup rates:

```
    Module                 Lookup rate

    MIME::Detect                 167/s
    Plack::MIME              5208333/s
    uSAC::MIME              43478261/s
```

# REPOSITORY

Checkout the repo at [https://github.com/drclaw1394/perl-usac-mime](https://github.com/drclaw1394/perl-usac-mime)

# AUTHOR

Ruben Westerberg 

# COPYRIGHT

Copyright (C) 2022 Ruben Westerberg

# LICENSE

MIT or Perl, whichever you choose.
