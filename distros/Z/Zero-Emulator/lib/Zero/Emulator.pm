#!/usr/bin/perl -I../lib/ -Ilib
#-------------------------------------------------------------------------------
# Assemble and execute code written in the Zero programming language.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Pointless adds and subtracts by 0. Perhaps we should flag adds and subtracts by 1 as well so we can have an instruction optimized for these variants.
# Assign needs to know from whence we got the value so we can write a better error message when it is no good
# Count number of ways an if statement actually goes.
use v5.30;
package Zero::Emulator;
our $VERSION = 20230514;                                                        # Version
use warnings FATAL=>qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
eval "use Test::More tests=>79" unless caller;

makeDieConfess;

my sub maximumInstructionsToExecute {1e6}                                       # Maximum number of subroutines to execute

sub execute(%)                                                                  # Execute a block of code.
 {my (%options) = @_;                                                           # Execution options

  my $exec=                 genHash("Zero::Emulator::Execution",                # Execution results
    calls=>                 [],                                                 # Call stack
    block=>                 $options{code},                                     # Block of code to be executed
    count=>                 0,                                                  # Executed instructions count
    counts=>                {},                                                 # Executed instructions by name counts
    tally=>                 0,                                                  # Tally executed instructions in a bin of this name
    tallyCount=>            0,                                                  # Executed instructions tally count
    tallyCounts=>           {},                                                 # Executed instructions by name tally counts
    tallyTotal=>            {},                                                 # Total instructions executed in each tally
    instructionPointer=>    0,                                                  # Current instruction
    memory=>                {},                                                 # Memory contents at the end of execution
    memoryType=>            {},                                                 # Memory contents at the end of execution
    rw=>                    {},                                                 # Read / write access to memory
    read=>                  {},                                                 # Records whether a memory address was ever read allowing us to find all the unused locations
    notReadAddresses=>      {},                                                 # Memory addresses never read
    out=>                   [],                                                 # The out channel
    doubleWrite=>           {},                                                 # Source of double writes {instruction number} to count - an existing value was overwritten before it was used
    pointlessAssign=>       {},                                                 # Location already has the specified value
    suppressOutput=>        $options{suppressOutput},                           # If true the Out instruction will only write to the execution out array but not to stdout as well.
    stopOnError=>           $options{stopOnError},                              # Stop on non fatal errors if true
    trace=>                 $options{trace},                                    # Trace all statements
    tracePoints=>           undef,                                              # Trace changes in execution flow
    printNotRead=>          $options{NotRead},                                  # Memory locations never read
    printDoubleWrite=>      $options{doubleWrite},                              # Double writes: earlier instruction number to later instruction number
    printPointlessAssign=>  $options{pointlessAssign},                          # Pointless assigns {instruction number} to count - address already has the specified value
    watch=>                 {},                                                 # Addresses to watch for changes
    instructionCounts=>     {},                                                 # The number of times each actual instruction is executed
    lastAssignArea=>        undef,                                              # Last assignment performed - area
    lastAssignAddress=>     undef,                                              # Last assignment performed - address
    lastAssignValue=>       undef,                                              # Last assignment performed - value
    lastAssignBefore=>      undef,                                              # Prior value of memory area before assignment
   );
 }

my sub Code(%)                                                                  # A block of code
 {my (%options) = @_;                                                           # Parameters

  genHash("Zero::Emulator::Code",                                               # Description of a call stack entry
    assembled=>     undef,                                                      # Needs to be assembled unless this field is true
    code=>          [],                                                         # An array of instructions
    variables=>     AreaStructure("Variables"),                                 # Variables in this block of code
    labels=>        {},                                                         # Label name to instruction
    labelCounter=>  0,                                                          # Label counter used to generate unique labels
    files=>         [],                                                         # File number to file name
    procedures=>    {},                                                         # Procedures defined in this block of code
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
      action=>         $options{action      },                                  # Instruction name
      number=>         $options{number      },                                  # Instruction sequence number
      source=>         $options{source      },                                  # Source memory address
      source2=>        $options{source2     },                                  # Secondary source memory address
      target=>         $options{target      },                                  # Target memory address
      target2=>        $options{target2     },                                  # Secondary target memory address
      line=>           $line,                                                   # Line in source file at which this instruction was encoded
      file=>           fne $fileName,                                           # Source file in which instruction was encoded
      context=>        stackTrace(),                                            # The call context in which this instruction was created
      executed=>       0,                                                       # The number of times this instruction was executed
    );
    return $i;
   }
 }

sub Zero::Emulator::Code::Instruction::contextString($$$)                       #P Stack trace back for this instruction.
 {my ($i, $exec, $title) = @_;                                                  # Instruction, execution environment, title
  @_ == 3 or confess "Three parameters";
  my @s;
  push @s, $title;
  if (! $exec->suppressOutput)
   {for my $c($i->context->@*)
     {push @s, sprintf "    at %s line %d", $$c[0], $$c[1];
     }
   }
  @s
 }

sub AreaStructure($@)                                                           # Describe a data structure mapping a memory area.
 {my ($structureName, @names) = @_;                                             # Structure name, fields names

  my $d = genHash("Zero::Emulator::AreaStructure",                              # Description of a data structure mapping a memory area
    structureName=>  $structureName,                                            # Name of the structure
    fieldOrder=>     [],                                                        # Order of the elements in the structure, in effect, giving the offset of each element in the data structure
    fieldNames=>     {},                                                        # Maps the names of the fields to their offsets in the structure
    instructions3=>   [],                                                       # The variable instruction associated with this variable
   );
  $d->field($_) for @names;                                                     # Add the field descriptions
  $d
 }

my sub isScalar($)                                                              # Check whether an element is a scalar or an array
 {my ($value) = @_;                                                             # Parameters
  ! ref $value;
 }

sub Zero::Emulator::AreaStructure::count($)                                     #P Add a field to a data structure.
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

my sub RefRight($)                                                              # Record a reference to a right address
 {my ($r) = @_;                                                                 # Reference
  @_ == 1 or confess "One parameter required formatted as either a address or an [area, address, name]";
  ref($r) and ref($r) !~ m(\A(array|scalar|ref)\Z)i and confess "Scalar or reference required, not: ".dump($r);

  if (ref($r) =~ m(array)i)
   {my ($area, $address, $name) = @$r;
     defined($area) and !defined($name) and confess "Name required for address specification: in [Area, address, name]";
    !defined($area) and  defined($name) and confess "Area required for address specification: in [Area, address, name]";
    isScalar($address) and defined($area) || defined($name) and confess "Constants cannot have an associated area";

    return genHash("Zero::Emulator::RefRight",
      area=>      $area,
      address=>   $address,
      name=>      $name,
      variable=>  1,
     );
   }
  else
   {return genHash("Zero::Emulator::RefRight",
      area=>      undef,
      address=>   $r,
      name=>      'stackArea',
      variable=>  0,
     );
   }
 }

my sub RefLeft($)                                                               # Record a reference to a left address
 {my ($r) = @_;                                                                 # Reference
  @_ == 1 or confess "One parameter required formatted as either a address or an [area, address, name]";

  ref($r) and ref($r) !~ m(\A(array|scalar|ref)\Z)i and confess "Scalar or reference required";

  if (ref($r) =~ m(array)i)
   {my ($area, $address, $name) = @$r;
     defined($area) and !defined($name) and confess "Name required for area: in {area, address, name]";
    !defined($area) and  defined($name) and confess "Area required for name: in {area, address, name]";

    return genHash("Zero::Emulator::RefLeft",
      area=>      $area,
      address=>   $address,
      name=>      $name,
     );
   }
  else
   {return genHash("Zero::Emulator::RefLeft",
      area=>      undef,
      address=>   $r,
      name=>      'stackArea',
     );
   }
 }

sub Zero::Emulator::Reference::print($)                                         #P Print the value of an address.
 {my ($ref) = @_;                                                               # Reference specification
  @_ == 1 or confess "One parameter";
  my $a  = dump($ref->area);
  my $l  = dump($ref->address);
  my $s  = "Reference area: $a, address: $l";
  say STDERR $s;
 }

