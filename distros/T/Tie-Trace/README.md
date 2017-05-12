# NAME

Tie::Trace - easy print debugging with tie, for watching variable

# VERSION

Version 0.17

# SYNOPSIS

       use Tie::Trace qw/watch/; # or qw/:all/
    
       my %hash = (key => 'value');
       watch %hash;
    
       $hash{hoge} = 'hogehoge'; # warn "main:: %hash => {hoge} => hogehgoe at ..."
    
       my @array;
       tie @array;
       push @array, "array";    # warn "main:: @array [0] => array at ..."
    
       my $scalar;
       watch $scalar;
       $scalar = "scalar";      # warn "main:: $scalar => scalar at ..."

# DESCRIPTION

This is useful for print debugging. Using tie mechanism,
you can see stored/deleted value for the specified variable.

If the stored value is scalar/array/hash ref, this can check
recursively.

for example;

    watch %hash;
    
    $hash{foo} = {a => 1, b => 2}; # warn "main:: %hash => {foo} => {a => 1, b => 2}"
    $hash{foo}->{a} = 2            # warn "main:: %hash => {foo}{a} => 2"

But This ignores blessed reference and tied value.

# FUNCTION

This provides one function `watch` from version 0.06.
Then you should use only this function. Don't use `tie` function instead.

- watch

        watch $variables;

        watch $scalar, %options;
        watch @array, %options;
        watch %hash, %options;

    When you `watch` variables and value is stored/delete in the variables,
    warn the message like as the following.

        main:: %hash => {key} => value at ...

    If the variables has values before `watch`, it is no problem. Tie::Trace work well.

        my %hash = (key => 'value');
        watch %hash;

# OPTIONS

You can use `watch` with some options.
If you want global options, see ["GLOBAL VARIABLES"](#global-variables).

- key => \[values/regexs/coderef\]

        watch %hash, key => [qw/foo bar/];

    It is for hash. You can specify key name/regex/coderef for checking.
    Not specified/matched keys are ignored for warning.
    When you give coderef, this coderef receive tied value and key as arguments,
    it returns false, the key is ignored.

    for example;

        watch %hash, key => [qw/foo bar/, qr/x/];
        
        $hash{foo} = 1 # warn ...
        $hash{bar} = 1 # warn ...
        $hash{var} = 1 # *no* warnings
        $hash{_x_} = 1 # warn ...

- value => \[contents/regexs/coderef\]

        watch %hash, value => [qw/foo bar/];

    You can specify value's content/regex/coderef for checking.
    Not specified/matched are ignored for warning.
    When you give coderef, this coderef receive tied value and value as arguments,
    it returns false, the value is ignored.

    for example;

        watch %hash, value => [qw/foo bar/, qr/\)/];
        
        $hash{a} = 'foo'  # warn ...
        $hash{b} = 'foo1' # *no* warnings
        $hash{c} = 'bar'  # warn ...
        $hash{d} = ':-)'  # warn ...

- use => \[qw/hash array scalar/\]

        tie %hash, "Tie::Trace", use => [qw/array/];

    It specify type(scalar, array or hash) of variable for checking.
    As default, all type will be checked.

    for example;

        watch %hash, use => [qw/array/];
        
        $hash{foo} = 1         # *no* warnings
        $hash{bar} = 1         # *no* warnings
        $hash{var} = []        # *no* warnings
        push @{$hash{var}} = 1 # warn ...

- debug => 'dumper'/coderef

        watch %hash, debug => 'dumper'
        watch %hash, debug => sub{my($self, @v) = @_; return @v }

    It specify value representation. As default, "dumper" is set.
    "dumper" makes value show with Data::Dumper::Dumper format(but ::Terse = 0 and ::Indent = 0).
    You can use coderef instead of "dumper".
    When you specify your coderef, its first argument is tied value and
    second argument is value, it should modify it and return it.

- debug\_value => \[contents/regexs/coderef\]

        watch %hash, debug => sub{my($s,$v) = @_; $v =~tr/op/po/;}, debug_value => [qw/foo boo/];

    You can specify debugged value's content/regex for checking.
    Not specified/matched are ignored for warning.
    When you give coderef, this coderef receive tied value and value as arguments,
    it returns false, the value is ignored.

    for example;

        watch %hash, debug => sub{my($s,$v) = @_; $v =~tr/op/po/;}, debug_value => [qw/foo boo/];
        
        $hash{a} = 'fpp'  # warn ...      because debugged value is foo
        $hash{b} = 'foo'  # *no* warnings because debugged value is fpp
        $hash{c} = 'bpp'  # warn ...      because debugged value is boo

- r => 0/1

        tie %hash, "Tie::Trace", r => 0;

    If r is 0, this won't check recursively. 1 is default.

- caller => number/\[numbers\]

        watch %hash, caller => 2;

    It effects warning message.
    default is 0. If you set grater than 0, it goes upstream to check.

    You can specify array ref.

        watch %hash, caller => [1, 2, 3];

    It display following messages.

        main %hash => {key} => 'hoge' at filename line 61.
        at filename line 383.
        at filename line 268.

# METHODS

It is used in coderef which is passed for options, for example,
key, value and/or debug\_value or as the method of the returned of tied function.

- storage

        watch %hash, debug =>
          sub {
            my($self, $v) = @_;
            my $storage = $self->storage;
            return $storage;
          };

    This returns reference in which value(s) stored.

- parent

        watch %hash, debug =>
          sub {
            my($self, $v) = @_;
            my $parent = $self->parent->storage;
            return $parent;
          };

    This method returns $self's parent tied value.

    for example;

        watch my %hash;
        my %hash2;
        $hash{1} = \%hash2;
        my $tied_hash2 = tied %hash2;
        print tied %hash eq $tied_hash2->parent; # 1

# GLOBAL VARIABLES

- %Tie::Trace::OPTIONS

    This is Global options for Tie::Trace.
    If you don't specify any options, this option is used.
    If you use override options, you use `watch` with options.

        %Tie::Trace::OPTIONS = (debug => undef, ...);

        # global options will be used
        watch my %hash;

        # your options will be used
        watch my %hash2, debug => 'dumper', ...;

- $Tie::Trace::QUIET

    If this value is true, Tie::Trace warn nothing.

        watch my %hash;
        
        $hash{1} = 1; # warn something
        
        $Tie::Trace::QUIET = 1;
        
        $hash{1} = 2; # no warn

# AUTHOR

Ktat, `<ktat.is at gmail.com>`

# BUGS

Please report any bugs or feature requests to
`bug-tie-debug at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Trace](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Trace).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Trace

You can also find documentation written in Japanese(euc-jp) for this module
with the perldoc command.

    perldoc Tie::Trace_JP

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Tie-Trace](http://annocpan.org/dist/Tie-Trace)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Tie-Trace](http://cpanratings.perl.org/d/Tie-Trace)

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Trace](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Trace)

- Search CPAN

    [http://search.cpan.org/dist/Tie-Trace](http://search.cpan.org/dist/Tie-Trace)

# ACKNOWLEDGEMENT

JN told me the idea of new warning message(from 0.06).

# COPYRIGHT & LICENSE

Copyright 2006-2010 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
