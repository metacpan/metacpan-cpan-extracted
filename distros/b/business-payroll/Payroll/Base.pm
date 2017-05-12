# Base.pm - The Base Object for the Business::Payroll.  Provides unified error handling, etc.
# Created by James A. Pattie, 2004-10-19.
# Derived from the Portal::Base module.

# Copyright (c) 2000-2004 Xperience, Inc. http://www.pcxperience.com/
# All rights reserved.  This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

package Business::Payroll::Base;
use strict;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '1.0';

=head1 NAME

Base - Base Object the Business::Payroll derives from.

=head1 SYNOPSIS

 package Business::Payroll::Test;
 use Business::Payroll::Base;
 use strict;
 use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

 require Exporter;

 @ISA = qw(Business::Payroll::Base Exporter AutoLoader);
 @EXPORT = qw();

 $VERSION = '0.01';

 sub new
 {
   my $class = shift;
   my $self = $class->SUPER::new(@_);
   my %args = ( something => 'Hello World!', @_ );

   if ($self->didErrorOccur)
   {
     $self->prefixError();
     return $self;
   }

   # instantiate anything unique to this module
   $self->{something} = $args{something};

   # do validation
   # The $self->Business::Payroll::Test::isValid makes sure we access our
   # isValid method and not any classes isValid method that has
   # derived from us.
   if (!$self->Business::Payroll::Test::isValid)
   {
     # the error is set in the isValid() method.
     return $self;
   }

   # do anything else you might need to do.
   return $self;
 }

 sub isValid
 {
   my $self = shift;

   # make sure our Parent class is valid.
   if (!$self->SUPER::isValid())
   {
     $self->prefixError();
     return 0;
   }

   # validate our parameters.
   if ($self->{something} !~ /^(.+)$/)
   {
     $self->invalid("something", $self->something);
   }

   if ($self->numInvalid() > 0 || $self->numMissing() > 0)
   {
     $self->postfixError($self->genErrorString("all"));
     return 0;
   }
   return 1;
 }

=head1 DESCRIPTION

Base is the base Business::Payroll class.

=head1 Exported FUNCTIONS

B<NOTE>: I<bool> = 1(true), 0(false)

=over 4

=item scalar new()

Creates a new instance of the Business::Payroll::Base object.

returns:  object reference

B<Variables>:

 error       - bool
 errorString - scalar
 _errors_    - hash contains the following error hashes:
                 missing,
                 invalid,
                 valid,
                 unknown,
                 extraInfo - holds extra info about an entry
                             in the missing or invalid hashes.
 errorPhrase     - "() - Error!<br>\n"
 missingArgument - "%s is missing"
 invalidArgument - "%s = '%s' is invalid"

=cut

sub new
{
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = bless {}, $class;
  my %args = ( @_ );

  # instantiate the Error variables
  $self->{error} = 0;
  $self->{errorString} = "";
  $self->{'_errors_'} = { missing => {},
                          invalid => {},
                          valid   => {},
                          unknown => {},
                          extraInfo => {},
                        };

  $self->{errorPhrase} = "() - Error!<br>\n";
  $self->{missingArgument} = "%s is missing";
  $self->{invalidArgument} = "%s = '%s' is invalid";

  # do validation
  if (!$self->Business::Payroll::Base::isValid)
  {
    # the error is set in the isValid() method.
    return $self;
  }

  return $self;
}

=item bool isValid(void)

 Returns 1 or 0 to indicate if the object is valid.
 The error will be available via errorMessage().

=cut

sub isValid
{
  my $self = shift;

  # make sure we don't have an error condition to start out with.
  $self->resetError();
  $self->clearErrors("all");

  # do validation code here.

  if ($self->numInvalid() > 0 || $self->numMissing() > 0)
  {
    $self->setError($self->genErrorString("all"));
    return 0;
  }
  return 1;
}

sub DESTROY
{
  my $self = shift;
}

