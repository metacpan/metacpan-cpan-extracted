#!/usr/bin/perl -I../lib/ -Ilib
#-------------------------------------------------------------------------------
# Assemble and execute code written in the Zero assembler programming language.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Pointless adds and subtracts by 0. Perhaps we should flag adds and subtracts by 1 as well so we can have an instruction optimized for these variants.
# Assign needs to know from whence we got the value so we can write a better error message when it is no good
# Count number of ways an if statement actually goes.
# doubleWrite, not read, rewrite need make-over
use v5.30;
package Zero::Emulator;
our $VERSION = 20230519;                                                        # Version
use warnings FATAL=>qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
eval "use Test::More tests=>387" unless caller;

makeDieConfess;
our $memoryTechnique;                                                           # Undef or the address of a sub that loads the memory handlers into an execution environment.

my sub maximumInstructionsToExecute {1e6}                                       # Maximum number of subroutines to execute

sub ExecutionEnvironment(%)                                                     # Execution environment for a block of code.
 {my (%options) = @_;                                                           # Execution options

  my $exec=                 genHash("Zero::Emulator",                           # Execution results
    calls=>                 [],                                                 # Call stack
    block=>                 $options{code},                                     # Block of code to be executed
    count=>                 0,                                                  # Executed instructions count
    counts=>                {},                                                 # Executed instructions by name counts
    tally=>                 0,                                                  # Tally executed instructions in a bin of this name
    tallyCount=>            0,                                                  # Executed instructions tally count
    tallyCounts=>           {},                                                 # Executed instructions by name tally counts
    tallyTotal=>            {},                                                 # Total instructions executed in each tally
    instructionPointer=>    0,                                                  # Current instruction
    memory=>                [],                                                 # Memory contents at the end of execution
    memoryString=>          '',                                                 # Memory packed into one string
    memoryType=>            [],                                                 # Memory contents at the end of execution
    rw=>                    [],                                                 # Read / write access to memory
    read=>                  [],                                                 # Records whether a memory address was ever read allowing us to find all the unused locations
    notReadAddresses=>      [],                                                 # Memory addresses never read
    notExecuted=>           [],                                                 # Instructions not executed
    out=>                   '',                                                 # The out channel. L<Out> writes an array of items to this followed by a new line.  L<out> does the same but without the new line.
    doubleWrite=>           {},                                                 # Source of double writes {instruction number} to count - an existing value was overwritten before it was used
    pointlessAssign=>       {},                                                 # Location already has the specified value
    suppressOutput=>        $options{suppressOutput},                           # If true the Out instruction will only write to the execution out array but not to stdout as well.
    stopOnError=>           $options{stopOnError},                              # Stop on non fatal errors if true
    trace=>                 $options{trace},                                    # Trace all statements
    traceLabels=>           undef,                                              # Trace changes in execution flow
    printNotRead=>          $options{NotRead},                                  # Memory locations never read
    printDoubleWrite=>      $options{doubleWrite},                              # Double writes: earlier instruction number to later instruction number
    printPointlessAssign=>  $options{pointlessAssign},                          # Pointless assigns {instruction number} to count - address already has the specified value
    watch=>                 [],                                                 # Addresses to watch for changes
    widestAreaInArena=>     [],                                                 # Track highest array access in each arena
    instructionCounts=>     {},                                                 # The number of times each actual instruction is executed
    lastAssignArena=>       undef,                                              # Last assignment performed - arena
    lastAssignArea=>        undef,                                              # Last assignment performed - area
    lastAssignAddress=>     undef,                                              # Last assignment performed - address
    lastAssignType=>        undef,                                              # Last assignment performed - name of area assigned into
    lastAssignValue=>       undef,                                              # Last assignment performed - value
    lastAssignBefore=>      undef,                                              # Prior value of memory area before assignment
    freedArrays=>           [],                                                 # Arrays that have been recently freed and can thus be reused
    checkArrayNames=>      ($options{checkArrayNames} // 1),                    # Check array names to confirm we are accessing the expected data
    GetMemoryHeaps=>       \&getMemoryHeaps,                                    # Low level memory access - arenas in use
    GetMemoryArea=>        \&getMemoryArea,                                     # Low level memory access - area
    GetMemoryLocation=>    \&getMemoryLocation,                                 # Low level memory access - location
    AllocMemoryArea=>      \&allocMemoryArea,                                   # Low level memory access - allocate new area
    FreeMemoryArea=>       \&freeMemoryArea,                                    # Low level memory access - free an area
    ResizeMemoryArea=>     \&resizeMemoryArea,                                  # Low level memory access - resize an area
    PushMemoryArea=>       \&pushMemoryArea,                                    # Low level memory access - push onto area
    PopMemoryArea=>        \&popMemoryArea,                                     # Low level memory access - pop from area
    memoryStringElementWidth=>   0,                                             # Width in bytes of a memory area element
    memoryStringUserElements=>   0,                                             # Maximum number of elements in the user area of a heap arena if such is required by the memory allocation technique in play
    memoryStringSystemElements=> 0,                                             # Maximum number of elements in the system area of a heap arena if such is required by the memory allocation technique in play
    memoryStringTotalElements=>  0,                                             # Maximum number of elements in total in an area in a heap arena if such is required by the memory allocation technique in play
   );

  $memoryTechnique->($exec) if $memoryTechnique;                                # Load memory handlers if a different memory handling system has been requested
  if (defined(my $n = $options{maximumAreaSize}))                               # Override the maximum number of elements in an array from the default setting if requested
   {$exec->memoryStringUserElements  = $n;
    $exec->memoryStringTotalElements = $n + $exec->memoryStringSystemElements;
   }

  $exec
 }

my sub Code(%)                                                                  # A block of code
 {my (%options) = @_;                                                           # Parameters

  genHash("Zero::Emulator::Code",                                               # Description of a call stack entry
    code=>          [],                                                         # An array of instructions
    variables=>     AreaStructure("Variables"),                                 # Variables in this block of code
    labels=>        {},                                                         # Label name to instruction
    labelCounter=>  0,                                                          # Label counter used to generate unique labels
    files=>         [],                                                         # File number to file name
    procedures=>    {},                                                         # Procedures defined in this block of code
    arrayNames=>    {stackArea=>0, params=>1, return=>2},                       # Array names as strings to numbers
    arrayNumbers=>  [qw(stackArea params return)],                              # Array number to name
    %options,
   );
 }

my sub stackFrame(%)                                                            # Describe an entry on the call stack: the return address, the parameter list length, the parameter list address, the line of code from which the call was made, the file number of the file from which the call was made
 {my (%options) = @_;                                                           # Parameters

  genHash("Zero::Emulator::StackFrame",                                         # Description of a stack frame. A stack frame provides the context in which a method runs.
    target=>       $options{target},                                            # The address of the subroutine being called
    instruction=>  $options{call},                                              # The address of the instruction making the call
    stackArea=>    $options{stackArea},                                         # Memory area containing data for this method
    params=>       $options{params},                                            # Memory area containing parameter list
    return=>       $options{return},                                            # Memory area containing returned result
    line=>         $options{line},                                              # The line number from which the call was made
    file=>         $options{file},                                              # The file number from which the call was made - this could be folded into the line number but for reasons best known to themselves people who cannot program very well often scatter projects across several files a practice that is completely pointless in this day of git and so can only lead to chaos and confusion
    variables=>    $options{variables},                                         # Variables local to this stack frame
  );
 }

sub Zero::Emulator::Code::instruction($%)                                       #P Create a new instruction.
 {my ($block, %options) = @_;                                                   # Block of code descriptor, options

  my ($package, $fileName, $line) = caller($options{level} // 1);

  my sub stackTrace()                                                           # File numbers and line numbers of callers
   {my @s;
    for my $c(1..99)
     {my @c = caller($c);
      last unless @c;
      push @s, [$c[1], $c[2]];
     }
    \@s
   };

  if ($options{action} !~ m(\Avariable\Z)i)                                     # Non variable
   {push $block->code->@*, my $i = genHash("Zero::Emulator::Code::Instruction", # Instruction details
      action=>         $options{action   },                                     # Instruction name
      number=>         $options{number   },                                     # Instruction sequence number
      source=>         $options{source   },                                     # Source memory address
      source2=>        $options{source2  },                                     # Secondary source memory address
      target=>         $options{target   },                                     # Target memory address
      jump=>           $options{jump     },                                     # Jump target
#     procedure=>      $options{procedure},                                     # Procedure target
      line=>           $line,                                                   # Line in source file at which this instruction was encoded
      file=>           fne $fileName,                                           # Source file in which instruction was encoded
      context=>        stackTrace(),                                            # The call context in which this instruction was created
      executed=>       0,                                                       # The number of times this instruction was executed
      step=>           0,                                                       # The last time (in steps from the start) that this instruction was executed
    );
    return $i;
   }
 }

sub Zero::Emulator::Code::codeToString($)                                       #P Code as a string.
 {my ($block) = @_;                                                             # Block of code
  @_ == 1 or confess "One parameter";
  my @T;
  my @code = $block->code->@*;
  for my $i(@code)
   {my $n = $i->number;
    my $a = $i->action;
    my $t = $block->referenceToString($i->{target});
    my $s = $block->referenceToString($i->{source});
    my $S = $block->referenceToString($i->{source2});
    my $T = sprintf "%04d  %8s %12s  %12s  %12s", $n, $a, $t, $s, $S;
    push @T, $T =~ s(\s+\Z) ()sr;
   }
  join "\n", @T, '';
 }

sub contextString($$$)                                                          #P Stack trace back for this instruction.
 {my ($exec, $i, $title) = @_;                                                  # Execution environment, Instruction, title
  @_ == 3 or confess "Three parameters";
  my @s = $title;
  if (! $exec->suppressOutput)
   {for my $c($i->context->@*)
     {push @s, sprintf "    at %s line %d", $$c[0], $$c[1];
     }
   }
  join "\n", @s
 }

sub Zero::Emulator::Code::Instruction::contextString($)                         #P Stack trace back for this instruction.
 {my ($i) = @_;                                                                 # Instruction
  @_ == 1 or confess "One parameter";
  my @s;
  for my $c($i->context->@*)
   {push @s, sprintf "    at %s line %d", $$c[0], $$c[1];
   }
  @s;
 }

sub AreaStructure($@)                                                           # Describe a data structure mapping a memory area.
 {my ($structureName, @names) = @_;                                             # Structure name, fields names

  my $d = genHash("Zero::Emulator::AreaStructure",                              # Description of a data structure mapping a memory area
    structureName=>  $structureName,                                            # Name of the structure
    fieldOrder=>     [],                                                        # Order of the elements in the structure, in effect, giving the offset of each element in the data structure
    fieldNames=>     {},                                                        # Maps the names of the fields to their offsets in the structure
   );
  $d->field($_) for @names;                                                     # Add the field descriptions
  $d
 }

sub Zero::Emulator::AreaStructure::count($)                                     #P Number of fields in a data structure.
 {my ($d) = @_;                                                                 # Area structure
  scalar $d->fieldOrder->@*
 }

sub Zero::Emulator::AreaStructure::name($$)                                     #P Add a field to a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (!defined $d->fieldNames->{$name})
   {$d->fieldNames->{$name} = $d->fieldOrder->@*;
    push $d->fieldOrder->@*, $name;
   }
  else
   {confess "Duplicate name: $name in structure: ".$d->name;
   }
  \($d->fieldNames->{$name})
 }

my sub procedure($%)                                                            # Describe a procedure
 {my ($label, %options) = @_;                                                   # Start label of procedure, options describing procedure

  genHash("Zero::Emulator::Procedure",                                          # Description of a procedure
    target=>        $label,                                                     # Label to call to call this procedure
    variables=>     AreaStructure("Procedure"),                                 # Registers local to this procedure
  );
 }

sub Zero::Emulator::AreaStructure::registers($)                                 #P Create one or more temporary variables. Need to reuse registers no longer in use.
 {my ($d, $count) = @_;                                                         # Parameters
  @_ == 1 or confess "One parameter";
  if (!defined($count))
   {my $o = $d->fieldOrder->@*;
    push $d->fieldOrder->@*, undef;
    return \$o;                                                                 # One temporary
   }
  map {__SUB__->($d)} 1..$count;                                                # Array of temporaries
 }

sub Zero::Emulator::AreaStructure::offset($$)                                   #P Offset of a field in a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (defined(my $n = $d->fieldNames->{$name})){return $n}
  confess "No such name: '$name' in structure: ".$d->structureName;
 }

sub Zero::Emulator::AreaStructure::address($$)                                  #P Address of a field in a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (defined(my $n = $d->fieldNames->{$name})){return \$n}
  confess "No such name: '$name' in structure: ".$d->structureName;
 }

sub Zero::Emulator::Procedure::registers($)                                     #P Allocate a register within a procedure.
 {my ($procedure) = @_;                                                         # Procedure description
  @_ == 1 or confess "One parameter";
  $procedure->variables->registers();
 }

my sub isScalar($)                                                              # Check whether an element is a scalar or an array
 {my ($value) = @_;                                                             # Parameters
  ! ref $value;
 }

# Memory is subdivided into arenas that hold items of similar types, sizes, access orders
my sub arenaLocal {0}                                                           # Variables whose location is fixed at compile time
my sub arenaHeap  {1}                                                           # Allocations whose location is dynamically allocated as the program runs
my sub arenaParms {2}                                                           # Parameter areas
my sub arenaReturn{3}                                                           # Return areas

sub Zero::Emulator::Code::referenceToString($$)                                 #P Reference as a string.
 {my ($block, $r) = @_;                                                         # Block of code, reference
  @_ == 2 or confess "Two parameters";

  return "" unless defined $r;
  ref($r) =~ m(Reference) or confess "Must be a reference, not: ".dump($r);

  if ($r->arena == arenaLocal)
   {return "" unless my $a = $r->address;
    return dump $a
   }
  else
   {return dump [$r->area, $r->address, $r->name, $r->delta];
   }
 }

sub Zero::Emulator::Code::ArrayNameToNumber($$)                                 #P Generate a unique number for this array name.
 {my ($code, $name) = @_;                                                       # Code block, array name

  if (defined(my $n = $code->arrayNames->{$name}))                              # Name already exists
   {return $n;
   }

  my $n = $code->arrayNames->{$name} = $code->arrayNumbers->@*;                 # Assign a number to this name
  push $code->arrayNumbers->@*, $name;                                          # Save new name
  $n
 }


sub Zero::Emulator::Code::ArrayNumberToName($$)                                 #P Return the array name associated with an array number.
 {my ($code, $number) = @_;                                                     # Code block, array name

  $code->arrayNumbers->[$number] // $number
 }

sub Zero::Emulator::Code::Reference($$)                                         # Record a reference to a left or right address.
 {my ($code, $r) = @_;                                                          # Code block, reference
  ref($r) and ref($r) !~ m(\A(array|scalar|ref)\Z)i and confess "Scalar or reference required, not: ".dump($r);
  my $arena = ref($r) =~ m(\Aarray\Z)i ? arenaHeap : arenaLocal;                # Local variables are variables that are not on the heap

  if (ref($r) =~ m(array)i)                                                     # Reference represented as [area, address, name, delta]
   {my ($area, $address, $name, $delta) = @$r;                                  # Delta is oddly useful, as illustrated by examples/*Sort, in that it enables us to avoid adding or subtracting one with a separate instruction that does not achieve very much in one clock but that which, is otherwise necessary.
    defined($area) and !defined($name) and confess "Name required for address specification: in [Area, address, name]";

    return genHash("Zero::Emulator::Reference",
      arena=>     $arena,                                                       # The memory arena being used.
      area=>      $area,
      address=>   $address,
      name=>      $code->ArrayNameToNumber($name),
      delta=>     $delta//0,
     );
   }
  else                                                                          # Reference represented as an address
   {return genHash("Zero::Emulator::Reference",
      arena=>     $arena,
      area=>      undef,
      address=>   $r,
      name=>      $code->ArrayNameToNumber('stackArea'),
      delta=>     0,
     );
   }
 }

