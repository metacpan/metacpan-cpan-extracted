# Win32::ASP.pm
#
# Win32::ASP - a Module for ASP (PerlScript) Programming
#
# Authors:
#   Matt Sergeant (through 2.12)
#   Bill Odom     (2.15 and later)
#
# Revision: 2.15
# 
# Changes:
# - Commented and reformatted code.
# - Removed experimental STDIN support (see sections commented out below).
# - Removed autosplit/autoloading (for now).
# - Removed END block death hook handling.
# - Fixed param() call.
# - Added LoadEnvironment().
# - Began cleaning up the POD.
#
# Copyright 1998 Matt Sergeant.  All rights reserved.
# 
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
# 


use strict;

# print overloading

package Win32::ASP::IO;

use Win32::OLE::Variant;


sub new
  {
    my $self = bless {}, shift;

# WNO: Removed experimental STDIN support.
#
#   my $request = shift;
#   $self->{input_data} = Win32::OLE::Variant->new( VT_UI1, $request->BinaryRead(
#            $request->{TotalBytes} ) )->Value;
#   $self->{current_pos} = 0;
#

    $self;
  }
# end sub new


sub print
  {
    my $self = shift;
    Win32::ASP::Print(@_);
    1;
  }
# end sub print


sub TIEHANDLE { shift->new(@_)             }
sub PRINT     { shift->print(@_)           }
sub PRINTF    { shift->print(sprintf(@_))  }

# WNO: Removed experimental STDIN support.
# 
# sub READ
#   {
#     my $self = shift;
#     my $bufref;
#     
#     $$bufref = \$_[0];
# 
#     my (undef, $len, $offset) = @_;
# 
#     if (defined $offset)
#       {
#         $self->{current_pos} = $offset;
#       }
# 
#     my $string = substr($self->{input_data}, $self->{current_pos}, $len);
# 
#     $self->{current_pos} += $len;
# 
#     $$bufref = $string;
# 
#     return length($string);
# 
#   }
# # end sub READ
# 
#     
# sub READLINE
#   {
#     my $self = shift;
#     my $string;
#     while (my $char = $self->GETC)
#       {
#         $string .= $char;
#         last if $char eq "\015";
#       }
#     return $string;
#   }
# # end sub READLINE
# 
# 
# sub GETC
#   {
#     my $char;
#     
#     return undef unless shift->READ($char, 1);
#     return $char;
#   }
# # end sub GETC
# 

1;

# end print overloading



## Win32::ASP Module Interface

package Win32::ASP;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

BEGIN
  {
    require Exporter;
#   require AutoLoader;

    use vars
      qw(
        @ISA
        @EXPORT
        @EXPORT_OK
        %EXPORT_TAGS

        $Application
        $ObjectContext
        $Request
        $Response
        $Server
        $Session

        @DeathHooks
      );

    @ISA =
      qw(
        Exporter
#       AutoLoader
      );

    @EXPORT =
      qw(
        Print
        wprint
        die
        exit
        GetFormValue
        GetFormCount
        param
      );

    %EXPORT_TAGS =
      (
        strict =>
          [ qw(
            Print
            wprint
            die
            exit
            GetFormValue
            GetFormCount

            $Application
            $ObjectContext
            $Request
            $Response
            $Server
            $Session
          ) ]
      );

    @EXPORT_OK = qw( SetCookie );

    # Add all strict vars to @EXPORT_OK.
    #
    Exporter::export_ok_tags('strict');

    # Set up the exportable ASP objects, while avoiding "only used once"
    # warnings.
    #
    $Application   = $::Application    = $::Application;
    $ObjectContext = $::ObjectContext  = $::ObjectContext;
    $Request       = $::Request        = $::Request;
    $Response      = $::Response       = $::Response;
    $Server        = $::Server         = $::Server;
    $Session       = $::Session        = $::Session;

  }
# end BEGIN block


$VERSION='2.15';

# Create tied filehandle for print overloading.
#
tie *RESPONSE_FH, 'Win32::ASP::IO';
select RESPONSE_FH;

# WNO: Removed experimental STDIN support.
#
# close STDIN;
# tie *STDIN, 'Win32::ASP::IO', $Request;
#


# Preloaded methods go here.


sub _END
  {
    my $func;

    for $func (@DeathHooks)
      {
        $func->();
      }
  }
# end sub _END


# Autoload methods go after =cut, and are processed by the autosplit program.

# WNO: Commented out until I reinstate autoloading.

# 1;
# __END__

=head1 NAME

Win32::ASP - a module for ASP (PerlScript) Programming