sub Zero::Emulator::Address::print($$)                                          #P Print the value of an address in the current execution.
 {my ($address, $exec) = @_;                                                    # Address specification
  @_ == 2 or confess "Two parameters";
  my $e  = $exec;
  my $m  = $e->memory;
  my $t  = $e->memoryType;
  my $a  = $address->area;
  my $l  = $address->address;
  my $s  = "Address area: $a";
     $s .= "(".($$t{$a} // "unknown")."), ";
     $s .= "address: $l";
 }

sub Zero::Emulator::Address::get($$)                                            #P Get the value of the specified address in memory in the specified execution environment.
 {my ($address, $exec) = @_;                                                    # Address specification
  @_ == 2 or confess "Two parameters";
  my $e = $exec;
  my $m = $e->memory;
  my $a = $address->area;
  my $l = $address->address;
  $$m{$a}[$l];
 }

sub Zero::Emulator::Address::at($$)                                             #P Reference to the specified address in memory of current execution environment.
 {my ($address, $exec) = @_;                                                    # Address specification
  @_ == 2 or confess "Two parameters";
  my $e = $exec;
  my $m = $e->memory;
  my $a = $address->area;
  my $l = $address->address;
  \$$m{$a}[$l]
 }

sub Zero::Emulator::Procedure::call($)                                          #P Call a procedure.  Arguments are supplied by the L<ParamsPut> and L<ParamsGet> commands, return values are supplied by the L<ReturnPut> and L<ReturnGet> commands.
 {my ($procedure) = @_;                                                         # Procedure description
  @_ == 1 or confess "One parameter";
  Zero::Emulator::Call($procedure->target);
 }

sub Zero::Emulator::Code::registers($)                                          #P Allocate registers.
 {my ($code, $number) = @_;                                                     # Code block, number of registers required
  @_ == 1 or confess "One parameter";
  $code->variables->registers
 }

sub Zero::Emulator::Code::assemble($%)                                          #P Assemble a block of code to prepare it for execution.
 {my ($Block, %options) = @_;                                                   # Code block, assembly options
  return $Block if $Block->assembled;                                           # Already assembled
  my $code = $Block->code;                                                      # The code to be assembled
  my $vars = $Block->variables;                                                 # The variables referenced by the code

  my %labels;                                                                   # Load labels
  my $stackFrame = AreaStructure("Stack");                                      # The current stack frame we are creating variables in

  for my $c(keys @$code)                                                        # Labels
   {my $i = $$code[$c];
    $i->number = $c;
    next unless $i->action eq "label";
    $labels{$i->source->address} = $i;                                          # Point label to instruction
   }

  for my $c(keys @$code)                                                        # Target jump and call instructions
   {my $i = $$code[$c];
    next unless $i->action =~ m(\A(j|call))i;
    if (my $l = $i->target->address)                                            # Label
     {if (my $t = $labels{$l})                                                  # Found label
       {$i->target = RefRight($t->number - $c);                                 # Relative jump
       }
      else
       {my $a = $i->action;
        confess "No target for $a to label: $l";
       }
     }
   }

  $Block->labels = {%labels};                                                   # Labels created during assembly
  $Block->assembled = time;                                                     # Time of assembly
  $Block
 }

#D1 Execution

sub Zero::Emulator::Execution::areaContent($$)                                  #P Content of an area containing a address in memory in the specified execution.
 {my ($exec, $address) = @_;                                                    # Execution environment, address specification
  @_ == 2 or confess "Two parameters";
  my $e = $exec;
  my $m = $e->memory;
  my $a = isScalar($address) ? $address : $$m{$exec->stackArea}[$$address];     # Dereference area
  my $A = $$m{$a};
  $exec->stackTraceAndExit("Invalid area: ".dump($a)."\n".dump($e->memory)) unless defined $A;
  @$A
 }

sub Zero::Emulator::Execution::dumpMemory($)                                    #P Dump memory.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $memory = $exec->memory;
  my @m;
  for my $area(sort {$a <=> $b} keys %$memory)
   {next if $area =~ m(\Astack\Z)i;
    my $l = dump($$memory{$area});
    $l = substr($l, 0, 100) if length($l) > 100;
    push @m, "$area=$l";
   }

  @m
 }

sub Zero::Emulator::Execution::analyzeExecutionResultsLeast($%)                 #P Analyze execution results for least used code.
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

sub Zero::Emulator::Execution::analyzeExecutionResultsMost($%)                  #P Analyze execution results for most used code.
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

sub Zero::Emulator::Execution::analyzeExecutionNotRead($%)                      #P Analyze execution results for variables never read.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @t;
  my $n = $exec->notRead;
  for my $areaK(sort keys %$n)
   {my $area = $$n{$areaK};
    for my $addressK(sort keys %$area)
     {my $address = $$area{$addressK};
      push @t, $exec->block->code->[$addressK]->contextString
       ($exec, "Not read from area: $areaK, address: $addressK in context:");
     }
   }
  @t;
 }

sub Zero::Emulator::Execution::analyzeExecutionResultsDoubleWrite($%)           #P Analyze execution results - double writes.
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

sub Zero::Emulator::Execution::analyzeExecutionResults($%)                      #P Analyze execution results.
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

sub Zero::Emulator::Execution::check($$$)                                       #P Check that a user area access is valid.
 {my ($exec, $area, $name) = @_;                                                # Execution environment, area, expected area name
  @_ == 3 or confess "Three parameters";
  if ($area and $area =~ m(\A\d+\Z))
   {my $Name = $exec->memoryType->{$area};
    if (!defined $Name)
     {$exec->stackTraceAndExit("Attempting to access unnamed area: $area");
      return;
     }
    if ($name ne $Name)
     {$exec->stackTraceAndExit("Attempting to access area: $Name using: $name");
     }
   }
 }

sub Zero::Emulator::Execution::getMemory($$$;$%)                                #P Get from memory.
 {my ($exec, $area, $address, $name, %options) = @_;                            # Execution environment, area, address, expected name of area, options
  @_ < 3 and confess "At least three parameters";
  $exec->check($area, $name);
  my $g = $exec->get($area, $address);
  my $n = $name // 'unknown';
  if (!defined($g) and !defined($options{undefinedOk}))
   {$exec->stackTraceAndExit("Undefined memory accessed at area: $area ($n), address: $address\n");
   }
  $g
 }

sub Zero::Emulator::Execution::get($$$)                                         #P Get from memory.
 {my ($exec, $area, $address) = @_;                                             # Execution environment, area, address
  @_ == 3 or confess "Three parameters";
  $exec->memory->{$area}[$address];
 }


sub Zero::Emulator::Execution::set($$$)                                         #P Set the value of an address at the specified address in memory in the current execution environment.
 {my ($exec, $address, $value) = @_;                                            # Execution environment, address specification, value
  @_ == 3 or confess "Three parameters";
  my $e = $exec;
  my $m = $e->memory;
  my $a = $address->area;
  my $l = $address->address;
  $exec->lastAssignArea    = $a;
  $exec->lastAssignAddress = $l;
  $exec->lastAssignValue   = $value;
  $exec->lastAssignBefore  = $$m{$a}[$l];

  $$m{$a}[$l] = $value;
 }

sub Zero::Emulator::Execution::stackArea($)                                     #P Current stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->calls->[-1]->stackArea;                                                # Stack area
 }

sub Zero::Emulator::Execution::address($$$$)                                    #P Record a reference to memory.
 {my ($exec, $area, $address, $name) = @_;                                      # Execution environment, area, address in area, memory
  @_ == 4 or confess "Four parameters";
  genHash("Zero::Emulator::Address",                                            # Address memory
    area=>      $area,                                                          # Area in memory
    address=>   $address,                                                       # Address within area
    name=>      $name // 'stackArea',                                           # Name of area
   );
 }