sub Zero::Emulator::Procedure::call($)                                          #P Call a procedure.  Arguments are supplied by the L<ParamsPut> and L<ParamsGet> commands, return values are supplied by the L<ReturnPut> and L<ReturnGet> commands.
 {my ($procedure) = @_;                                                         # Procedure description
  @_ == 1 or confess "One parameter";
  Zero::Emulator::Call($procedure->target);
 }

sub Zero::Emulator::Code::assemble($%)                                          #P Assemble a block of code to prepare it for execution.  This modifies the jump targets and so once assembled we cannot assembled again.
 {my ($Block, %options) = @_;                                                   # Code block, assembly options

  my $code = $Block->code;                                                      # The code to be assembled
  my $vars = $Block->variables;                                                 # The variables referenced by the code

  my %labels;                                                                   # Load labels
  my $stackFrame = AreaStructure("Stack");                                      # The current stack frame we are creating variables in

  for my $c(keys @$code)                                                        # Labels
   {my $i = $$code[$c];
    $i->number = $c;
    next unless $i->action eq "label";
    $labels{$i->source->address} = $c;                                          # Point label to instruction
   }

  for my $c(keys @$code)                                                        # Target jump and call instructions
   {my $i = $$code[$c];
    next unless $i->action =~ m(\A(j|call))i;
    if (my $l = $i->target->address)                                            # Label
     {if (my $t = $labels{$l})                                                  # Found label
       {$i->jump = $Block->Reference($t - $c);                                  # Relative jump
       }
      else
       {my $a = $i->action;
        confess "No target for $a to label: $l";
       }
     }
   }

  $Block->labels = {%labels};                                                   # Labels created during assembly
  $Block
 }

sub heap($$)                                                                    #P Return a heap entry.
 {my ($exec, $area) = @_;                                                       # Execution environment, area
  $exec->GetMemoryArea->($exec, arenaHeap, $area);
 }

sub areaContent($$)                                                             #P Content of an area containing a specified address in memory in the specified execution.
 {my ($exec, $ref) = @_;                                                        # Execution environment, reference to array
  @_ == 2 or confess "Two parameters";
  my $array = $exec->right($ref);
  my $a = $exec->heap($array);
  $exec->stackTraceAndExit("Invalid area: ".dump($array)) unless defined $a;
  @$a
 }

sub areaLength($$)                                                              #P Content of an area containing a specified address in memory in the specified execution.
 {my ($exec, $array) = @_;                                                      # Execution environment, reference to array
  @_ == 2 or confess "Two parameters";
  my $a = $exec->heap($array);
  $exec->stackTraceAndExit("Invalid area: ".dump($array)) unless defined $a;
  scalar @$a
 }

sub currentStackFrame($)                                                        #P Address of current stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current stack frame";
  $$calls[-1]->stackArea;
 }

sub currentParamsGet($)                                                         #P Address of current parameters to get from.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 1 or confess "No current parameters to get";
  $$calls[-2]->params;
 }

sub currentParamsPut($)                                                         #P Address of current parameters to put to.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current parameters to put";
  $$calls[-1]->params;
 }

sub currentReturnGet($)                                                         #P Address of current return to get from.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current return to get";
  $$calls[-1]->return;
 }

sub currentReturnPut($)                                                         #P Address of current return to put to.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 1 or confess "No current return to put";
  $$calls[-2]->return;
 }

sub dumpMemory($)                                                               #P Dump heap memory.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my @m;
  my $m = $exec->GetMemoryHeaps->($exec);                                       # Memory areas
  for my $area(1..$m)                                                           # Each memory area except memory area 0 - which might once have been reserved for some purpose
   {my $h = $exec->heap($area);
    next unless defined $h and @$h;
    my $l = dump $exec->heap($area);
       $l = substr($l, 0, 100) if length($l) > 100;
       $l =~ s(\n) ( )gs;
    push @m, "$area=$l";
   }

  join "\n", @m, '';
 }

# These methods provide the original unlimited memory mechanism using multidimensional arrays

sub getMemoryHeaps($)                                                           #P Heaps.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  scalar($exec->memory->[arenaHeap]->@*)
 }

sub getMemoryArea($$$)                                                          #P Lowest level memory access to an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  $exec->memory->[$arena][$area]
 }

sub getMemoryLocation($$$$)                                                     #P Lowest level memory access to an array: get the address of the indicated location in memory.   This method is replaceable to model different memory structures.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address, expected name of area
  @_ == 4 or confess "Four parameters";
  \$exec->memory->[$arena][$area][$address];
 }

sub allocMemoryArea($$$$)                                                       #P Allocate a memory area.
 {my ($exec, $number, $arena, $area) = @_;                                      # Execution environment, name of allocation to bless result, arena to use, area to use
  @_ == 4 or confess "Four parameters";
  $exec->memory->[$arena][$area] = $number ? bless [], $number : [];            # Blessing with 0 is a very bad idea!
 }

sub freeMemoryArea($$$)                                                         #P Free a memory area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena to use, area to use
  @_ == 3 or confess "Three parameters";
  $exec->memory->[$arena][$area] = [];
 }

sub resizeMemoryArea($$$)                                                       #P Resize an area in the heap.
 {my ($exec, $area, $size) = @_;                                                # Execution environment, area to use, new size
  @_ == 3 or confess "Three parameters";
  my $a = $exec->memory->[arenaHeap][$area];
  $#$a = $size-1;
 }

sub pushMemoryArea($$$)                                                         #P Push a value onto the specified array.
 {my ($exec, $area, $value) = @_;                                               # Execution environment, arena, array, value to assign
  @_ == 3 or confess "Three parameters";
  push $exec->memory->[arenaHeap][$area]->@*, $value;                           # Push
 }

sub popMemoryArea($$$)                                                          #P Pop a value from the specified memory area if possible else confess.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, array,
  my $a = $exec->memory->[$arena][$area];
  if (!defined($a) or !$a->@*)                                                  # Area does not exists or has zero elements
   {$exec->stackTraceAndExit("Cannot pop area: $area, in arena: $arena");
   }
  pop @$a;                                                                      # Pop
 }

sub setOriginalMemoryTechnique($)                                               #P Set the handlers for the original memory allocation technique.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->GetMemoryHeaps    = \&getMemoryHeaps;                                  # Low level memory access - arena
  $exec->GetMemoryArea     = \&getMemoryArea;                                   # Low level memory access - area
  $exec->GetMemoryLocation = \&getMemoryLocation;                               # Low level memory access - location
  $exec->AllocMemoryArea   = \&allocMemoryArea;                                 # Low level memory access - allocate new area
  $exec->FreeMemoryArea    = \&freeMemoryArea;                                  # Low level memory access - free area
  $exec->ResizeMemoryArea  = \&resizeMemoryArea;                                # Low level memory access - resize a memory area
  $exec->PushMemoryArea    = \&pushMemoryArea;                                  # Low level memory access - push onto area
  $exec->PopMemoryArea     = \&popMemoryArea;                                   # Low level memory access - pop from area
 }

# These methods place the heap arena in a vector string. Each area is up to a prespecified width wide. The current length of each such array is held in the first element.

sub stringMemoryAreaLength($$$)                                                 #P Get the current length of a string memory area n area in.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, array,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena
  my $l = vec($exec->memoryString, $o, $w * 8);                                 # Zero current length of area so we can push and pop
    $l > 0 or confess "Area underflow, arena: $arena, area: $area";             # Check we are within the area
  --$l;                                                                         # Pop
  my $O = $o + $s + $l;                                                         # Offset of element in area
  my $v = vec($exec->memoryString, $O, $w * 8);                                 # Pop element
          vec($exec->memoryString, $o, $w * 8) = $l;                            # Decrease size of area
  $v
 }

sub stringGetMemoryHeaps($)                                                     #P Get number of heaps.
 {my ($exec) = @_;                                                              # Execution environment, arena
  @_ == 1 or confess "One parameter";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $a = $w * $t;                                                              # Offset of heap area in arena
  my $l = length $exec->memoryString;
  my $n = int($l / $a);                                                         # Heap objects must be smaller than a maximum size so that we can calculate their offset in the memory string
  if ($n * $a < $l)                                                             # Last heap might not be full
   {++$n;
   }
  $n
 }

sub stringGetMemoryArea($$$$)                                                   #P Lowest level memory access to an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  return getMemoryArea($exec, $arena, $area) if $arena != arenaHeap;            # Non heap objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena

  my $l = vec($exec->memoryString, $o, $w * 8);                                 # Length of area so we can push and pop
  my @o;
  for my $i(0..$l-1)                                                            # Check we are within the area
   {push @o, ${$exec->stringGetMemoryLocation($arena, $area, $i)};
   }
  [@o]
 }

sub stringGetMemoryLocation($$$$)                                               #P Lowest level memory access to an array: get the address of the indicated location in memory.   This method is replaceable to model different memory structures.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address, expected name of area
  @_ == 4 or confess "Four parameters";
  if ($arena != arenaHeap)                                                      # Non heap  objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,
   {return getMemoryLocation($exec, $arena, $area, $address);
   }

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset into memory of area
  $address < $u or confess "Address $address >= $u";                            # Check we are within the area
  my $O = $o + $s + $address;                                                   # Offset into memory of element

  if ($address+1 > vec($exec->memoryString, $o, $w * 8))                        # Extend length of array if necessary
   {vec($exec->memoryString, $o, $w * 8) = $address+1;
   }
  \vec($exec->memoryString, $O, $w * 8)                                         # Memory containing one element
 }

sub stringAllocMemoryArea($$$$)                                                 #P Allocate a memory area.
 {my ($exec, $number, $arena, $area) = @_;                                      # Execution environment, name of allocation to bless result, arena to use, area to use
  @_ == 4 or confess "Four parameters";
  return allocMemoryArea($exec, $number, $arena, $area) if $arena != arenaHeap; # Non heap  objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena
  vec($exec->memoryString, $o, $w * 8) = 0;                                     # Zero current length of area so we can push and pop
 }

sub stringFreeMemoryArea($$$)                                                   #P Free a memory area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena to use, area to use
  @_ == 3 or confess "Three parameters";
  return freeMemoryArea($exec, $arena, $area) if $arena != arenaHeap;           # Non heap  objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena

  vec($exec->memoryString, $o, $w * 8) = 0;                                     # Zero current length of area so we can push and pop
 }

sub stringResizeMemoryArea($$$)                                                 #P Resize a heap memory area.
 {my ($exec, $area, $size) = @_;                                                # Execution environment, area to resize, new size
  @_ == 3 or confess "Three parameters";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena

  vec($exec->memoryString, $o, $w * 8) = $size;                                 # Set new size
 }

sub stringPushMemoryArea($$$)                                                   #P Push a value onto the specified array.
 {my ($exec, $area, $value) = @_;                                               # Execution environment, arena, array, value to assign
  @_ == 3 or confess "Three parameters";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena
  my $l = vec($exec->memoryString, $o, $w * 8);                                 # Zero current length of area so we can push and pop
  $l < $u-1 or                                                                  # Check we are within the area
    confess "Area overflow, area: $area, "
    ."position: $l, value: $value";
  my $O = $o + ($s + $l);                                                       # Offset of element in area
  vec($exec->memoryString, $O, $w * 8) = $value;                                # Push element
  vec($exec->memoryString, $o, $w * 8) = $l + 1;                                # Increase size of area
 }

sub stringPopMemoryArea($$$)                                                    #P Pop a value from the specified memory area if possible else confess.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, array,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $u = $exec->memoryStringUserElements;                                      # User width of a heap area
  my $s = $exec->memoryStringSystemElements;                                    # System width of a heap area
  my $t = $exec->memoryStringTotalElements;                                     # Total width of a heap area
  my $o = $area * $t;                                                           # Offset of heap area in arena
  my $l = vec($exec->memoryString, $o, $w * 8);                                 # Zero current length of area so we can push and pop
    $l > 0 or confess "Area underflow, arena: $arena, area: $area";             # Check we are within the area
  --$l;                                                                         # Pop
  my $O = $o + $s + $l;                                                         # Offset of element in area
  my $v = vec($exec->memoryString, $O, $w * 8);                                 # Pop element
          vec($exec->memoryString, $o, $w * 8) = $l;                            # Decrease size of area
  $v
 }

sub setStringMemoryTechnique($)                                                 #P Set the handlers for the string memory allocation technique.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->GetMemoryHeaps    = \&stringGetMemoryHeaps;                            # Low level memory access - arena
  $exec->GetMemoryArea     = \&stringGetMemoryArea;                             # Low level memory access - area
  $exec->GetMemoryLocation = \&stringGetMemoryLocation;                         # Low level memory access - location
  $exec->AllocMemoryArea   = \&stringAllocMemoryArea;                           # Low level memory access - allocate new area
  $exec->FreeMemoryArea    = \&stringFreeMemoryArea;                            # Low level memory access - free area
  $exec->ResizeMemoryArea  = \&stringResizeMemoryArea;                          # Low level memory access - resize a memory area
  $exec->PushMemoryArea    = \&stringPushMemoryArea;                            # Low level memory access - push onto area
  $exec->PopMemoryArea     = \&stringPopMemoryArea;                             # Low level memory access - pop from area
  $exec->memoryStringElementWidth   = my $e = 4;                                # Each element is 32 bits wide
  $exec->memoryStringUserElements   = my $u = 5;                                # User part of a heap area
  $exec->memoryStringSystemElements = my $s = 1;                                # System part of a heap area
  $exec->memoryStringTotalElements  =    $u + $s;                               # Total width of a heap area
 }

# End of memory implementation

sub getMemory($$$$$)                                                            #P Get from memory.
 {my ($exec, $arena, $area, $address, $name) = @_;                              # Execution environment, arena, area, address, expected name of area
  @_ == 5 or confess "Five parameters";
  $exec->checkArrayName($arena, $area, $name);
  my $v = $exec->GetMemoryLocation->($exec, $arena, $area, $address);
  if (!defined($$v))                                                            # Check we are getting a defined value.  If undefined values are acceptable use L<getMemoryAddress> and dereference the result.
   {my $n = $name // 'unknown';
    $exec->stackTraceAndExit
     ("Undefined memory accessed in arena: $arena, at area: $area ($n), address: $address\n");
   }
  $$v
 }