sub AUTOLOAD
{
  my $self = shift;
  my $type = ref($self);
  if (!ref($self))
  {
    my $i=0;
    my $result = "";
    while (my @info=caller($i++))
    {
      $result .= "$info[2] - $info[3]: $info[4]\n";
    }
    die "$self is not an object\nCalled from:\n$result";
  }
  my $name = $AUTOLOAD;

  # make sure we don't emulate the DESTROY() method.
  return if $name =~ /::DESTROY$/;

  $name =~ s/.*://;	# strip fully-qualified portion
  unless (exists $self->{$name})
  {
    die "Can't access `$name' field in object of class $type";
  }
  if (@_)
  {
    return $self->{$name} = shift;
  }
  else
  {
    return $self->{$name};
  }
}

=item bool error(errorString)

 This method will set the error condition if an argument is 
 specified.
 
 The current error state is returned, regardless of if we are 
 setting an error or not.
 
 A \n is appended to the errorString so you don't have to provide it.
 errorString is prefixed with the caller's full method name followed 
 by the errorPhrase string.
 
 You can either specify the errorString value by name:
 
 $self->error(errorString => "This is an error!");
 
 or by value:
 
 $self->error("This is an error!");
 
 If you specify multiple arguments (in pass by value mode), then
 we check to see if the first argument contains %'s that are not
 \ escaped and are not %%.  If this is the case, then the incoming 
 arguments will be passed through sprintf() for formatting, else we 
 just join them with a space ' ' and append them to the current 
 errorString.
 
 
 To see if an error happened:
 
 if ($self->error) { die "Error: " . $self->errorMessage; }
 
