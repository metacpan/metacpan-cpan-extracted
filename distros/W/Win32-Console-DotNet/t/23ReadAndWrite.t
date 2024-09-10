# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ReadAndWrite.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Config;
use constant CAPTURE_TINY => eval { require Capture::Tiny };
use if CAPTURE_TINY, 'Capture::Tiny', qw( capture_stdout );
use Encode ();
use Encode::Alias ();
use English qw( -no_match_vars );
use List::Util qw( first );
use Perl::OSType qw( os_type );
use POSIX;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

# Fix STDOUT redirection from prove
# This workaround only works if STDERR has not also been redirected
POSIX::dup2(fileno(STDERR), fileno(STDOUT));

use constant FALSE  => !!'';
use constant TRUE   => !!1;

#------------
note 'Write';
#------------

sub WriteCore {
  # We just want to ensure none of these throw exceptions, we don't actually 
  # validate what was written.

  Console->Write("%d", 32);
  Console->Write("%s", undef);
  Console->Write("%d %s", 32, "Hello");
  Console->Write("%s", undef, undef);
  Console->Write("%d %s %d", 32, "Hello", 50);
  Console->Write("%s", undef, undef, undef);
  Console->Write("%d %s %d %d", ( 32, "Hello", 50, 5 ));
  Console->Write("%s", ( undef, undef, undef, undef ));
  Console->Write("%d %s %d %d %s", ( 32, "Hello", 50, 5, 'a' ));
  Console->Write("%s", ( undef, undef, undef, undef, undef ));
  Console->Write(TRUE ? 'True' : 'False');
  Console->Write('a');
  Console->Write(join '' => ( 'a', 'b', 'c', 'd', ) );
  Console->Write(join '' => ( 'a', 'b', 'c', 'd', )[1, 2] );
  Console->Write(1.23);
  Console->Write(123.456);
  Console->Write(1.234);
  Console->Write(39);
  Console->Write(unpack 'I', pack 'j' => 50);
  Console->Write(unpack 'l', pack 'j' => 50);
  Console->Write(unpack 'L', pack 'j' => 50);
  Console->Write(ref bless \do { \0 }, 'System::Object');
  Console->Write("Hello World");
}

subtest 'WriteOverloads' => sub {
  plan tests => 1;
  my $savedStandardOutput = Console->Out;
  lives_ok {
    use autodie;
    my $memStream = '';
    open(my $sw, '>', \$memStream);
    Console->SetOut($sw);
    WriteCore();
  };
  Console->SetOut($savedStandardOutput);
};

SKIP: { 
  skip 'Capture::Tiny not installed', 2 unless CAPTURE_TINY;
  subtest 'WriteToOutputStream_EmptyArray' => sub {
    plan tests => 2;
    my $outStream = Console->OpenStandardOutput();

    my $data = capture_stdout( sub { 
      lives_ok {
        use warnings FATAL => 'all';
        $outStream->print(()[0..0]);
      }
    });
    is length($data), 0;
  };

  subtest 'WriteOverloadsToRealConsole' => sub {
    plan tests => 2;
    my $data = capture_stdout( sub {
      lives_ok { WriteCore() }
    });
    ok length($data);
  };
}

sub WriteLineCore {
  subtest 'NewLine' => sub {
    plan tests => 2;
    like $INPUT_RECORD_SEPARATOR, qr/\R/, 'Equal';
    { 
      local $INPUT_RECORD_SEPARATOR = "abcd";
      is $INPUT_RECORD_SEPARATOR, "abcd", 'Equal';
    }
  };

  # We just want to ensure none of these throw exceptions, we don't actually 
  # validate what was written.

  no if $] >= 5.022, 'warnings', qw( redundant );
  Console->WriteLine("%d", 32);
  Console->WriteLine("%s", undef);
  Console->WriteLine("%d %s", 32, "Hello");
  Console->WriteLine("%s", undef, undef);
  Console->WriteLine("%d %s %d", 32, "Hello", 50);
  Console->WriteLine("%s", undef, undef, undef);
  Console->WriteLine("%d %s %d %d", ( 32, "Hello", 50, 5 ));
  Console->WriteLine("%s", ( undef, undef, undef, undef ));
  Console->WriteLine("%d %s %d %d %s", ( 32, "Hello", 50, 5, 'a' ));
  Console->WriteLine("%s", ( undef, undef, undef, undef, undef ));
  Console->WriteLine(TRUE ? 'True' : 'False');
  Console->WriteLine('a');
  Console->WriteLine(join '' => ( 'a', 'b', 'c', 'd', ) );
  Console->WriteLine(join '' => ( 'a', 'b', 'c', 'd', )[1, 2] );
  Console->WriteLine(1.23);
  Console->WriteLine(123.456);
  Console->WriteLine(1.234);
  Console->WriteLine(39);
  Console->WriteLine(unpack 'I', pack 'j' => 50);
  Console->WriteLine(unpack 'l', pack 'j' => 50);
  Console->WriteLine(unpack 'L', pack 'j' => 50);
  Console->WriteLine(ref bless \do { \0 }, 'System::Object');
  Console->WriteLine("Hello World");
}