sub getMemoryAddress($$$$$)                                                     #P Evaluate an address in the current execution environment.
 {my ($exec, $arena, $area, $address, $name) = @_;                              # Execution environment, arena, area, address, expected name of area
  @_ == 5 or confess "Five parameters";
  $exec->widestAreaInArena->[$arena] =                                          # Track the widest area in each arena
    max(($exec->widestAreaInArena->[$arena]//0), $address);
  $exec->checkArrayName($arena, $area, $name);                                  # Check area name
  $exec->GetMemoryLocation->($exec, $arena, $area, $address);                   # Read from memory
 }

sub getMemoryFromAddress($$)                                                    #P Get a value from memory at a specified address.
 {my ($exec, $left) = @_;                                                       # Execution environment, left address
  @_ == 2 or confess "Two parameters";
  ref($left) =~ m(Address) or confess "Address needed for second parameter, not: ".ref($left);
  $exec->getMemory($left->arena, $left->area, $left->address, $left->name);
 }

sub getMemoryAddressFromAddress($)                                              #P Get address of memory location from an address in the current execution environment.
 {my ($exec, $left) = @_;                                                       # Execution environment, address
  @_ == 2 or confess "Two parameters";
  ref($left) =~ m(Address) or confess "Address needed for second parameter, not: ".ref($left);
  $exec->getMemoryAddress($left->arena, $left->area, $left->address, $left->name);
 }

sub setMemory($$$)                                                              #P Set the value of an address at the specified address in memory in the current execution environment.
 {my ($exec, $ref, $value) = @_;                                                # Execution environment, address specification, value
  @_ == 3 or confess "Three parameters";
  my $arena   = $ref->arena;
  my $area    = $ref->area;
  my $address = $ref->address;
  $exec->lastAssignArena   = $arena;
  $exec->lastAssignArea    = $area;
  $exec->lastAssignAddress = $address;
  $exec->lastAssignType    = $exec->getMemoryType($arena, $area);
  $exec->lastAssignValue   = $value;
  $exec->lastAssignBefore  = $exec->getMemoryAddressFromAddress($ref)->$*;

  my $a = $exec->GetMemoryLocation->($exec, $arena, $area, $address);
  $$a = $value;
 }

sub Address($$$$;$)                                                             #P Record a reference to memory.
 {my ($arena, $area, $address, $name, $delta) = @_;                             # Arena, area, address in area, name of area, delta from specified address
  my $r = genHash("Zero::Emulator::Address",                                    # Address memory
    arena=>     $arena,                                                         # Arena in memory
    area=>      $area,                                                          # Area in memory, either a number or a reference to a number indicating the level of indirection
    address=>   $address,                                                       # Address within area, either a number or a reference to a number indicating the level of indirection
    name=>      $name // 'stackArea',                                           # Name of area
    delta=>     ($delta//0),                                                    # Offset from indicated address
   );
  confess "AAAA" unless defined $name;
  $r
 }

sub stackTrace($;$)                                                             #P Create a stack trace.
 {my ($exec, $title) = @_;                                                      # Execution environment, title
  my $i = $exec->currentInstruction;
  my $s = $exec->suppressOutput;                                                # Suppress file and line numbers in dump to facilitate automated testing
  my @t = $exec->contextString($i, $title//"Stack trace:");

  for my $j(reverse keys $exec->calls->@*)
   {my $c = $exec->calls->[$j];
    my $i = $c->instruction;
    push @t, sprintf "%5d  %4d %s", $j+1, $i->number+1, $i->action if $s;
    push @t, sprintf "%5d  %4d %-16s at %s line %d",
      $j+1, $i->number+1, $i->action, $i->file, $i->line       unless $s;
   }
  join "\n", @t, '';
 }

sub stackTraceAndExit($$%)                                                      #P Create a stack trace and exit from the emulated program.
 {my ($exec, $title, %options) = @_;                                            # Execution environment, title, options
  @_ >= 2 or confess "At least two parameters";

  my $t = $exec->stackTrace($title);
  $exec->output($t);
  confess $t unless $exec->suppressOutput;                                      # Confess if requested - presumably because this indicates an error in programming and thus nothing can be done about it within the program

  $exec->instructionPointer = undef;                                            # Execution terminates as soon as undefined instruction is encountered
  $t
 }

my $allocs = [];                                                                # Allocations

sub allocMemory($$$)                                                            #P Create the name of a new memory area.
 {my ($exec, $number, $arena) = @_;                                             # Execution environment, name of allocation, arena to use
  @_ == 3 or confess "Three parameters";
  $number =~ m(\A\d+\Z) or confess "Array name must be numeric not : $number";
  my $f = $exec->freedArrays->[$arena];                                         # Reuse recently freed array if possible
  my $a = $f && @$f ? pop @$f : ++$$allocs[$arena];                             # Area id to reuse or use for the first time
  my $n = $exec->block->ArrayNumberToName($number);                             # Convert array name to number if possible
  $exec->AllocMemoryArea->($exec, $n, $arena, $a);                              # Create new area
  $exec->setMemoryType($arena, $a, $number);                                    # Track name of area
  $a
 }

sub freeArea($$$$)                                                              #P Free a heap memory area.
 {my ($exec, $arena, $area, $number) = @_;                                      # Execution environment, arena, array, name of allocation
  @_ == 4 or confess "Four parameters";
  $number =~ m(\A\d+\Z) or confess "Array name must be numeric not : $number";
  $exec->checkArrayName($arena, $area, $number);

  $exec->FreeMemoryArea->($exec, $arena, $area);

  push $exec->freedArrays->[$arena]->@*, $area;                                 # Save array for reuse
 }

sub pushArea($$$$)                                                              #P Push a value onto the specified heap array.
 {my ($exec, $area, $name, $value) = @_;                                        # Execution environment, array, name of allocation, value to assign
  @_ == 4 or confess "Four parameters";
  $exec->checkArrayName(arenaHeap, $area, $name);
  $exec->PushMemoryArea->($exec, $area, $value);
 }

sub popArea($$$$)                                                               # Pop a value from the specified memory area if possible else confess.
 {my ($exec, $arena, $area, $name) = @_;                                        # Execution environment, arena, array, name of allocation, value to assign
  $exec->checkArrayName($arena, $area, $name);                                  # Check stack name
  $exec->PopMemoryArea->($exec, $arena, $area);
 }

sub getMemoryType($$$)                                                          #P Get the type of an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  $exec->memoryType->[$arena][$area];
 }

sub setMemoryType($$$$)                                                         #P Set the type of a memory area - a name that can be used to confirm the validity of reads and writes to that array represented by that area.
 {my ($exec, $arena, $area, $name) = @_;                                        # Execution environment, arena, area name, name of allocation
  @_ == 4 or confess "Four parameters";
  $exec->memoryType->[$arena][$area] = $name;
  $exec
 }

sub notRead()                                                                   #P Record the unused memory locations in the current stack frame.
 {my ($exec) = @_;                                                              # Parameters
  my $area = $exec->currentStackFrame;
#    my @area = $memory{$area}->@*;                                             # Memory in area
#    my %r;                                                                     # Location in stack frame=>  instruction defining vasriable
#    for my $a(keys @area)
#     {if (my $I  = $calls[-1]->variables->instructions->[$a])
#       {$r{$a} = $I;                                                           # Number of instruction creating variable
#       }
#     }
#
#    if (my $r = $read{$area})                                                  # Locations in this area that have ben read
#     {delete $r{$_} for keys %$r;                                              # Delete locations that have been read from
#     }
#
#    $notRead{$area} = {%r} if keys %r;                                         # Record not read
     {}
   }

sub rwWrite($$$$)                                                               #P Observe write to memory.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address within area
  my $P = $exec->rw->[$arena][$area][$address];
  if (defined($P))
   {my $T = $exec->getMemoryType($arena, $area);
    my $M = $exec->getMemoryAddress($arena, $area, $address, $T);
    if ($$M)
     {my $Q = $exec->currentInstruction;
      my $p = $exec->contextString($P, "Previous write");
      my $q = $exec->contextString($Q, "Current  write");
      $exec->doubleWrite->{$p}{$q}++;
     }
   }
  $exec->rw->[$arena][$area][$address] = $exec->currentInstruction;
 }

sub markAsRead($$$$)                                                            #P Mark a memory address as having been read from.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area in memory, address within area
  @_ == 4 or confess "Four parameters";
  delete $exec->rw->[$arena][$area][$address];                                  # Clear last write operation
 }

sub rwRead($$$$)                                                                #P Observe read from memory.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area in memory, address within area
  @_ == 4 or confess "Four parameters";
  if (defined(my $a = $exec->rw->[$arena][$area][$address]))                    # Can only read from locations that actually have something in them
   {$exec->markAsRead($arena, $area, $address);                                 # Clear last write operation
   $exec->read->[$arena][$area][$address]++;                                    # Track reads
   }
 }

sub stackAreaNameNumber($)                                                      # Number of name representing stack area.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->block->ArrayNameToNumber("stackArea");
 }

sub left($$)                                                                    #P Address of a location in memory.
 {my ($exec, $ref) = @_;                                                        # Execution environment, reference
  @_ == 2 or confess "Two parameters";
  ref($ref) =~ m(Reference)
    or confess "Reference required, not: ".dump($ref);
  my $r       =  $ref->address;
  my $address =  $r;
     $address = \$r if isScalar $address;                                       # Interpret constants as direct memory locations
  my $arena   = $ref->arena;
  my $area    = $ref->area;
  my $delta   = $ref->delta;
  my $S       = $exec->currentStackFrame;                                       # Current stack frame
  my $stackArea = $exec->stackAreaNameNumber;

  my sub invalid($)
   {my ($e) = @_;                                                               # Parameters
    my $i   = $exec->currentInstruction;
    my $l   = $i->line;
    my $f   = $i->file;
    $exec->stackTraceAndExit(
     "Invalid left address,"
     ." arena: ".dump($arena)
     ." area: ".dump($area)
     ." address: ".dump($address)
     ." e: ".dump($e)
     , confess=>1)
   };

  my $M;                                                                        # Memory address
  if (isScalar $$address)
   {$M = $$address + $delta;
   }
  elsif (isScalar $$$address)
   {$M = $exec->getMemory(arenaLocal, $S, $$$address, $stackArea) + $delta;
   }
  else
   {invalid(1)
   }

  if ($M < 0)                                                                   # Disallow negative addresses because they mean something special to Perl
   {$exec->stackTraceAndExit("Negative address: $M, "
     ." for arena: ".dump($arena)
     ." for area: " .dump($area)
     .", address: " .dump($address));
   }
  elsif (!defined($area))                                                       # Current stack frame
   {my $a = Address(arenaLocal, $S, $M, $ref->name);                            # Stack frame
    return $a;
   }
  elsif (isScalar($area))
   {my $a = Address($arena, $area, $M, $ref->name);                             # Specified constant area
    return $a;
   }
  elsif (isScalar($$area))
   {my $A = $exec->getMemory(arenaLocal, $S, $$area, $stackArea);
    my $a = Address($arena, $A, $M, $ref->name);                                # Indirect area
    return $a;
   }
  invalid(2);
 }

sub right($$)                                                                   #P Get a constant or a value from memory.
 {my ($exec, $ref) = @_;                                                        # Location, optional area
  @_ == 2 or confess "Two parameters";
  ref($ref) =~ m(Reference) or confess "Reference required";
  my $address   = $ref->address;
  my $arena     = $ref->arena;
  my $area      = $ref->area;
  my $stackArea = $exec->currentStackFrame;
  my $name      = $ref->name;
  my $delta     = $ref->delta;
  my $stackAN   = $exec->stackAreaNameNumber;

  my $r; my $e = 0; my $tArena = $arena; my $tArea = $area; my $tAddress = $address; my $tDelta = $delta;

  my sub invalid($)                                                             # Invalid address
   {my ($error) = @_;
    my $i = $exec->currentInstruction;
    my $l = $i->line;
    my $f = $i->file;
    $exec->stackTraceAndExit(
     "Invalid "
     ." error: "      .dump($error)
     ." right arena: ".dump($arena)
     ." right area: " .dump($area)
     ." address: "    .dump($a)
     ." stack: "      .$exec->currentStackFrame
     ." error: "      .dump($e)
     ." target Area: ".dump($tArea)
     ." address: "    .dump($tAddress)
     ." delta: "      .dump($tDelta));
   }

  if (isScalar($address))                                                       # Constant
   {#rwRead($area//&stackArea, $a) if $a =~ m(\A\-?\d+\Z);
    return $address if defined $address;                                        # Attempting to read a address that has never been set is an error
    invalid(1);
   }

  my $m;
  my $memory = $exec->memory;

  if (isScalar($$address))                                                      # Direct
   {$m = $$address + $delta;
   }
  elsif (isScalar($$$a))                                                        # Indirect
   {$m = $exec->getMemory(arenaLocal, $stackArea, $$$address, $stackAN) + $delta;
   }
  else
   {invalid(2);
   }
  invalid(3) unless defined $m;

  if (!defined($area))                                                          # Stack frame
   {$r = $exec->getMemory(arenaLocal, $stackArea, $m, $stackAN);                # Indirect from stack area
    $e = 1; $tArena = arenaLocal; $tArea = $stackArea;  $tAddress = $m;
   }
  elsif (isScalar($area))
   {$r = $exec->getMemory($arena, $area, $m, $ref->name);                       # Indirect from stack area
    $e = 2; $tArena = $arena; $tArea = $stackArea;  $tAddress = $m;
   }
  elsif (isScalar($$area))
   {$e = 3; $tArena = arenaLocal; $tArea = $stackArea;  $tAddress = $m;
    if (defined(my $j = $exec->getMemory(arenaLocal, $stackArea, $$area, $stackAN)))
     {$r = $exec->getMemory($arena, $j, $m, $ref->name);                        # Indirect from stack area
      $e = 4; $tArena = $arena; $tArea = $j;  $tAddress = $m;
     }
   }
  else
   {invalid(4);
   }

  invalid(5) unless defined $r;
  $r
 }

sub jumpOp($$$)                                                                 #P Jump to the target address if the tested memory area if the condition is matched.
 {my ($exec, $i, $check) = @_;                                                  # Execution environment, Instruction, check
  @_ == 3 or confess "Three parameters";
  $exec->instructionPointer = $i->number + $exec->right($i->jump) if &$check;   # Check if condition is met
 }

sub assert1($$$)                                                                #P Assert true or false.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = $exec->currentInstruction;
  my $a = $exec->right($i->source);
  unless($sub->($a))
   {$exec->stackTraceAndExit("Assert$test $a failed");
   }
 }

sub assert2($$$)                                                                #P Assert generically.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = $exec->currentInstruction;
  my ($a, $b) = ($exec->right($i->source), $exec->right($i->source2));
  unless($sub->($a, $b))
   {$exec->stackTraceAndExit("Assert $a $test $b failed");
   }
 }

sub assign($$$)                                                                 #P Assign - check for pointless assignments.
 {my ($exec, $target, $value) = @_;                                             # Execution environment, Target of assign, value to assign
  @_ == 3 or confess "Three parameters";
  ref($target) =~ m(Address)i or confess "Not an address: ".dump($target);
  !ref($value) or confess "Not a  scalar value".dump($value);

  my $arena   = $target->arena;
  my $area    = $target->area;
  my $address = $target->address;
  my $name    = $target->name;
  $exec->checkArrayName($arena, $area, $name);

  if (!defined($value))                                                         # Check that the assign is not pointless
   {$exec->stackTraceAndExit
     ("Cannot assign an undefined value to arena: $arena, area: $area($name),"
     ." address: $address");
   }
  else
   {my $currently = $exec->getMemoryAddressFromAddress($target);
    if (defined $$currently)
     {if ($$currently == $value)
       {$exec->pointlessAssign->{$exec->currentInstruction->number}++;          # Record the pointless assign
        if ($exec->stopOnError)
         {$exec->stackTraceAndExit("Pointless assign of: $$currently "
          ."to arena: $arena, area: $area($name), at: $address");
         }
       }
     }
   }

  if (defined $exec->watch->[$area][$address])                                  # Watch for specified changes
   {my $n = $exec->block->ArrayNumberToName($name) // "unknown";
    my @s = $exec->stackTrace("Change at watched "
     ."arena: $arena, area: $area($n), address: $address");
    $s[-1] .= join ' ', "Current value:", $exec->getMemory($arena, $area, $address, $name),
                        "New value:", $value;
    my $s = join "", @s;
    say STDERR $s unless $exec->suppressOutput;
    $exec->output("$s\n");
   }

  $exec->setMemory($target, $value);                                            # Actually do the assign
 }

sub stackAreaNumber($)                                                          #P Number for type of stack area array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->block->ArrayNameToNumber("stackArea")
 }

sub paramsNumber($)                                                             #P Number for type of parameters array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->block->ArrayNameToNumber("params")
 }

sub returnNumber($)                                                             #P Number for type of return area array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->block->ArrayNameToNumber("return")
 }

sub allocateSystemAreas($)                                                      #P Allocate system areas for a new stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  (stackArea=>   $exec->allocMemory($exec->stackAreaNameNumber, arenaLocal),
   params=>      $exec->allocMemory($exec->paramsNumber,        arenaParms),
   return=>      $exec->allocMemory($exec->returnNumber,        arenaReturn));
 }

sub freeSystemAreas($$)                                                         #P Free system areas for the specified stack frame.
 {my ($exec, $c) = @_;                                                          # Execution environment, stack frame
  @_ == 2 or confess "Two parameters";
  $exec->notRead;                                                               # Record unread memory locations in the current stack frame
  $exec->freeArea(arenaLocal,  $c->stackArea, $exec->stackAreaNumber);
  $exec->freeArea(arenaParms,  $c->params,    $exec->paramsNumber);
  $exec->freeArea(arenaReturn, $c->return,    $exec->returnNumber);
 }

sub currentInstruction($)                                                       #P Locate current instruction.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->calls->[-1]->instruction;
 }

sub createInitialStackEntry($)                                                  #P Create the initial stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  my $variables = $exec->block->variables;
  my $nVariables = $variables->fieldOrder->@*;                                  # Number of variables in this stack frame

  push $exec->calls->@*,                                                        # Variables in initial stack frame
    stackFrame(
     $exec->block ? (variables=>  $variables) : (),
     $exec->allocateSystemAreas);
  $exec
 }