sub Zero::Emulator::Execution::stackTrace($;$)                                  #P Create a stack trace.
 {my ($exec, $title) = @_;                                                      # Execution environment, title
  my $i = $exec->currentInstruction;
  my $s = $exec->suppressOutput;                                                # Suppress file and line numbers in dump to facilitate automated testing
  my @t;
  push @t, $i->contextString($exec, $title//"Stack trace");

  for my $j(reverse keys $exec->calls->@*)
   {my $c = $exec->calls->[$j];
    my $i = $c->instruction;
    push @t, sprintf "%5d  %4d %s", $j+1, $i->number+1, $i->action if $s;
    push @t, sprintf "%5d  %4d %-16s at %s line %d",
      $j+1, $i->number+1, $i->action, $i->file, $i->line       unless $s;
   }

  @t
 }

sub Zero::Emulator::Execution::stackTraceAndExit($$%)                           #P Create a stack trace and exit from the emulated program.
 {my ($exec, $title, %options) = @_;                                            # Execution environment, title, options
  @_ >= 2 or confess "At least two parameters";

  my @t = $exec->stackTrace($title);
  push $exec->out->@*, @t;
  my $t = join "\n", @t;

  if (!$exec->suppressOutput)
   {confess $t if $options{confess};
    say STDERR $t;
   }

  $exec->instructionPointer = undef;                                            # Execution terminates as soon as undefined instruction is encountered
  $t
 }

my $allocs = 0; my $allocsStacked = 0;                                          # Normal arrays allocated by the user, stacked allocations are made to support subroutine calling, parameter passing, result returning.

sub Zero::Emulator::Execution::allocMemory($$;$)                                #P Create the name of a new memory area.
 {my ($exec, $name, $stacked) = @_;                                             # Execution environment, name of allocation, stacked if true
  if ($stacked)
   {my $a = $allocsStacked--;
    $exec->memory->{$a} = bless [], $name;
    $exec->memoryType->{$a} = $name;
    return $a
   }
  my $a = ++$allocs;
  $exec->memory    ->{$a} = bless [], $name;
  $exec->memoryType->{$a} = $name;
  $a
 }

sub Zero::Emulator::Execution::setMemoryType($$$)                               #P Set the type of a memory area - a name that can be used to confirm the validity of reads and writes to that array represented by that area.
 {my ($exec, $area, $name) = @_;                                                # Execution environment, area name, name of allocation
  @_ == 3 or confess "Three parameters";
  $exec->memoryType->{$area} = $name;
  $exec
 }

sub Zero::Emulator::Execution::notRead()                                        #P Record the unused memory locations in the current stack frame.
 {my ($exec) = @_;                                                              # Parameters
  my $area = $exec->stackArea;
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

sub Zero::Emulator::Execution::rwWrite($$$)                                     #P Observe write to memory.
 {my ($exec, $area, $address) = @_;                                             # Area in memory, address within area
  my $P = $exec->rw->{$area}{$address};
  if (defined($P))
   {my $M = $exec->memory->{$area}[$address];                                   # If the memory address is zero we will assume that it has been cleared rather than set.
    if ($M)
     {my $Q = $exec->currentInstruction;
      my $p = $P->contextString($exec, "Previous write");
      my $q = $Q->contextString($exec, "Current  write");
      $exec->doubleWrite->{$p}{$q}++;
     }
   }
  $exec->rw->{$area}{$address} = $exec->currentInstruction;
 }

sub Zero::Emulator::Execution::markAsRead($$$)                                  #P Mark a memory address as having been read from.
 {my ($exec, $area, $address) = @_;                                             # Area in memory, address within area
  @_ == 3 or confess "Three parameters";
  delete $exec->rw->{$area}{$address};                                          # Clear last write operation
 }

sub Zero::Emulator::Execution::rwRead($$$)                                      #P Observe read from memory.
 {my ($exec, $area, $address) = @_;                                             # Area in memory, address within area
  @_ == 3 or confess "Three parameters";
  if (defined(my $a = $exec->rw->{$area}{$address}))                            # Can only read from locations that actually have something in them
   {$exec->markAsRead($area, $address);                                         # Clear last write operation
   $exec->read->{$area}{$address}++;                                            # Track reads
   }
 }

sub Zero::Emulator::Execution::left($$;$)                                       #P Address a memory address.
 {my ($exec, $ref, $extra) = @_;                                                # Reference, an optional extra offset to add or subtract to the final memory address
  @_ == 2 or @_ == 3 or confess "Two or three parameters";
  ref($ref) =~ m((RefLeft|RefRight)\Z)
    or confess "RefLeft or RefRight required, not: ".dump($ref);
  my $r    =  $ref->address;
  my $a    =  $r;
     $a    = \$r if isScalar $a;                                                # Interpret constants as direct memory locations
  my $area = $ref->area;
  my $x = $extra // 0;                                                          # Default is to use the address as supplied without locating a nearby address
  my $S = $exec->stackArea;                                                     # Current stack frame

  my sub invalid()
   {my ($p) = @_;                                                               # Parameters
    my $i = $exec->currentInstruction;
    my $l = $i->line;
    my $f = $i->file;
    $exec->stackTraceAndExit(
     "Invalid left area: ".dump($area)
     ." address: ".dump($a)
     .(defined($extra) ? " + extra: ".dump($extra) : ''))
   };

  my $M;                                                                        # Memory address
  if (isScalar $$a)
   {$M = $$a+$x
   }
  elsif (isScalar $$$a)
   {$exec->rwRead($S, $$$a);
    $M = $exec->getMemory($S, $$$a, $ref->name)+$x
   }
  else
   {invalid
   }

  if ($M < 0)                                                                   # Disallow negative addresses because they mean something special to Perl
   {$exec->stackTraceAndExit("Negative address for area: "
     .dump($area)
     .", address: ".dump($a)
     ." extra:".dump($x));
   }
  elsif (!defined($area))                                                       # Current stack frame
   {$exec->rwWrite(        $S, $M);
    return  $exec->address($S, $M, $ref->name);                                 # Stack frame
   }
  elsif (isScalar($area))
   {$exec->rwWrite(        $area, $M);
    return  $exec->address($area, $M, $ref->name)                               # Specified constant area
   }
  elsif (isScalar($$area))
   {$exec->rwRead (        $S, $$area);
    my $A = $exec->getMemory($S, $$area, $ref->name);
    $exec->rwWrite(        $A, $M);
    return  $exec->address($A, $M, $ref->name)                                  # Indirect area
   }
  invalid;
 }

sub Zero::Emulator::Execution::leftSuppress($$)                                 #P Indicate that a memory address has been read.
 {my ($exec, $ref) = @_;                                                        #  Execution environment, Reference
  @_ == 2 or confess "Two parameters";
  ref($ref) =~ m((RefLeft|RefRight)\Z) or confess "RefLeft or RefRight required";
  my $A     = $ref->address;
  my $area  = $ref->area;
  my $a = $A;
     $a = \$A if isScalar $a;                                                   # Interpret constants as direct memory locations

  my $m;
  my $memory = $exec->memory;
  my $stackArea = $exec->stackArea;

  if (isScalar $$a)                                                             # Direct
   {$m = $$a;
   }
  elsif (isScalar $$$a)                                                         # Indirect
   {$exec->rwRead  ($stackArea, $$$a);
    $m = $exec->get($stackArea, $$$a, $ref->name);
   }

  if (defined($m))
   {if (!defined($area))                                                        # Current stack frame
     {$exec->rwRead($stackArea, $m);
     }
   elsif (isScalar($area))                                                      # Direct area
     {$exec->rwRead($area, $m);
     }
   elsif (isScalar($$area))                                                     # Indirect area
     {$exec->rwRead(           $stackArea,  $area);
      $exec->rwRead($exec->get($stackArea, $$area), $m);
     }
   }
 }

sub Zero::Emulator::Execution::right($$)                                        #P Get a constant or a memory address.
 {my ($exec, $ref) = @_;                                                        # Location, optional area
  @_ == 2 or confess "Two parameters";
  ref($ref) =~ m((RefLeft|RefRight)\Z) or confess "RefLeft or RefRight required";
  my $a    = $ref->address;
  my $area = $ref->area;
  my $stackArea = $exec->stackArea;
  my $r; my $e = 0; my $tAddress; my $tArea;

  my sub invalid()
   {my $i = $exec->currentInstruction;
    my $l = $i->line;
    my $f = $i->file;
    $exec->stackTraceAndExit(
     "Invalid right area: ".dump($area)
     ." address: "    .dump($a)
     ." stack: "      .$exec->stackArea
     ." error: "      .dump($e)
     ." target Area: ".dump($tArea)
     ." address: "    .dump($tAddress));
   }

  if (isScalar($a))                                                             # Constant
   {#rwRead($area//&stackArea, $a) if $a =~ m(\A\-?\d+\Z);
    return $a if defined $a;                                                    # Attempting to read a address that has never been set is an error
    $exec->stackTraceAndExit("Undefined right address: ".dump($a));
   }

  my $m;
  my $memory = $exec->memory;

  if (isScalar($$a))                                                            # Direct
   {$m = $$a;
   }
  elsif (isScalar($$$a))                                                        # Indirect
   {$exec->rwRead($stackArea, $$$a);
    $m = $exec->getMemory($stackArea, $$$a);
   }
  else
   {$exec->stackTraceAndExit("Invalid right address: ".dump($a));
   }
  if (!defined($m))
   {invalid;
   }

  if (!defined($area))
   {$exec->rwRead($stackArea, $m);
    $r = $exec->getMemory($stackArea, $m);                                      # Indirect from stack area
    $e = 1; $tAddress = $m; $tArea = $exec->stackArea;
   }
  elsif (isScalar($area))
   {$exec->rwRead(        $area, $m);
    $r = $exec->getMemory($area, $m, $ref->name);                               # Indirect from stack area
    $e = 2; $tAddress = $m; $tArea = $area;
   }
  elsif (isScalar($$area))
   {$exec->rwRead($exec->stackArea, $$area);                                    # Mark the address holding the area as having been read
    if (defined(my $j = $$memory{$exec->stackArea}[$$area]))
     {$exec->rwRead($j, $m);
      $r = $$memory{$j}[$m];                                                    # Indirect from indirect area
      $r = $exec->getMemory($j, $m, $ref->name);                                # Indirect from stack area
      $e = 9; $tAddress = $m; $tArea = $j;
     }
   }
  invalid if !defined $r;
  $r
 }

sub Zero::Emulator::Execution::jumpOp($$$)                                      #P Jump to the target address if the tested memory area if the condition is matched.
 {my ($exec, $i, $check) = @_;                                                  # Execution environment, Instruction, check
  @_ == 3 or confess "Three parameters";
  $exec->instructionPointer = $i->number + $exec->right($i->target) if &$check; # Check if condition is met
 }

sub Zero::Emulator::Execution::assert1($$$)                                     #P Assert true or false.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = $exec->currentInstruction;
  my $a = $exec->right($i->source);
  unless($sub->($a))
   {$exec->stackTraceAndExit("Assert$test $a failed");
   }
 }

sub Zero::Emulator::Execution::assert($$$)                                      #P Assert generically.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = $exec->currentInstruction;
  my ($a, $b) = ($exec->right($i->source), $exec->right($i->source2));
  unless($sub->($a, $b))
   {$exec->stackTraceAndExit("Assert $a $test $b failed");
   }
 }

sub Zero::Emulator::Execution::assign($$$)                                      #P Assign - check for pointless assignments.
 {my ($exec, $target, $value) = @_;                                             # Execution environment, Target of assign, value to assign
  @_ == 3 or confess "Three parameters";
  ref($target) =~ m(Address)i or confess "Not an address: ".dump($target);

  my $a = $target->area;
  my $l = $target->address;
  my $n = $target->name//'unknown';

  my $N = $exec->memoryType->{$a};
  if (!defined $N)                                                              # Check that the area has a name
   {$exec->stackTraceAndExit("No name for area $a\n".dump($exec->memory)." address:".dump($target), confess=>1);
   }

  if ($n ne $N)                                                                 # Check that the area name matches the one supplied in the address
   {$exec->stackTraceAndExit
     ("Area name provided: '$n' does not match actual area name '$N' for area: $a");
   }

  if (!defined($value))                                                         # Check that the assign is not pointless
   {$exec->stackTraceAndExit
     ("Cannot assign an undefined value to area: $a ($n), address: $l");
   }
  else
   {my $currently = $target->get($exec);
    if (defined($currently) and $currently == $value)
     {$exec->pointlessAssign->{$exec->currentInstruction->number}++;
      if ($exec->stopOnError)
       {$exec->stackTraceAndExit("Pointless assign of: $currently to area: $a, at: $l");
       }
     }
   }

  if (defined $exec->watch->{$a}{$l})                                           # Watch for specified changes
   {my @s = $exec->stackTrace("Change at watched area: $a ($n), address: $l\n");
    push @s, join ' ', "Current value:", $exec->memory->{$a}[$l];
    push @s, join ' ', "New     value:", $value;
    push @s, $exec->dumpMemory;
    say STDERR join "\n", @s unless $exec->suppressOutput;
    push $exec->out->@*, @s;
   }

  $exec->set($target, $value);                                                  # Actually do the assign
 }

sub Zero::Emulator::Execution::allocateSystemAreas($)                           #P Allocate system areas for a new stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  (stackArea=>   $exec->allocMemory("stackArea", 1),
   params=>      $exec->allocMemory("params",    1),
   return=>      $exec->allocMemory("return",    1));
 }

sub Zero::Emulator::Execution::freeSystemAreas($$)                              #P Free system areas for the specified stack frame.
 {my ($exec, $c) = @_;                                                          # Execution environment, stack frame
  @_ == 2 or confess "Two parameters";
  $exec->notRead;                                                               # Record unread memory locations in the current stack frame
  delete $exec->memory->{$_} for $c->stackArea, $c->params, $c->return;
  $allocsStacked -= 3;
 }