=head1 SYNOPSIS

    use Win32::ASP;

    print "This is a test<BR><BR>";

    $PageName = GetFormValue('PageName');

    if ($PageName eq 'Select a page...')
      {
        die "Please go back and select a value from the Pages list.";
      }

    print "You selected the ", $PageName, " page.<BR>";

    exit;

=head1 DESCRIPTION

I knocked these routines together one day when I was wondering
"Why don't my C<print> statements output to the browser?" and
"Why don't C<exit> and C<die> end my script?"  So I started investigating how
I could overload the core functions. C<print> is overloaded via the C<tie>
mechanism (thanks to Eryq (F<eryq@zeegee.com>), Zero G Inc. for the
code which I ripped from IO::Scalar).

Also added recently was C<AddDeathHook>, which allows cleanup code to
be executed upon an C<exit> or C<die>. C<BinaryWrite> wraps up Unicode
conversion and C<< $Response->BinaryWrite >> in one call. Finally, I was
annoyed that I couldn't just develop a script using GET, then change to
POST for release, since ASP code handles each one differently. C<GetFormValue>
solves that one.

=head2 Installation instructions

Assuming the ActiveState repository is up-to-date with the latest archive
from CPAN, you should be able to type:

    ppm install Win32-ASP

on the command line. Make sure you're connected to the Internet first.

Installing via MakeMaker is pretty standard -- just download
the archive from CPAN, extract it to some directory, then type in that
directory:

    perl Makefile.PL
    nmake
    nmake install

Don't do C<nmake test> because the ASP objects won't be available.


=head1 Function Reference

=head2 Print LIST

Obsolete - use C<print> instead.

Outputs a string or comma-separated list of strings to the browser. Use
as if you were using C<print> in a CGI application. C<Print> handles the ASP
limitation of 128K per C<< $Response->Write >> call.

Note: C<print> calls C<Print>, so you can actually use either one,
but C<print> is more integrated with "the Perl way."

=cut

sub Print
  {
    for my $output (@_)
      {
        if (length($output) > 128000)
          {
            Win32::ASP::Print(unpack('a128000a*', $output));
          }
        else
          {
            $::Response->Write($output);
          }
      }
  }
# end sub Print


=head2 DebugPrint LIST

The same as C<Print>, except the output is wrapped in HTML comment markers,
so that you can only see it by viewing the page source. C<DebugPrint> is
not exported, so call it as

    Win32::ASP::DebugPrint($val);

This function is useful for debugging your application. For example, I
use it to print out SQL before it is executed.

=cut

sub DebugPrint(@)
  {
    Print "<!-- ", @_, " -->\n";
  }
# end sub DebugPrint


=head2 HTMLPrint LIST

The same as C<Print>, except the output is encoded so that
any HTML tags appear as sent, i.e. E<lt> becomes &lt;, E<gt> becomes &gt;, etc.
C<HTMLPrint> is not exported, so call it as

  Win32::ASP::HTMLPrint($val);

This function is useful for printing output that comes from a database
or a file, where you don't have total control over the input.

=cut

sub HTMLPrint(@)
  {
    for my $output (@_)
      {
        Print $::Server->HTMLEncode($output);
      }
  }
# end sub HTMLPrint


=head2 wprint LIST

Deprecated - use C<print> instead.

=cut

# WNO: Consider changing the wprint-to-Print calling method, similar to
# the param-to-GetFormValue change.

sub wprint(@)
  {
    Print @_;
  }
# end sub wprint


=head2 die LIST

Outputs the contents of LIST to the browser and then exits. C<die> automatically
calls C<< $Response->End >> and executes any cleanup code added with
C<AddDeathHook>.

=cut

sub die(@)
  {
    Print @_;
    Print "</BODY></HTML>";
    _END;
    $::Response->End();
    CORE::die();
  }
# end sub die


=head2 exit

Exits the current script. C<exit> automatically
calls C<< $Response->End >> and executes any cleanup code added with
C<AddDeathHook>.

=cut

# WNO: This prototype doesn't seem to do very much here,
# since the optional argument isn't used.

sub exit(;$)
  {
    _END;
    $::Response->End();
    CORE::exit();
  }
# end sub exit


=head2 HTMLEncode LIST

The same as C<HTMLPrint>, except the output is not printed but returned
as a scalar instead. C<HTMLEncode> is not exported, so call it as

    my $text = Win32::ASP::HTMLEncode($val);

This function is useful to handle output that comes from a database
or a file, where you don't have total control over the input.

