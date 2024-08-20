use 5.014;
use warnings;

use Test::More;
use Test::Exception;

use List::Util qw( min );
use POSIX;
use Scalar::Util qw( openhandle );

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 40;
  }
}

BEGIN {
  use_ok 'Win32::Console';
  use_ok 'Win32::Console::DotNet';
}

# Fix STDOUT redirection from prove
POSIX::dup2(fileno(STDERR), fileno(STDOUT));

#-------------------
note 'Constructors';
#-------------------

use_ok 'System';
isa_ok(
  Console(),
  System::Console->FACTORY,
);

#----------------
note 'Properties';
#----------------

my ($fg, $bg);
lives_ok( 
  sub { $bg = System::Console->BackgroundColor },
  'Console->BackgroundColor'
);

cmp_ok(
  System::Console->BufferHeight, '>', '0',
  'Console->BufferHeight'
);

cmp_ok(
  System::Console->BufferWidth, '>', '0',
  'Console->BufferWidth'
);

lives_ok(
  sub { System::Console->CapsLock },
  'Console->CapsLock'
);

cmp_ok(
  System::Console->CursorLeft, '>=', '0',
  'Console->CursorLeft'
);

ok(
  (System::Console->CursorSize >= 0 && System::Console->CursorSize <= 100),
  'Console->CursorSize'
);

cmp_ok(
  System::Console->CursorTop, '>=', '0',
  'Console->CursorTop'
);

lives_ok(
  sub { System::Console->CursorVisible(1) },
  'Console->CursorVisible'
);

ok(
  defined(System::Console->Error),
  'Console->Error'
);

lives_ok(
  sub { $fg = System::Console->ForegroundColor },
  'Console->ForegroundColor'
);

ok(
  defined(System::Console->In),
  'Console->In'
);

cmp_ok(
  System::Console->InputEncoding, '>', '0',
  'Console->InputEncoding'
);

lives_ok(
  sub { System::Console->IsErrorRedirected },
  'Console->IsErrorRedirected'
);

lives_ok(
  sub { System::Console->IsInputRedirected },
  'Console->IsInputRedirected'
);

lives_ok(
  sub { System::Console->IsOutputRedirected },
  'Console->IsOutputRedirected'
);

lives_ok(
  sub { System::Console->KeyAvailable },
  'Console->KeyAvailable'
);

cmp_ok(
  System::Console->LargestWindowHeight, '>', '0',
  'Console->LargestWindowHeight'
);

cmp_ok(
  System::Console->LargestWindowWidth, '>', '0',
  'Console->LargestWindowWidth'
);

lives_ok(
  sub { System::Console->NumberLock },
  'Console->NumberLock'
);

ok(
  defined(System::Console->Out),
  'Console->Out'
);

cmp_ok(
  System::Console->OutputEncoding, '>', '0',
  'Console->OutputEncoding'
);

lives_ok(
  sub { System::Console->Title('Test::More') },
  'Console->Title'
);

lives_ok(
  sub { System::Console->TreatControlCAsInput(0) },
  'Console->TreatControlCAsInput'
);

subtest 'WindowHeight' => sub {
  plan tests => 3;
  my $height = 25;
  lives_ok { 
    $height = min(
      System::Console->BufferHeight,
      System::Console->LargestWindowHeight
    );
  } 'Console->LargestWindowHeight';
  lives_ok { System::Console->WindowHeight($height) } 'Console->WindowHeight';
  is System::Console->WindowHeight(), $height, '$height';
};

cmp_ok(
  System::Console->WindowLeft, '>=', 0,
  'Console->WindowLeft'
);

subtest 'WindowWidth' => sub {
  plan tests => 3;
  my $width = 80;
  lives_ok { 
    $width = min(
      System::Console->BufferWidth,
      System::Console->LargestWindowWidth
    );
  } 'Console->LargestWindowWidth';
  lives_ok { System::Console->WindowWidth($width) } 'Console->WindowWidth';
  is System::Console->WindowWidth(), $width, '$width';
};

cmp_ok(
  System::Console->WindowTop, '>=', 0,
  'Console->WindowTop'
);

#----------------------
note 'System::Console';
#----------------------

lives_ok(
  sub { System::Console->Clear() },
  'Console->Clear'
);

subtest 'ResetColor' => sub {
  plan tests => 5;
  lives_ok { System::Console->ForegroundColor($FG_YELLOW) } 
    'Console->ForegroundColor(14)';
  lives_ok { System::Console->BackgroundColor($BG_BLUE >> 4) } 
    'Console->BackgroundColor(1)';
  lives_ok { System::Console->ResetColor() } 'Console->ResetColor';
  is System::Console->ForegroundColor, $fg, 'Console->ForegroundColor';
  is System::Console->BackgroundColor, $bg, 'Console->BackgroundColor';
};

subtest 'SetBufferSize' => sub {
  plan tests => 3;
  my $height = System::Console->BufferHeight;
  my $width = System::Console->BufferWidth;
  lives_ok { System::Console->SetBufferSize($width, $height) } 
    'Console->SetBufferSize';
  is System::Console->BufferHeight, $height, 'Console->BufferHeight';
  is System::Console->BufferWidth, $width, 'Console->BufferWidth';
};

subtest 'SetCursorPosition' => sub {
  plan tests => 3;
  my $x = System::Console->CursorLeft;
  my $y = System::Console->CursorTop;
  lives_ok { System::Console->SetCursorPosition($x, $y) } 
    'Console->SetCursorPosition';
  cmp_ok System::Console->CursorLeft, '>=', 0, 'Console->CursorLeft';
  cmp_ok System::Console->CursorTop, '>=', $y, 'Console->CursorTop';
};

subtest 'GetCursorPosition' => sub {
  plan tests => 3;
  my ($x, $y);
  lives_ok { ($x, $y) = @{ System::Console->GetCursorPosition() } } 
    'Console->GetCursorPosition';
  ok defined($x), 'Console->CursorLeft';
  ok defined($y), 'Console->CursorTop';
};

subtest 'OpenStandardHandle' => sub {
  plan tests => 3;
  ok(
    openhandle(System::Console->OpenStandardError()),
    'OpenStandardError',
  );
  ok(
    openhandle(System::Console->OpenStandardInput()),
    'OpenStandardInput',
  );
  ok(
    openhandle(System::Console->OpenStandardOutput()),
    'OpenStandardOutput',
  );
};

subtest 'SetStandardHandle' => sub {
  plan tests => 3;
  lives_ok(
    sub { System::Console->SetError(\*STDERR) },
    'Console->SetError'
  );
  lives_ok(
    sub { System::Console->SetIn(\*STDIN) },
    'Console->SetIn'
  );
  lives_ok(
    sub { System::Console->SetOut(\*STDERR) },
    'Console->SetOut'
  );
};

lives_ok(
  sub { System::Console->Beep() },
  'Console->Beep'
);

SKIP: {
  skip 'Manual test not enabled', 1 unless $ENV{"MANUAL_TESTS"};
  lives_ok(
    sub {
      System::Console->WriteLine("Please type somesting and press 'Enter'.");
      my $key = System::Console->Read()
    },
    'Console->Read'
  );
};

done_testing;