sub Zero::Emulator::Execution::currentInstruction($)                            #P Locate current instruction.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->calls->[-1]->instruction;
 }

sub Zero::Emulator::Execution::createInitialStackEntry($)                       #P Create the initial stack frame.
 {my ($exec) = @_;                                                              # Execution environment

  push $exec->calls->@*,                                                        # Variables in initial stack frame
    stackFrame(
     $exec->block ? (variables=>  $exec->block->variables) : (),
     $exec->allocateSystemAreas);
  $exec
 }

sub Zero::Emulator::Execution::checkArrayName($$$)                              #P Check the name of an array.
 {my ($exec, $area, $name) = @_;                                                # Execution environment, array, array name
  @_ == 3 or confess "Three parameters";

  if (!defined($name))                                                          # A name is required
   {$exec->stackTraceAndExit("Array name required to size an array: ".dump($area));
    return 0;
   }

  my $Name = $exec->memoryType->{$area};                                        # Area has a name
  if (!defined($Name))
   {$exec->stackTraceAndExit("No name associated with array: $area");
    return 0;
   }

  if ($name ne $Name)                                                           # Name matches supplied name
   {$exec->stackTraceAndExit("Wrong name: $name for array with name: $Name");
    return 0;
   }

  1
 }

sub Zero::Emulator::Execution::locateAreaElement($$$)                           #P Locate an element in an array.
 {my ($exec, $area, $op) = @_;                                                  # Execution environment, array, operation
  my @a = $exec->memory->{$area}->@*;
  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {return $a + 1;
     }
   }
  0
 }

sub Zero::Emulator::Execution::countAreaElement($$$)                            #P Count the number of elements in array that meet some specification.
 {my ($exec, $area, $op) = @_;                                                  # Execution environment, array, operation
  my @a = $exec->memory->{$area}->@*;
  my $n = 0;

  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {++$n;
     }
   }

  $n
 }

sub Zero::Emulator::Code::execute($%)                                           #P Execute a block of code.
 {my ($block, %options) = @_;                                                   # Block of code, execution options

  $block->assemble;                                                             # Assemble if necessary

  my $exec = execute(code=>$block, %options);                                   # Execution environment

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
     {$exec->assert("==", sub {my ($a, $b) = @_; $a == $b})
     },

    assertNe=> sub                                                              # Assert not equals
     {$exec->assert("!=", sub {my ($a, $b) = @_; $a != $b})
     },

    assertLt=> sub                                                              # Assert less than
     {$exec->assert("< ", sub {my ($a, $b) = @_; $a <  $b})
     },

    assertLe=> sub                                                              # Assert less than or equal
     {$exec->assert("<=", sub {my ($a, $b) = @_; $a <= $b})
     },

    assertGt=> sub                                                              # Assert greater than
     {$exec->assert("> ", sub {my ($a, $b) = @_; $a >  $b})
     },

    assertGe=> sub                                                              # Assert greater
     {$exec->assert(">=", sub {my ($a, $b) = @_; $a >= $b})
     },

    assertFalse=> sub                                                           # Assert false
     {$exec->assert1("False", sub {my ($a) = @_; $a == 0})
     },

    assertTrue=> sub                                                            # Assert true
     {$exec->assert1("True", sub {my ($a) = @_; $a != 0})
     },

    array=> sub                                                                 # Create a new memory area and write its number into the address named by the target operand
     {my $i = $exec->currentInstruction;
      my $a = $exec->allocMemory($i->source);                                   # The reason for this allocation
      my $t = $exec->left($i->target);

      my $A = $exec->memory->{$a} = [];
      bless $A, $i->source;                                                     # Useful because dump then prints the type of each area for us
      $exec->assign($t, $a);
      $a
     },

    free=> sub                                                                  # Free the memory area named by the source operand
     {my $i = $exec->currentInstruction;
      my $area = $exec->right($i->target);                                      # Area
      my $name = $exec->right($i->source);

      if ($area !~ m(\A\d+\Z))                                                  # User free-able area
       {$exec->stackTraceAndExit("Attempting to allocate non user area: $area");
        return;
       }

      $exec->checkArrayName($area, $name);                                      # Check that the supplied array name matches what is actually in memory

      delete $exec->memory->{$area}                                             # Free correctly identified area
     },

    arraySize=> sub                                                             # Get the size of the specified area
     {my $i = $exec->currentInstruction;
      my $size = $exec->left ($i->target);                                      # Location to store size in
      my $area = $exec->right($i->source);                                      # Location of area
      my $name = $i->source2;                                                   # Name of area

      $exec->checkArrayName($area, $name);                                      # Check that the supplied array name matches what is actually in memory

      $exec->assign($size, scalar $exec->memory->{$area}->@*)                   # Size of area
     },

    arrayIndex=> sub                                                            # Place the 1 based index of the second source operand in the array referenced by the first source operand in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $a = $exec->right($i->source);                                         # Location of area
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->locateAreaElement($a, sub{$_[0] == $e}))         # Index of element
     },

    arrayCountGreater=> sub                                                     # Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $a = $exec->right($i->source);                                         # Location of area
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->countAreaElement($a, sub{$_[0] > $e}))           # Index of element
     },

    arrayCountLess=> sub                                                        # Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location
     {my $i = $exec->currentInstruction;
      my $x = $exec->left ($i->target);                                         # Location to store index in
      my $a = $exec->right($i->source);                                         # Location of area
      my $e = $exec->right($i->source2);                                        # Location of element

      $exec->assign($x, $exec->countAreaElement($a, sub{$_[0] < $e}))           # Index of element
     },

    resize=> sub                                                                # Resize an array
     {my $i = $exec->currentInstruction;
      my $size =  $exec->right($i->source);                                     # New size
      my $area =  $exec->right($i->target);                                     # Array to resize
      $exec->stackTraceAndExit("Attempting to resize non user area: $area")
        unless $area =~ m(\A\d+\Z);
      $#{$exec->memory->{$area}} = $size-1;
     },

    call=> sub                                                                  # Call a subroutine
     {my $i = $exec->currentInstruction;
      my $t = $i->target->address;                                              # Subroutine to call

      if (isScalar($t))
       {$exec->instructionPointer = $i->number + $t;                            # Relative call if we know where the subroutine is relative to the call instruction
       }
      else
       {$exec->instructionPointer = $t;                                         # Absolute call
       }
      push $exec->calls->@*,
        stackFrame(target=>$block->code->[$exec->instructionPointer],           # Create a new call stack entry
        instruction=>$i, variables=>$i->source->variables,
        $exec->allocateSystemAreas());
     },

    return=> sub                                                                # Return from a subroutine call via the call stack
     {my $i = $exec->currentInstruction;
      $exec->calls or $exec->stackTraceAndExit("The call stack is empty so I do not know where to return to");
      $exec->freeSystemAreas(pop $exec->calls->@*);
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
      my $m = join ' ', "Trace: $s";
      say STDERR           $m unless $exec->suppressOutput;
      push $exec->out->@*, $m;
     },

    tracePoints=> sub                                                           # Start trace points
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source) ? 1 : 0;
      $exec->tracePoints = $s;
      my $m = "TracePoints: $s";
      say STDERR           $m unless $exec->suppressOutput;
      push $exec->out->@*, $m;
     },

    tracePoint=> sub                                                            # Trace point
     {return unless $exec->tracePoints;
      my @s = $exec->stackTrace("Trace");
      say STDERR join "\n", @s unless $exec->suppressOutput;
      push $exec->out->@*, @s;
     },

    dump=> sub                                                                  # Dump memory
     {my $i = $exec->currentInstruction;
      my @m;
      if (ref($i->source) =~ m(Code)i)
       {$i->source->($exec);
        return;
       }

      push @m, $i->source // "Memory dump";
      push @m, $exec->dumpMemory;
      push @m, $exec->stackTrace;

      say STDERR join "\n", @m unless $exec->suppressOutput;
      push $exec->out->@*, @m;
     },

    dumpArray=> sub                                                             # Dump array in memory
     {my $i = $exec->currentInstruction;
      my @m;
      push @m, $i->source // "Array dump";
      my $a = $exec->right($i->target);
      push @m, dump($exec->memory->{$a});
      push @m, $exec->stackTrace;

      say STDERR join "\n", @m unless $exec->suppressOutput;
      push $exec->out->@*, @m;
     },

    dec=> sub                                                                   # Decrement locations in memory. The first address is incremented by 1, the next by two, etc.
     {my $i = $exec->currentInstruction;
      my $T = $exec->right($i->target);
      my $t = $exec->left($i->target);
      $exec->set($t, defined($t) ? $T-1 : -1);
     },

    inc=> sub                                                                   # Increment locations in memory. The first address is incremented by 1, the next by two, etc.
     {my $i = $exec->currentInstruction;
      my $T = $exec->right($i->target);
      my $t = $exec->left($i->target);
      $exec->set($t, defined($t) ? $T+1 : 1);
     },

    jmp=> sub                                                                   # Jump to the target address
     {my $i = $exec->currentInstruction;
      my $n = $i->number;
      my $r = $exec->right($i->target);
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
     },

    clear=> sub                                                                 # Clear the first bytes of an area as specified by the target operand
     {my $i = $exec->currentInstruction;
      my $n =  $exec->left($i->target);
      for my $a(0..$n->address-1)
       {my $A =  $exec->left(RefLeft([$i->target->area, $a, q(aaa)]));
        $exec->set($A, 0);
       }
     },

    leAddress=> sub                                                             # Load the address component of a reference
     {my $i = $exec->currentInstruction;
      my $s = $exec->left($i->source);
      my $t = $exec->left($i->target);
      $exec->assign($t, $s->address);
     },

    leArea=> sub                                                                # Load the area component of an address
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
       {my $S = RefRight [$s->area, \($s->address+$j), $s->name];
        my $T = RefLeft  [$t->area,   $t->address+$j,  $t->name];
        $exec->assign($exec->left($T), $exec->right($S));
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
      my $p = RefLeft([$exec->calls->[-2]->params, $i->source->address,
       'params']);
      my $t = $exec->left ($i->target);
      $exec->leftSuppress ($p);                                                 # The source will be read from
      my $s = $exec->left ($p);                                                 # The source has to be a left hand side because we want to address a memory area not get a constant
      $exec->assign($t, $s->get($exec));
     },

    paramsPut=> sub                                                             # Place a parameter in the current parameter block
     {my $i = $exec->currentInstruction;
      my $p = $i->target->area // $exec->calls->[-1]->params;
      my $r = RefLeft [$p, $i->target->address, 'params'];
      $exec->leftSuppress ($r);
      my $t = $exec->left ($r);
      my $s = $exec->right($i->source);
      $exec->assign($t, $s);
     },

    returnGet=> sub                                                             # Get a word from the return area
     {my $i = $exec->currentInstruction;
      my $p = $exec->calls->[-1]->return;                                       # Memory area
      my $t = $exec->left ($i->target);
      my $r = RefLeft([$p, \$i->source->address, 'return']);                    # The source will be read from
      $exec->leftSuppress($r);                                                  # The source will be read from
      my $s = $exec->left($r);                                                  # The source has to be a left hand side because we want to address a memory area not get a constant
      $exec->assign($t, $s->get($exec));
     },

    returnPut=> sub                                                             # Put a word into the return area
     {my $i = $exec->currentInstruction;
      my $p = $exec->calls->[-2]->return;
      my $t = $exec->left (RefLeft([$p, $i->target->address, q(return)]));
      my $s = $exec->right($i->source);
      $exec->assign($t, $s);
     },

    nop=> sub                                                                   # No operation
     {my ($i) = @_;                                                             # Instruction
     },

    out=> sub                                                                   # Write source as output to an array of words
     {my $i = $exec->currentInstruction;
      my $t = $exec->right($i->source);
      lll $t unless $exec->suppressOutput;
      push $exec->out->@*, $t;
     },

    pop=> sub                                                                   # Pop a value from the specified memory area if possible else confess
     {my $i = $exec->currentInstruction;
      my $s = $i->source;
      my $area = $i->source ? $exec->right($i->source) : &stackArea;            # Memory area to pop
      if (!defined($exec->memory->{$area}) or !$exec->memory->{$area}->@*)      # Stack not pop-able
        {$exec->stackTraceAndExit("Cannot pop area $area");
        }
      my $t = $exec->left($i->target);
      my $p = pop $exec->memory->{$area}->@*;
      $exec->assign($t, $p);                                                    # Pop from memory area into indicated memory address
     },

    push=> sub                                                                  # Push a value onto the specified memory area
     {my $i = $exec->currentInstruction;
      if ($i->target)
       {my $t = $exec->right($i->target);
        my $s = $exec->right($i->source);
        push $exec->memory->{$t}->@*, $s;
       }
      else
       {push $exec->memory->{&stackArea}->@*, right($i->source);
       }
     },

    shiftLeft=> sub                                                             # Shift left within an element
     {my $i = $exec->currentInstruction;
      $exec->leftSuppress ($i->target);                                         # Make sure there something to shift
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      $exec->assign($t, $t->get($exec) << $s);
     },

    shiftRight=> sub                                                            # Shift right within an element
     {my $i = $exec->currentInstruction;
      $exec->leftSuppress ($i->target);                                         # Make sure there something to shift
      my $t = $exec->left ($i->target);
      my $s = $exec->right($i->source);
      $exec->assign($t, $t->get($exec) >> $s);
     },

    shiftUp=> sub                                                               # Shift an element up in a memory area
     {my $i = $exec->currentInstruction;
      my $s = $exec->right($i->source);
      my $t = $exec->left($i->target);
      my $L = $exec->areaContent($t->area);                                     # Length of area
      my $l = $t->address;
      for my $j(reverse 1..$L-$l)
       {my $s = $exec->left($i->target, $j-1);
        my $t = $exec->left($i->target, $j);
        $exec->assign($t, $s->get($exec));
       }
      $exec->assign($t, $s);
     },

    shiftDown=> sub                                                             # Shift an element down in a memory area
     {my $i = $exec->currentInstruction;
      my $s = $exec->left($i->source);
      my $t = $exec->left($i->target);
      my $L = $exec->areaContent($s->area);                                     # Length of area
      my $l = $s->address;
      my $v = $s->get($exec);
      for my $j($l..$L-2)                                                       # Each element in specified range
       {my $S = $exec->left(RefLeft([$s->area, $j+1, $s->name]));
        my $T = $exec->left(RefLeft([$s->area, $j,   $s->name]));
        $exec->assign($T, $S->get($exec));
       }
      pop $exec->memory->{$s->area}->@*;
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
      $exec->watch->{$t->area}{$t->address}++;
     },
   );

  $exec->createInitialStackEntry;                                               # Variables in initial stack frame

  my $mi = $options{maximumInstructionsToExecute} //                            # Prevent run away executions
                    maximumInstructionsToExecute;
  for my $j(1..$mi)                                                             # Each instruction in the code until we hit an undefined instruction
   {last unless defined($exec->instructionPointer);
    my $i = $exec->block->code->[$exec->instructionPointer++];                  # Current instruction
            $exec->calls->[-1]->instruction = $i;
    last unless $i;
    if (my $a = $i->action)                                                     # Action
     {$exec->stackTraceAndExit(qq(Invalid instruction: "$a"\n))
        unless my $c = $instructions{$a};

      if ($a !~ m(\A(assert.*|label|tally|trace(Points?)?)\Z))                  # Omit instructions that are not tally-able
       {if (my $t = $exec->tally)                                               # Tally instruction counts
         {$exec->tallyCount++;
          $exec->tallyTotal->{$t}++;
          $exec->tallyCounts->{$t}{$a}++;
         }
        $exec->counts->{$a}++; $exec->count++;                                  # Execution instruction counts
       }

      $exec->lastAssignArea = $exec->lastAssignAddress = $exec->lastAssignValue = undef;
      $c->($i);                                                                 # Execute instruction

      $exec->instructionCounts->{$i->number}++;                                 # Execution count by actual instruction

      ++$i->executed;

      if ($exec->trace)                                                         # Trace changes to memory
       {my $e = $exec->instructionCounts->{$i->number};                         # Execution count for this instruction
        my $f = $exec->formatTrace;
        my $s = $exec->suppressOutput;
        my $a = $i->action;
        my $n = $i->number;
        my $m =  sprintf "%4d  %4d  %4d  %12s  %20s", $j, $n, $e, $a, $f;
           $m .= sprintf "  at %s line %d", $i->file, $i->line unless $s;
           $m .= "\n";
        say STDERR $m unless $s;
        push $exec->out->@*, $m;
       }

     }
    confess "Out of instructions after $j"if $j >= maximumInstructionsToExecute;
   }

  $exec->freeSystemAreas($exec->calls->[0]);                                    # Free first stack frame

  $exec
 }                                                                              # Execution results

