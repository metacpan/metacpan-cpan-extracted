package Test::Subunits;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.000003';

sub import {
    # Client code passes in filename or module name...
    our (undef, $source) = @_;

    if (!defined $source || !length($source)) {
        _croak( q{No argument supplied to 'use Test::Subunits'} );
    }

    # Locate file in library path...
    $source = _locate($source);

    # Extract source code...
    my $source_code = _slurp($source);

    # Accumulate code to be extracted, while tracking line numbers...
    my $extracted_code = q{};
    my $line_number    = 1;

    # Locate and isolate subunits...
    $source_code =~ s{
        \G ^ (?&ws)
        (?:
            # A bracketed subunit...
            (?<DELIM> \#\#\{ )
            (?: # Optional subroutine wrapper specification...
                    (?&ws)     (?<SUBNAME>  (?&ident)     )
                    (?&ws)     (?<PARAMS>   (?&paramlist) )
                (?: (?&ws) --> (?<RETEXPR>  (?&whatever)  ) )?
            )?
            (?&ws) \n
            (?<EXTRACTED>
                .*?
                ^ (?&ws) \#\#\} (?&ws) (?&eol)
            )
        |
            # A paragraphed subunit...
            (?<DELIM> \#\#: )
            (?: # Optional subroutine wrapper specification...
                    (?&ws)     (?<SUBNAME>  (?&ident)     )
                    (?&ws)     (?<PARAMS>   (?&paramlist) )
                (?: (?&ws) --> (?<RETEXPR>  (?&whatever)  ) )?
            )?
            (?&ws) \n
            (?<EXTRACTED>
                .*?
                ^ (?&ws) (?&eol)
            )
        |
            # Catch junk after opening delimiters...
            (?<INVALID_WRAPPER>  \#\#[:\{] (?&ws) \S (?&whatever) ) (?&eol)
        |
            # Catch unmatched delimiters...
            (?<UNMATCHED_DELIM>  \#\#[{}]          ) (?&whatever)   (?&eol)
        |
            # Catch unknown delimiters...
            (?<UNKNOWN_DELIM>    \#\#\S            ) (?&whatever)   (?&eol)
        |
            # One-or-more consecutive single-line subunits...
            (?<DELIM> \#\# )
            (?<EXTRACTED>
                (?&whatever) (?&eol)
                (?: ^ (?&ws) \#\# (?=\s) (?&whatever) (?&eol) )*+
            )
        |
            # Ignore anything else...
            (?&whatever) (?&eol)
        )

        (?(DEFINE)
            (?<paramlist>
                \( (?&ws) (?&var) (?: (?&ws) , (?&ws) (?&var) )*+ (?&ws) \)
            )
            (?<var>       [\$\@%] (?&ident)  )
            (?<ws>        \h*+               )
            (?<whatever>  (?-s: .*+ )        )
            (?<ident>     [^\W\d] \w*+       )
            (?<eol>       \n | \Z            )
        )
    }{
        # Every match consumes at least one line...
        $line_number++;

        # Handle bad delimiters...
        if (exists $+{UNMATCHED_DELIM}) {
            my $where = "at $source line " . ($line_number - 1);
            $extracted_code .= qq(BEGIN { die "Unmatched $+{UNMATCHED_DELIM} $where\n" });
        }
        elsif (exists $+{UNKNOWN_DELIM}) {
            my $where = "at $source line " . ($line_number - 1);
            $extracted_code .= qq(BEGIN { die "Unrecognized subunit marker ($+{UNKNOWN_DELIM}) $where\n" });
        }
        elsif (exists $+{INVALID_WRAPPER}) {
            my $where = "at $source line " . ($line_number - 1);
            $extracted_code .= qq(BEGIN { die "Invalid wrapper specification: $+{INVALID_WRAPPER} $where\n" });
        }

        # Remember anything that was extracted...
        elsif (exists $+{EXTRACTED}) {
            my $extracted = $+{EXTRACTED};

            # Track how many lines the extracton covered...
            my $extracted_lines = ($extracted =~ tr/\n//);

            # Wrap in a subroutine, if requested...
            if (exists $+{SUBNAME}) {
                # If no return specification, return original parameter list...
                my $retexpr = $+{RETEXPR} // $+{PARAMS};

                # Build the wrapper...
                $extracted = "sub $+{SUBNAME} { my $+{PARAMS} = \@_;\n"
                           . $extracted
                           . "return $retexpr; }\n";
            }

            # Remember the extracted code (and where it was in the original file)...
            $extracted_code .= " # line $line_number $source\n" . $extracted;

            # Track the extra lines that have been matched...
            $line_number += $extracted_lines;
        }
    }egxms;

    # Remove any extra internal ## lines...
    $extracted_code =~ s{ ^ \h*+ \# \#[{}\s]? }{}gxms;

    # Compile the code in the caller's namespace...
    my $target_package = caller;
    eval qq{
        package $target_package;
        $extracted_code;
        1;
    } or die;
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub _slurp {
    local (@ARGV, $/) = shift;
    return readline();
}

sub _locate {
    my ($source) = @_;
    my $orig_source = $source;

    # Convert module name to filename if necessary...
    if ($source =~ m{^\w+(?:::\w+)*$}) {
        $source =~ s{::}{/}g ;
        $source .= '.pm';
    }

    # Try within all the standard inclusion directories...
    for my $path (@INC) {
        my $file = "$path/$source";
        return $file if -e $file;
    }

    # Finally, try the exact path by itself...
    return $source if -e $source;

    # Otherwise give up with extreme prejudice...
    _croak( qq{Test::Subunits can't locate requested source file: $orig_source} );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::Subunits - Extract subunit tests from within complex source code


=head1 VERSION

This document describes Test::Subunits version 0.000003


=head1 SYNOPSIS

    # Extract and compile testable "subunits"...
    use Test::Subunits 'Your::Module::Here';

    # Then test them in your preferred manner, for example...
    use Test::More;

    my @normalized_data = normalize_subunit(@data);
    ok !grep({!defined}, @normalized_data) => 'All data normalized';

    my @sorted = sort_subunit(@unsorted);
    my $prev = shift @sorted;
    while (my $next = shift @sorted) {
        cmp_ok $prev, '>=', $next => "$prev >= $next";
        $next = $prev;
    }

    done_testing();


=head1 DESCRIPTION

I<"Unit testing is right. Unit testing works. Unit testing clarifies.
   Unit testing, for lack of a better word, is good.">

...but unit testing can also be expensive. In particular, unit testing
requires that your code be composed from a large number of small
independently testable units (i.e. short subroutines). And, while
that's good software engineering, it can sometimes be bad performance
engineering.

Because that kind of highly decomposed then highly recomposed code also
requires a large number of internal subroutine calls, and a lot of
argument passing, either of which can reduce the performance of your
code to unacceptable levels.

When that happens, the usual solution is to "inline" the original units
of code: to create a single, larger, more complex subroutine that does
everything in one place and as fast as possible.

But that kind of subroutine is also much more difficult to test (if it
can be tested at all).

This module allows you to write fast-but-monolithic subroutines when you
need to, but still be able to test individual sections of that code
(known as "subunits") as if they were separate small-but-composable
subroutines.

To do this, you annotate parts of your monolithic code with special
comments. This module then uses those annotations to extract individual
chunks of your code which it compiles into separate subroutines, which
your test suite can then test independently.

In a sense, it's the exact opposite of inlining small subroutines into
your code. The module effectively "out-lines" predetermined fragments of
your code to create small subroutines that you can then test.


=head1 INTERFACE

To extract subunits from a source file, you load the Test::Subunits
module, passing it a single argument that specifies that source file.
This argument can be either the full name of the module:

    use Test::Subunits 'Your::Module::Name';

or a filepath to the module's source file:

    use Test::Subunits 'Your/Module/Name.pm';

The module then searches the usual C<@INC> path, looking for a matching
source file. When it finds the file, it reads the source and extracts
any subunits that you have specified using the L<Subunit mark-up
notation> which is described in the next section.

Normally, you specify these subunits as small subroutines, which
are then compiled into your namespace, whereupon you can call them
within your preferred testing framework (i.e. Test::More, Test::Class,
Test::Effects, etc.)


=head2 Subunit mark-up notation

Within your source file, you indicate subunits to be extracted using
special comments that start with two C<#> characters (i.e. using
ordinary Perl comments where the very first character of the comment is
another C<#>)

There are three forms of these special comments: block inclusions,
paragraph inclusions, and single-line inclusions...

=head3 Block inclusions

Block inclusions include all the code and any extra mark-up found
between two balanced delimiters: C<##{> and C<##}>. For example, given
the following source code:

    package My::Module;

    sub frobnicate_widgets {
        my ($threshold, $widgets_ref) = @_;

        # Normalize widget list...
        $widgets_ref = [grep {defined} @{$widgets_ref}];

        # Select widgets to be processed...
        my @selections;
        for my $list_elem (@{$widgets_ref}) {
            if ($list_elem > $threshold) {
                push @selections, $list_elem;
            }

            else {
                warn "Rejecting: $list_elem";
            }
        }

        # Process selected widgets...
        return map { frobnicate($_) } @selections;
    }

you could mark up two subunits to be extracted for testing like so:

    package My::Module;

    sub frobnicate_widgets {
        my ($threshold, $widgets_ref) = @_;

        # Normalize widget list...
        ##{
        ## sub normalize_list {
        ##  my $widgets_ref = shift;
            $widgets_ref = [grep {defined} @{$widgets_ref}];
        ##  return $widgets_ref
        ## }
        ##}

        # Select widgets to be processed...
        ##{
        ## sub divide_list {
        ##  my ($widgets_ref, $threshold)  = @_;
            my @selections;
            for my $list_elem (@{$widgets_ref}) {
                if ($list_elem > $threshold) {
                    push @selections, $list_elem;
                }

                else {
                    warn "Rejecting: $list_elem";
                }
            }
        ##  return @selections;
        ## }
        ##}

        # Process selected widgets...
        return map { frobnicate($_) } @selections;
    }

This defines two spearate subunits, which would be extracted as:

        sub normalize_list {
            my $widgets_ref = shift;
            $widgets_ref = [grep {defined} @{$widgets_ref}];
            return $widgets_ref
        }

        sub divide_list {
            my ($widgets_ref, $threshold)  = @_;
            my (@selections, @rejections);
            for my $list_elem (@{$widgets_ref}) {
                if ($list_elem > $threshold) {
                    push @selections, $list_elem;
                }

                else {
                    push @rejections, $list_elem;
                }
            }
            return [\@selections, \@rejections];
        }

It is an error to specify a C<##{> without a matching C<##}>, or
vice versa. 

Note that the C<##{> and C<##}> must be on lines by themselves
(i.e. the block starts on the line I<after> the C<##{> and finishes
on the line I<before> the C<##}>).


=head3 Paragraph inclusions

Because subunits are supposed to be small, coherent chunks of a larger
subroutine, it is often the case that they will consist of a single code
"paragraph". That is: they will consist of a sequence of statements with
no blank lines between them.

For example, in the C<frobnicate_widgets()> subroutine, the normalizing
step is a single paragraph of code:

        # Normalize widget list...
        $widgets_ref = [grep {defined} @{$widgets_ref}];

Because this happens frequently, Test::Subunits provides a shorthand for
the C<##{>..C<##}> notation: C<##:>

This shortcut does not require a closing delimiter because it always
terminates at the next blank line (i.e. the next line that is empty or
contains only whitespace characters).

For example, we could rewrite the normalizing subunit from:

        ##{
        ## sub normalize_list {
        ##  my $widgets_ref = shift;
            $widgets_ref = [grep {defined} @{$widgets_ref}];
        ##  return $widgets_ref
        ## }
        ##}

to:

        ##:
        ## sub normalize_list {
        ##  my $widgets_ref = shift;
            $widgets_ref = [grep {defined} @{$widgets_ref}];
        ##  return $widgets_ref
        ## }

This may seem like only a trivial improvement, but becomes much more
significant, and much more useful, when you are also using
L<wrappers|Creating subunits automatically (via wrappers)> (as
described later).


=head3 Single-line inclusions

As the above examples imply, within a block-inclusion or
paragraph-inclusion, you can also insert simple C<##> markers to inject
extra "virtual" lines of code around the actual lines of code being
extracted.

You can also use these kinds of inclusions to inject entirely independent
code fragments. For example, to enable L<inline testing|Inline unit testing>
(as described later).

You can even use them to I<prevent> the Test::Subunits module from
extracting code from a particular source file:

    ## BEGIN{ die 'No Test::Subunits for you!' }

or, less belligerently:

    ## __END__


=head2 Creating subunits manually

The previous L<examples|Block inclusions> demonstrate how to set up
testable subunits as independent subroutines, by injecting a C<sub>
declaration, some parameter unpacking, and a return statement around a
selection of actual code.

For example, given a subroutine:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        $limit //= 0;
        my @data = grep {defined && $_ >= $limit} @{$data_ref};

        return sort { $b <=> $a } @data;
    }

You could define three subunits (C<check_limit()>, C<check_data()>, and
C<check_sort()>, by annotating the source like so:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        ##{
        ## sub check_limit {
        ##     my $limit = shift;
        $limit //= 0;
        ##     return $limit;
        ## }
        ##}

        ##{
        ## sub check_data {
        ##     my ($limit, $data_ref) = @_;
        my @data = grep {defined && $_ >= $limit} @{$data_ref};
        ##     return @data;
        ## }
        ##}

        ##{
        ## sub check_sort {
        ##     my @data = @_;
        return sort { $b <=> $a } @data;
        ## }
        ##}
    }

Test::Subunits would then extract the following code:

        sub check_limit {
            my $limit = shift;
            $limit //= 0;
            return $limit;
        }

        sub check_data {
             my ($limit, $data_ref) = @_;
             my @data = grep {defined && $_ >= $limit} @{$data_ref};
             return @data;
        }

        sub check_sort {
             my @data = @_;
             return sort { $b <=> $a } @data;
        }

which you could test like so:

    use Test::Subunits 'My::Module';
    use Test::More;

    plan tests => 3;

    is         check_limit(undef), 0                  => 'Default limit';
    is_deeply [check_data(42, [40..44])], [42..44]    => 'Data checked';
    is_deeply [check_sort(40..44)], [reverse(40..44)] => 'Sorted';

    done_testing();


=head2 Creating subunits automatically (via wrappers)

Manually setting up each subunit subroutine gives you complete
flexibility but is often tedious, as almost every subroutine requires
more or less the same "boilerplate" code wrapped around it:
define the subroutine, unpack the arguments, execute the extracted code,
return the results.

So Test::Subunits provides a short-cut for specifying those kinds
of wrappers.

In all the preceding examples, the C<##{> and C<##:> markers had nothing
else on their line. However, if there is any extra text on the same line
after those opening delimiters, that text is used as the declaration of
the "boilerplate" wrapper to be placed around the extracted code.

The format of such declarations is:

    <subname> ( <parameters> ) --> <return expr>

which is converted to:

    sub <subname> {
        my ( <parameters> ) = @_;
        ...
        return <return expr>;
    }

So we could rewrite the example from the previous section:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        ##{
        ## sub check_limit {
        ##     my $limit = shift;
        $limit //= 0;
        ##     return $limit;
        ## }
        ##}

        ##{
        ## sub check_data {
        ##     my ($limit, $data_ref) = @_;
        my @data = grep {defined && $_ >= $limit} @{$data_ref};
        ##     return @data;
        ## }
        ##}

        ##{
        ## sub check_sort {
        ##     my @data = @_;
        return sort { $b <=> $a } @data;
        ## }
        ##}
    }

like so:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        ##{ check_limit ($limit) --> $limit
        $limit //= 0;
        ##}

        ##{ check_data ($limit, $data_ref) --> @data
        my @data = grep {defined && $_ >= $limit} @{$data_ref};
        ##}

        ##{ check_sort (@data) --> ()
        return sort { $b <=> $a } @data;
        ##}
    }

or, even more concisely using paragraph subunits, like so:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        ##: check_limit ($limit) --> $limit
        $limit //= 0;

        ##: check_data ($limit, $data_ref) --> @data
        my @data = grep {defined && $_ >= $limit} @{$data_ref};

        ##: check_sort (@data) --> ()
        return sort { $b <=> $a } @data;

    }

Note that, in both the above examples, the wrapper declaration for
C<check_sort()> explicitly specified no return value (i.e. an empty
list: C<< --> () >>). However, that return behaviour will actually be pre-empted by the
extracted C<return> statement itself. This is a common technique for
testing any subunit that includes a C<return> statement.

As a further optimization, if you leave off the return value
specification entirely (i.e. you don't specify a C<< --> >> at all),
then the wrapper simply returns its own parameter list.

That is, a wrapper declaration of the form:

    <subname> ( <parameters> )

is converted to:

    sub <subname> {
        my ( <parameters> ) = @_;
        ...
        return <parameters>;
    }

So we could rewrite the previous example even more compactly:

    sub sort_data {
        my ($data_ref, $limit) = @_;

        ##: check_limit ($limit)
        $limit //= 0;

        ##: check_data ($limit, $data_ref) --> @data
        my @data = grep {defined && $_ >= $limit} @{$data_ref};

        ##: check_sort (@data)
        return sort { $b <=> $a } @data;

    }


Note that this wrapper approach is the recommended way of using
Test::Subunits, as it imposes as little extra mark-up as possible on
your original source code.


=head2 Inline subunit testing

Using Test::Subunits to extract parts of your code into separate
subroutines is the preferred way of handling testing, as the extracted
subunits can then be tested repeatedly and independently.

However, it is also possible to use Test::Subunits to place your tests
directly within your source code. Note that this in I<not> the
recommended approach as it couples your tests too tightly with your
source, "fattens" your source code with too much mark-up, and also makes
it far more difficult to run multiple tests on the same code fragment.

Nevertheless, inlined tests I<are> possible. For example, in your source file:

    package My::Module;

    ## use Test::More;
    ## plan tests => 3;

    sub frobnicate_widgets {
        my ($threshold, $widgets_ref) = @_;

        # Normalize widget list...
        ##:
        ##  my $widgets_ref = [1,undef,2,undef,3];
            $widgets_ref = [grep {defined} @{$widgets_ref}];
        ##  is_deeply $widgets_ref, [1..3] => 'Normalized';

        # Select widgets to be processed...
        ##{
        ##  my $widgets_ref = [1..5];
        ##  my $threshold   = 3;
            my @selections;
            for my $list_elem (@{$widgets_ref}) {
                if ($list_elem > $threshold) {
                    push @selections, $list_elem;
                }

                else {
                    warn "Rejecting: $list_elem";
                }
            }
        ##  is_deeply \@selections, [4..5] => 'Selectioned';
        ##}

        # Process selected widgets...
        return
        ##:
        ## subtest 'Selections frobnicated' => sub {
        ##   like $_, qr/<frob>/ for
                map { frobnicate($_) } @selections;
        ## }

    }

    ## done_testing();

and then, in your test file:

    use Test::Subunits 'My::Module';
    # (No other code required)


=head2 Changing your subunits' namespace

Test::Subunits always compiles any code it extracts into the current
namespace in which the module itself is loaded. So if you write:

    use Test::Subunits 'Some::Module';  
    # ...which contains a check_input() subunit

    # ...and later...
    my @result = check_input(@test_data);

then any subunits extracted from F<Some/Module.pm> will be compiled into
the default C<main> namespace, and so you will be able to call them
directly, as above.

If you prefer to extract subunits into some other namespace, just
load Test::Subunits within that package instead, like so:

    {
        package Extracted::Subunits;

        use Test::Subunits 'Some::Module';  
        # ...which contains a check_input() subunit
    }

    # ...and later...
    my @result = Extracted::Subunits::check_input(@test_data);

So now you would need to qualify any call to an extracted subunit
that is made outside the namespace it was extracted into.

This I<extract-into-the-current-namespace> behaviour is particulaly
useful if you are using an OO testing framework such as Test::Class, as
it means you can install your subunits directly into your test class's
package, simply by loading Test::Subunits as part of the class
declaration.


=head1 DIAGNOSTICS

=over

=item C<< No argument supplied to 'use Test::Subunits' >>

Loading this module requires a single argument: a string containing the
name of another module, or else containing a path to an appropriate
source file. That argument tells the module where to locate and extract
your subunits.

But you loaded the module without specifying that argument, so it has
no idea where to look.

You just need to add an argument to your C<use Test::Subunits> statement.

Unless, you're attempting something tricky that involves loading the
module but I<not> using its normal functionality, in which case you
probably want:

    use Test::Subunits ();


=item C<< Test::Subunits can't locate requested source file: %s >>;

Loading this module requires a single argument: the name of another
module or else a path to an appropriate source file.

You specified such a argument when loading the module, but the module
couldn't find that source anywhere under your library path (i.e. it
wasn't in any of the directories listed in C<@INC>).

Did you mistype the source file's name, or do you need to add its
directory to C<@INC> using a C<use lib> statement?


=item C<< Unmatched ##{ >>

=item C<< Unmatched ##} >>

C<##{> and C<##}> subunit markers must appear in matched pairs in your
source file. But the module found an unmatched marker.

Did you (or your editor's helpful autoformatting) accidentally write
C<## {> or C<## }> instead?


=item C<< Unrecognized subunit marker %s >>

The module currently accepts only three kinds of valid subunit marker:
block markers (C<##{>), paragraph markers (C<##:>), and single line
markers (C<##>).

Any other (potential) marker consisting of C<##> followed by a printable
character is reserved for future use. You used such a marker, but it
isn't the future yet.

Did you mean one of the existing markers instead? Perhaps you wanted
a simple C<##>, but forgot to leave at least one whitespace
character after it?


=item C<< Invalid wrapper specification >>

The module found trailing text on a line with a C<##{> or a C<##:>
opening delimiter. The only trailing text allowed on such lines must
be a valid wrapper declaration of the form:

    <subname>  (<parameters>)  -->  <return expr>

or:

    <subname>  (<parameters>)

But the module encountered some other kind of text after the delimiter,
became hopelessly confused, burst into tears, and gave up.

Did you make a mistake in the wrapper specification format?
If so, see above.

Or did you try to inject some extra code on the same line as the opening
delimiter...which, unfortunately, you simply can't (yes, that's a
deliberate design decision).

In that second case, you'll need to rewrite something like:

    ##{ my $code = 'here';

as:

    ##{
    ##  my $code = 'here';

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::Subunits requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.

Works under Perl 5.10 or later.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-subunits@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 ACKNOWLEDGEMENTS

My sincere thanks to Mathias Fischer, who first brought this conflict
between the needs of testing and the constraints of code performance to
my attention.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