sub checkArrayName($$$$)                                                        #P Check the name of an array.
 {my ($exec, $arena, $area, $number) = @_;                                      # Execution environment, arena, array, array name
  @_ == 4 or confess "Four parameters";

  return 1 unless $exec->checkArrayNames;                                       # Check the names of arrays if requested

  if (!defined($number))                                                        # A name is required
   {$exec->stackTraceAndExit("Array name required to size array: $area in arena $arena");
    return 0;
   }

  my $Number = $exec->getMemoryType($arena, $area);                             # Area has a name
  if (!defined($Number))
   {$exec->stackTraceAndExit("No name associated with array: $area in arena $arena");
    return 0;
   }
  if ($number != $Number)                                                       # Name does not match supplied name
   {my $n = $exec->block->ArrayNumberToName($number);
    my $N = $exec->block->ArrayNumberToName($Number);
    $exec->stackTraceAndExit("Wrong name: $n for array with name: $N");
    return 0;
   }

  1
 }

sub locateAreaElement($$$)                                                      #P Locate an element in an array.
 {my ($exec, $ref, $op) = @_;                                                   # Execution environment, reference naming the array, operation

  my @a = $exec->areaContent($ref);
  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {return $a + 1;
     }
   }
  0
 }

sub countAreaElement($$$)                                                       #P Count the number of elements in array that meet some specification.
 {my ($exec, $ref, $op) = @_;                                                   # Execution environment, reference naming the array, operation
  my @a = $exec->areaContent($ref);
  my $n = 0;

  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {++$n;
     }
   }

  $n
 }

sub output($$)                                                                  #P Write an item to the output channel. Items are separated with one blank each unless the caller has provided formatting with new lines.
 {my ($exec, $item) = @_;                                                       # Execution environment, item to write
  if ($exec->out and $exec->out !~ m(\n\Z) and $item !~ m(\A\n)s)
   {$exec->out .= " $item";
   }
  else
   {$exec->out .= $item;
   }
 }

sub outLines($)                                                                 #P Turn the output channel into an array of lines.
 {my ($exec) = @_;                                                              # Execution environment
  [split /\n/, $exec->out]
 }

sub analyzeExecutionResultsLeast($%)                                            #P Analyze execution results for least used code.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @c = $exec->block->code->@*;
  my %l;
  for my $i(@c)                                                                 # Count executions of each instruction
   {$l{$i->file}{$i->line} += $i->executed unless $i->action =~ m(\Aassert)i;
   }

  my @L;
  for   my $f(keys %l)
   {for my $l(keys $l{$f}->%*)
     {push @L, [$l{$f}{$l}, $f, $l];
     }
   }
  my @l = sort {$$a[0] <=> $$b[0]}                                              # By frequency
          sort {$$a[2] <=> $$b[2]} @L;                                          # By line number

  my $N = $options{least}//1;
  $#l = $N if @l > $N;
  map {sprintf "%4d at %s line %4d", $$_[0], $$_[1], $$_[2]} @l;
 }

sub analyzeExecutionResultsMost($%)                                             #P Analyze execution results for most used code.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @c = $exec->block->code->@*;
  my %m;
  for my $i(@c)                                                                 # Count executions of each instruction
   {my $t =                                                                     # Traceback
     join "\n", map {sprintf "    at %s line %4d", $$_[0], $$_[1]} $i->context->@*;
    $m{$t} += $i->executed;
   }
  my @m = reverse sort {$$a[1] <=> $$b[1]} map {[$_, $m{$_}]} keys %m;          # Sort a hash into value order
  my $N = $options{most}//1;
  $#m = $N if @m > $N;
  map{sprintf "%4d\n%s", $m[$_][1], $m[$_][0]} keys @m;
 }

sub analyzeExecutionNotRead($%)                                                 #P Analyze execution results for variables never read.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @t;
  my $n = $exec->notRead;
  for my $areaK(sort keys %$n)
   {my $area = $$n{$areaK};
    for my $addressK(sort keys %$area)
     {my $address = $$area{$addressK};
      push @t, $exec->contextString(block->code->[$addressK],
       "Not read from area: $areaK, address: $addressK in context:");
     }
   }
  @t;
 }

sub analyzeExecutionResultsDoubleWrite($%)                                      #P Analyze execution results - double writes.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @r;

  my $W = $exec->doubleWrite;
  if (keys %$W)
   {for my $p(sort keys %$W)
     {for my $q(keys $$W{$p}->%*)
       {push @r, sprintf "Double write occured %d  times. ", $$W{$p}{$q};
        if ($p eq $q)
         {push @r, "First  and second write\n$p\n";
         }
        else
         {push @r, "First  write:\n$p\n";
          push @r, "Second write:\n$q\n";
         }
       }
     }
   }
  @r
 }

sub analyzeExecutionResults($%)                                                 #P Analyze execution results.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @r;

  if (1)
   {my @l = $exec->analyzeExecutionResultsLeast(%options);                      # Least/most executed
    my @m = $exec->analyzeExecutionResultsMost (%options);
    if (@l and $options{leastExecuted})
     {push @r, "Least executed:";
      push @r, @l;
     }
    if (@m and $options{mostExecuted})
     {push @r, "Most executed:";
      push @r, @m;
     }
   }

  if (my @n = $exec->analyzeExecutionNotRead(%options))                         # Variables not read
   {my $n = @n;
    @n = () unless $options{notRead};
    push @r, @n;
    push @r, sprintf "# %8d variables not read", $n;
   }

  if (my @d = $exec->analyzeExecutionResultsDoubleWrite(%options))              # Analyze execution results - double writes
   {my $d = @d;
    @d = () unless $options{doubleWrite};
    push @r, @d;
    push @r, sprintf "# %8d double writes", $d/2;
   }

  push @r,   sprintf "# %8d instructions executed", $exec->count;
  join "\n", @r;
 }

sub Zero::Emulator::Code::execute($%)                                           #P Execute a block of code.
 {my ($block, %options) = @_;                                                   # Block of code, execution options

  $block->assemble if $block;                                                   # Assemble unless we just want the instructions

  my $exec = ExecutionEnvironment(code=>$block, %options);                      # Create the execution environment

  my %instructions =                                                            # Instruction definitions
   (add=> sub                                                                   # Add the two source operands and store the result in the target
     {my $i = $exec->currentInstruction;
      my $t = $exec->left($i->target);
      my $a = $exec->right($i->source);
      my $b = $exec->right($i->source2);
      $exec->assign($t, $a + $b);
     },

    subtract=> sub                                                              # Subtract the second source operand from the first and store the result in the target
     {my $i = $exec->currentInstruction;
      my $t = $exec->left($i->target);
      my $a = $exec->right($i->source);
      my $b = $exec->right($i->source2);
      $exec->assign($t, $a - $b);
     },

    assert=> sub                                                                # Assert
     {my $i = $exec->currentInstruction;
      $exec->stackTraceAndExit("Assert failed");
     },

    assertEq=> sub                                                              # Assert equals
     {$exec->assert2("==", sub {my ($a, $b) = @_; $a == $b})
     },

    assertNe=> sub                                                              # Assert not equals
     {$exec->assert2("!=", sub {my ($a, $b) = @_; $a != $b})
     },

    assertLt=> sub                                                              # Assert less than
     {$exec->assert2("< ", sub {my ($a, $b) = @_; $a <  $b})
     },

    assertLe=> sub                                                              # Assert less than or equal
     {$exec->assert2("<=", sub {my ($a, $b) = @_; $a <= $b})
     },

    assertGt=> sub                                                              # Assert greater than
     {$exec->assert2("> ", sub {my ($a, $b) = @_; $a >  $b})
     },

    assertGe=> sub                                                              # Assert greater
     {$exec->assert2(">=", sub {my ($a, $b) = @_; $a >= $b})
     },

    assertFalse=> sub                                                           # Assert false
     {$exec->assert1("False", sub {my ($a) = @_; $a == 0})
     },

    assertTrue=> sub                                                            # Assert true
     {$exec->assert1("True", sub {my ($a) = @_; $a != 0})
     },

    array=> sub                                                                 # Create a new memory area and write its number into the address named by the target operand
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);                                         # The reason for this allocation
      my $a = $exec->allocMemory($s, arenaHeap);                                # Allocate
      my $t = $exec->left($i->target);                                          # Target in which to save array number
      $exec->assign($t, $a);                                                    # Save array number in target#
      $a
     },

    free=> sub                                                                  # Free the memory area named by the source operand
     {my $i = $exec->currentInstruction;
      my $area = $exec->right($i->target);                                      # Area
      my $name = $exec->right($i->source);
      $exec->freeArea(arenaHeap, $area, $name);                                 # Free the area
     },

    arraySize=> sub                                                             # Get the size of the specified area
     {my $i = $exec->currentInstruction;
      my $size = $exec->left ($i->target);                                      # Location to store size in
      my $area = $exec->right($i->source);                                      # Location of area
      my $name = $i->source2;                                                   # Name of area

      $exec->checkArrayName(arenaHeap, $area, $name);                           # Check that the supplied array name matches what is actually in memory

      $exec->assign($size, $exec->areaLength($area))                            # Size of area
     },

    arrayIndex=> sub                                                            # Place the 1 based index of the second source operand in the array referenced by the first source operand in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->locateAreaElement($i->source, sub{$_[0] == $e})) # Index of element
     },

    arrayCountGreater=> sub                                                     # Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->countAreaElement($i->source, sub{$_[0] > $e}))   # Index of element
     },

    arrayCountLess=> sub                                                        # Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->countAreaElement($i->source, sub{$_[0] < $e}))   # Index of element
     },

    resize=> sub                                                                # Resize an array
     {my $i = $exec->currentInstruction;
      my $size =  $exec->right($i->source);                                     # New size
      my $name =  $exec->right($i->source2);                                    # Array name
      my $area =  $exec->right($i->target);                                     # Array to resize
      $exec->checkArrayName(arenaHeap, $area, $name);
      $exec->ResizeMemoryArea->($exec, $area, $size);
     },

    call=> sub                                                                  # Call a subroutine
     {my $i = $exec->currentInstruction;
      my $t = $i->jump->address;                                                # Subroutine to call

      if (isScalar($t))
       {$exec->instructionPointer = $i->number + $t;                            # Relative call if we know where the subroutine is relative to the call instruction
       }
      else
       {$exec->instructionPointer = $t;                                         # Absolute call
       }
      push $exec->calls->@*,
        stackFrame(target=>$block->code->[$exec->instructionPointer],           # Create a new call stack entry
        instruction=>$i, #variables=>$i->procedure->variables,
        $exec->allocateSystemAreas());
     },

    return=> sub                                                                # Return from a subroutine call via the call stack
     {my $i = $exec->currentInstruction;
      $exec->calls or $exec->stackTraceAndExit("The call stack is empty so I do not know where to return to");
      $exec->freeSystemAreas(pop $exec->calls->@* );
      if ($exec->calls)
       {my $c = $exec->calls->[-1];
        $exec->instructionPointer = $c->instruction->number+1;
       }
      else
       {$exec->instructionPointer = undef;
       }
     },

    confess=> sub                                                               # Print the current call stack and stop
     {$exec->stackTraceAndExit("Confess at:", confess=>1);
     },

    trace=> sub                                                                 # Start/stop/change tracing status from a program. A trace writes out which instructions have been executed and how they affected memory
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source) ? 1 : 0;
      $exec->trace = $s;
      my $m = "Trace: $s";
      say STDERR           $m unless $exec->suppressOutput;
      $exec->output("$m\n");
     },

    traceLabels=> sub                                                           # Start trace points
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source) ? 1 : 0;
      $exec->traceLabels = $s;
      my $m = "TraceLabels: $s";
      say STDERR           $m unless $exec->suppressOutput;
      $exec->output("$m\n");
     },

    dump=> sub                                                                  # Dump memory
     {my $i = $exec->currentInstruction;
      my   @m= $exec->dumpMemory;
      push @m, $exec->stackTrace;
      my $m = join '', @m;
      say STDERR $m unless $exec->suppressOutput;
      $exec->output($m);
     },

    arrayDump=> sub                                                             # Dump array in memory
     {my $i = $exec->currentInstruction;
      my $a = $exec->right($i->target);
      my $m = dump($exec->GetMemoryArea->($exec, arenaHeap, $a)) =~ s(\n) ()gsr;
      say STDERR $m unless $exec->suppressOutput;
      $exec->output("$m\n");
     },

    dec=> sub                                                                   # Decrement locations in memory. The first address is incremented by 1, the next by two, etc.
     {my $i = $exec->currentInstruction;
      my $T = $exec->right($i->target);
      my $t = $exec->left($i->target);
      $exec->setMemory($t, defined($t) ? $T-1 : -1);
     },

    inc=> sub                                                                   # Increment locations in memory. The first address is incremented by 1, the next by two, etc.
     {my $i = $exec->currentInstruction;
      my $T = $exec->right($i->target);
      my $t = $exec->left($i->target);
      $exec->setMemory($t, defined($t) ? $T+1 : 1);
     },

    jmp=> sub                                                                   # Jump to the target address
     {my $i = $exec->currentInstruction;
      my $n = $i->number;
      #my $r = $exec->right($i->target);
      my $r = $exec->right($i->jump);
      $exec->instructionPointer = $n + $r;
     },
                                                                                # Conditional jumps
    jEq=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) == $exec->right($i->source2)})},
    jNe=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) != $exec->right($i->source2)})},
    jLe=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) <= $exec->right($i->source2)})},
    jLt=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) <  $exec->right($i->source2)})},
    jGe=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) >= $exec->right($i->source2)})},
    jGt=>    sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) >  $exec->right($i->source2)})},
    jFalse=> sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) == 0})},
    jTrue=>  sub {my $i = $exec->currentInstruction; $exec->jumpOp($i, sub{$exec->right($i->source) != 0})},

    label=> sub                                                                 # Label - no operation
     {my ($i) = @_;                                                             # Instruction
      return unless $exec->traceLabels;
      my $s = $exec->stackTrace("Label");
      say STDERR $s unless $exec->suppressOutput;
      $exec->output($s);
     },

    clear=> sub                                                                 # Clear the first bytes of an area as specified by the target operand
     {my $i = $exec->currentInstruction;
      my $t =  $exec->right($i->target);
      my $N =  $exec->right($i->source);
      my $n =  $exec->right($i->source2);
      for my $a(0..$N-1)
       {my $p = Address(arenaHeap, $t, $a, $N);
        $exec->assign($p, 0);
       }
     },

    loadAddress=> sub                                                           # Load the address component of a reference
     {my $i = $exec->currentInstruction;
      my $s = $exec->left($i->source);
      my $t = $exec->left($i->target);
      $exec->assign($t, $s->address);
     },

    loadArea=> sub                                                              # Load the area component of an address
     {my $i = $exec->currentInstruction;
      my $s = $exec->left($i->source);
      my $t = $exec->left($i->target);
      $exec->assign($t, $s->area);
     },

    mov=> sub                                                                   # Move data moves data from one part of memory to another - "set", by contrast, sets variables from constant values
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->left($i->target);
      $exec->assign($t, $s);
     },

    moveLong=> sub                                                              # Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand
     {my $i = $exec->currentInstruction;
      my $s = $exec->left ($i->source);                                         # Source
      my $l = $exec->right($i->source2);                                        # Length
      my $t = $exec->left($i->target);                                          # Target
      for my $j(0..$l-1)
       {my $S = Address($s->arena, $s->area, $s->address+$j, $s->name, 0);
        my $T = Address($t->arena, $t->area, $t->address+$j, $t->name, 0);
        my $v = $exec->getMemoryFromAddress($S);
        $exec->assign($T, $v);
       }
     },

    not=> sub                                                                   # Not in place
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->left($i->target);
      $exec->assign($t, !$s);
     },

    paramsGet=> sub                                                             # Get a parameter from the previous parameter block - this means that we must always have two entries on the call stack - one representing the caller of the program, the second representing the current context of the program
     {my $i = $exec->currentInstruction;
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      my $S = Address(arenaParms, $exec->currentParamsGet, $s, $exec->paramsNumber);
      my $v = $exec->getMemoryFromAddress($S);
      $exec->assign($t, $v);
     },

    paramsPut=> sub                                                             # Place a parameter in the current parameter block
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->right($i->target);
      my $T = Address(arenaParms, $exec->currentParamsPut, $t, $exec->paramsNumber);
      $exec->assign($T, $s);
     },

    random=> sub                                                                # Random number in the specified range
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->left ($i->target);
      $exec->assign($t, int rand($s));
     },

    randomSeed=> sub                                                            # Random number seed
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      srand $s;
     },

    returnGet=> sub                                                             # Get a returned value
     {my $i = $exec->currentInstruction;
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      my $S = Address(arenaReturn, $exec->currentReturnGet, $s, $exec->returnNumber);
      my $v = $exec->getMemoryFromAddress($S);
      $exec->assign($t, $v);
     },

    returnPut=> sub                                                             # Place a value to be returned
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->right($i->target);
      my $T = Address(arenaReturn, $exec->currentReturnPut, $t, $exec->returnNumber);
      $exec->assign($T, $s);
     },

    nop=> sub                                                                   # No operation
     {my ($i) = @_;                                                             # Instruction
     },

    out=> sub                                                                   # Write source as output to an array of words
     {my $i = $exec->currentInstruction;
      if (ref($i->source) =~ m(array)i)
       {my @t = map {$exec->right($_)} $i->source->@*;
        my $t = join ' ', @t;
        say STDERR $t unless $exec->suppressOutput;
        $exec->output("$t\n");
       }
      else
       {my $t = $exec->right($i->source);
        say STDERR $t unless $exec->suppressOutput;
        $exec->output("$t\n");
       }
     },

    pop=> sub                                                                   # Pop a value from the specified memory area if possible else confess
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $S = $i->source2;
      my $t = $exec->left($i->target);
      my $v = $exec->popArea(arenaHeap, $s, $S);
      $exec->assign($t, $v);                                                    # Pop from memory area into indicated memory address
     },

    push=> sub                                                                  # Push a value onto the specified memory area
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $S = $i->source2;
      my $t = $exec->right($i->target);
      $exec->pushArea($t, $S, $s);
     },

    shiftLeft=> sub                                                             # Shift left within an element
     {my $i = $exec->currentInstruction;
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      my $v = $exec->getMemoryFromAddress($t) << $s;
      $exec->assign($t, $v);
     },

    shiftRight=> sub                                                            # Shift right within an element
     {my $i = $exec->currentInstruction;
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      my $v = $exec->getMemoryFromAddress($t) >> $s;
      $exec->assign($t, $v);
     },

    shiftUp=> sub                                                               # Shift an element up in a memory area
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->left($i->target);
      my $L = $exec->areaLength($t->area);                                      # Length of target array
      my $l = $t->address;
      for my $j(reverse $l..$L)
       {my $S = Address($t->arena, $t->area, $j-1,   $t->name, 0);
        my $T = Address($t->arena, $t->area, $j,     $t->name, 0);
        my $v = $exec->getMemoryFromAddress($S);
        $exec->assign($T, $v);
       }
      $exec->assign($t, $s);
     },

    shiftDown=> sub                                                             # Shift an element down in a memory area
     {my $i = $exec->currentInstruction;
      my $s = $exec->left($i->source);
      my $t = $exec->left($i->target);
      my $L = $exec->areaLength($s->area);                                      # Length of source array
      my $l = $s->address;
      my $v = $exec->getMemoryFromAddress($s);
      for my $j($l..$L-2)                                                       # Each element in specified range
       {my $S = Address($s->arena, $s->area, $j+1,   $s->name, 0);
        my $T = Address($s->arena, $s->area, $j,     $s->name, 0);
        my $v = $exec->getMemoryFromAddress($S);
        $exec->assign($T, $v);
       }
      $exec->popArea(arenaHeap, $s->area, $s->name);
      my $T = $exec->left($i->target);
      $exec->assign($T, $v);
     },

    tally=> sub                                                                 # Tally instruction usage
     {my $i = $exec->currentInstruction;
      my $t = $exec->right($i->source);
      $exec->tally = $t;
     },

    watch=> sub                                                                 # Watch a memory location for changes
     {my $i = $exec->currentInstruction;
      my $t = $exec->left($i->target);
      $exec->watch->[$t->area][$t->address]++;
     },
   );
  return {%instructions} unless $block;                                         # Return a list of the instructions

  $allocs = [];                                                                 # Reset all allocations
  $exec->createInitialStackEntry;                                               # Variables in initial stack frame

  my $mi = $options{maximumInstructionsToExecute} //                            # Prevent run away executions
                    maximumInstructionsToExecute;

  for my $step(1..$mi)                                                          # Execute each instruction in the code until we hit an undefined instruction. Track various statistics to assist in debugging and code improvement.
   {last unless defined($exec->instructionPointer);
    my $instruction = $exec->block->code->[$exec->instructionPointer++];        # Current instruction
    last unless $instruction;                                                   # Current instruction is undefined so we must have reached the end of the program

    $exec->calls->[-1]->instruction = $instruction;                             # Make this instruction the current instruction

    if (my $a = $instruction->action)                                           # Action
     {$exec->stackTraceAndExit(qq(No implementation for instruction: "$a"))     # Check that there is come code implementing the action for this instruction
        unless my $implementation = $instructions{$a};

      $exec->tallyInstructionCounts($instruction);                              # Tally instruction counts
      $exec->resetLastAssign;                                                   # Trace assignments
      $instruction->step = $step;                                               # Execution step number facilitates debugging

      $implementation->($instruction);                                          # Execute instruction

      #say STDERR "AAAA", unpack "h*", $exec->memoryString if $a =~ m(mov);     # Print memory
      $exec->instructionCounts->{$instruction->number}++;                       # Execution count by actual instruction

      ++$instruction->executed;

      $exec->traceMemory($instruction);                                         # Trace changes to memory
     }
    if ($step >= maximumInstructionsToExecute)
     {confess "Out of instructions after $step";
     }
   }

  $exec->freeSystemAreas($exec->calls->[0]);                                    # Free first stack frame

  $exec->completionStatistics;

  $exec
 }                                                                              # Execution results