sub Zero::Emulator::Execution::formatTrace($)                                   #P Describe last memory assignment.
 {my ($exec) = @_;                                                              # Execution
  return "" unless defined(my $area  = $exec->lastAssignArea);
  return "" unless defined(my $addr  = $exec->lastAssignAddress);
  return "" unless defined(my $type  = $exec->memoryType->{$area});
  return "" unless defined(my $value = $exec->lastAssignValue);
  my $B = $exec->lastAssignBefore;
  my $b = $B ? " was $B" : "";
  sprintf "[%d, %d, %s] = %d$b", $area, $addr, $type, $value;
 }

my $assembly;                                                                   # The current assembly

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
  (q(source), RefRight $s)
 }

my sub xSource2($)                                                              # Record a source argument
 {my ($s) = @_;                                                                 # Source expression
  (q(source2), RefRight $s)
 }

my sub xTarget($)                                                               # Record a target argument
 {my ($t) = @_;                                                                 # Target expression
  (q(target), RefLeft $t)
 }

sub Start($)                                                                    # Start the current assembly using the specified version of the Zero language.  At  the moment only version 1 works.
 {my ($version) = @_;                                                           # Version desired - at the moment only 1
  $version == 1 or confess "Version 1 is currently the only version available\n";
  $allocs = $allocsStacked = 0;
  $assembly = Code;                                                             # The current assembly
 }

sub Add($$;$)                                                                   # Add the source locations together and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"add", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Subtract($$;$)                                                              # Subtract the second source operand value from the first source operand value and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"subtract", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Array($)                                                                    # Create a new memory area and write its number into the address named by the target operand.
 {my ($name) = @_;                                                              # Name of allocation
  my $t = &Var();
  $assembly->instruction(action=>"array", target=>RefLeft($t), source=>$name);
  $t;
 }

sub Free($$)                                                                    # Free the memory area named by the target operand after confirming that it has the name specified on the source operand.
 {my ($target, $source) = @_;                                                   # Target area yielding the id of the area to be freed, source area yielding the name of the area to be freed
  $assembly->instruction(action=>"free", xTarget($target), xSource($source));
 }

sub ArraySize($$)                                                               # The current size of an array.
 {my ($area, $name) = @_;                                                       # Location of area, name of area
  my $t = &Var();
  $assembly->instruction(action=>"arraySize",                                   # Target - location to place the size in, source - address of the area, source2 - the name of the area which cannot be taken from the area of the first source operand because that area name is the name of the area that contains the location of the area we wish to work on.
    target=>RefLeft($t), xSource($area), source2=>$name);
  $t
 }