subtest 'WriteLineOverloads' => sub {
  plan tests => 2;
  my $savedStandardOutput = Console->Out;
  lives_ok {
    use autodie;
    my $memStream = '';
    open(my $sw, '>', \$memStream);
    Console->SetOut($sw);
    WriteLineCore();
  };
  Console->SetOut($savedStandardOutput);
};

SKIP: { 
  skip 'Capture::Tiny not installed', 1 unless CAPTURE_TINY;
  subtest 'WriteOverloadsToRealConsole' => sub {
    plan tests => 3;
    my $data = capture_stdout( sub {
      lives_ok { WriteLineCore() }
    });
    is split(/\R/, $data), 23;
  };
}

subtest 'OutWriteAndWriteLineOverloads' => sub {
  plan tests => 3;
  my $savedStandardOutput = Console->Out;
  lives_ok {
    use autodie;
    my $memStream = '';
    open(my $sw, '>', \$memStream);
    Console->SetOut($sw);
    {
      my $writer = Console->Out;
      ok defined($writer), 'NotNull';
      is $writer, $sw, 'NotEqual'; # the writer we provide gets wrapped

      # We just want to ensure none of these throw exceptions, we don't actually 
      # validate what was written.

      $writer->printf("%d", 32);
      $writer->printf("%s", undef);
      $writer->printf("%d %s", 32, "Hello");
      $writer->printf("%s", undef, undef);
      $writer->printf("%d %s %d", 32, "Hello", 50);
      $writer->printf("%s", undef, undef, undef);
      $writer->printf("%d %s %d %d", ( 32, "Hello", 50, 5 ));
      $writer->printf("%s", ( undef, undef, undef, undef ));
      $writer->printf("%d %s %d %d %s", ( 32, "Hello", 50, 5, 'a' ));
      $writer->printf("%s", ( undef, undef, undef, undef, undef ));
      $writer->print(TRUE ? 'True' : 'False');
      $writer->print('a');
      $writer->printf( ( 'a', 'b', 'c', 'd', ) );
      $writer->printf( ( 'a', 'b', 'c', 'd', )[1, 2] );
      $writer->printf(1.23);
      $writer->printf(123.456);
      $writer->printf(1.234);
      $writer->printf(39);
      $writer->printf(unpack 'I', pack 'j' => 50);
      $writer->printf(unpack 'l', pack 'j' => 50);
      $writer->printf(unpack 'L', pack 'j' => 50);
      $writer->printf(ref bless \do { \0 }, 'System::Object');
      $writer->printf("Hello World");

      $writer->flush();
    }
  };
  Console->SetOut($savedStandardOutput);
};

SKIP: { skip 'Platform specific', 1 unless os_type eq 'iphoneos';
subtest 'TestConsoleWrite' => sub {
  plan tests => 2;
  my $savedStandardOutput = Console->Out;
  lives_ok {
    use autodie;
    my $s = '';
    open(my $w, '+>', \$s);
    $w->autoflush(TRUE);
    Console->SetOut($w);

    Console->Write("A");
    Console->Write("B");
    Console->Write("C");

    open(my $r, '<&', $w);
    seek($r, 0, 0);
    read($r, my $line, 3);
    is $line, "ABC", 'Equal';
  };
  Console->SetOut($savedStandardOutput);
}}

#---------------
note 'Encoding';
#---------------

# Create singelton Encode::Encoding objects
sub Encoding::Unicode {
  # Use alias from Win32::Console::DotNet
  state $instance = Encode::find_encoding('cp120'. ($Config{byteorder} & 0b1));
}
sub Encoding::UTF8 {
  # Use already existing alias from Perl
  state $instance = Encode::find_encoding('cp65001');
}

# Gets the code page identifier of the current Encoding.
my $CodePage = sub {
  my $self = shift;
  return if @_ || !ref($self) || !$self->isa('Encode::Encoding');

  my $regex = qr/^cp(\d+)$/;
  my @aliases = grep { 
    /$regex/ && $Encode::Alias::Alias{$_} eq $self;
  } keys(%Encode::Alias::Alias);
  my $element = first { /$regex/ } ( $self->name, @aliases );
  return $element && $element =~ $regex ? 0+ $1 : 0;
};

# When BE or LE is omitted during encode(), it returns a BE-encoded string with 
# BOM prepended: https://perldoc.perl.org/Encode::Unicode
my $GetPreamble = sub { # $octets ($self)
  return ref($_[0]) ? $_[0]->encode('') : undef;
};

# Method Encoding() for IO::File objects
my $Encoding = sub { # $cpi ($fh)
  $_[0] // return;
  my $regex = qr/^encoding\((.+?)\)$/;
  $_ = first { /$regex/ } PerlIO::get_layers($_[0]);
  $_ //= '';
  return /$regex/ ? Encode::find_encoding($1) : undef;
};