sub completionStatistics($)                                                     #P Produce various statistics summarizing the execution of the program.
 {my ($exec) = @_;                                                              # Execution environment
  my $code = $exec->block->code;                                                # Instructions in code block
  my @n;
  for my $i(@$code)                                                             # Each instruction
   {push @n, $i unless $i->executed;
   }
  $exec->notExecuted = [@n];
 }

sub tallyInstructionCounts($$)                                                  #P Tally instruction counts.
 {my ($exec, $instruction) = @_;                                                # Execution environment, instruction being executed
  my $a = $instruction->action;
  if ($a !~ m(\A(assert.*|label|tally|trace(Points?)?)\Z))                      # Omit instructions that are not tally-able
   {if (my $t = $exec->tally)                                                   # Tally instruction counts
     {$exec->tallyCount++;
      $exec->tallyTotal->{$t}++;
      $exec->tallyCounts->{$t}{$a}++;
     }
    $exec->counts->{$a}++; $exec->count++;                                      # Execution instruction counts
   }
 }

sub resetLastAssign($)                                                          #P Reset the last assign trace fields ready for this instruction.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->lastAssignArena   = $exec->lastAssignArea  =
  $exec->lastAssignAddress = $exec->lastAssignValue = undef;
 }                                                                              # Execution results

sub traceMemory($$)                                                             #P Trace memory.
 {my ($exec, $instruction) = @_;                                                # Execution environment, current instruction
  return unless $exec->trace;                                                   # Trace changes to memory if requested
  my $e = $exec->instructionCounts->{$instruction->number};                     # Execution count for this instruction
  my $f = $exec->formatTrace;
  my $s = $exec->suppressOutput;
  my $a = $instruction->action;
  my $n = $instruction->number;
  my $F = $instruction->file;
  my $L = $instruction->line;
  my $S = $instruction->step;
  my $m  = sprintf "%5d  %4d  %4d  %12s", $S, $n, $e, $a;
     $m .= sprintf "  %20s", $f if $f;
     $m .= sprintf "  at %s line %d", $F, $L unless $s;
  say STDERR $m unless $s;
  $exec->output("$m\n");
 }

sub formatTrace($)                                                              #P Describe last memory assignment.
 {my ($exec) = @_;                                                              # Execution
  return "" unless defined(my $arena = $exec->lastAssignArena);
  return "" unless defined(my $area  = $exec->lastAssignArea);
  return "" unless defined(my $addr  = $exec->lastAssignAddress);
  return "" unless defined(my $type  = $exec->block->ArrayNumberToName($exec->lastAssignType));
  return "" unless defined(my $value = $exec->lastAssignValue);
  my $B = $exec->lastAssignBefore;
  my $b = defined($B) ? " was $B" : "";
  sprintf "[%d, %d, %s] = %d$b", $area, $addr, $type, $value;
 }

#D1 Instruction Set                                                             # The instruction set used by the Zero assembler programming language.

my $assembly;                                                                   # The current assembly

sub Assembly()                                                                  #P Start some assembly code.
 {$assembly = Code;                                                             # The current assembly
 }

my sub label()                                                                  # Next unique label
 {++$assembly->labelCounter;
 }

my sub setLabel(;$)                                                             # Set and return a label
 {my ($l) = @_;                                                                 # Optional preset label
  $l //= label;                                                                 # Create label if none supplied
  Label($l);                                                                    # Set label
  $l                                                                            # Return (new) label
 }

my sub xSource($)                                                               # Record a source argument
 {my ($s) = @_;                                                                 # Source expression
  (q(source), $assembly->Reference($s))
 }

my sub xSource2($)                                                              # Record a source argument
 {my ($s) = @_;                                                                 # Source expression
  (q(source2), $assembly->Reference($s))
 }

my sub xTarget($)                                                               # Record a target argument
 {my ($t) = @_;                                                                 # Target expression
  (q(target), $assembly->Reference($t))
 }

sub Inc($);
sub Jge($$$);
sub Jlt($$$);
sub Jmp($);
sub Mov($;$);
sub Subtract($$;$);

sub Add($$;$)                                                                   #i Add the source locations together and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"add", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Array($)                                                                    #i Create a new memory area and write its number into the address named by the target operand.
 {my ($source) = @_;                                                            # Name of allocation
  my $t = &Var();
  my $n = $assembly->ArrayNameToNumber($source);
  $assembly->instruction(action=>"array", xTarget($t), xSource($n));            # Encode array name as a number
  $t;
 }

sub ArrayCountLess($$;$) {                                                      #i Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountLess",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountLess",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayCountGreater($$;$) {                                                   #i Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountGreater",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountGreater",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayDump($)                                                                #i Dump an array.
 {my ($target) = @_;                                                            # Array to dump, title of dump
  $assembly->instruction(action=>"arrayDump", xTarget($target));
 }

sub ArrayIndex($$;$) {                                                          #i Find the 1 based index of the second source operand in the array referenced by the first source operand if it is present in the array else 0 into the target location.  The business of returning -1 would have led to the confusion of "try catch" and we certainly do not want that.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayIndex",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayIndex",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArraySize($$)                                                               #i The current size of an array.
 {my ($area, $name) = @_;                                                       # Location of area, name of area
  my $t = &Var();
  $assembly->instruction(action=>"arraySize",                                   # Target - location to place the size in, source - address of the area, source2 - the name of the area which cannot be taken from the area of the first source operand because that area name is the name of the area that contains the location of the area we wish to work on.
    xTarget($t), xSource($area), source2=>$assembly->ArrayNameToNumber($name));
  $t
 }
sub Assert1($$)                                                                 #P Assert operation.
 {my ($op, $a) = @_;                                                            # Operation, Source operand
  $assembly->instruction(action=>"assert$op", xSource($a), level=>2);
 }

sub Assert2($$$)                                                                #P Assert operation.
 {my ($op, $a, $b) = @_;                                                        # Operation, First memory address, second memory address
  $assembly->instruction(action=>"assert$op",
    xSource($a), xSource2($b), level=>2);
 }

sub Assert(%)                                                                   #i Assert regardless.
 {my (%options) = @_;                                                           # Options
  $assembly->instruction(action=>"assert");
 }

sub AssertEq($$%)                                                               #i Assert two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Eq", $a, $b);
 }

sub AssertFalse($%)                                                             #i Assert false.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("False", $a);
 }

sub AssertGe($$%)                                                               #i Assert are greater than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ge", $a, $b);
 }

sub AssertGt($$%)                                                               #i Assert two memory locations are greater than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Gt", $a, $b);
 }

sub AssertLe($$%)                                                               #i Assert two memory locations are less than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Le", $a, $b);
 }

sub AssertLt($$%)                                                               #i Assert two memory locations are less than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Lt", $a, $b);
 }

sub AssertNe($$%)                                                               #i Assert two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ne", $a, $b);
 }

sub AssertTrue($%)                                                              #i Assert true.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("True", $a);
 }

sub Bad(&)                                                                      #i A bad ending.
 {my ($bad) = @_;                                                               # What to do on a bad ending
  @_ == 1 or confess "One parameter";
  (bad=>  $bad)
 }

sub Block(&%)                                                                   #i Block of code that can either be restarted or come to a good or a bad ending.
 {my ($block, %options) = @_;                                                   # Block, options
  my ($Start, $Good, $Bad, $End) = (label, label, label, label);

  my $g = $options{good};
  my $b = $options{bad};

  setLabel($Start);                                                             # Start

  &$block($Start, $Good, $Bad, $End);                                           # Code of block

  if ($g)                                                                       # Good
   {Jmp $End;
    setLabel($Good);
    &$g($Start, $Good, $Bad, $End);
   }

  if ($b)                                                                       # Bad
   {Jmp $End;
    setLabel($Bad);
    &$b($Start, $Good, $Bad, $End);
   }
  setLabel($Good) unless $g;                                                    # Default positions for Good and Bad if not specified
  setLabel($Bad)  unless $b;
  setLabel($End);                                                               # End
 }

sub Call($)                                                                     #i Call the subroutine at the target address.
 {my ($p) = @_;                                                                 # Procedure description.
  $assembly->instruction(action=>"call", xTarget($p->target));
 }

sub Clear($$$)                                                                  #i Clear the first bytes of an area.  The area is specified by the first element of the address, the number of locations to clear is specified by the second element of the target address.
 {my ($target, $source, $source2) = @_;                                         # Target address to clear, number of bytes to clear, name of target
  $assembly->instruction(action=>"clear", xTarget($target),
    xSource($source), xSource2($source2));
 }

sub Confess()                                                                   #i Confess with a stack trace showing the location both in the emulated code and in the code that produced the emulated code.
 {$assembly->instruction(action=>"confess");
 }

sub Dec($)                                                                      #i Decrement the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"dec", xTarget($target))
 }

sub Dump()                                                                      #i Dump all the arrays currently in memory.
 {$assembly->instruction(action=>"dump");
 }

sub Else(&)                                                                     #i Else block.
 {my ($e) = @_;                                                                 # Else block subroutine
  @_ == 1 or confess "One parameter";
  (else=>  $e)
 }

sub Execute(%)                                                                  #i Execute the current assembly.
 {my (%options) = @_;                                                           # Options
  $assembly->execute(%options);                                                 # Execute the code in the current assembly
 }