=cut
sub error
{
  my $self = shift;
  my @callerArgs = caller(1);
  (my $subName = $callerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $callerErrStr = "$subName$self->{errorPhrase}";

  if (scalar @_ > 0)
  {
    # we are setting an error condition.
    if (scalar @_ == 1)
    {
      $self->{errorString} .= $callerErrStr . @_[0];
    }
    else
    {
      if (@_[0] eq "errorString")
      {
        my %args = ( @_ );
        if (!exists $args{errorString})  # make sure we get the errorString argument!
        {
          $self->error($callerErrStr . "<b>errorString</b> is missing!<br>\n");
          return;
        }
        else
        {
          $self->{errorString} .= $callerErrStr . $args{errorString};
        }
      }
      else
      {
        # handle the sprintf case.
        if (@_[0] =~ /(?<!\\)%[^%]/)
        {
          # build up the string to eval for the sprintf.
          my $str = "\"@_[0]\"";
          for (my $i=1; $i < scalar @_; $i++)
          {
            $str .= ", \"@_[$i]\"";
          }
          $self->{errorString} .= $callerErrStr;
          eval "\$self->{errorString} .= sprintf($str);";
          if ($@)
          {
            $self->error($callerErrStr . $@);
            return;
          }
        }
        else
        {
          $self->{errorString} .= $callerErrStr . join(" ", @_);          
        }
      }
    }
    $self->{errorString} .= "\n";
    $self->{error} = 1;
  }
  
  return $self->{error};
}

=item void setError(errorString)

 DEPRECATED: see error()

 optional: errorString
 returns: nothing
 Sets error = 1 and errorString = string passed in.
 The errorString is prefixed with the caller's full
 method name followed by the errorPhrase string.

 You can either call as
 setError(errorString => $string)
 or setError($string)

 If you do not specify anything, we blow an error
 telling you to specify errorString.
 
 \n is appended to the contents of the errorString
 passed in.

=cut

sub setError
{
  my $self = shift;
  my @callerArgs = caller(1);
  (my $subName = $callerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $callerErrStr = "$subName$self->{errorPhrase}";
  my $deprecated = "DEPRECATED call to setError!  Convert to using error().<br />\n";

  if (scalar @_ == 1)
  {
    $self->{errorString} = $deprecated . $callerErrStr . @_[0];
  }
  else
  {
    my %args = ( @_ );
    if (!exists $args{errorString})  # make sure we get the errorString argument!
    {
      $self->setError($callerErrStr . "<b>errorString</b> is missing!<br>\n");
      return;
    }
    else
    {
      $self->{errorString} = $deprecated . $callerErrStr . $args{errorString};
    }
  }
  $self->{errorString} .= "\n";
  $self->{error} = 1;
}

=item void prefixError(errorString)

 optional: errorString
 returns: nothing
 Sets error = 1 and prefixes errorString with string passed in.
 The errorString is prefixed with the caller's full
 method name followed by the errorPhrase string.

 You can either specify the errorString value by name:
 
 $self->prefixError(errorString => "This is an error!");
 
 or by value:
 
 $self->prefixError("This is an error!");
 
 If you specify multiple arguments (in pass by value mode), then
 we check to see if the first argument contains %'s that are not
 \ escaped and are not %%.  If this is the case, then the incoming 
 arguments will be passed through sprintf() for formatting, else we 
 just join them with a space ' ' and append them to the current 
 errorString.
 

 If you don't specify anything then
   If you have a previous error, we prefix the caller info to
     that error message.

=cut

sub prefixError
{
  my $self = shift;
  my @callerArgs = caller(1);
  (my $subName = $callerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $callerErrStr = "$subName$self->{errorPhrase}";

  if (scalar @_ == 1)
  {
    $self->{errorString} = $callerErrStr . @_[0] . $self->{errorString} . "\n";
  }
  else
  {
    if (@_[0] eq "errorString")
    {
      my %args = ( @_ );
      if (!exists $args{errorString})  # make sure we get the errorString argument!
      {
        if ($self->{errorString})
        {
          # prefix the old errorString value.
          $self->{errorString} = $callerErrStr . $self->{errorString};
        }
        else
        {     
          $self->error($callerErrStr . "<b>errorString</b> is missing!<br>\n");
          return;
        }
      }
      else
      {
        $self->{errorString} = $callerErrStr . $args{errorString} . "\n" . $self->{errorString};
      }
    }
    else
    {
      # handle the sprintf case.
      if (@_[0] =~ /(?<!\\)%[^%]/)
      {
        # build up the string to eval for the sprintf.
        my $str = "\"@_[0]\"";
        for (my $i=1; $i < scalar @_; $i++)
        {
          $str .= ", \"@_[$i]\"";
        }
        my $oldErrorStr = $self->{errorString};
        $self->{errorString} = $callerErrStr;
        eval "\$self->{errorString} .= sprintf($str);";
        if ($@)
        {
          $self->error($callerErrStr . $@);
          return;
        }
        $self->{errorString} .= "\n" . $oldErrorStr;
      }
      else
      {
        $self->{errorString} = $callerErrStr . join(" ", @_) . "\n" . $self->{errorString};
      }
    }
  }
  $self->{error} = 1;
}

=item void postfixError(errorString)


 DEPRECATED: see error()

 optional: errorString
 returns: nothing
 Sets error = 1 and postfixes errorString with string passed in.
 The errorString is prefixed with the caller's full
 method name followed by the errorPhrase string.

 You can either call as
 postfixError(errorString => $string)
 or postfixError($string)

 If you don't specify anything then we call setError and
   inform you that you need to specify the errorString value.

=cut

sub postfixError
{
  my $self = shift;
  my @callerArgs = caller(1);
  (my $subName = $callerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $callerErrStr = "$subName$self->{errorPhrase}";
  my $deprecated = "DEPRECATED call to postfixError!  Convert to using error().<br />\n";

  if (scalar @_ == 1)
  {
    $self->{errorString} .= $deprecated . $callerErrStr . @_[0];
  }
  else
  {
    my %args = ( @_ );
    if (!exists $args{errorString})
    {
      # they didn't pass in an errorString value.

      $self->setError($callerErrStr . "<b>errorString</b> is missing!<br>\n");
      return;
    }
    else
    {
      $self->{errorString} .= $deprecated . $callerErrStr . $args{errorString};
    }
  }
  $self->{errorString} .= "\n";
  $self->{error} = 1;
}

=item scalar didErrorOccur(void)

 DEPRECATED: see error()
 
 Returns the value of error.

=cut

sub didErrorOccur
{
  my $self = shift;

  return $self->{error};
}

=item scalar errorMessage(void)

 Returns the value of errorString.

=cut

sub errorMessage
{
  my $self = shift;

  return $self->{errorString};
}

=item scalar errorStr(void)

 Returns the value of errorString.
 
 Alternative to errorMessage().

=cut

sub errorStr
{
  my $self = shift;

  return $self->{errorString};
}

=item void resetError(void)

 Resets the error condition flag and string.

=cut

sub resetError
{
  my $self = shift;

  $self->{error} = 0;
  $self->{errorString} = "";
}

=item void missing(name, extraInfo)

 Adds an entry for name to the missing hash.
 If you specify another value, it will be stored
 as extra info about why this is missing.

 Ex:  $self->missing("personObj");
 would signal that personObj was not found.

 $self->missing("personObj", "this is a test.");
 would signal that personObj was not found and that
 you wanted to tell the user that "this is a test.".

=cut

sub missing
{
  my $self = shift;
  my $name = shift;
  my $extraInfo = (scalar @_ ? shift : "");
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  # set the error condition
  $self->{'_errors_'}->{missing}->{$name} = 1;
  $self->{'_errors_'}->{extraInfo}->{$name} = $extraInfo;
}

=item void valid(name, value)

 Adds an entry for name with it's value to the valid hash.

 Ex: $self->valid("name", "John Doe");
 would signal that name was found and specify the value we got.

=cut

sub valid
{
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  # set the error condition
  $self->{'_errors_'}->{valid}->{$name} = $value;
}

=item void invalid(name, value, extraInfo)

 Adds an entry for name with it's value in the invalid hash so you
 know it was invalid and what the user specified.
 If extraInfo is specified, then it is tacked on after the value
 part is displayed so you can inform the user of extra conditions
 about why this was invalid.

 Ex: $self->invalid("name", "");
 would signal that name was found but it was invalid and the value
 the user sent us.

 $self->invalid("name", "1", "names can not start with digits.");
 would signal that name = '1' was invalid and then let you give the
 user more feedback as to why "names can not start with digits."

=cut

sub invalid
{
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my $extraInfo = (scalar @_ ? shift : "");
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  # set the error condition
  $self->{'_errors_'}->{invalid}->{$name} = $value;
  $self->{'_errors_'}->{extraInfo}->{$name} = $extraInfo;
}

=item void unknown(name, value)

 Adds an entry for name with it's value in the unknown hash so you
 know it was specified but the calling program didn't know how to
 handle it.

 Ex: $self->unknown("123num", "xdy391234ksldfj.askj28095;");

=cut

sub unknown
{
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  # set the error condition
  $self->{'_errors_'}->{unknown}->{$name} = $value;
}

=item % or @ getMissing(void)

 Returns the hash of name entries that were required but not found
 or the array of name entries if in list context.

=cut

sub getMissing
{
  my $self = shift;

  return (wantarray ? keys %{$self->{'_errors_'}->{missing}} : %{$self->{'_errors_'}->{missing}});
}

=item % or @ getInvalid(void)

 Returns the hash of name, value pairs that were found to be invalid
 or the array of name entries if in list context.

=cut

sub getInvalid
{
  my $self = shift;

  return (wantarray ? keys %{$self->{'_errors_'}->{invalid}} : %{$self->{'_errors_'}->{invalid}});
}

=item % or @ getValid(void)

 Returns the hash of name, value pairs that were found to be valid
 or the array of name entries if in list context.

=cut

sub getValid
{
  my $self = shift;

  return (wantarray ? keys %{$self->{'_errors_'}->{valid}} : %{$self->{'_errors_'}->{valid}});
}

=item % or @ getUnknown(void)

 Returns the hash of name, value pairs that were found to be unknown
 or the array of name entries if in list context.

=cut

sub getUnknown
{
  my $self = shift;

  return (wantarray ? keys %{$self->{'_errors_'}->{unknown}} : %{$self->{'_errors_'}->{unknown}});
}

=item scalar getMissingEntry(entry)

 Returns the value from the missing hash associated with entry.

=cut
sub getMissingEntry
{
  my $self = shift;
  my $entry = shift;

  return $self->{'_errors_'}->{missing}->{$entry};
}

=item scalar getInvalidEntry(entry)

 Returns the value from the invalid hash associated with entry.

=cut
sub getInvalidEntry
{
  my $self = shift;
  my $entry = shift;

  return $self->{'_errors_'}->{invalid}->{$entry};
}

=item scalar getValidEntry(entry)

 Returns the value from the valid hash associated with entry.

=cut
sub getValidEntry
{
  my $self = shift;
  my $entry = shift;

  return $self->{'_errors_'}->{valid}->{$entry};
}

=item scalar getUnknownEntry(entry)

 Returns the value from the unknown hash associated with entry.

=cut
sub getUnknownEntry
{
  my $self = shift;
  my $entry = shift;

  return $self->{'_errors_'}->{unknown}->{$entry};
}

=item scalar formEncodeString(string)

 HTTP Form encodes the string to protect against xss
 (cross site scripting) or for embedding in an HTML Form.

=cut

sub formEncodeString
{
  my $self = shift;
  my $string = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $string)
  {
    die($errStr . sprintf($self->{missingArgument}, "string"));
  }

  my $formEncodeChars = '<>"';
  my %formEncodeStrings = ( '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', '&' => '&amp;' );

  if (length $string > 0)
  {
    # handle the special cases first.
    foreach my $char (qw/&/)
    {
      $string =~ s/(?<!\\)[$char]/$formEncodeStrings{$char}/emg;
    }
    # now handle the rest.
    $string =~ s/(?<!\\)([$formEncodeChars])/$formEncodeStrings{$1}/emg;
  }

  return $string;
}

=item scalar genErrorString(type)

 Generates the Error String for the specified type.

 type = missing, invalid, all

 When type = all, then we generate first the missing then the
 invalid error strings.

 type = missing uses the missingArgument language phrase.

 type = invalid uses the invalidArgument language phrase.

 Ex:  $self->setError($self->genErrorString("missing"));

=cut

sub genErrorString
{
  my $self = shift;
  my $type = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $type)
  {
    die($errStr . sprintf($self->{missingArgument}, "type"));
  }
  if ($type !~ /^(all|missing|invalid)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "type", $type));
  }

  my $errorString = "";
  if ($type =~ /^(all|missing)$/)
  {
    foreach my $name (keys %{$self->{'_errors_'}->{missing}})
    {
      # protect us from xss (cross site scripting)
      $name = $self->formEncodeString($name);

      $errorString .= sprintf($self->{missingArgument}, $name) . " " . $self->{'_errors_'}->{extraInfo}->{$name} . "<br>\n";
    }
  }
  if ($type =~ /^(all|invalid)$/)
  {
    foreach my $name (keys %{$self->{'_errors_'}->{invalid}})
    {
      my $value = $self->{'_errors_'}->{invalid}->{$name};

      # protect us from xss (cross site scripting)
      $name = $self->formEncodeString($name);
      $value = (defined $value ? $self->formEncodeString($value) : $value);

      $errorString .= sprintf($self->{invalidArgument}, $name, $value) . " " . $self->{'_errors_'}->{extraInfo}->{$name} . "<br>\n";
    }
  }

  return $errorString;
}

