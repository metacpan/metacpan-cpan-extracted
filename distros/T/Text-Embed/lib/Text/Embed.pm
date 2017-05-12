package Text::Embed;

use strict;
use warnings;
use Carp;

our $VERSION  = '0.03';

my %modules   = ();
my %regexen   = ();
my %callbacks = ();
my %handles   = ();

my $rex_proc  = undef;
my $rex_parse = undef;

my $NL        = '(?:\r?\n)'; 
my $VARS      = '\$\((\w+)\)';

#
# Default handlers for parsing - see POD
# 

my %def_parse  =
(
    ':underscore' => qr/${NL}__([^_].*[^_])__$NL/,
    ':define'     => qr/${NL}#define\s+?(\S+?)(?:$NL|\s+?$NL|\s+?)/,
    ':cdata'      => sub{$_ = shift or return; 
                       return($$_ =~ m#\s*?<!\[(.+?)\[(.*?)\]\]>\s*#sgo);
                     },
);

$def_parse{':default'} = $def_parse{':underscore'};
$rex_parse             = join('|', keys %def_parse);

#
# Default handlers for processing - see POD
# 

my %def_proc  =
(
    ':raw'            => undef,
    ':trim'           => sub{ trim($_[1]);     },
    ':compress'       => sub{ compress($_[1]); },
    ':block-indent'   => sub{ block($_[1]);    },
    ':block-noindent' => sub{ block($_[1],1);  },

    ':strip-cpp'      => sub{strip($_[1],'/\*','\*/'),strip($_[1], '//');},
    ':strip-c'        => sub{strip($_[1],'/\*','\*/');},
    ':strip-xml'      => sub{strip($_[1],'<!--','-->');},
    ':strip-perl'     => sub{strip($_[1]);},
);

$def_proc{':default'}  = $def_proc{':raw'};
$rex_proc              = join('|', keys %def_proc);

#
# import: 
# process arguments and tie caller's %DATA
#
sub import
{
    my $package = shift;
    my $regex   = shift;
    my $cback   = @_ ? [@_] : undef;
    my $caller  = caller;

    $regex = $def_parse{$regex}    if($regex && $regex =~ /^$rex_parse$/);
    $regex = $def_parse{':default'}unless $regex;

    # NB: test for existence...
    if(!exists $modules{$caller}){
        # process all callbacks that are stringified
        no strict 'refs';
        if($cback){
            foreach(@$cback){
                if(!ref $_){
                    if($_ =~ /^$rex_proc$/){
                        # predefined alias
                        $_ = $def_proc{$_};
                    }
                    else{
                        # stringy code ref - relative or absolute
                        $_ = ($_ =~ /\:\:/go) ? \&{$_} : 
                                                \&{$caller."\::".$_}; 
                    }
                }
                else{
                    Carp::croak("Not a CODE reference")
                        unless "CODE" eq ref($_);
                }
            }
        }

        *{"$caller\::DATA"} = {};
        tie %{"$caller\::DATA"}, $package, $caller;

        # store private attributes till lazy-loading DATA
        $handles{$caller}   = \*{$caller."::DATA"};
        $modules{$caller}   = undef;
        $regexen{$caller}   = (ref $regex) ? $regex : qr($regex);
        $callbacks{$caller} = $cback;
    }
}

#
# _read_data:
# Parse and process DATA handle once %DATA has been used. 
# Cant do during import as Perl hasn't parsed that far by then
#
sub _read_data
{
    my $self = shift;

    # NB:test for definedness...
    if(! defined $modules{$$self})
    {
        my (@data, $data, $tell, $rex, $code, $strip);
        $rex   = delete $regexen{$$self};
        $code  = delete $callbacks{$$self};
        $data  = delete $handles{$$self};

        {
            # slurp and parse...
            no warnings;
            local $/ = undef;
            binmode($data);

            $tell = tell($data);
            Carp::croak("Error: $$self has no __DATA__ section")
                if ($tell < 0);

            my $d = <$data>;
            @data = (ref($rex) eq "CODE") ? $rex->(\$d)  : 
                                            split(/$rex/, $d);
        }

        $modules{$$self} = {} and return 
            unless @data;

        # remove empty elements...depends on syntax used
        shift @data if $data[0]  =~ /^\s*$/o;
        pop   @data if $data[-1] =~ /^\s*$/o;
        Carp::croak("Error: \%$$self\::DATA - bad key/value pairs")
            if (@data % 2);

        #  invoke any callbacks...
        if($code){
            for(my $i=0; $i<@data; $i+=2){
                $_ && $_->(\$data[$i], \$data[$i+1])  
                    foreach @$code;
            }
        }
        
        # coerce into hashref and cover our tracks
        $modules{$$self} = {@data};
        delete $modules{$$self}{''};
        seek($data, $tell,0);
    }
}

#
# Utility functions - see POD
#

#
# compress: trim and compact all whitspace to ' '
#
sub compress
{
    my $txt = shift;
    s#\s+# #gs, s#^\s+## , s#\s+$## for($$txt);
}

#
# block: preserve common indentation and surrounding newlines
#
sub block
{
    my $txt = shift;
    my $i   = shift;
    if($i){
        # strip smallest common indentation
        ($i) = sort {length($a) <=> length($b)} $$txt =~ m#^$NL?(\s+)\S#mg;
        s#^$i##mg for($$txt);   
    }  
    s#^\s+$##mg for($$txt);
}

#
# trim: remove trailing and leading whitespace
#
sub trim
{
    my $txt = shift;
    s#^\s+##, s#\s+$## for($$txt);
}

#
# strip: remove (comment) sequences
#
sub strip
{
    my $txt = shift;
    my $beg = shift || '\#';
    my $end = shift || $NL;
    $$txt =~ s#$beg.*?$end##sgi;
}

#
# interpolate: simple template interpolation
#
sub interpolate
{
    my $txt  = shift;
    my $vals = shift;
    my $rex  = shift || $VARS;
    $$txt =~ s#$rex#$vals->{$1}#sg;
}

#
# TIE HASH interface (read-only)
# not much to see here...
#

sub TIEHASH 
{
    my $class  = shift;
    my $caller = shift;
    return bless \$caller, $class;
}

sub FETCH 
{
    my $self = shift;
    my $key  = shift;
    $self->_read_data if(! defined $modules{$$self});
    return $modules{$$self}{$key};
}

sub EXISTS
{
    my $self = shift;
    my $key  = shift;
    $self->_read_data if(! defined $modules{$$self});
    return exists $modules{$$self}{$key};
}

sub FIRSTKEY
{
    my $self = shift;
    $self->_read_data if(! defined $modules{$$self});
    my $a = keys %{$modules{$$self}};
    return each %{$modules{$$self}};
}

sub NEXTKEY
{
    my $self = shift;
    $self->_read_data if(! defined $modules{$$self});
    return each %{ $modules{$$self} }
}

sub DESTROY
{
    my $self = shift;
    $modules{$$self} = undef; 
}

sub STORE 
{
    my $self = shift;
    my $k    = shift;
    my $v    = shift;
    #$self->_read_data if(! defined $modules{$$self});
    Carp::croak("Attempt to store key ($k) in read-only hash \%DATA");
}

sub DELETE   
{
    my $self = shift;
    my $k    = shift;
    #$self->_read_data if(! defined $modules{$$self});
    Carp::croak("Attempt to delete key ($k) from read-only hash \%DATA");
}

sub CLEAR    
{
    my $self = shift;
    #$self->_read_data if(! defined $modules{$$self});
    Carp::croak("Attempt to clear read-only hash \%DATA");
}


1;


=pod

=head1 NAME

Text::Embed - Cleanly seperate unwieldy text from your source code

=head1 SYNOPSIS

    use Text::Embed
    use Text::Embed CODE|REGEX|SCALAR
    use Text::Embed CODE|REGEX|SCALAR, LIST

=head1 ABSTRACT

Code often requires chunks of text to operate - chunks not large enough 
to warrant extra file dependencies, but enough to make using quotes and 
heredocs' ugly.

A typical example might be code generators. The text itself is code, 
and as such is difficult to differentiate and maintain when it is 
embedded inside more code. Similarly, CGI scripts often include 
embedded HTML or SQL templates. 

B<Text::Embed> provides the programmer with a flexible way to store 
these portions of text in their namespace's __DATA__ handle - I<away 
from the logic> - and access them through the package variable B<%DATA>. 

=head1 DESCRIPTION

=head2 General Usage:

The general usage is expected to be suitable for a majority of cases:

    use Text::Embed;

    foreach(keys %DATA)
    {
        print "$_ = $DATA{$_}\n";
    }

    print $DATA{foo};



    __DATA__
    
    __foo__

    yadda yadda yadda...

    __bar__

    ee-aye ee-aye oh

    __baz__
    
    woof woof

=head2 Custom Usage:

There are two stages to B<Text::Embed>'s execution - corresponding to the 
first and remaining arguments in its invocation.  

    use Text::Embed ( 
        sub{ ... },  # parse key/values from DATA 
        sub{ ... },  # process pairs
        ...          # process pairs
    );

    ...

    __DATA__

    ...

=head3 Stage 1: Parsing

By default, B<Text::Embed> uses similar syntax to the __DATA__ token to 
seperate segments - a line consisting of two underscores surrounding an
identifier. Of course, a suitable syntax depends on the text being embedded.

A REGEX or CODE reference can be passed as the first argument - in order 
to gain finer control of how __DATA__ is parsed:

=over 4

=item REGEX

    use Text::Embed qr(<<<<<<<<(\w*?)>>>>>>>>);

A regular expression will be used in a call to C<split()>. Any 
leading or trailing empty strings will be removed automatically.

=item CODE

    use Text::Embed sub{$_ = shift; ...}
    use Text::Embed &Some::Other::Function;

A subroutine will be passed a reference to the __DATA__ I<string>. 
It should return a LIST of key-value pairs.

=back

In the name of laziness, B<Text::Embed> provides a couple of 
predefined formats:

=over 4

=item :default

Line-oriented __DATA__ like format:

    __BAZ__ 
    baz baz baz
    __FOO__
    foo foo foo
    foo foo foo

=item :define

CPP-like format (%DATA is readonly - can be used to define constants):

    #define BAZ     baz baz baz
    #define FOO     foo foo foo
                    foo foo foo

=item :cdata

Line-agnostic CDATA-like format. Anything outside of tags is ignored.

    <![BAZ[baz baz baz]]>
    <![FOO[
        foo foo foo
        foo foo foo
    ]]>

=back

=head3 Stage 2: Processing

After parsing, each key-value pair can be further processed by an arbitrary
number of callbacks. 

A common usage of this might be controlling how whitespace is represented 
in each segment. B<Text::Embed> provides some likely defaults which operate
on the hash values only.

=over 4

=item :trim

Removes trailing or leading whitespace

=item :compress

Substitutes zero or more whitspace with a single <SPACE>

=item :block-indent

Removes trailing or leading blank lines, preserves all indentation

=item :block-noindent

Removes trailing or leading blank lines, preserves unique indentation

=item :raw

Leave untouched

=item :default

Same as B<:raw>

=back

If you need more control, CODE references or named subroutines can be 
invoked as necessary. At this point it is safe to rename or modify keys. 
Undefining a key removes the entry from B<%DATA>.

=head3 An Example Callback chain

For the sake of brevity, consider a module that has some embedded SQL. 
We can implement a processing callback that will prepare each statement, 
leaving B<%DATA> full of ready to execute DBI statement handlers: 

    package Whatever;

    use DBI;
    use Text::Embed(':default', ':trim', 'prepare_sql');

    my $dbh;

    sub prepare_sql
    {
        my ($k, $v) = @_;
        if(!$dbh)
        {
            $dbh = DBI->connect(...);
        }
        $$v = $dbh->prepare($$v);
    }

    sub get_widget
    {
        my $id  = shift;
        my $sql = $DATA{select_widget};

        $sql->execute($id);
    
        if($sql->rows)
        {
            ...          
        }
    }
  

    __DATA__
    
    __select_widget__
        SELECT * FROM widgets WHERE widget_id = ?;

    __create_widget__
        INSERT INTO widgets (widget_id,desc, price) VALUES (?,?,?);

    ..etc

Notice that each pair is I<passed by reference>. 

=head3 Utility Functions

Several utility functions are available to aid implementing custom 
processing handlers. These are not exported into the callers namespace.

The first are equivalent to the default processing options:

=over 4

=item Text::Embed::trim SCALARREF

    use Text::Embed(':default',':trim');
    use Text::Embed(':default', sub {Text::Embed::trim($_[1]);} );

=item Text::Embed::compress SCALARREF

    use Text::Embed(':default',':compress');
    use Text::Embed(':default', sub {Text::Embed::compress($_[1]);} );

=item Text::Embed::block SCALARREF BOOLEAN

    use Text::Embed(':default',':block-indent');
    use Text::Embed(':default', sub {Text::Embed::block($_[1]);} );

If a true value is passed as the second argument, then shared
indentation is removed, ie B<:block-noindent>.

=back

=head3 Commenting 

If comments would make your segments easier to manage, B<Text::Embed> 
provides defaults handlers for stripping common comment syntax - 
B<:strip-perl>, B<:strip-c>, B<:strip-cpp>, B<:strip-xml>. 

=over 4

=item Text::Embed::strip SCALARREF [REGEX] [REGEX]

    use Text::Embed(':default',':strip-c');
    use Text::Embed(':default', sub {Text::Embed::strip($_[1], '/\*', '\*/');} );

Strips all sequences between second and third arguments. The default 
arguments are '#' and '\n' respectively.

=back

=head3 Templating

Typically, embedded text may well be some kind of template. Text::Embed 
provides rudimentary variable interpolation for simple templates.
The default variable syntax is of the form C<$(foo)>:

=over 4

=item Text::Embed::interpolate SCALARREF HASHREF [REGEX]

    my $tmpl = "Hello $(name)! Your age is $(age)\n";
    my %vars = (name => 'World', age => 4.5 * (10 ** 9));
    
    Text::Embed::interpolate(\$tmpl, \%vars);
    print $tmpl;

Any interpolation is done via a simple substitution. An additional 
regex argument should accomodate this appropriately, by capturing 
the necessary hashkey in C<$1>: 

    Text::Embed::interpolate(\$tmpl, \%vars, '<%(\S+)%>');

=back

=head1 BUGS & CAVEATS

The most likely bugs related to using this module should manifest 
themselves as C<bad key/value> error messages. There are two related 
causes:

=over 4

=item COMMENTS

It is important to realise that B<Text::Embed> does I<not> have its own 
comment syntax or preprocessor. Any parser that works using C<split()> is 
likely to fail if comments precede the first segment. I<Comments should 
exist in the body of a segment - not preceding it>.

=item CUSTOM PARSING

If you are defining your own REGEX parser, make sure you understand 
how it works when used with C<split()> - particularly if your syntax 
wraps your data. Consider using a subroutine for anything non-trivial.

=back

If you employ REGEX parsers, use seperators that are I<significantly> 
different - and well spaced - from your data, rather than relying on
complicated regular expressions to escape pathological cases.

Bug reports and suggestions are most welcome.

=head1 AUTHOR

Copyright (C) 2005 Chris McEwan - All rights reserved.

Chris McEwan <mcewan@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