sub ArrayIndex($$;$) {                                                          # Find the 1 based index of the second source operand in the array referenced by the first source operand if it is present in the array else 0 into the target location.  The business of returning -1 leads to the inferno of try catch.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayIndex",
    target=>RefLeft($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayIndex",
    xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayCountLess($$;$) {                                                      # Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountLess",
    target=>RefLeft($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountLess",
    xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayCountGreater($$;$) {                                                   # Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountGreater",
    target=>RefLeft($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountGreater",
    xTarget($target), xSource($area), xSource2($element));
   }
 }

sub Call($)                                                                     # Call the subroutine at the target address.
 {my ($p) = @_;                                                                 # Procedure description
  $assembly->instruction(action=>"call",
    target=>RefLeft($p->target), source=>$p);
 }

sub Confess()                                                                   # Confess.
 {$assembly->instruction(action=>"confess");
 }

sub Dump(;$)                                                                    # Dump memory.
 {my ($title) = @_;                                                             # Title
  $assembly->instruction(action=>"dump", source=>$title);
 }

sub DumpArray($;$)                                                              # Dump an array.
 {my ($target, $title) = @_;                                                    # Array to dump, title of dump
  $assembly->instruction(action=>"dumpArray", target=>RefRight($target), source=>$title);
 }

sub Trace($)                                                                    # Trace.
 {my ($source) = @_;                                                            # Trace setting
  $assembly->instruction(action=>"trace", xSource($source));
 }

sub TracePoints($)                                                              # Enable trace points.
 {my ($source) = @_;                                                            # Trace points if true
  $assembly->instruction(action=>"tracePoints", xSource($source));
 }

sub TracePoint(%)                                                               #P Trace point - a point in the code where the flow of execution might change.
 {my (%options) = @_;                                                           # Parameters
  $assembly->instruction(action=>"tracePoint", %options);
 }

sub Dec($)                                                                      # Decrement the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"dec", xTarget($target))
 }

sub Inc($)                                                                      # Increment the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"inc", xTarget($target))
 }

sub Jmp($)                                                                      # Jump to a label.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"jmp", xTarget($target));
 }

sub Jle($$$)                                                                    # Jump to a target label if the first source field is less than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jlt($$$)                                                                    # Jump to a target label if the first source field is less than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jge($$$)                                                                    # Jump to a target label if the first source field is greater than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jgt($$$)                                                                    # Jump to a target label if the first source field is greater than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jeq($$$)                                                                    # Jump to a target label if the first source field is equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jEq",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jne($$$)                                                                    # Jump to a target label if the first source field is not equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jNe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub JFalse($$)                                                                  # Jump to a target label if the first source field is equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jFalse", xTarget($target), xSource($source));
 }

sub JTrue($$)                                                                   # Jump to a target label if the first source field is not equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jTrue", xTarget($target), xSource($source));
 }

sub Label($)                                                                    # Create a label.
 {my ($source) = @_;                                                            # Name of label
  $assembly->instruction(action=>"label", xSource($source));
 }

sub Clear($)                                                                    # Clear the first bytes of an area.  The area is specified by the first element of the address, the number of locations to clear is specified by the second element of the target address.
 {my ($target) = @_;                                                            # Target address, source address
  $assembly->instruction(action=>"clear", xTarget($target));
 }

sub LeAddress($;$) {                                                            # Load the address component.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"leAddress",
      target=>RefLeft($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"leAddress",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub LeArea($;$) {                                                               # Load the address component.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"leArea",
      target=>RefLeft($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"leArea",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub Mov($;$) {                                                                  # Copy a constant or memory address to the target address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"mov", target=>RefLeft($t),xSource($source));
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

sub MoveLong($$$)                                                               # Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.
 {my ($target, $source, $source2) = @_;                                         # Target of move, source of move, length of move
  $assembly->instruction(action=>"moveLong", xTarget($target),
    xSource($source), xSource2($source2));
 }

sub Not($) {                                                                    # Move and not.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"not", target=>RefLeft($t),xSource($source));
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

sub Nop()                                                                       # Do nothing (but do it well!).
 {$assembly->instruction(action=>"nop");
 }

sub Out($)                                                                      # Write memory contents to out.
 {my ($source) = @_;                                                            # Either a scalar constant or memory address to output
  $assembly->instruction(action=>"out", xSource($source))
 }

sub Procedure($$)                                                               # Define a procedure.
 {my ($name, $source) = @_;                                                     # Name of procedure, source code as a subroutine# $assembly->instruction(action=>"procedure", target=>$target, source=>$source);
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

sub ParamsGet($;$) {                                                            # Get a word from the parameters in the previous frame and store it in the current frame.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Memory address to place parameter in, parameter number
    my $p = &Var();
    $assembly->instruction(action=>"paramsGet",
      target=>RefLeft($p), xSource($source));
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

sub ParamsPut($$)                                                               # Put a word into the parameters list to make it visible in a called procedure.
 {my ($target, $source) = @_;                                                   # Parameter number, address to fetch parameter from
  $assembly->instruction(action=>"paramsPut",
    xTarget($target), xSource($source));
 }

sub Return()                                                                    # Return from a procedure via the call stack.
 {$assembly->instruction(action=>"return");
 }

sub ReturnGet($;$) {                                                            # Get a word from the return area and save it.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"returnGet",
      target=>RefLeft($p), xSource($source));
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

sub ReturnPut($$)                                                               # Put a word into the return area.
 {my ($target, $source) = @_;                                                   # Offset in return area to write to, memory address whose contents are to be placed in the return area
  $assembly->instruction(action=>"returnPut",
    xTarget($target), xSource($source));
 }

sub Resize($$)                                                                  # Resize the target area to the source size.
 {my ($target, $source) = @_;                                                   # Target address, source address
  $assembly->instruction(action=>"resize", xTarget($target), xSource($source));
 }

sub Pop(;$$) {                                                                  # Pop the memory area specified by the source operand into the memory address specified by the target operand.
  if (@_ == 0)                                                                  # Pop current stack frame into a local variable
   {my $p = &Var();
    my $i = $assembly->instruction(action=>"pop", target=>RefLeft($p));
    $i->source = undef;
    return $p;
   }
  elsif (@_ == 1)                                                               # Pop indicated area into a local variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"pop", target=>RefLeft($p),xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Pop indicated area into target address
    $assembly->instruction(action=>"pop", xTarget($target), xSource($source));
   }
  else
   {confess "Zero, One or two parameters required";
   }
 }

sub Push($;$) {                                                                 # Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Push a value onto the current stack frame
    $assembly->instruction(action=>"push", xSource($source));
   }
  elsif (@_ == 2)                                                               # Push a value onto the specified memory area
   {my ($target, $source) = @_;                                                 # Memory area to push to, memory containing value to push
    $assembly->instruction(action=>"push", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ShiftLeft($;$) {                                                            # Shift left within an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftLeft",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftRight($;$) {                                                           # Shift right with an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftRight",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftUp($;$)                                                                # Shift an element up one in an area.
 {my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftUp",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftDown($;$) {                                                            # Shift an element down one in an area.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"shiftDown",
      target=>RefLeft($p), xSource($source));
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

sub Watch($)                                                                    # Shift an element down one in an area.
 {my ($target) = @_;                                                            # Memory address to watch
  $assembly->instruction(action=>"watch", xTarget($target));
 }

sub Tally($)                                                                    # Counts instructions when enabled.
 {my ($source) = @_;                                                            # Tally instructions when true
  $assembly->instruction(action=>"tally", xSource($source));
 }

sub Then(&)                                                                     # Then block.
 {my ($t) = @_;                                                                 # Then block subroutine
  @_ == 1 or confess "One parameter";
  (then=>  $t)
 }

sub Else(&)                                                                     # Else block.
 {my ($e) = @_;                                                                 # Else block subroutine
  @_ == 1 or confess "One parameter";
  (else=>  $e)
 }

sub Ifx($$$%)                                                                   #P Execute then or else clause depending on whether two memory locations are equal.
 {my ($cmp, $a, $b, %options) = @_;                                             # Comparison, first memory address, second memory address, then block, else block
  confess "Then required" unless $options{then};
  if ($options{else})
   {my $else = label;
    my $end  = label;
    &$cmp($else, $a, $b);
      TracePoint level=>2;
      &{$options{then}};
      Jmp $end;
    setLabel($else);
      TracePoint level=>2;
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

sub IfFalse($%)                                                                 # Execute then clause if the specified memory address is zero representing false.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jne, $a, 0, %options);
 }

sub IfTrue($%)                                                                  # Execute then clause if the specified memory address is not zero representing true.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jeq, $a, 0, %options);
 }

sub IfEq($$%)                                                                   # Execute then or else clause depending on whether two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jne, $a, $b, %options);
 }

sub IfNe($$%)                                                                   # Execute then or else clause depending on whether two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jeq, $a, $b, %options);
 }

sub IfLt($$%)                                                                   # Execute then or else clause depending on whether two memory locations are less than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jge, $a, $b, %options);
 }

sub IfLe($$%)                                                                   # Execute then or else clause depending on whether two memory locations are less than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jgt, $a, $b, %options);
 }

sub IfGt($$%)                                                                   # Execute then or else clause depending on whether two memory locations are greater than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jle, $a, $b, %options);
 }

sub IfGe($$%)                                                                   # Execute then or else clause depending on whether two memory locations are greater than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jlt, $a, $b, %options);
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

sub Assert(%)                                                                   # Assert regardless.
 {my (%options) = @_;                                                           # Options
  $assembly->instruction(action=>"assert");
 }

sub AssertEq($$%)                                                               # Assert two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Eq", $a, $b);
 }

sub AssertNe($$%)                                                               # Assert two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ne", $a, $b);
 }

sub AssertLt($$%)                                                               # Assert two memory locations are less than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Lt", $a, $b);
 }

sub AssertLe($$%)                                                               # Assert two memory locations are less than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Le", $a, $b);
 }

sub AssertGt($$%)                                                               # Assert two memory locations are greater than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Gt", $a, $b);
 }

sub AssertGe($$%)                                                               # Assert are greater than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ge", $a, $b);
 }