=item bool isEntryMissing(name)

 Returns 1 if name is found in the missing hash, else 0.

=cut

sub isEntryMissing
{
  my $self = shift;
  my $name = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  return (exists $self->{'_errors_'}->{missing}->{$name});
}

=item bool isEntryInvalid(name)

 Returns 1 if name is found in the invalid hash, else 0.

=cut

sub isEntryInvalid
{
  my $self = shift;
  my $name = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  return (exists $self->{'_errors_'}->{invalid}->{$name});
}

=item bool isEntryValid(name)

 Returns 1 if name is found in the valid hash, else 0.

=cut

sub isEntryValid
{
  my $self = shift;
  my $name = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  return (exists $self->{'_errors_'}->{valid}->{$name});
}

=item bool isEntryUnknown(name)

 Returns 1 if name is found in the unknown hash, else 0.

=cut

sub isEntryUnknown
{
  my $self = shift;
  my $name = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $name)
  {
    die($errStr . sprintf($self->{missingArgument}, "name"));
  }
  if ($name !~ /^(.+)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "name", $name));
  }

  return (exists $self->{'_errors_'}->{unknown}->{$name});
}

=item void clearErrors(type)

 Empties the specified error hash.

 type can be all, missing, invalid, valid, unknown

 When type = all, then we clear all the hashes, otherwise we just
 clear the specified hash.

 Ex:  $self->clearErrors("missing");
 would clear just the missing entries.