If an array reference is passed, C<HTMLEncode> uses it. Otherwise, it assumes
an array of scalars is used. Using a reference makes for less time spent
passing values back and forth, and is the prefered method.

=cut

sub HTMLEncode(@)
  {
    my (@encodedHTML,$output) = (@_);
    my $ref = 0;

    if (ref $encodedHTML[0] eq "ARRAY")
      {
        @encodedHTML = @{$encodedHTML[0]};
        $ref++;
      }

    for $output (@encodedHTML)
      {
        $output = $::Server->HTMLEncode($output);
      }

    return $ref ? \@encodedHTML : @encodedHTML;
  }
# end sub HTMLEncode


=head2 GetFormValue EXPR [, EXPR]

Returns the value passed from a form (or non-form GET request). Use this
method if you want to be able to develop in GET mode (for ease of debugging)
and move to POST mode for release. The second (optional) parameter is for
getting multiple parameters, as in

    http://localhost/scripts/test.asp?Q=a&Q=b

In the above, S<C<GetFormValue("Q", 1)>> returns "a" and S<C<GetFormValue("Q", 2)>>
returns "b".

C<GetFormValue> will work in an array context too, returning all the values
for a particular parameter. For example, with the above URL:

    my @AllQs = GetFormValue('Q');

will result in the array C<@AllQs> containing C<('a', 'b')>.

If you call C<GetFormValue> without any parameters, it will
return a list of form parameters in the same way that CGI.pm's C<param>
function does. This allows easy iteration over the form elements:

    for my $key (GetFormValue())
      {
        print "$key = ", GetFormValue($key), "<br>\n";
      }

For convenience, Win32::ASP exports C<param> as an alias for C<GetFormValue>.

=cut

# WNO: Replace the $_[1] with a named parameter, if possible.
#
# WNO: Is the processing of both the query string *and* the form
#      the correct thing to do here?
#

sub GetFormValue(;$$)
  {

    unless (@_)
      {
        my @keys;

        for my $f (Win32::OLE::in ($::Request->QueryString))
          {
            push @keys, $f;
          }

        for my $f (Win32::OLE::in ($::Request->Form))
          {
            push @keys, $f;
          }

        return @keys;
      }

    $_[1] = 1 unless defined $_[1];

    if (!wantarray)
      {
        if ($::Request->ServerVariables('REQUEST_METHOD')->Item eq 'GET')
          {
            return $::Request->QueryString($_[0])->Item($_[1]);
          }
        else
          {
            return $::Request->Form($_[0])->Item($_[1]);
          }
      }
    else
      {
        my ($i, @ret);

        if ($::Request->ServerVariables('REQUEST_METHOD')->Item eq 'GET')
          {
            my $count = $::Request->QueryString($_[0])->{Count};

            for ($i = 1; $i <= $count; $i++ )
              {
                push @ret, $::Request->QueryString($_[0])->Item($i);
              }
          }
        else
          {
            my $count = $::Request->Form($_[0])->{Count};
            for ($i = 1; $i <= $count; $i++)
              {
                push @ret, $::Request->Form($_[0])->Item($i);
              }
          }

        return @ret;
      }
    # end if (!wantarray)

  }
# end sub GetFormValue


=head2 param EXPR [, EXPR]

C<param> is an alias for C<GetFormValue>.

=cut

# WNO: Since param() wasn't working, I've changed this to use
# the & form of subroutine call, so the @_ argument list is passed directly.
# I think this also has an affect on the context, but I'm not certain.
#

sub param { &GetFormValue; }


=head2 GetFormCount EXPR

Returns the number of times EXPR appears in the request (Form or QueryString).
Use this value as C<$i> to iterate over S<C<GetFormValue(EXPR, $i)>>.

For example, if the URL is:

    http://localhost/scripts/myscript.asp?Q=a&Q=b

And code is:

    my $numQs = GetFormCount('Q');

Then C<$numQs> will equal 2.

=cut

sub GetFormCount($)
  {
    if ($::Request->ServerVariables('REQUEST_METHOD')->Item eq 'GET')
      {
        return $::Request->QueryString($_[0])->Count;
      }
    else
      {
        return $::Request->Form($_[0])->Count;
      }

  }
# end sub GetFormCount


=head2 AddDeathHook LIST

This frightening-sounding function allows you to have cleanup code
executed when you C<die> or C<exit>. For example, you may want to
disconnect from your database if there is a problem:

    <%
        my $Conn = $Server->CreateObject('ADODB.Connection');
        $Conn->Open( "DSN=BADEV1;UID=sa;DATABASE=ProjAlloc" );
        $Conn->BeginTrans();

        Win32::ASP::AddDeathHook( sub { $Conn->Close if $Conn; } );
    %>

