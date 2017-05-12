Welcome to VMS::IndexedFile

Version 0.02

Copyright (c) 1996 Kent A. Covert and Toni L. Harbaugh-Blackford.
All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

This used to be called VMDBM, and was repackaged in the VMS::
namespace in April 1999.

DESCRIPTION
-----------
   This is a module for VMS Perl which implements DBM-like functionality
   using OpenVMS RMS Indexed files.

BUILDING VMS::IndexedFile
------------------
   If you normally use MMK as your MAKE facility, then substitute MMK for MMS
   in the following instructions.  

   1.) Issue the command

        $ perl makefile.pl

       This will create a DESCRIP.MMS file

   2.) Issue the command

        $ MMS

       depending on which make facility you have.  This will build VMS::IndexedFile
       as a dynamic extension.

   3.) Test the module

       Perl 5.001:
       -----------

        Type the command

          $ perl "-Iblib" test.pl

       Perl 5.002:
       -----------

        Either type the command

        Alpha:
          $ perl "-Iblib" "-Iblib/VMS_AXP" test.pl

        VAX:
          $ perl "-Iblib" "-Iblib/VMS_VAX" test.pl

PROBLEMS:
---------
   Send bug reports to COVERTKA@muohio.edu.  Please include basic hardware
   and system information with your message.

EXAMPLE PROGRAMS:
-----------------

   There is currently 1 example program in the [.EXAMPLES] directory.

     SYSUAF         Reads the SYSUAF file and displays the first 20 entries
                      in order alphabetically and the first 20 entries in order
                      by UIC.

   I recommend that you read through the sample runs *before* trying the programs

KNOWN PROBLEMS:
---------------
  - There is a bug in Perl 5.002.01 and before that prevents the indexed file
    from being closed when the untie() function is called if the hash
    variable has been populated using an array.
  - If a flag in the tie() function is set, but O_RDONLY, O_WRONLY, or
    O_RDWR is not specified, the system defaults to O_RDONLY.

USAGE:
------
initialization
--------------
  The VMS::IndexedFile interface needs to be initialized using the command:

    use VMS::IndexedFile;

  at the beginning of your Perl program.

tie() funcation
---------------
  To access the VMS::IndexedFile interface, you must tie a hash variable to VMS::IndexedFile. 
  This is accomplished using the tie() function in Perl.  The syntax for
  this function in the context of VMS::IndexedFile is as follows:

  objvar = tie(%hash_variable,VMS::IndexedFile,filespec,[key],[flags],[fdlspec]);

  where
    objvar        - reference to the object created.  This can be used to
                    access special methods within the VMS::IndexedFile interface.  The
                    2 currently defined methods are store() and replace().
    hash_variable - the hash variable to be tied to.  This can be any valid
                    hash variable you want.
    filespec      - the name of the indexed file you want to open.  This
                    filespec should be a valid VMS file specification.
    key           - the key that should be used when accessing the indexed
                    file.  The primary key is 0, the first alternate key is
                    1, etc.  If this parameter is omitted, it defaults to 0
                    (the primary key).
    flags         - flags used when opening the file.  The valid flags are
                    listed below:
                      O_RDONLY   - opens the file for reading only.
                      O_WRONLY   - opens the file for writing only.
                      O_RDWR     - opens the file for reading and writing.
                      O_CREAT    - opens the file and creates it if needed. 
                                   If this flag is specified, then the
                                   fdlspec parameter must also be specified.
                      O_EXCL     - when used with the O_CREAT flag, this
                                   flag will cause an error if the file
                                   already exists.
                      O_TRUNC    - alway create a new file.  If this flag
                                   is specified, then the fdlspec parameter
                                   must also be specified.
                    When specifying any flags, O_RDONLY, O_WRONLY, or O_RDWR
                    must always be specified.  Multiple flags can be
                    specified by seperating the flags with an | symbol.  If
                    this parameter is omitted, it will default to O_RDWR.
    fdlspec         the fdl specification for the file to be created.  This
                    can either be the fdl specified as a string or the name
                    of a file containing the fdl specification.  When
                    specifying the fdlspec as a file, the filename must be
                    preceeded by a < character.

  Examples:
    tie(%h,VMS::IndexedFile,"test.dat",0,O_RDWR|O_CREAT,"<test.fdl");
    $testobj = tie(%test,VMS::IndexedFile,"test.dat");
    $hobj = tie(%h,VMS::IndexedFile,"test.dat",1,O_RDWR|O_TRUNC,
      "FILE; ORGANIZATION indexed; RECORD; CARRIAGE_CONTROL carriage_return;" .
      "FORMAT variable; SIZE 10;" .
      "KEY 0; CHANGES no; DUPLICATES no;  SEG0_POSITION 0; SEG0_LENGTH 3;" .
        "TYPE string;" .
      "KEY 1; CHANGES no; DUPLICATES yes; SEG0_POSITION 3; SEG0_LENGTH 2;" .
        "SEG1_POSITION 0; SEG1_LENGTH 3; TYPE string;");