sub AssertTrue($%)                                                              # Assert true.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("True", $a);
 }

sub AssertFalse($%)                                                             # Assert false.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("False", $a);
 }

sub For(&$%)                                                                    # For loop 0..range-1 or in reverse.
 {my ($block, $range, %options) = @_;                                           # Block, limit, options
  if (!exists $options{reverse})                                                # Ascending order
   {my $s = 0; my $e = $range;                                                  # Start, end
    ($s, $e) = @$range if ref($e) =~ m(ARRAY);                                  # Start, end as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Mov $s;
      setLabel($Check);                                                         # Check
      Jge  $End, $i, $e;
        TracePoint level=>2;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Inc $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
  else
   {my $s = $range; my $e = 0;                                                  # Start, end
    ($e, $s) = @$range if ref($e) =~ m(ARRAY);                                  # End, start as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Subtract $s, 1;
    Subtract $i, $s;
      setLabel($Check);                                                         # Check
      Jlt  $End, $i, $e;
        TracePoint level=>2;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Dec $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
 }

sub ForArray(&$$%)                                                              # For loop to process each element of the named area.
 {my ($block, $area, $name, %options) = @_;                                     # Block of code, area, area name, options
  my $e = ArraySize $area, $name;                                               # End
  my $s = 0;                                                                    # Start

  my ($Start, $Check, $Next, $End) = (label, label, label, label);

  setLabel($Start);                                                             # Start
  my $i = Mov $s;
    setLabel($Check);                                                           # Check
    Jge  $End, $i, $e;
      TracePoint level=>2;
      my $a = Mov [$area, \$i, $name];
      &$block($i, $a, $Check, $Next, $End);                                     # Block
    setLabel($Next);
    Inc $i;                                                                     # Next
    Jmp $Check;
  setLabel($End);                                                               # End
 }

sub Good(&)                                                                     # A good ending.
 {my ($good) = @_;                                                              # What to do on a good ending
  @_ == 1 or confess "One parameter";
  (good=>  $good)
 }

sub Bad(&)                                                                      # A bad ending.
 {my ($bad) = @_;                                                               # What to do on a bad ending
  @_ == 1 or confess "One parameter";
  (bad=>  $bad)
 }

sub Block(&%)                                                                   # Block of code that can either be restarted or come to a good or a bad ending.
 {my ($block, %options) = @_;                                                   # Block, options
  my ($Start, $Good, $Bad, $End) = (label, label, label, label);

  my $g = $options{good};
  my $b = $options{bad};

  setLabel($Start);                                                             # Start

  TracePoint level=>2;
  &$block($Start, $Good, $Bad, $End);                                           # Code of block

  if ($g)                                                                       # Good
   {Jmp $End;
    setLabel($Good);
    TracePoint level=>2;
    &$g;
   }

  if ($b)                                                                       # Bad
   {Jmp $End;
    setLabel($Bad);
    TracePoint level=>2;
    &$b;
   }
  setLabel($End);                                                               # End
 }

sub Var(;$)                                                                     #P Create a variable initialized to the specified value.
 {my ($value) = @_;                                                             # Value
  my $i = $assembly->registers;
  my $a = $assembly->variables;
  my $v = $a->count-1;
  my $c = $assembly->code->@*;
# $a->instructions->[$v] = $c;

  Mov $i, $value if defined $value;
  $i
 }

sub Execute(%)                                                                  # Execute the current assembly.
 {my (%options) = @_;                                                           # Options
  my $r = $assembly->execute(%options);                                         # Execute the code in the current assembly
  if (my $out = $options{out})
   {my $c = compareArraysAndExplain $r->out, $out;
    lll $c if $c;
    say STDERR dump($r->out) if $c;
    return 0 if $c;
   }
  if (my $memory = $options{memory})
   {my $E = dump $memory;
    my $G = dump $r->memory;
    my $e = [split "\n", $E];
    my $g = [split "\n", $G];
    my $c = compareArraysAndExplain $g, $e;
    lll "$c\n$G\n" if $c;
    return 0 if $c;
   }
  return $r;
 }

use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(Add AreaStructure Array ArrayIndex ArrayCountLess ArrayCountGreater Assert AssertEq AssertGe AssertGt AssertLe AssertLt AssertNe Bad Block Call Clear Confess Dec Dump DumpArray Else Execute For ForArray Free Good IfEq IfFalse IfGe IfGt IfLe IfLt IfNe IfTrue Ifx Inc Jeq Jge Jgt Jle Jlt Jmp Jne JTrue JFalse Label Mov MoveLong Nop Not Out ParamsGet ParamsPut Pop Procedure Push Resize Return ReturnGet ReturnPut ShiftDown ShiftLeft ShiftRight ShiftUp Start Subtract Tally Then Trace TracePoints Var Watch);
#say STDERR '@EXPORT_OK   = qw(', (join ' ', sort @EXPORT_OK), ')'; exit;
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

return 1 if caller;

Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

eval {goto latest};
sub is_deeply;
sub ok($;$);

# Tests

if (1)                                                                          # Address dereferencing
 {my $e = execute->createInitialStackEntry->setMemoryType(1, 'aaa');
  my $s = $e->stackArea;

  $e->set(RefLeft([ 1, 1, 'aaa']), 99);
  $e->set(RefLeft([$s, 2, $s]),     1);

  is_deeply $e->right(RefRight [1,  \1,  'aaa']), 99;
  is_deeply $e->right(RefRight [1, \\2,  'aaa']), 99;

  is_deeply $e->left (RefLeft  [1,  \1,  'aaa']), {address=>1, area=>1, name=>"aaa"};
  is_deeply $e->left (RefLeft  [1, \\2,  'aaa']), {address=>1, area=>1, name=>"aaa"};
 }

# Examples

#latest:;
if (1)                                                                          ##Out ##Start ##Execute
 {Start 1;
  Out "hello World";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["hello World"];
 }

#latest:;
if (1)                                                                          ##Nop
 {Start 1;
  Nop;
  ok Execute(out=>[]);
 }

#latest:;
if (1)                                                                          ##Mov
 {Start 1;
  my $a = Mov 2;
  Out $a;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
 }

#latest:;
if (1)
 {Start 1;                                                                      ##Mov
  my $a = Mov  3;
  my $b = Mov  $$a;
  my $c = Mov  \$b;
  Out $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [3];
 }

#latest:;
if (1)                                                                          ##Add
 {Start 1;
  my $a = Add 3, 2;
  Out  $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [5];
 }

#latest:;
if (1)                                                                          ##Add ##Subtract
 {Start 1;
  my $a = Subtract 4, 2;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
 }

#latest:;
if (1)                                                                          ##Dec
 {Start 1;
  my $a = Mov 3;
  Dec $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
 }

#latest:;
if (1)                                                                          ##Inc
 {Start 1;
  my $a = Mov 3;
  Inc $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [4];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [3, "", 1];
 }

#latest:;
if (1)                                                                          ##ShiftLeft
 {Start 1;
  my $a = Mov 1;
  ShiftLeft $a, $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
 }

#latest:;
if (1)                                                                          ##ShiftRight
 {Start 1;
  my $a = Mov 4;
  ShiftRight $a, 1;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2];
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
    Out  1;
    Jmp (my $d = label);
  setLabel($c);
    Out  2;
  setLabel($d);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2,1];
 }

#latest:;
if (1)                                                                          ##Label
 {Start 1;
  Mov 0, 0;
  my $a = setLabel;
    Out \0;
    Inc \0;
  Jlt $a, \0, 10;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [0..9];
 }

#latest:;
if (1)                                                                          ##Mov
 {Start 1;
  my $a = Array "aaa";
  Mov     [$a,  1, "aaa"],  11;
  Mov  1, [$a, \1, "aaa"];
  Out \1;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [11];
 }

#latest:;
if (1)                                                                          ##Call ##Return
 {Start 1;
  my $w = Procedure 'write', sub
   {Out 'aaa';
    Return;
   };
  Call $w;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["aaa"];
 }

#latest:;
if (1)                                                                          ##Call
 {Start 1;
  my $w = Procedure 'write', sub
   {my $a = ParamsGet 0;
    Out $a;
    Return;
   };
  ParamsPut 0, 'bbb';
  Call $w;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["bbb"];
 }

#latest:;
if (1)                                                                          ##Call ##ReturnPut ##ReturnGet
 {Start 1;
  my $w = Procedure 'write', sub
   {ReturnPut 0, "ccc";
    Return;
   };
  Call $w;
  ReturnGet \0, 0;
  Out \0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["ccc"];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [4];
 }

#latest:;
if (1)                                                                          ##Confess
 {Start 1;
  my $c = Procedure 'confess', sub
   {Confess;
   };
  Call $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Confess at:", "    2     3 confess", "    1     6 call"];
 }

#latest:;
if (1)                                                                          ##Push ##Pop
 {Start 1;
  my $a = Array "aaa";
  Push $a, 1;
  Push $a, 2;
  my $c = Pop $a;
  my $d = Pop $a;

  Out $c;
  Out $d;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out,    [2, 1];
  is_deeply $e->memory, { 1=>  []};
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov
 {Start 1;
  my $a = Array "alloc";
  my $b = Mov 99;
  my $c = Mov $a;
  Mov [$a, 0, 'alloc'], $b;
  Mov [$c, 1, 'alloc'], 2;
  ok Execute(memory=>  { 1=>  bless([99, 2], "alloc") });
 }

#latest:;
if (1)                                                                          ##Free
 {Start 1;
  my $a = Array "node";
  Free $a, "aaa";
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, [
  "Wrong name: aaa for array with name: node",
  "    1     2 free",
];
 }

#latest:;
if (1)                                                                          ##Free ##Dump
 {Start 1;
  my $a = Array "node";
  Out $a;
  Mov [$a, 1, 'node'], 1;
  Mov [$a, 2, 'node'], 2;
  Mov 1, [$a, \1, 'node'];
  Dump "dddd";
  Free $a, "node";
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, [
  1,
  "dddd",
  "-2=bless([], \"return\")",
  "-1=bless([], \"params\")",
  "0=bless([1, 1], \"stackArea\")",
  "1=bless([undef, 1, 2], \"node\")",
  "Stack trace",
  "    1     6 dump",
];
 }

#latest:;
if (1)                                                                          # Layout
 {Start 1;
  my $a = Mov 'A';
  my $b = Mov 'B';
  my $c = Mov 'C';
  Out $c;
  Out $b;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [qw(C B A)];
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
  is_deeply $e->out, ["Eq", "Le", "Ge"];
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
  is_deeply $e->out, ["Ne", "Le", "Lt"];
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
  is_deeply $e->out, ["Ne", "Ge", "Gt"];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1];
 }