Now when you C<die> because of an error, your database connection
will close gracefully, instead of you having loads of rogue connections
that you have to kill by hand, or restart your database once a day.

Death hooks are not executed upon the normal termination of the script,
so if you have processing that should occur upon a normal exit,
be sure to execute it directly.

=cut

sub AddDeathHook(@)
  {
    push @DeathHooks, @_;
  }
# end sub AddDeathHook


# WNO: I've removed this for now, since the execution of END blocks is
# inconsistent among different PerlScript versions.
#
# According to my very brief tests, END blocks seem to run under builds
# 516 and 522, but not under 623 (or at least not visibly).  I don't yet
# know how they act under other builds.
#
# END
#   {
#     my $func;
# 
#     for $func (@DeathHooks)
#       {
#         &$func();
#       }
#   }
# # end END block


=head2 BinaryWrite LIST

Performs the same function as C<< $Response->BinaryWrite >>, but handles
Perl's Unicode-related null padding. This function is not exported,
so call it as

  Win32::ASP::BinaryWrite($val);

=cut

use Win32::OLE::Variant;

sub BinaryWrite(@)
  {
    for my $output (@_)
      {
        if (length($output) > 128000)
          {
            BinaryWrite(unpack('a128000a*', $output));
          }
        else
          {
            my $variant = Win32::OLE::Variant->new( VT_UI1, $output );
            $::Response->BinaryWrite($variant);
          }
      }
  }
# end sub BinaryWrite


=head2 LoadEnvironment

Copies the C<< $Request->ServerVariables >> collection
to the C<%ENV> hash, allowing the values to be accessed as environment variables.
Changes to C<%ENV> are not propagated back to the C<ServerVariables>
collection, and changes to the C<ServerVariables> collection do not automatically
appear in C<%ENV>. To see any such changes, simply run C<LoadEnvironment> again.

C<LoadEnvironment> is not exported, so run it as follows:

    Win32::ASP::LoadEnvironment;

=cut

sub LoadEnvironment
  {
    for my $svar (Win32::OLE::in($::Request->ServerVariables))
      {
        $ENV{$svar} = $::Request->ServerVariables($svar)->{Item};
      }
  }
# end sub LoadEnvironment


# These two functions are ripped from CGI.pm

# WNO: I'm leaving expire_calc and data alone for now.

sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || ($time eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^([+-]?\d+)([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}

sub date {
    my($time,$format) = @_;
    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    if ("$time" =~ m/^[^0-9]/o) {
        return $time;
    }

    # make HTTP/cookie date string from GMT'ed time
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sc) = ' ';
    $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

=head2 SetCookie Name, Value [, HASH]

Sets the cookie I<Name> with the value I<Value>. The optional HASH can
contain any of the following parameters:

=over 4

=item * -expires => A CGI.pm style expires value (see the CGI.pm header() documentation).

=item * -domain => a domain in the style ".matt.com" that the cookie is returned to.

=item * -path => a path that the cookie is returned to.

=item * -secure => cookie only gets returned under SSL if this is true.

=back

If I<Value> is a hash reference, then it creates a cookie dictionary. See 
the ASP docs for more info on cookie dictionaries.

Example:

    Win32::ASP::SetCookie("Matt", "Sergeant", ( -expires => "+3h",
        -domain => ".matt.com",
        -path => "/users/matt",
        -secure => 0 ));

=cut


sub SetCookie($$;%)
  {
    my ($name, $value, %hash) = @_;

    if (ref($value) eq 'HASH')
      {
        $value = join( "\&" ,
          map { $::Server->URLEncode($_) . '=' . $::Server->URLEncode($$value{$_}) }
          keys(%$value)
          )
      }

    $::Response->AddHeader( 'Set-Cookie',
      "$name=$value"
      . ($hash{-path}    ? "; path="    . $hash{-path}                         : "")
      . ($hash{-domain}  ? "; domain="  . $hash{-domain}                       : "")
      . ($hash{-secure}  ? "; secure"                                          : "")
      . ($hash{-expires} ? "; expires=" . &date(&expire_calc($hash{-expires})) : "")
      );
  }
# end sub SetCookie

=head1 AUTHORS

Originally created by Matt Sergeant E<lt>F<matt@sergeant.org>E<gt>.

Currently being maintained and updated by Bill Odom E<lt>F<wnodom@intrasection.com>E<gt>.

=cut

# end module Win32::ASP