sub ValidateConsoleEncoding {
  my $encoding = shift;
  subtest 'ValidateConsoleEncoding' => sub {
    plan tests => 5;
    ok $encoding, 'NotNull';

    # There's not much validation we can do, but we can at least invoke members
    # to ensure they don't throw exceptions as they delegate to the underlying
    # encoding wrapped by ConsoleEncoding.

    like $encoding->name, qr/\S/, 'False';
    like $encoding->mime_name, qr/\S/, 'False';
    cmp_ok $encoding->$CodePage, '>=', 0, 'True';

    # And we can validate that the encoding is self-consistent by roundtripping
    # data between chars and octets.

    my $str = "This is the input string.";
    my $strAsBytes = $encoding->encode($str);
    my $strAsChars = $encoding->decode($strAsBytes);
    is $strAsChars, $str, 'Equal';
  };
  return;
}

subtest 'OutputEncodingPreamble' => sub {
  plan tests => 3;
  my $curEncoding = Console->OutputEncoding;

  lives_ok {
    my $encoding = Console->Out->$Encoding;
    # The primary purpose of ConsoleEncoding is to return an empty preamble.
    is $encoding->$GetPreamble(), '', 'Equal';

    # Try setting the ConsoleEncoding to something else and see if it works.
    Console->OutputEncoding(Encoding::Unicode);
    # The primary purpose of ConsoleEncoding is to return an empty preamble.
    is Console->Out->$Encoding->$GetPreamble(), '', 'Equal';
  };
  Console->OutputEncoding($curEncoding);
};

subtest 'OutputEncoding' => sub {
  plan tests => 7;
  my $curEncoding = Console->OutputEncoding;

  lives_ok {
    is Console->Out, Console->Out, 'Same';

    my $encoding = Console->Out->$Encoding;
    ok $encoding, 'NotNull';
    is Console->OutputEncoding->name, Console->Out->$Encoding->name, 'Equal';
    ValidateConsoleEncoding($encoding);

    # Try setting the ConsoleEncoding to something else and see if it works.
    Console->OutputEncoding(Encoding::Unicode);
    is Console->OutputEncoding->$CodePage, Encoding::Unicode->$CodePage, 
      'Equal';
    ValidateConsoleEncoding(Console->Out->$Encoding);
  };
  Console->OutputEncoding($curEncoding);
};

my @s_testLines = (
  "3232 Hello32 Hello 5032 Hello 50 532 Hello 50 5 aTrueaabcdbc1.23123.4561.". 
    "23439505050System.ObjectHello World",
  "32",
  "",
  "32 Hello",
  "",
  "32 Hello 50",
  "",
  "32 Hello 50 5",
  "",
  "32 Hello 50 5 a",
  "",
  "True",
  "a",
  "abcd",
  "bc",
  "1.23",
  "123.456",
  "1.234",
  "39",
  "50",
  "50",
  "50",
  "System.Object",
  "Hello World",
);

# Method ReadLine() for IO::File objects
my $ReadLine = sub { # $line ($fh)
  $_[0] // return;
  $! = undef;
  my $line = $_[0]->getline();
  return if $! || !defined($line);
  chomp $line; 
  return $line;
};

subtest 'ReadAndReadLine' => sub {
  my $savedStandardOutput = Console->Out;
  my $savedStandardInput = Console->In;

  lives_ok {
    use autodie;
    my $memStream = '';
    open(my $sw, '>', \$memStream);

    $sw->say(join "\n", @s_testLines);
    $sw->flush();

    $sw->seek(0, 0);

    open(my $sr, '<', \$memStream);
    Console->SetIn($sr);

    foreach my $ch (split //, $s_testLines[0]) {
      is Console->Read(), ord($ch), 'Equal';
    }

    # Read the newline at the end of the first line.
    is Console->ReadLine(), '', 'Equal';

    for (my $i = 1; $i < @s_testLines; $i++) {
      is $sr->$ReadLine(), $s_testLines[$i], 'Equal';
    }

    # We should be at EOF now.
    is Console->Read(), -1, 'Equal';
  };
  Console->SetOut($savedStandardOutput);
  Console->SetIn($savedStandardInput);
};

subtest 'OpenStandardInput' .
  '_NegativeBufferSize_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 1;
  throws_ok { Console->OpenStandardInput(-1) } qr/bufferSize/, 'Throws';
};

subtest 'OpenStandardOutput' .
  '_NegativeBufferSize_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 1;
  throws_ok { Console->OpenStandardOutput(-1) } qr/bufferSize/, 'Throws';
};

subtest 'OpenStandardError' .
  '_NegativeBufferSize_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 1;
  throws_ok { Console->OpenStandardError(-1) } qr/bufferSize/, 'Throws';
};

subtest 'FlushOnStreams_Nop' => sub {
  plan tests => 3;
  my $input = Console->OpenStandardInput();
  my $output = Console->OpenStandardOutput();
  my $error = Console->OpenStandardError();

  foreach my $s ($input, $output, $error) {
    lives_ok { $s->flush() } 'Assert';
  }
};

done_testing;