=cut

sub clearErrors
{
  my $self = shift;
  my $type = shift;
  my @myCallerArgs = caller(0);
  (my $subName = $myCallerArgs[3]) =~ s/^(.+)(::)([^:]+)$/$1->$3/;
  my $errStr = "$subName$self->{errorPhrase}";

  if (!defined $type)
  {
    die($errStr . sprintf($self->{missingArgument}, "type"));
  }
  if ($type !~ /^(all|missing|invalid|valid|unknown)$/)
  {
    die($errStr . sprintf($self->{invalidArgument}, "type", $type));
  }

  if ($type =~ /^(all|missing)$/)
  {
    %{$self->{'_errors_'}->{missing}} = ();
  }
  if ($type =~ /^(all|invalid)$/)
  {
    %{$self->{'_errors_'}->{invalid}} = ();
  }
  if ($type =~ /^(all|valid)$/)
  {
    %{$self->{'_errors_'}->{valid}} = ();
  }
  if ($type =~ /^(all|unknown)$/)
  {
    %{$self->{'_errors_'}->{unknown}} = ();
  }
  if ($type =~ /^(all|missing|invalid)$/)
  {
    %{$self->{'_errors_'}->{extraInfo}} = ();
  }
}

=item scalar numMissing(void)

 Returns the number of entries that were required but not found.

