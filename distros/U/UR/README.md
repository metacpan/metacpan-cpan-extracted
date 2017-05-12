[![Build Status](https://travis-ci.org/genome/UR.png?branch=master)](https://travis-ci.org/genome/UR)
# NAME

UR - rich declarative transactional objects

# VERSION

This document describes UR version 0.46

# SYNOPSIS

    use UR;

    ## no database

    class Foo { is => 'Bar', has => [qw/prop1 prop2 prop3/] };

    $o1 = Foo->create(prop1 => 111, prop2 => 222, prop3 => 333);

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns one object

    $o1->delete;

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns zero objects

    @o = Foo->get(prop2 => 222, prop1 => [101,111,121], 'prop3 between' => [200, 400]);
    # returns one object again

    ## database

    class Animal {
        has => [
            favorite_food => { is => 'Text', doc => "what's yummy?" },
        ],
        data_source => 'MyDB1',
        table_name => 'Animal'
    };

    class Cat {
        is => 'Animal',
        has => [
            feet    => { is => 'Number', default_value => 4 },
            fur     => { is => 'Text', valid_values => [qw/fluffy scruffy/] },
        ],
        data_source => 'MyDB1',
        table_name => 'Cat'
    };

    Cat->create(feet => 4, fur => 'fluffy', favorite_food => 'taters');

    @cats = Cat->get(favorite_food => ['taters','sea bass']);

    $c = $cats[0];

    print $c->feet,"\n";

    $c->fur('scruffy');

    UR::Context->commit();

# DESCRIPTION

UR is a class framework and object/relational mapper for Perl.  It starts
with the familiar Perl meme of the blessed hash reference as the basis for
object instances, and extends its capabilities with ORM (object-relational
mapping) capabilities, object cache, in-memory transactions, more formal
class definitions, metadata, documentation system, iterators, command line
tools, etc.

UR can handle multiple column primary and foreign keys, SQL joins involving
class inheritance and relationships, and does its best to avoid querying
the database unless the requested data has not been loaded before.  It has
support for SQLite, Oracle, Mysql and Postgres databases, and the ability
to use a text file as a table.

UR uses the same syntax to define non-persistent objects, and supports
in-memory transactions for both.

# DOCUMENTATION

## Manuals

[ur](https://metacpan.org/pod/ur) - command line interface

[UR::Manual::Overview](https://metacpan.org/pod/UR::Manual::Overview) - UR from Ten Thousand Feet

[UR::Manual::Tutorial](https://metacpan.org/pod/UR::Manual::Tutorial) - Getting started with UR

[UR::Manual::Presentation](https://metacpan.org/pod/UR::Manual::Presentation) - Slides for a presentation on UR

[UR::Manual::Cookbook](https://metacpan.org/pod/UR::Manual::Cookbook) - Recepies for getting stuff working

[UR::Manual::Metadata](https://metacpan.org/pod/UR::Manual::Metadata) - UR's metadata system

[UR::Object::Type::Initializer](https://metacpan.org/pod/UR::Object::Type::Initializer) - Defining classes

## Basic Entities

[UR::Object](https://metacpan.org/pod/UR::Object) - Pretty much everything is-a UR::Object

[UR::Object::Type](https://metacpan.org/pod/UR::Object::Type) - Metadata class for Classes

[UR::Object::Property](https://metacpan.org/pod/UR::Object::Property) - Metadata class for Properties

[UR::Namespace](https://metacpan.org/pod/UR::Namespace) - Manage packages and classes

[UR::Context](https://metacpan.org/pod/UR::Context) - Software transactions and More!

[UR::DataSource](https://metacpan.org/pod/UR::DataSource) - How and where to get data

# QUICK TUTORIAL

First create a Namespace class for your application, Music.pm:

    package Music;
    use UR;

    class Music {
        is => 'UR::Namespace'
    };

    1;

Next, define a data source representing your database, Music/DataSource/DB1.pm

    package Music::DataSource::DB1;
    use Music;

    class Music::DataSource::DB1 {
        is => ['UR::DataSource::MySQL', 'UR::Singleton'],
        has_constant => [
            server  => { value => 'database=music' },
            owner   => { value => 'music' },
            login   => { value => 'mysqluser' },
            auth    => { value => 'mysqlpasswd' },
        ]
    };

    or to get something going quickly, SQLite has smart defaults...

    class Music::DataSource::DB1 {
        is => ['UR::DataSource::SQLite', 'UR::Singleton'],
    };

Create a class to represent artists, who have many CDs, in Music/Artist.pm

    package Music::Artist;
    use Music;

    class Music::Artist {
        id_by => 'artist_id',
        has => [
            name => { is => 'Text' },
            cds  => { is => 'Music::Cd', is_many => 1, reverse_as => 'artist' }
        ],
        data_source => 'Music::DataSource::DB1',
        table_name => 'ARTIST',
    };

Create a class to represent CDs, in Music/Cd.pm

    package Music::Cd;
    use Music;

    class Music::Cd {
        id_by => 'cd_id',
        has => [
            artist => { is => 'Music::Artist', id_by => 'artist_id' },
            title  => { is => 'Text' },
            year   => { is => 'Integer' },
            artist_name => { via => 'artist', to => 'name' },
        ],
        data_source => 'Music::DataSource::DB1',
        table_name => 'CD',
    };

If the database does not exist, you can run this to generate the tables and columns from the classes you've written
(very experimental):

    $ cd Music
    $ ur update schema

If the database existed already, you could have done this to get it to write the last 2 classes for you:

    $ cd Music;
    $ ur update classes

Regardless, if the classes and database tables are present, you can then use these classes in your application code:

    # Using the namespace enables auto-loading of modules upon first attempt to call a method
    use Music;

    # This would get back all Artist objects:
    my @all_artists = Music::Artist->get();

    # After the above, further requests would be cached
    # if that set were large though, you might want to iterate gradually:
    my $artist_iter = Music::Artist->create_iterator();

    # Get the first object off of the iterator
    my $first_artist = $artist_iter->next();

    # Get all the CDs published in 2007 for the first artist
    my @cds_2007 = Music::Cd->get(year => 2007, artist => $first_artist);

    # Use non-equality operators:
    my @some_cds = Music::Cd->get(
        'year between' => ['2004','2009']
    );

    # This will use a JOIN with the ARTISTS table internally to filter
    # the data in the database.  @some_cds will contain Music::Cd objects.
    # As a side effect, related Artist objects will be loaded into the cache
    @some_cds = Music::Cd->get(
        year => '2007',
        'artist_name like' => 'Bob%'
    );

    # These values would be cached...
    my @artists_for_some_cds = map { $_->artist } @some_cds;

    # This will use a join to prefetch Artist objects related to the
    # objects that match the filter
    my @other_cds = Music::Cd->get(
        'title like' => '%White%',
        -hints => ['artist']
    );
    my $other_artist_0 = $other_cds[0]->artist;  # already loaded so no query

    # create() instantiates a new object in the current "context", but does not save
    # it in the database.  It will autogenerate its own cd_id:
    my $new_cd = Music::Cd->create(
        title => 'Cool Album',
        year  => 2009
    );

    # Assign it to an artist; fills in the artist_id field of $new_cd
    $first_artist->add_cd($new_cd);

    # Save all changes in the current transaction back to the database(s)
    # which are behind the changed objects.
    UR::Context->current->commit;

# Environment Variables

UR uses several environment variables to do things like run with
database commits disabled, watching SQL queries run, examine query plans,
and control cache size, etc.

These make development and debugging fast and easy.

See [UR::Env](https://metacpan.org/pod/UR::Env) for details.

# DEPENDENCIES

Class::Autouse
Cwd
Data::Dumper
Date::Format
DBI
File::Basename
FindBin
FreezeThaw
Path::Class
Scalar::Util
Sub::Installer
Sub::Name
Sys::Hostname
Text::Diff
Time::HiRes
XML::Simple

# AUTHORS

UR was built by the software development team at the McDonnell Genome Institute
at the Washington University School of Medicine (Richard K. Wilson, PI).

Incarnations of it run laboratory automation and analysis systems
for high-throughput genomics.

    Anthony Brummett   brummett@cpan.org
    Nathan Nutter
    Josh McMichael
    Eric Clark
    Ben Oberkfell
    Eddie Belter
    Feiyu Du
    Adam Dukes
    Brian Derickson
    Craig Pohl
    Gabe Sanderson
    Todd Hepler
    Jason Walker
    James Weible
    Indraniel Das
    Shin Leong
    Ken Swanson
    Scott Abbott
    Alice Diec
    William Schroeder
    Shawn Leonard
    Lynn Carmichael
    Amy Hawkins
    Michael Kiwala
    Kevin Crouse
    Mark Johnson
    Kyung Kim
    Jon Schindler
    Justin Lolofie
    Jerome Peirick
    Ryan Richt
    John Osborne
    Chris Harris
    Philip Kimmey
    Robert Long
    Travis Abbott
    Matthew Callaway
    James Eldred
    Scott Smith        sakoht@cpan.org
    David Dooling

# LICENCE AND COPYRIGHT

Copyright (C) 2002-2016 Washington University in St. Louis, MO.

This software is licensed under the same terms as Perl itself.
See the LICENSE file in this distribution.
