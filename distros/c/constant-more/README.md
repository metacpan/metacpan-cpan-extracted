# NAME

constant::more - Assign values to constants from the command arguments

# SYNOPSIS

Can use as a direct alternative to `use constant`:

```perl
    use constant::more PI    => 4 * atan2(1, 1);
    use constant:more DEBUG => 0;

    print "Pi equals ", PI, "...\n" if DEBUG;

    use constant::more {
        SEC   => 0,
        MIN   => 1,
        HOUR  => 2,
        MDAY  => 3,
        MON   => 4,
        YEAR  => 5,
        WDAY  => 6,
        YDAY  => 7,
        ISDST => 8,
    };
```

Parse command line arguments and/or environment variables to assign
to constants:

```perl
    # ###
    # example.pl

    use constant::more {
            FEATURE_A_ENABLED=>{            #Name of the constant
                    val=>0,         #default value 
                    opt=>"feature1",        #Getopt::Long option specification
                    env=>"MY_APP_FEATURE_A" #Environment variable copy value from 
            },

            FEATURE_B_CONFIG=>{
                    val=>"disabled",
                    opt=>"feature2=s",      #Getopt::Long format
            }
    };

    
    if(FEATURE_A_ENABLED){
            #Do interesting things here
            print "Feature a is enabled
    }
    
    print "Feature b config is: ".FEATURE_B_CONFIG."\n";

    __END__

    #######

    # From command line
    perl example.pl --feature1  --feature2=active
    

    # ####
    # output

    Feature a is enabled
    Feature b config is: active
    
```

# DESCRIPTION

Performs similar tasks as `use constant`, but adds features to assign values
of constants from the command line or environment variables.

In addition, constants are only defined/set if they don't exist already, making
configuring and overriding constants defined in sub modules possible. A module
can specify a default value which is used if the constant hasn't been defined
by the top level script. 

[GetOpt::Long](https://metacpan.org/pod/GetOpt%3A%3ALong) option specification is used for processing command line
options to give flexibility in how and what switches are used.  To save on
memory, [GetOpt::Long](https://metacpan.org/pod/GetOpt%3A%3ALong) is only loaded if option processing is wanted (i.e. the
`opt` field non disabled).

In advanced form, a user subroutine can be supplied to give control of
processing. This is used by [Log::OK](https://metacpan.org/pod/Log%3A%3AOK) for example to generate multiple
constants from a single input level.

# MOTIVATION

I use the [constant](https://metacpan.org/pod/constant) and [enum](https://metacpan.org/pod/enum) pragma frequently for unchanging values in my
code.  However, I would like to have the flexibility to configure constants at
program start to enable debugging or platform specific code.

This module started as a way of disabling logging with no runtime overhead.
However goals changed and I made it more general purpose. I wrote the module
`Log::OK` to handle disabling of inactive logging statements. It uses this
module under the hood.

# USAGE

## Implementation Details

It is important to `use constant::more` before other modules that also `use
constant::more`. This ensures that you can manipulate constant values from the
top level of the program.  Otherwise you risk sub modules overriding your top
level applications logic.

Constants are defined in a callers package unless the name includes a package.
A name with '::' in it is classed as a full name for a variable. Use this to
declare constants in a common namespace for example.

In the case of the `val` field, command line and environment processing all
being enabled simultaneously, the precedence of a constant's value is: command
option, environment variable and lastly the `val` field.

Constant names and their values are set in a table (hash) before they are
actually created. In the case of the Advanced Form usage  (see below), a
constant can have it's value updated multiple times, or multiple constants
generated from the same command line option and added to the table.  When
processing is complete all entries in the table are created.

The usage of the pragma takes three forms, depending on how you want to set the
value of your constants. These are detailed in the following sections.

## Simple Form

In its simplest form, defining an constant (or multiple) is just like the 
`use constant` pragma:

```perl
    use constant::more NAME=>"value";       #Set a single constant
            
    use constant::more {                    #Set multiple constants
                    NAME=>"value",
                    ANOTHER=>"one",
    };
```

The key of the hash becomes the name of the constant. 

## Normal Form

In its normal form, one or more anonymous hashes containing keys `val`,
`opt`, `env`, `keep` and `sub` are used to setup the processing of a
constant:

```perl
    use constant::more {
            MY_NAME=>{
                    val=>"john",
                    opt=>"name=s",
                    env=>"ENV_VAR_NAME",
            },
            ANOTHER=>{
                    value=>"one",
            }
    };
```

The key for each anonymous hash is the name of the constant created (MY\_NAME
and ANOTHER from above).

The field values are all optional and include:

### val

The (default) value set for the constant if no command line option or
environment variable is used/detected. If not provided the value of constant
generated will be `undef`.

### opt

The [GetOpt::Long](https://metacpan.org/pod/GetOpt%3A%3ALong) option specification to use in processing the command line.
If not specified, no command line processing is performed and [GetOpt::Long](https://metacpan.org/pod/GetOpt%3A%3ALong)
in not loaded.

### env

The name of the environment variable to use in setting the constant's value. If
not provided, environment variables are not processed.

### keep

A flag indicating if the `@ARGV` should be left as is (to keep) or  consumed
when processing command line options. If not specified, `@ARGV` will have
options consumed and only remaining options passed through.

## Advanced Form

Advanced form has an additional field `sub` which changes behaviour of the
pragma dramatically.

If a child anonymous hash contains a CODE reference in the field `sub`, the top
level key in the hash is **NOT** used as the constant name, but only as a
label.

The actual constant names and values to be generated are returned as a
key/value list from the CODE ref. 

The CODE ref is called with a key/value pair. The first input argument is the
name of the command line option, or undef if default or environment variable.

The second argument is the value from the command line, default or
environment variable.

```perl
    eg:

    use constant::more {
            just_a_label=>{                 #this is just a label
                    val=>"john",
                    opt=>"name=s",
                    env=>"ENV_VAR_NAME",
                    sub=>sub{
                            my ($key,$value)=@_;
                            state $i=0;

                            #each time this sub is called it returns 
                            #a new for a constant with value to set
                            ("CONSTANT".$i++, $value);
                    
                    }
            },
    };
```

The code ref may be called multiple times if command line processing is enabled
(with the `opt` field). If multiple matching switches are present on the
command line, they are each passed in a call.

The names and values returned can be different each time to implement advanced use
cases.

# REPOSITOTY and BUGS

Please report feature requests and bugs via the github:

[https://github.com/drclaw1394/perl-constant-more.git](https://github.com/drclaw1394/perl-constant-more.git)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

Licensed under MIT

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