sub For(&$%)                                                                    #i For loop 0..range-1 or in reverse.
 {my ($block, $range, %options) = @_;                                           # Block, limit, options
  if (!exists $options{reverse})                                                # Ascending order
   {my $s = 0; my $e = $range;                                                  # Start, end
    ($s, $e) = @$range if ref($e) =~ m(ARRAY);                                  # Start, end as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Mov $s;
      setLabel($Check);                                                         # Check
      Jge  $End, $i, $e;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Inc $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
  else
   {my $s = $range; my $e = 0;                                                  # Start, end
    ($e, $s) = @$range if ref($s) =~ m(ARRAY);                                  # End, start as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Subtract $s, 1;
    Subtract $i, $s;
      setLabel($Check);                                                         # Check
      Jlt  $End, $i, $e;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Dec $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
 }

sub ForArray(&$$%)                                                              #i For loop to process each element of the named area.
 {my ($block, $area, $name, %options) = @_;                                     # Block of code, area, area name, options
  my $e = ArraySize $area, $name;                                               # End
  my $s = 0;                                                                    # Start

  my ($Start, $Check, $Next, $End) = (label, label, label, label);

  setLabel($Start);                                                             # Start
  my $i = Mov $s;
    setLabel($Check);                                                           # Check
    Jge  $End, $i, $e;
      my $a = Mov [$area, \$i, $name];
      &$block($i, $a, $Check, $Next, $End);                                     # Block
    setLabel($Next);
    Inc $i;                                                                     # Next
    Jmp $Check;
  setLabel($End);                                                               # End
 }

sub Free($$)                                                                    #i Free the memory area named by the target operand after confirming that it has the name specified on the source operand.
 {my ($target, $source) = @_;                                                   # Target area yielding the id of the area to be freed, source area yielding the name of the area to be freed
  my $n = $assembly->ArrayNameToNumber($source);
  $assembly->instruction(action=>"free", xTarget($target), xSource($n));
 }

sub Good(&)                                                                     #i A good ending.
 {my ($good) = @_;                                                              # What to do on a good ending
  @_ == 1 or confess "One parameter";
  (good=>  $good)
 }

sub Ifx($$$%)                                                                   #P Execute then or else clause depending on whether two memory locations are equal.
 {my ($cmp, $a, $b, %options) = @_;                                             # Comparison, first memory address, second memory address, then block, else block
  confess "Then required" unless $options{then};
  if ($options{else})
   {my $else = label;
    my $end  = label;
    &$cmp($else, $a, $b);
      &{$options{then}};
      Jmp $end;
    setLabel($else);
      &{$options{else}};
    setLabel($end);
   }
  else
   {my $end  = label;
    &$cmp($end, $a, $b);
      &{$options{then}};
    setLabel($end);
   }
 }

sub IfEq($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jne, $a, $b, %options);
 }

sub IfFalse($%)                                                                 #i Execute then clause if the specified memory address is zero thus representing false.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jne, $a, 0, %options);
 }

sub IfGe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are greater than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jlt, $a, $b, %options);
 }

sub IfGt($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are greater than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jle, $a, $b, %options);
 }

sub IfNe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jeq, $a, $b, %options);
 }

sub IfLe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are less than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jgt, $a, $b, %options);
 }

sub IfLt($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are less than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jge, $a, $b, %options);
 }

sub IfTrue($%)                                                                  #i Execute then clause if the specified memory address is not zero thus representing true.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jeq, $a, 0, %options);
 }

sub Inc($)                                                                      #i Increment the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"inc", xTarget($target))
 }

sub Jeq($$$)                                                                    #i Jump to a target label if the first source field is equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jEq",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub JFalse($$)                                                                  #i Jump to a target label if the first source field is equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jFalse", xTarget($target), xSource($source));
 }

sub Jge($$$)                                                                    #i Jump to a target label if the first source field is greater than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jgt($$$)                                                                    #i Jump to a target label if the first source field is greater than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jle($$$)                                                                    #i Jump to a target label if the first source field is less than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jlt($$$)                                                                    #i Jump to a target label if the first source field is less than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jmp($)                                                                      #i Jump to a label.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"jmp", xTarget($target));
 }

sub Jne($$$)                                                                    #i Jump to a target label if the first source field is not equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jNe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub JTrue($$)                                                                   #i Jump to a target label if the first source field is not equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jTrue", xTarget($target), xSource($source));
 }

sub Label($)                                                                    #P Create a label.
 {my ($source) = @_;                                                            # Name of label
  $assembly->instruction(action=>"label", xSource($source));
 }

sub LoadAddress($;$) {                                                          #i Load the address component of an address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"loadAddress", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"loadAddress",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub LoadArea($;$) {                                                             #i Load the area component of an address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"loadArea",
      xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"loadArea",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub Mov($;$) {                                                                  #i Copy a constant or memory address to the target address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"mov", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"mov", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required for mov";
   }
 }

sub MoveLong($$$)                                                               #i Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.
 {my ($target, $source, $source2) = @_;                                         # Target of move, source of move, length of move
  $assembly->instruction(action=>"moveLong", xTarget($target),
    xSource($source), xSource2($source2));
 }

sub Not($) {                                                                    #i Move and not.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"not", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"not", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required for not";
   }
 }

sub Nop()                                                                       #i Do nothing (but do it well!).
 {$assembly->instruction(action=>"nop");
 }

sub Out(@)                                                                      #i Write memory location contents to out.
 {my (@source) = @_;                                                            # Either a scalar constant or memory address to output
  if (@source > 1)
   {my @a = map {$assembly->Reference($_)} @source;
    $assembly->instruction(action=>"out",  source=>[@a]);
   }
  else
   {$assembly->instruction(action=>"out",  xSource($source[0]));
   }
 }