fetching records
----------------
  You can retrieve records in the indexed file just as you would an ordinary
  hashed array the only major differences being that VMS::IndexedFile will return the
  entire record rather than just the non-key portion.  For example,

    print $h{'ABC'};

  This will print the entire record whose key begins with ABC.

  Segmented keys should be specified by concatenating the key segments together. 
  For example, the following statement would print the record with the SEG0 of
  '12' and the SEG1 of 'ABC' from the file whose FDL is listed in the third
  tie() example above.

    print $h{'12ABC'};

  Specifying an empty key will force VMS::IndexedFile to begin reading sequentially from
  the file.  For example:

    print $h{'ABC'};
    print $h{''};
    print $h{''};

  Will read the record whose key is 'ABC' and the next 2 records.

storing records
---------------
  Storing records are done in a similar manner to storing data in a hash table. 
  For example,

    $h{'ABC'} = 'ABC12345';

  Notice that the right-hand side of the equation is specified as the entire
  record rather than just the non-key portion.  In fact, the key specification
  is completely ignored except for error-checking (Perl will store the record
  and then fetch it to see if it was successful).

  The error message returned by a store is actually not the error message from
  the store, but rather the error message from the fetch that is performed after
  the store.  For this reason, a store() method has been added to VMS::IndexedFile.  This
  method can be used if you need to know the true error message returned by the
  act of storing the record.  To use it, you must store the objvar returned by
  the tie() function.  Using this you can access the store() method.  The syntax
  is as follows:

    retval store(string);

  where
    retval  - success of the store.  0 is a failure, 1 is a success.
    string  - string to store in the file.  This should be the entire record to
              be store.

  Examples,

    $h = tie(%h,VMS::IndexedFile,"test.dat");
    $h->store("ABC12345") || die "Couldn't store record - $!";

  By default, the act of storing a record will always attempt replace the current
  record (if there are no duplicates allowed on the key being added) or add an
  additional record (if duplicates are allowed).  This can be changed with the
  replace() method.  The syntax is as follows:

    oldvalue = replace(newvalue);

  where
    oldvalue  - the previous replace() mode.
    newvalue  - the replace mode().  0 indicates that records should not be
      replaced.  1 indicates the default action.

  If duplicates are allowed on the key, the current replace() mode is ignored.

deleting records
----------------
  Records can be deleted with the Perl delete() function.  For example,

    delete($h{'ABC'});

  would delete the record whose key is 'ABC'.  VMS::IndexedFile will delete the first
  record it encounters when a key is provided as shown above.  If the key is
  empty, though, VMS::IndexedFile will delete the last record read.  This can be useful
  when dealing with duplicate keys.  For example,
  
    print $h{'ABC'};
    print $h{''};
    print $h{''};
    delete($h{''});

  would display the record whose key is 'ABC' and the 2 records that follow.  It
  would then delete the last record that was read and displayed.

additional options
------------------
  VMS::IndexedFile will also work with foreach() and each() and keys() and values() in a
  manner similar to the way Perl treats associative arrays.  Remember, though,
  that VMS::IndexedFile always returns whole records, though, for values.

CREDITS:
--------
  I would like to thank the following:
    Toni L. Harbaugh-Blackford  - author of the original VDBM
      implementation on which this much of this code was based.  Toni also
      helped me work on the command syntax for VMS::IndexedFile.
    Charles Bailey - the primary porter for VMS Perl who answered several
      of my questions about Perl internals and offered several very good
      suggestions that were incorporated into the implementation.