#latest:;
if (1)                                                                          ##IfFalse ##True ##False
 {Start 1;
  IfFalse 1,
  Then
   {Out 1
   },
  Else
   {Out 0
   };
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [0];
 }

#latest:;
if (1)                                                                          ##ForLoop
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [0..9];
 }

#latest:;
if (1)                                                                          ##ForLoop
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10, reverse=>1;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [reverse 0..9];
 }

#latest:;
if (1)                                                                          ##ForLoop
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } [2, 10];
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2..9];
 }

#latest:;
if (1)                                                                          ##Assert
 {Start 1;
  Assert;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert failed", "    1     1 assert"];
 }

#latest:;
if (1)                                                                          ##AssertEq
 {Start 1;
  Mov 0, 1;
  AssertEq \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 == 2 failed", "    1     2 assertEq"];
 }

#latest:;
if (1)                                                                          ##AssertNe
 {Start 1;
  Mov 0, 1;
  AssertNe \0, 1;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 != 1 failed", "    1     2 assertNe"];
 }

#latest:;
if (1)                                                                          ##AssertLt
 {Start 1;
  Mov 0, 1;
  AssertLt \0, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 <  0 failed", "    1     2 assertLt"];
 }

#latest:;
if (1)                                                                          ##AssertLe
 {Start 1;
  Mov 0, 1;
  AssertLe \0, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 <= 0 failed", "    1     2 assertLe"];
 }

#latest:;
if (1)                                                                          ##AssertGt
 {Start 1;
  Mov 0, 1;
  AssertGt \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 >  2 failed", "    1     2 assertGt"];
 }

#latest:;
if (1)                                                                          ##AssertGe
 {Start 1;
  Mov 0, 1;
  AssertGe \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, ["Assert 1 >= 2 failed", "    1     2 assertGe"];
 }

#latest:;
if (1)                                                                          ##AssertTrue
 {Start 1;
  AssertFalse 0;
  AssertTrue  0;
  my $e = Execute(suppressOutput=>1, trace=>1);
  is_deeply $e->out,
[ "   1     0     1   assertFalse                      \n",
  "AssertTrue 0 failed",
  "    1     2 assertTrue",
  "   2     1     1    assertTrue                      \n"];
 }

#latest:;
if (1)                                                                          ##AssertFalse
 {Start 1;
  AssertTrue  1;
  AssertFalse 1;
  my $e = Execute(suppressOutput=>1, trace=>1);
  is_deeply $e->out,
[ "   1     0     1    assertTrue                      \n",
  "AssertFalse 1 failed",
  "    1     2 assertFalse",
  "   2     1     1   assertFalse                      \n"];

 }

#latest:;
if (1)                                                                          # Temporary variable
 {my $s = Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  Out $a;
  Out $b;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1..2];
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Call
 {Start 1;
  my $a = Array "aaa";
  Dump "dddd";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [
  "dddd",
  "-2=bless([], \"return\")",
  "-1=bless([], \"params\")",
  "0=bless([1], \"stackArea\")",
  "1=bless([], \"aaa\")",
  "Stack trace",
  "    1     2 dump",
];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [11];
 }

#latest:;
if (1)                                                                          ##Alloc ##Clear
 {Start 1;
  my $a = Array "aaa";
  Clear [$a, 10, 'aaa'];
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory->{1}, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1,2,4];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1,3,4];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1..10];
 }

#latest:;
if (1)                                                                          # Double write
 {Start 1;
  Mov 1, 1;
  Mov 2, 1;
  Mov 3, 1;
  Mov 3, 1;
  Mov 1, 1;
  my $e = Execute(suppressOutput=>1);
  is_deeply keys($e->doubleWrite->%*), 1;                                       # In area 0, variable 1 was first written by instruction 0 then again by instruction 1 once.
 }

#latest:;
if (1)                                                                          # Pointless assign
 {Start 1;
  Add 2,  1, 1;
  Add 2, \2, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->pointlessAssign, { 1=>  1 };
 }

#latest:;
if (0)                                                                          # Not read
 {Start 1;
  my $a = Mov 1;
  my $b = Mov $a;
  my $e = Execute(suppressOutput=>1);
  ok $e->notRead->{0}{1} == 1;                                                  # Area 0 == stack, variable 1 == $b generated by instruction 1
 }

#latest:;
if (1)                                                                          ##Alloc ##Mov ##Call
 {Start 1;
  my $set = Procedure 'set', sub
   {my $a = ParamsGet 0;
   };
  ParamsPut 0, 1;
  Call $set;
  ParamsPut 0, 1;
  Call $set;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [];
 }

#latest:;
if (1)                                                                          # Invalid address
 {Start 1;
  Mov 1, \0;
  my $e = Execute(suppressOutput=>1);
  my $t = join "\n", $e->out->@*;
  ok $t =~ m"Cannot assign an undefined value";
 }

#latest:;
if (1)                                                                          ##LeArea ##LeAddress
 {Start 1;
  my $a = Array "array";
  my $b = Mov 2;
  my $c = Mov 5;
  my $d = LeAddress $c;
  my $f = LeArea    [$a, \0, 'array'];
  Out $d;
  Out $f;
  Mov [$a, \$b, 'array'], 22;
  Mov [$a, \$c, 'array'], 33;
  Mov [$f, \$d, 'array'], 44;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out,    [2,1];
  is_deeply $e->memory, {1=>[undef, undef, 44, undef, undef, 33]};
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";
  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  ShiftUp [$a, 1, 'array'], 99;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory, {1=>[0, 99, 1, 2]};
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory, {1=>[0, 2]};
  is_deeply $e->out,    [99];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
  is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [2, 3];
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
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed";
  is_deeply $e->memory, {1=>  bless([undef, undef, 1], "aaa")};
 }

#latest:;
if (1)                                                                          ##Resize
 {Start 1;
  my $a = Array 'aaa';
  Mov [$a, 0, 'aaa'], 1;
  Mov [$a, 1, 'aaa'], 2;
  Mov [$a, 2, 'aaa'], 3;
  Resize $a, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory, {1=>  [1, 2]};
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
  my $e = Execute(suppressOutput=>1);
  is_deeply scalar($e->out->@*), 14;
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
  is_deeply $e->out,
[
  "Change at watched area: 0 (stackArea), address: 1\n",
  "    1     6 mov",
  "Current value: 2",
  "New     value: 5",
  "-2=bless([], \"return\")",
  "-1=bless([], \"params\")",
  "0=bless([4, 2, 3], \"stackArea\")",
];
 }

#latest:;
if (1)                                                                          ##ArraySize ##ForArray ##Array ##Nop
 {Start 1;
  my $a = Array "aaa";
    Mov [$a, 0, "aaa"], 1;
    Mov [$a, 1, "aaa"], 22;
    Mov [$a, 2, "aaa"], 333;
  my $n = ArraySize $a, "aaa";
  DumpArray $a, "AAAA";

  ForArray
   {my ($i, $e, $check, $next, $end) = @_;
    Out $i; Out $e;
   }  $a, "aaa";

  Nop;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {1=>[1, 22, 333]};

  is_deeply $e->out,
[ "AAAA",
  "bless([1, 22, 333], \"aaa\")",
  "Stack trace",
  "    1     6 dumpArray",
  0,
  1,
  1,
  22,
  2,
  333];
 }

#latest:;
if (1)                                                                          ##DumpArray ##Mov
 {Start 1;
  my $a = Array "aaa";
    Mov [$a, 0, "aaa"], 1;
    Mov [$a, 1, "aaa"], 22;
    Mov [$a, 2, "aaa"], 333;
  DumpArray $a, "AAAA";
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out,
 ["AAAA",
  "bless([1, 22, 333], \"aaa\")",
  "Stack trace",
  "    1     5 dumpArray",
];
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

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory,
{
  1 => bless([0 .. 9], "aaa"),
  2 => bless([100, 101, 4, 5, 6, 105 .. 109], "bbb"),
};
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

  Out ArrayIndex $a, 30;
  Out ArrayIndex $a, 20;
  Out ArrayIndex $a, 10;
  Out ArrayIndex $a, 15;

  Out ArrayCountLess $a, 35;
  Out ArrayCountLess $a, 25;
  Out ArrayCountLess $a, 15;
  Out ArrayCountLess $a,  5;

  Out ArrayCountGreater $a, 35;
  Out ArrayCountGreater $a, 25;
  Out ArrayCountGreater $a, 15;
  Out ArrayCountGreater $a,  5;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [3,2,1,0,  3,2,1,0, 0,1,2,3];
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
  is_deeply $e->tallyCounts,{ 1 => {mov => $N}, 2 => {inc => $N}};
 }

#latest:;
if (1)                                                                          ##TracePoints
 {my $N = 5;
  Start 1;
  TracePoints 1;
  For
   {my $a = Mov 1;
    Inc $a;
   } $N;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [
  "TracePoints: 1",
  "Trace",
  "    1     6 tracePoint",
  "Trace",
  "    1     6 tracePoint",
  "Trace",
  "    1     6 tracePoint",
  "Trace",
  "    1     6 tracePoint",
  "Trace",
  "    1     6 tracePoint",
];
 }