sub ParamsGet($;$) {                                                            #i Get a word from the parameters in the previous frame and store it in the current frame.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Memory address to place parameter in, parameter number
    my $p = &Var();
    $assembly->instruction(action=>"paramsGet", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place parameter in, parameter number
    $assembly->instruction(action=>"paramsGet",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ParamsPut($$)                                                               #i Put a word into the parameters list to make it visible in a called procedure.
 {my ($target, $source) = @_;                                                   # Parameter number, address to fetch parameter from
  $assembly->instruction(action=>"paramsPut",
    xTarget($target), xSource($source));
 }

sub Pop(;$$) {                                                                  #i Pop the memory area specified by the source operand into the memory address specified by the target operand.
  if (@_ == 2)                                                                  # Pop indicated area into a local variable
   {my ($source, $source2) = @_;                                                # Memory address to place return value in, return value to get
    my $p = &Var();
    my $n = $assembly->ArrayNameToNumber($source2);
    $assembly->instruction(action=>"pop", xTarget($p), xSource($source), source2=>$n);
    return $p;
   }
  elsif (@_ == 3)
   {my ($target, $source, $source2) = @_;                                       # Pop indicated area into target address
    my $n = $assembly->ArrayNameToNumber($source2);
    $assembly->instruction(action=>"pop", xTarget($target), xSource($source), source2=>$n);
   }
  else
   {confess "Two or three parameters required";
   }
 }

sub Procedure($$)                                                               #i Define a procedure.
 {my ($name, $source) = @_;                                                     # Name of procedure, source code as a subroutine
  if ($name and my $n = $assembly->procedures->{$name})                         # Reuse existing named procedure
   {return $n;
   }

  Jmp(my $end = label);                                                         # Jump over the code of the procedure body
  my $start = setLabel;
  my $p = procedure($start);                                                    # Procedure description
  my $save_registers = $assembly->variables;
  $assembly->variables = $p->variables;
  &$source($p);                                                                 # Code of procedure called with start label as a parameter
  &Return;
  $assembly->variables = $save_registers;

  setLabel $end;
  $assembly->procedures->{$name} = $p;                                          # Return the start of the procedure
 }

sub Push($$$)                                                                   #i Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.
 {my ($target, $source, $source2) = @_;                                         # Memory area to push to, memory containing value to push
  @_ == 3 or confess "Three parameters";
    my $n = $assembly->ArrayNameToNumber($source2);
  $assembly->instruction(action=>"push", xTarget($target), xSource($source), source2=>$n);
 }

sub Resize($$$)                                                                 #i Resize the target area to the source size.
 {my ($target, $source, $source2) = @_;                                         # Target array, new size, array name
  $assembly->instruction(action=>"resize", xTarget($target),
    xSource($source), xSource2($assembly->ArrayNameToNumber($source2)));
 }

sub Random($;$) {                                                               #i Create a random number in a specified range.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"random", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"random",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub RandomSeed($)                                                               #i Seed the random number generator.
 {my ($seed) = @_;                                                              # Parameters
  $assembly->instruction(action=>"randomSeed", xSource($seed));
 }

sub Return()                                                                    #i Return from a procedure via the call stack.
 {$assembly->instruction(action=>"return");
 }

sub ReturnGet($;$) {                                                            #i Get a word from the return area and save it.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"returnGet", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"returnGet",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ReturnPut($$)                                                               #i Put a word into the return area.
 {my ($target, $source) = @_;                                                   # Offset in return area to write to, memory address whose contents are to be placed in the return area
  $assembly->instruction(action=>"returnPut",
    xTarget($target), xSource($source));
 }

sub ShiftDown($;$) {                                                            #i Shift an element down one in an area.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"shiftDown", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"shiftDown",
      xTarget($target), xSource($source));
    confess "Needs work";
    return $target;
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ShiftLeft($;$) {                                                            #i Shift left within an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftLeft",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftRight($;$) {                                                           #i Shift right with an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftRight",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftUp($;$)                                                                #i Shift an element up one in an area.
 {my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftUp",
    xTarget($target), xSource($source));
  $target
 }

sub Start($)                                                                    #i Start the current assembly using the specified version of the Zero language.  At  the moment only version 1 works.
 {my ($version) = @_;                                                           # Version desired - at the moment only 1
  $version == 1 or confess "Version 1 is currently the only version available";
  Assembly();
 }

sub Subtract($$;$)                                                              #i Subtract the second source operand value from the first source operand value and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"subtract", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Tally($)                                                                    #i Counts instructions when enabled.
 {my ($source) = @_;                                                            # Tally instructions when true
  $assembly->instruction(action=>"tally", xSource($source));
 }

sub Then(&)                                                                     #i Then block.
 {my ($t) = @_;                                                                 # Then block subroutine
  @_ == 1 or confess "One parameter";
  (then=>  $t)
 }

sub Trace($)                                                                    #i Start or stop tracing.  Tracing prints each instruction executed and its effect on memory.
 {my ($source) = @_;                                                            # Trace setting
  $assembly->instruction(action=>"trace", xSource($source));
 }

sub TraceLabels($)                                                              #i Enable or disable label tracing.  If tracing is enabled a stack trace is printed for each label instruction executed showing the call stack at the time the instruction was generated as well as the current stack frames.
 {my ($source) = @_;                                                            # Trace points if true
  $assembly->instruction(action=>"traceLabels", xSource($source));
 }

sub Var(;$)                                                                     #i Create a variable initialized to the specified value.
 {my ($value) = @_;                                                             # Value
  return Mov $value if @_;
  $assembly->variables->registers
 }

sub Watch($)                                                                    #i Watches for changes to the specified memory location.
 {my ($target) = @_;                                                            # Memory address to watch
  $assembly->instruction(action=>"watch", xTarget($target));
 }

#D1 Instruction Set Architecture                                                # Map the instruction set into a machine architecture.

my $instructions = Zero::Emulator::Code::execute(undef);
my @instructions = sort keys %$instructions;
my %instructions = map {$instructions[$_]=>$_} keys @instructions;

sub instructionList()                                                           #P Create a list of instructions.
 {my @i = grep {m(\s+#i)} readFile $0;
  my @j;                                                                        # Description of instruction
  for my $i(@i)
   {my @parse     = split /[ (){}]+/, $i, 5;
    my $name = $parse[1];
    my $sig  = $parse[2];
    my $comment = $i =~ s(\A.*?#i\s*) ()r;
    push @j, [$name, $sig, $comment];
   }
  [sort {$$a[0] cmp $$b[0]} @j]
}

sub instructionListExport()                                                     #P Create an export statement.
 {my $i = instructionList;
  say STDERR '@EXPORT_OK   = qw(', (join ' ', map {$$_[0]} @$i), ");\n";
}
#instructionListExport; exit;

sub instructionListReadMe()                                                     #P List  instructions for inclusion in read me.
 {my $i = instructionList;
  my $s = '';
  for my $i(@$i)
   {my ($name, $sig, $comment) = @$i;
    $s .= sprintf("**%10s**  %s\n", $name, $comment);
   }
  $s
 }

sub instructionListMapping()                                                    #P Map instructions to small integers.
 {my $i = instructionList;
  my @n = map {$$_[0]} @$i;                                                     # Description of instruction
  my $n = join ' ', @n;
  say STDERR <<END;
my \@instructions = qw($n);
END
}
#instructionListMapping(); exit;

sub refDepth($)                                                                 #P The depth of a reference.
 {my ($ref) = @_;                                                               # Reference to pack
  return 0 if isScalar($ref);
  return 1 if isScalar($$ref);
  return 2 if isScalar($$$ref);
  confess "Reference too deep".dump($ref);
 }

sub refValue($)                                                                 #P The value of a reference after dereferencing.
 {my ($ref) = @_;                                                               # Reference to pack
  return $ref if isScalar($ref);
  return $$ref if isScalar($$ref);
  return $$$ref if isScalar($$$ref);
  confess "Reference too deep".dump($ref);
 }

sub rerefValue($$)                                                              #P Re-reference a value.
 {my ($value, $depth) = @_;                                                     # Value to reference, depth of reference
  return   $value if $depth == 0;
  return  \$value if $depth == 1;
  return \\$value if $depth == 2;
  confess "Rereference depth of $depth is too deep";
 }

sub Zero::Emulator::Code::packRef($$$)                                          #P Pack a reference into 8 bytes.
 {my ($code, $instruction, $ref) = @_;                                          # Code block being packed, instruction being packed, reference being packed

  if (!defined($ref) or ref($ref) =~ m(array)i && !@$ref)                       # Unused reference
   {my $a = '';
    vec($a, 0, 32) = 0;
    vec($a, 1, 32) = 0;
    vec($a, 7,  8) =  2**7 - 1;
    return $a;
   }

  my @a = (arenaLocal, 0, $ref, 0);                                             # Local variable or constant
  @a = @$ref{qw(arena area address delta name)} if ref($ref) =~ m(Reference)i;  # Heap reference

  $_ //= 0 for @a;
  my ($arena, $area, $address, $delta, $name) = @a;

  my $dArea    = dump $area;
  my $dAddress = dump $address;
  my $dArena   = dump $arena;
  my $dDelta   = dump $delta;

  my $b = "too big, should be less than:";

  my $bArea    = "$b 2**16";
  my $bAddress = "$b 2**32";
  my $bArena   = "$b 2**2";
  my $bDelta   = "$b 2**7";


  my @m;
  push @m, "Area: $dArea $bArea"          if refValue($area)    >= 2**16;       # 2 + 16
  push @m, "Address: $dAddress $bAddress" if refValue($address) >= 2**32;       # 2 + 32
  push @m, "Arena: $dArena $bArea"        if     $arena         >= 2**2;        # 2
  push @m, "Delta: $dDelta $bDelta"       if abs($delta)        >  2**7;        # 8

  if (@m)
   {my $i = dump $instruction;
    my $r = dump $ref;
    my $c = join  "\n", $instruction->contextString, '';
    my ($m) = @m;
    confess <<END;
Unable to pack reference: $r
$m
$i
$c
END
   }

  my $a = '';
  vec($a, 0, 32) =  refValue $address;
  vec($a, 2, 16) =  refValue $area;
  vec($a, 24, 2) =  refDepth $address;
  vec($a, 25, 2) =  refDepth $area;
  vec($a, 26, 2) =           $arena;
  vec($a, 27, 2) =           $arena;
  vec($a, 7,  8) =  2**7 +   $delta - 1;
  $a
 }

sub Zero::Emulator::Code::unpackRef($$)                                         #P Unpack a reference.
 {my ($code, $a) = @_;                                                          # Code block being packed, instruction being packed, reference being packed

  my $vAddress = vec($a,  0, 32);
  my $vArea    = vec($a,  2, 16);
  my $rAddress = vec($a, 24,  2);
  my $rArea    = vec($a, 25,  2);
  my $arena    = vec($a, 26,  2);
  my $delta    = vec($a,  7,  8) - (2**7 - 1);

  my $area     = rerefValue($vArea,    $rArea);
  my $address  = rerefValue($vAddress, $rAddress);
  $code->Reference([$arena  != arenaHeap ? undef : $area, $address, 0, $delta]);
 }

sub Zero::Emulator::Code::packInstruction($$)                                   #P Pack an instruction.
 {my ($code, $i) = @_;                                                          # Code being packed, instruction to pack
  my  $a = '';
  vec($a, 0, 32) = $instructions{$i->action};
  vec($a, 1, 32) = 0;
  $a .= $code->packRef($i, $i->target);
  $a .= $code->packRef($i, $i->source);
  $a .= $code->packRef($i, $i->source2);
  $a
 }

sub unpackInstruction($)                                                        #P Unpack an instruction.
 {my ($I) = @_;                                                                 # Instruction numbers, instruction to pack

  my $i = vec($I, 0, 32);
  my $n = $instructions[$i];
  confess "Invalid instruction number: $i" unless defined $n;
  $n
 }

sub GenerateMachineCode(%)                                                      # Generate a string of machine code from the current block of code.
 {my (%options) = @_;                                                           # Generation options

  my $code = $assembly->code;
  my $pack = '';
  for my $i(@$code)
   {$pack .= $assembly->packInstruction($i);
   }
  $pack
 }

sub disAssemble($)                                                              # Disassemble machine code.
 {my ($mc) = @_;                                                                # Machine code string

  my $C = Code;

  my $n = length($mc) / 32;                                                     # The instructions are formatted into 32 byte blocks
  for my $i(1..$n)
   {my $c = substr($mc, ($i-1)*32, 32);
    my $i = $C->instruction
     (action=>  unpackInstruction(substr($c,  0, 8)),
      target=>  $C->unpackRef    (substr($c,  8, 8)),
      source=>  $C->unpackRef    (substr($c, 16, 8)),
      source2=> $C->unpackRef    (substr($c, 24, 8)));
   }
  $C
 }

sub disAssembleMinusContext($)                                                  #P Disassemble and remove context information from disassembly to make testing easier.
 {my ($D) = @_;                                                                 # Machine code string

  my $d = disAssemble  $D;

  for my $c($d->code->@*)                                                       # Remove context fields
   {delete @$c{qw(context executed file line number)};
    delete $$c{$_}{name} for qw(target source source2);
   }

  delete @$d{qw(assembled files labelCounter labels procedures variables)};

  $d
 }

sub GenerateMachineCodeDisAssembleExecute(%)                                    #i Round trip: generate machine code and write it onto a string, disassemble the generated machine code string and recreate a block of code from it, then execute the reconstituted code to prove that it works as well as the original code.
 {my (%options) = @_;                                                           # Options
  my $m = GenerateMachineCode;
  my $M = disAssemble $m;
     $M->execute(checkArrayNames=>0,  %options);
 }

#D0

use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(GenerateMachineCodeDisAssembleExecute Add Array ArrayCountGreater ArrayCountLess ArrayDump ArrayIndex ArraySize Assert AssertEq AssertFalse AssertGe AssertGt AssertLe AssertLt AssertNe AssertTrue Bad Block Call Clear Confess Dec Dump Else Execute For ForArray Free Good IfEq IfFalse IfGe IfGt IfLe IfLt IfNe IfTrue Inc JFalse JTrue Jeq Jge Jgt Jle Jlt Jmp Jne LoadAddress LoadArea Mov MoveLong Nop Not Out ParamsGet ParamsPut Pop Procedure Push Random RandomSeed Resize Return ReturnGet ReturnPut ShiftDown ShiftLeft ShiftRight ShiftUp Start Subtract Tally Then Trace TraceLabels Var Watch);
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

return 1 if caller;

# Tests

#Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

my $debug = -e q(/home/phil/);                                                  # Assume debugging if testing locally
sub is_deeply;
sub ok($;$);
sub x {exit if $debug}                                                          # Stop if debugging.
Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

=pod

Tests are run using different combinations of execution engine and memory
manager to prove that different implementations produce the same results.

=cut

for my $testSet(1..4) {                                                         # Select various combinations of execution engine and memory handler
say STDOUT "TestSet: $testSet";
my $ee = $testSet % 2 ? \&Execute :                                             # Assemble and execute
                        \&GenerateMachineCodeDisAssembleExecute;                # Generate machine code, load code and execute

$memoryTechnique = $testSet <= 2 ? undef : \&setStringMemoryTechnique;          # Set memory allocation technique

eval {goto latest if $debug};

#latest:;
if (1)                                                                          ##Out ##Start ##Execute
 {Start 1;
  Out "Hello", "World";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Hello World
END
 }

#latest:;
if (1)                                                                          ##Var
 {Start 1;
  my $a = Var 22;
  AssertEq $a, 22;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, "";
 }

#latest:;
if (1)                                                                          ##Nop
 {Start 1;
  Nop;
  my $e = &$ee;
  is_deeply $e->out, "";
 }

#latest:;
if (1)                                                                          ##Mov
 {Start 1;
  my $a = Mov 2;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)
 {Start 1;                                                                      ##Mov
  my $a = Mov  3;
  my $b = Mov  $$a;
  my $c = Mov  \$b;
  Out $c;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
3
END
 }

#latest:;
if (1)                                                                          ##Add
 {Start 1;
  my $a = Add 3, 2;
  Out  $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
5
END
 }

#latest:;
if (1)                                                                          ##Subtract
 {Start 1;
  my $a = Subtract 4, 2;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)                                                                          ##Dec
 {Start 1;
  my $a = Mov 3;
  Dec $a;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)                                                                          ##Inc
 {Start 1;
  my $a = Mov 3;
  Inc $a;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
4
END
 }

#latest:;
if (1)                                                                          ##Not
 {Start 1;
  my $a = Mov 3;
  my $b = Not $a;
  my $c = Not $b;
  Out $a;
  Out $b;
  Out $c;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
3

1
END
 }

#latest:;
if (1)                                                                          ##ShiftLeft
 {Start 1;
  my $a = Mov 1;
  ShiftLeft $a, $a;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)                                                                          ##ShiftRight
 {Start 1;
  my $a = Mov 4;
  ShiftRight $a, 1;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)                                                                          ##Jmp
 {Start 1;
  Jmp (my $a = label);
    Out  1;
    Jmp (my $b = label);
  setLabel($a);
    Out  2;
  setLabel($b);
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
 }

#latest:;
if (1)                                                                          ##JLt ##Label
 {Start 1;
  Mov 0, 1;
  Jlt ((my $a = label), \0, 2);
    Out  1;
    Jmp (my $b = label);
  setLabel($a);
    Out  2;
  setLabel($b);

  Jgt ((my $c = label), \0, 3);
    Out  3;
    Jmp (my $d = label);
  setLabel($c);
    Out  4;
  setLabel($d);
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
3
END
 }

#latest:;
if (1)                                                                          ##Label
 {Start 1;
  Mov 0, 0;
  my $a = setLabel;
    Out \0;
    Inc \0;
  Jlt $a, \0, 10;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
0
1
2
3
4
5
6
7
8
9
END
 }

#latest:;
if (1)                                                                          ##Mov
 {Start 1;
  my $a = Array "aaa";
  Mov     [$a,  1, "aaa"],  11;
  Mov  1, [$a, \1, "aaa"];
  Out \1;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
11
END
 }

#latest:;
if (1)                                                                          ##Call ##Return
 {Start 1;
  my $w = Procedure 'write', sub
   {Out 1;
    Return;
   };
  Call $w;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
END
 }

#latest:;
if (1)                                                                          ##Call
 {Start 1;
  my $w = Procedure 'write', sub
   {my $a = ParamsGet 0;
    Out $a;
    Return;
   };
  ParamsPut 0, 999;
  Call $w;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
999
END
 }

#latest:;
if (1)                                                                          ##Call ##ReturnPut ##ReturnGet
 {Start 1;
  my $w = Procedure 'write', sub
   {ReturnPut 0, 999;
    Return;
   };
  Call $w;
  ReturnGet \0, 0;
  Out \0;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
999
END
 }

#latest:;
if (1)                                                                          ##Procedure
 {Start 1;
  my $add = Procedure 'add2', sub
   {my $a = ParamsGet 0;
    my $b = Add $a, 2;
    ReturnPut 0, $b;
    Return;
   };
  ParamsPut 0, 2;
  Call $add;
  my $c = ReturnGet 0;
  Out $c;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
4
END
 }

#latest:;
if (1)                                                                          ##Confess
 {Start 1;
  my $c = Procedure 'confess', sub
   {Confess;
   };
  Call $c;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Confess at:
    2     3 confess
    1     6 call
END
 }

#latest:;
if (1)                                                                          ##Push ##Pop
 {Start 1;
  my $a = Array   "aaa";
  Push $a, 1,     "aaa";
  Push $a, 2,     "aaa";
  my $c = Pop $a, "aaa";
  my $d = Pop $a, "aaa";

  Out $c;
  Out $d;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
1
END
  is_deeply $e->heap(1), [];
 }

#latest:;
if (1)                                                                          ##Push
 {Start 1;
  my $a = Array "aaa";
  Push $a, 1, "aaa";
  Push $a, 2, "aaa";
  Push $a, 3, "aaa";
  my $b = Array "bbb";
  Push $b, 11, "bbb";
  Push $b, 22, "bbb";
  Push $b, 33, "bbb";
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->GetMemoryHeaps->($e), 3;
  is_deeply $e->heap(1), [1, 2, 3];
  is_deeply $e->heap(2), [11, 22, 33];
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov
 {Start 1;
  my $a = Array "alloc";
  my $b = Mov 99;
  my $c = Mov $a;
  Mov [$a, 0, 'alloc'], $b;
  Mov [$c, 1, 'alloc'], 2;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->heap(1), [99, 2];
 }

#latest:;
if (1)                                                                          ##Free
 {Start 1;
  my $a = Array "node";
  Free $a, "aaa";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Wrong name: aaa for array with name: node
    1     2 free
END
 }

#latest:;
if (1)                                                                          ##Free ##Dump
 {Start 1;
  my $a = Array "node";
  Out $a;
  Mov [$a, 1, 'node'], 1;
  Mov [$a, 2, 'node'], 2;
  Mov 1, [$a, \1, 'node'];
  Dump;
  Free $a, "node";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END if $testSet <= 2;
1
1=bless([undef, 1, 2], "node")
Stack trace:
    1     6 dump
END
  is_deeply $e->out, <<END if $testSet >  2;
1
1=[0, 1, 2]
Stack trace:
    1     6 dump
END
 }

#latest:;
if (1)                                                                          # Layout
 {Start 1;
  my $a = Mov 'A';
  my $b = Mov 'B';
  my $c = Mov 'C';
  Out $c, $b, $a;
  my $e = Execute(suppressOutput=>1);
 is_deeply $e->out, <<END;
C B A
END
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $a, $a, Then {Out "Eq"};
  IfNe $a, $a, Then {Out "Ne"};
  IfLe $a, $a, Then {Out "Le"};
  IfLt $a, $a, Then {Out "Lt"};
  IfGe $a, $a, Then {Out "Ge"};
  IfGt $a, $a, Then {Out "Gt"};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Eq
Le
Ge
END
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $a, $b, Then {Out "Eq"};
  IfNe $a, $b, Then {Out "Ne"};
  IfLe $a, $b, Then {Out "Le"};
  IfLt $a, $b, Then {Out "Lt"};
  IfGe $a, $b, Then {Out "Ge"};
  IfGt $a, $b, Then {Out "Gt"};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Ne
Le
Lt
END
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $b, $a, Then {Out "Eq"};
  IfNe $b, $a, Then {Out "Ne"};
  IfLe $b, $a, Then {Out "Le"};
  IfLt $b, $a, Then {Out "Lt"};
  IfGe $b, $a, Then {Out "Ge"};
  IfGt $b, $a, Then {Out "Gt"};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Ne
Ge
Gt
END
 }

#latest:;
if (1)                                                                          ##IfTrue
 {Start 1;
  IfTrue 1,
  Then
   {Out 1
   },
  Else
   {Out 0
   };
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
END
 }

#latest:;
if (1)                                                                          ##IfFalse ##Then ##Else
 {Start 1;
  IfFalse 1,
  Then
   {Out 1
   },
  Else
   {Out 0
   };
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
0
END
 }


#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
0
1
2
3
4
5
6
7
8
9
END
 }

#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10, reverse=>1;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
9
8
7
6
5
4
3
2
1
0
END
 }

#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } [2, 10];
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
3
4
5
6
7
8
9
END
 }

#latest:;
if (1)                                                                          ##Assert
 {Start 1;
  Assert;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert failed
    1     1 assert
END
 }

#latest:;
if (1)                                                                          ##AssertEq
 {Start 1;
  Mov 0, 1;
  AssertEq \0, 2;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 == 2 failed
    1     2 assertEq
END
 }

#latest:;
if (1)                                                                          ##AssertNe
 {Start 1;
  Mov 0, 1;
  AssertNe \0, 1;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 != 1 failed
    1     2 assertNe
END
 }

#latest:;
if (1)                                                                          ##AssertLt
 {Start 1;
  Mov 0, 1;
  AssertLt \0, 0;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 <  0 failed
    1     2 assertLt
END
 }

#latest:;
if (1)                                                                          ##AssertLe
 {Start 1;
  Mov 0, 1;
  AssertLe \0, 0;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 <= 0 failed
    1     2 assertLe
END
 }

#latest:;
if (1)                                                                          ##AssertGt
 {Start 1;
  Mov 0, 1;
  AssertGt \0, 2;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 >  2 failed
    1     2 assertGt
END
 }

#latest:;
if (1)                                                                          ##AssertGe
 {Start 1;
  Mov 0, 1;
  AssertGe \0, 2;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 >= 2 failed
    1     2 assertGe
END
 }

#latest:;
if (1)                                                                          ##AssertTrue
 {Start 1;
  AssertFalse 0;
  AssertTrue  0;
  my $e = &$ee(suppressOutput=>1, trace=>1);
  is_deeply $e->out, <<END;
    1     0     1   assertFalse
AssertTrue 0 failed
    1     2 assertTrue
    2     1     1    assertTrue
END
 }

#latest:;
if (1)                                                                          ##AssertFalse
 {Start 1;
  AssertTrue  1;
  AssertFalse 1;
  my $e = &$ee(suppressOutput=>1, trace=>1);

  is_deeply $e->out, <<END;
    1     0     1    assertTrue
AssertFalse 1 failed
    1     2 assertFalse
    2     1     1   assertFalse
END
 }

#latest:;
if (1)                                                                          # Temporary variable
 {my $s = Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  Out $a;
  Out $b;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
END
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Call
 {Start 1;
  my $a = Array "aaa";
  Dump;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Stack trace:
    1     2 dump
END
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Call ##ParamsPut ##ParamsGet
 {Start 1;
  my $a = Array "aaa";
  my $i = Mov 1;
  my $v = Mov 11;
  ParamsPut 0, $a;
  ParamsPut 1, $i;
  ParamsPut 2, $v;
  my $set = Procedure 'set', sub
   {my $a = ParamsGet 0;
    my $i = ParamsGet 1;
    my $v = ParamsGet 2;
    Mov [$a, \$i, 'aaa'], $v;
    Return;
   };
  Call $set;
  my $V = Mov [$a, \$i, 'aaa'];
  AssertEq $v, $V;
  Out [$a, \$i, 'aaa'];
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
11
END
 }

#latest:;
if (1)                                                                          ##Alloc ##Clear
 {Start 1;
  my $a = Array "aaa";
  Clear $a, 10, 'aaa';
  my $e = &$ee(suppressOutput=>1, maximumAreaSize=>10);
  is_deeply $e->heap(1), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
 }

#latest:;
if (1)                                                                          ##Block ##Good ##Bad
 {Start 1;
  Block
   {my ($start, $good, $bad, $end) = @_;
    Out 1;
    Jmp $good;
   }
  Good
   {Out 2;
   },
  Bad
   {Out 3;
   };
  Out 4;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
4
END
 }

#latest:;
if (1)                                                                          ##Block
 {Start 1;
  Block
   {my ($start, $good, $bad, $end) = @_;
    Out 1;
    Jmp $bad;
   }
  Good
   {Out 2;
   },
  Bad
   {Out 3;
   };
  Out 4;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
3
4
END
 }

#latest:;
if (1)                                                                          ##Procedure
 {Start 1;
  for my $i(1..10)
   {Out $i;
   };
  IfTrue 0,
  Then
   {Out 99;
   };
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
3
4
5
6
7
8
9
10
END
  is_deeply $e->outLines, [1..10];
 }

#latest:;
if (0)                                                                          # Double write - needs rewrite of double write detection
 {Start 1;
  Mov 1, 1;
  Mov 2, 1;
  Mov 3, 1;
  Mov 3, 1;
  Mov 1, 1;
  my $e = &$ee(suppressOutput=>0);
  ok keys($e->doubleWrite->%*) == 2;                                            # In area 0, variable 1 was first written by instruction 0 then again by instruction 1 once.
 }

#latest:;
if (1)                                                                          # Pointless assign
 {Start 1;
  Add 2,  1, 1;
  Add 2, \2, 0;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->pointlessAssign, { 1=>  1 };
 }

#latest:;
if (0)                                                                          # Not read
 {Start 1;
  my $a = Mov 1;
  my $b = Mov $a;
  my $e = &$ee(suppressOutput=>1);
  ok $e->notRead->{0}{1} == 1;                                                  # Area 0 == stack, variable 1 == $b generated by instruction 1
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Call
 {Start 1;
  my $set = Procedure 'set', sub
   {my $a = ParamsGet 0;
    Out $a;
   };
  ParamsPut 0, 1;  Call $set;
  ParamsPut 0, 2;  Call $set;
  ParamsPut 0, 3;  Call $set;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
3
END
 }

#latest:;
if (1)                                                                          # Invalid address
 {Start 1;
  Mov 1, \0;
  my $e = &$ee(suppressOutput=>1);
  ok $e->out =~ m"Cannot assign an undefined value";
 }

#latest:;
if (1)                                                                          ##LoadArea ##LoadAddress
 {Start 1;
  my $a = Array "array";
  my $b = Mov 2;
  my $c = Mov 5;
  my $d = LoadAddress $c;
  my $f = LoadArea    [$a, \0, 'array'];

  Out $d;
  Out $f;

  Mov [$a, \$b, 'array'], 22;
  Mov [$a, \$c, 'array'], 33;
  Mov [$f, \$d, 'array'], 44;

  my $e = &$ee(suppressOutput=>1, maximumAreaSize=>6);

  is_deeply $e->out, <<END;
2
1
END

  is_deeply $e->heap(1), [undef, undef, 44, undef, undef, 33] if $testSet <= 2;
  is_deeply $e->heap(1), [0,     0,     44, 0,     0,     33] if $testSet  > 2;
  is_deeply $e->widestAreaInArena, [4,5];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  ShiftUp [$a, 0, 'array'], 99;

  my $e = &$ee(suppressOutput=>0);
  is_deeply $e->heap(1), [99, 0, 1, 2];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  ShiftUp [$a, 1, 'array'], 99;

  my $e = &$ee(suppressOutput=>0);
  is_deeply $e->heap(1), [0, 99, 1, 2];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  ShiftUp [$a, 2, 'array'], 99;

  my $e = &$ee(suppressOutput=>0);
  is_deeply $e->heap(1), [0, 1, 99, 2];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  ShiftUp [$a, 3, 'array'], 99;

  my $e = &$ee(suppressOutput=>0);
  is_deeply $e->heap(1), [0, 1, 2, 99];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  Mov [$a, $_-1, 'array'], 10*$_ for 1..7;
  ShiftUp [$a, 2, 'array'], 26;

  my $e = &$ee(suppressOutput=>1, maximumAreaSize=>8);
  is_deeply $e->heap(1), bless([10, 20, 26, 30, 40, 50, 60, 70], "array");
 }

#latest:;
if (1)                                                                          ##ShiftDown
 {Start 1;
  my $a = Array "array";
  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 99;
  Mov [$a, 2, 'array'], 2;

  my $b = ShiftDown [$a, \1, 'array'];
  Out $b;

  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->heap(1), [0, 2];
  is_deeply $e->out, <<END;
99
END
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Jeq ##Jne ##Jle ##Jlt ##Jge ##Jgt
 {Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  Mov [$a, 0, 'aaa'], $b;
  Mov [$b, 0, 'bbb'], 99;

  For
   {my ($i, $check, $next, $end) = @_;
    my $c = Mov [$a, \0, 'aaa'];
    my $d = Mov [$c, \0, 'bbb'];
    Jeq $next, $d, $d;
    Jne $next, $d, $d;
    Jle $next, $d, $d;
    Jlt $next, $d, $d;
    Jge $next, $d, $d;
    Jgt $next, $d, $d;
   } 3;

  my $e = &$ee(suppressOutput=>1);

  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
  is_deeply $e->heap(1), [2];
  is_deeply $e->heap(2), [99];
 }

#latest:;
if (1)                                                                          ##JTrue ##JFalse
 {Start 1;
  my $a = Mov 1;
  Block
   {my ($start, $good, $bad, $end) = @_;
    JTrue $end, $a;
    Out 1;
   };
  Block
   {my ($start, $good, $bad, $end) = @_;
    JFalse $end, $a;
    Out 2;
   };
  Mov $a, 0;
  Block
   {my ($start, $good, $bad, $end) = @_;
    JTrue $end, $a;
    Out 3;
   };
  Block
   {my ($start, $good, $bad, $end) = @_;
    JFalse $end, $a;
    Out 4;
   };
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
3
END
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov
 {Start 1;
  my $a = Array 'aaa';
  my $b = Mov 2;                                                                # Location to move to in a

  For
   {my ($i, $check, $next, $end) = @_;
    Mov [$a, \$b, 'aaa'], 1;
    Jeq $next, [$a, \$b, 'aaa'], 1;
   } 3;

  my $e = &$ee(suppressOutput=>1);

  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed";
  is_deeply $e->heap(1), [undef, undef, 1] if $testSet <= 2;
  is_deeply $e->heap(1), [0,     0,     1] if $testSet  > 2;
 }

#latest:;
if (1)                                                                          ##Alloc
 {Start 1;

  For                                                                           # Allocate and free several times to demonstrate area reuse
   {my ($i) = @_;
    my $a = Array 'aaaa';
    Mov [$a, 0, 'aaaa'], $i;
    Free $a, 'aaaa';
    Dump;
   } 3;

  my $e = &$ee(suppressOutput=>1);

  is_deeply $e->counts,                                                         # Several allocations and frees
   {array=>3, dump=>3, free=>3, inc=>3, jGe=>4, jmp=>3, mov=>4
   };
  is_deeply $e->out, <<END;
Stack trace:
    1     8 dump
Stack trace:
    1     8 dump
Stack trace:
    1     8 dump
END
 }

#latest:;
if (1)                                                                          ##Resize
 {Start 1;
  my $a = Array 'aaa';
  Mov [$a, 0, 'aaa'], 1;
  Mov [$a, 1, 'aaa'], 2;
  Mov [$a, 2, 'aaa'], 3;
  Resize $a, 2, "aaa";
  ArrayDump $a;
  my $e = &$ee(suppressOutput=>1);

  is_deeply $e->heap(1), [1, 2];
  is_deeply eval($e->out), [1,2];
 }

#latest:;
if (1)                                                                          ##Trace ##Then ##Else
 {Start 1;
  Trace 1;
  IfEq 1, 2,
  Then
   {Mov 1, 1;
    Mov 2, 1;
   },
  Else
   {Mov 3, 3;
    Mov 4, 4;
   };
  IfEq 2, 2,
  Then
   {Mov 1, 1;
    Mov 2, 1;
   },
  Else
   {Mov 3, 3;
    Mov 4, 4;
   };
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
Trace: 1
    1     0     1         trace
    2     1     1           jNe
    3     5     1         label
    4     6     1           mov  [1, 3, stackArea] = 3
    5     7     1           mov  [1, 4, stackArea] = 4
    6     8     1         label
    7     9     1           jNe
    8    10     1           mov  [1, 1, stackArea] = 1
    9    11     1           mov  [1, 2, stackArea] = 1
   10    12     1           jmp
   11    16     1         label
END
  my $E = &$ee(suppressOutput=>1);
  is_deeply $E->out, <<END;
Trace: 1
    1     0     1         trace
    2     1     1           jNe
    3     5     1         label
    4     6     1           mov  [1, 3, stackArea] = 3
    5     7     1           mov  [1, 4, stackArea] = 4
    6     8     1         label
    7     9     1           jNe
    8    10     1           mov  [1, 1, stackArea] = 1
    9    11     1           mov  [1, 2, stackArea] = 1
   10    12     1           jmp
   11    16     1         label
END

  is_deeply scalar($e->notExecuted->@*), 6;
  is_deeply scalar($E->notExecuted->@*), 6;
 }

#latest:;
if (1)                                                                          ##Watch
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  my $c = Mov 3;
  Watch $b;
  Mov $a, 4;
  Mov $b, 5;
  Mov $c, 6;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Change at watched arena: 0, area: 1(stackArea), address: 1
    1     6 mov
Current value: 2 New value: 5
END
 }

#latest:;
if (1)                                                                          ##ArraySize ##ForArray ##Array ##Nop
 {Start 1;
  my $a = Array "aaa";
    Mov [$a, 0, "aaa"], 1;
    Mov [$a, 1, "aaa"], 22;
    Mov [$a, 2, "aaa"], 333;

  my $n = ArraySize $a, "aaa";
  Out "Array size:", $n;
  ArrayDump $a;

  ForArray
   {my ($i, $e, $check, $next, $end) = @_;
    Out $i; Out $e;
   }  $a, "aaa";

  Nop;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(1), [1, 22, 333];
  is_deeply $e->out, <<END if $testSet <= 2;
Array size: 3
bless([1, 22, 333], "aaa")
0
1
1
22
2
333
END
  is_deeply $e->out, <<END if $testSet  > 2;
Array size: 3
[1, 22, 333]
0
1
1
22
2
333
END
 }

#latest:;
if (1)                                                                          # Small array
 {Start 1;
  my $a = Array "array";
  my @a = qw(6 8 4 2 1 3 5 7);
  Push $a, $_, "array" for @a;                                                  # Load array
  ArrayDump $a;
  my $e = &$ee(suppressOutput=>1, maximumAreaSize=>9);
  is_deeply $e->heap(1),  [6, 8, 4, 2, 1, 3, 5, 7];
 }

#latest:;
if (1)                                                                          ##ArrayDump ##Mov
 {Start 1;
  my $a = Array "aaa";
  Mov [$a, 0, "aaa"], 1;
  Mov [$a, 1, "aaa"], 22;
  Mov [$a, 2, "aaa"], 333;
  ArrayDump $a;
  my $e = &$ee(suppressOutput=>1);

  is_deeply eval($e->out), [1, 22, 333];

  #say STDERR $e->block->codeToString;
  is_deeply $e->block->codeToString, <<'END' if $testSet == 1;
0000     array           \0             3
0001       mov [\0, 0, 3, 0]             1
0002       mov [\0, 1, 3, 0]            22
0003       mov [\0, 2, 3, 0]           333
0004  arrayDump           \0
END

  is_deeply $e->block->codeToString, <<'END' if $testSet == 2;
0000     array [undef, \0, 3, 0]  [undef, 3, 3, 0]  [undef, 0, 3, 0]
0001       mov [\0, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
0002       mov [\0, 1, 3, 0]  [undef, 22, 3, 0]  [undef, 0, 3, 0]
0003       mov [\0, 2, 3, 0]  [undef, 333, 3, 0]  [undef, 0, 3, 0]
0004  arrayDump [undef, \0, 3, 0]  [undef, 0, 3, 0]  [undef, 0, 3, 0]
END
 }

#latest:;
if (1)                                                                          ##MoveLong
 {my $N = 10;
  Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  For
   {my ($i, $Check, $Next, $End) = @_;
    Mov [$a, \$i, "aaa"], $i;
    my $j = Add $i, 100;
    Mov [$b, \$i, "bbb"], $j;
   } $N;

  MoveLong [$b, \2, 'bbb'], [$a, \4, 'aaa'], 3;

  my $e = &$ee(suppressOutput=>1, maximumAreaSize=>11);
  is_deeply $e->heap(1), [0 .. 9];
  is_deeply $e->heap(2), [100, 101, 4, 5, 6, 105 .. 109];
 }

#      0     1     2
#     10    20    30
# 5=0   15=1  25=2  35=3

#latest:;
if (1)                                                                          ##ArrayIndex ##ArrayCountLess ##ArrayCountGreater
 {Start 1;
  my $a = Array "aaa";
  Mov [$a, 0, "aaa"], 10;
  Mov [$a, 1, "aaa"], 20;
  Mov [$a, 2, "aaa"], 30;

  Out ArrayIndex       ($a, 30), ArrayIndex       ($a, 20), ArrayIndex       ($a, 10), ArrayIndex       ($a, 15);
  Out ArrayCountLess   ($a, 35), ArrayCountLess   ($a, 25), ArrayCountLess   ($a, 15), ArrayCountLess   ($a,  5);
  Out ArrayCountGreater($a, 35), ArrayCountGreater($a, 25), ArrayCountGreater($a, 15), ArrayCountGreater($a,  5);

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
3 2 1 0
3 2 1 0
0 1 2 3
END
 }

#latest:;
if (1)                                                                          ##Tally ##For
 {my $N = 5;
  Start 1;
  For
   {Tally 1;
    my $a = Mov 1;
    Tally 2;
    Inc $a;
    Tally 0;
   } $N;
  my $e = Execute;

  is_deeply $e->tallyCount, 2 * $N;
  is_deeply $e->tallyCounts, { 1 => {mov => $N}, 2 => {inc => $N}};
 }

#latest:;
if (1)                                                                          ##TraceLabels
 {my $N = 5;
  Start 1;
  TraceLabels 1;
  For
   {my $a = Mov 1;
    Inc $a;
   } $N;
  my $e = &$ee(suppressOutput=>1);

  is_deeply $e->out, <<END;
TraceLabels: 1
Label
    1     2 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1    11 label
END
 }

#latest:;
if (1)                                                                          ##Random ##RandomSeed
 {Start 1;
  RandomSeed 1;
  my $a = Random 10;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  ok $e->out =~ m(\A\d\Z);
 }

#latest:;
if (1)                                                                          # Local variable
 {Start 1;
  my $a = Mov 1;
  Out $a;
  my $e = &$ee(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
END
 }
}

#latest:;
if (1)                                                                          ##GenerateMachineCode ##GenerateMachineCodeDisAssembleExecute ##disAssemble
 {Start 1;
  my $a = Mov 1;
  my $g = GenerateMachineCode;
  is_deeply dump($g), 'pack("H*","0000002300000000000000000000017f000000010000007f000000000000007f")';

  my $d = disAssemble $g;
     $d->assemble;
  is_deeply $d->codeToString, <<'END';
0000       mov [undef, \0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
END
  my $e =  GenerateMachineCodeDisAssembleExecute;
  is_deeply $e->block->codeToString, <<'END';
0000       mov [undef, \0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
END
 }

#latest:;
if (1)                                                                          # String memory
 {Start 1;
  my $a = Array "aaa";
  Push $a,  1,  "aaa";
  Push $a,  2,  "aaa";
  Push $a,  3,  "aaa";
  my $b = Array "bbb";
  Push $b, 11,  "bbb";
  Push $b, 22,  "bbb";
  Push $b, 33,  "bbb";
  my $b3 = Pop $b, "bbb";
  my $b2 = Pop $b, "bbb";
  my $b1 = Pop $b, "bbb";
  my $a3 = Pop $a, "aaa";
  my $a2 = Pop $a, "aaa";
  my $a1 = Pop $a, "aaa";

  Out $a1;
  Out $a2;
  Out $a3;
  Out $b1;
  Out $b2;
  Out $b3;

  $memoryTechnique = \&setStringMemoryTechnique;
  my $e = Execute(suppressOutput=>1);
#  say STDERR $e->out;
  is_deeply $e->out, <<END;
1
2
3
11
22
33
END

  my $E = GenerateMachineCodeDisAssembleExecute(suppressOutput=>1);
  is_deeply $E->out, <<END;
1
2
3
11
22
33
END
 }

=pod
(\A.{80})\s+(#.*\Z) \1\2
say STDERR '  is_deeply $e->out, <<END;', "\n", $e->out, "END"; exit;
=cut