=cut

sub numMissing
{
  my $self = shift;

  return keys %{$self->{'_errors_'}->{missing}};
}

=item scalar numInvalid(void)

 Returns the number of entries that were found to be invalid.

=cut

sub numInvalid
{
  my $self = shift;

  return keys %{$self->{'_errors_'}->{invalid}};
}

=item scalar numValid(void)

 Returns the number of entries that were found to be valid.

=cut

sub numValid
{
  my $self = shift;

  return keys %{$self->{'_errors_'}->{valid}};
}

=item scalar numUnknown(void)

 Returns the number of entries that were found to be unknown.

=cut

sub numUnknown
{
  my $self = shift;

  return keys %{$self->{'_errors_'}->{unknown}};
}

=item % extract(args)

 Takes a string of comma seperated arguments that are taken
 from the current object and inserted into a hash.

 Returns the hash of arguments capable of being passed to
 a new method.

 Ex:

 my %args = $self->extract("error, errorString");

 Would return a hash containing the error and errorString
 variables from the current object.

=cut

sub extract
{
  my $self = shift;
  my $args = shift;
  my %result = ();

  my @args = split /\s*,\s*/, $args;
  foreach my $arg (@args)
  {
    $result{$arg} = $self->{$arg};
  }

  return %result;
}

=back

=cut

1;
__END__

=head1 NOTE

 All data fields are accessible by specifying the object
 and pointing to the data member to be modified on the
 left-hand side of the assignment.
 Ex.  $obj->variable($newValue); or $value = $obj->variable;

=head1 AUTHOR

James A. Pattie (mailto:james@pcxperience.com)

=head1 SEE ALSO

perl(1), Business::Payroll(3)

=cut
