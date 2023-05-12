# Zero

![Test](https://github.com/philiprbrenan/zero/workflows/Test/badge.svg)

A minimal [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) and [emulator](https://en.wikipedia.org/wiki/Emulator) for the Zero [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) programming language.

Includes an implementation of N-Way [trees](https://en.wikipedia.org/wiki/Tree_(data_structure)) using [code](https://en.wikipedia.org/wiki/Computer_program) written in the Zero [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) programming language: assiduously optimized through exhaustive
testing, ready for realization in [Silicon](https://en.wikipedia.org/wiki/Silicon) as an [integrated circuit](https://en.wikipedia.org/wiki/Integrated_circuit) rather than as software on a
conventional [CPU](https://en.wikipedia.org/wiki/Central_processing_unit) so that large, extremely fast, associative memories can be
manufactured on an industrial scale.

Open the __Actions__ [tab](https://en.wikipedia.org/wiki/Tab_key) to see the [code](https://en.wikipedia.org/wiki/Computer_program) in action on [Ubuntu](https://ubuntu.com/download/desktop) and [Windows Services for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux) for [Ubuntu](https://ubuntu.com/download/desktop) on windows.

The initial idea is to produce a small CPU which implements just the
instructions needed to implement the algorithm.  The small CPU will then be
replicated across an [fpga](https://en.wikipedia.org/wiki/Field-programmable_gate_array) so that the [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) can be queried in parallel.

Only one [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) will be used: typically mapping 64 [bit](https://en.wikipedia.org/wiki/Bit) keys into 64 [bit](https://en.wikipedia.org/wiki/Bit) data. It
will be useful to add additional data at the front of the keys such as data
length, data position, [process](https://en.wikipedia.org/wiki/Process_management_(computing)) id, [userid](https://en.wikipedia.org/wiki/User_identifier), time stamp etc. As the keys are
sorted in the [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)), [trees](https://en.wikipedia.org/wiki/Tree_(data_structure)) with similar prefixes will tend to collect together
so we can compress out the common prefix of the keys in each node to make
better use of [memory](https://en.wikipedia.org/wiki/Computer_memory). 
Strings longer than 64 bits can be processed in pieces with each piece prefixed
by the [string](https://en.wikipedia.org/wiki/String_(computer_science)) id and the position in the [string](https://en.wikipedia.org/wiki/String_(computer_science)).  Incoming [strings](https://en.wikipedia.org/wiki/String_(computer_science)) can be made
unique by assigning a unique 64 [bit](https://en.wikipedia.org/wiki/Bit) number to each prefix of the [string](https://en.wikipedia.org/wiki/String_(computer_science)) so that
a second such [string](https://en.wikipedia.org/wiki/String_(computer_science)) can be easily recognized.  Once such a long [string](https://en.wikipedia.org/wiki/String_(computer_science)) has
been represented by a unique number it can be located in one descent through
the [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)); although a single traversal of the [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) will no longer yield such [strings](https://en.wikipedia.org/wiki/String_(computer_science)) in alphabetic order.

All communications with the chip will be done via tcp .  Incoming read requests
can be done in parallel as long as there are processors left to assign work to.
An update will have to wait for all existing finds to finish while stalling all
trailing actions until the update is complete.

Associative lookups are the [sine qua non](https://en.wikipedia.org/wiki/Sine_qua_non) of all [Turing](https://en.wikipedia.org/wiki/Alan_Turing) complete programming languages.
This arrangement should produce very fast associative lookups - much faster
than can be performed by any generic system reliant on external software. Usage
of power and [integrated circuit](https://en.wikipedia.org/wiki/Integrated_circuit) surface area should be reduced by having a minimal CPU to
perform the lookups. Being able to deliver such lookups faster than can be
done with conventional software solutions might prove profitable in much the
same way as graphics chips and other chips used at scale.

Memory is addressed via named areas which act as flexible [arrays](https://en.wikipedia.org/wiki/Dynamic_array) with the usual
indexing, push, pop, index, iteration, resizing and scan operations.  Each
procedure has its own stack frame implemented as a stack frame area, parameter
area and return results area. Each area can grow as much as is needed to hold
data.  Additional [user](https://en.wikipedia.org/wiki/User_(computing)) [memory](https://en.wikipedia.org/wiki/Computer_memory) areas can be allocated and freed as necessary.
Communication with other systems can be achieved by reading and writing to [arrays](https://en.wikipedia.org/wiki/Dynamic_array) with predetermined names.

Well known locations are represented by character == non numeric area ids.
Stack frames, parameters and return areas are represented by negative area ids.

References can represent constants via a scalar with zero levels of
dereferencing; direct addresses by scalars with one level of dereferencing, and
indirect addresses by scalars with two levels of dereferencing.  A reference
consisting of an area, an offset within an area and an area name are
represented as an [array](https://en.wikipedia.org/wiki/Dynamic_array) reference with three entries. A reference to a location
in the current stack frame is represented as a single scalar with the
appropriate levels of dereferencing.  The area name is used to confirm that the
area being processed is the one that should be being processed.

If you would like to be involved with this interesting and potentially
lucrative project, please raise an issue saying so!

## Emulator:

The [emulator](https://en.wikipedia.org/wiki/Emulator) converts a Perl representation of the [assembly](https://en.wikipedia.org/wiki/Assembly_language) source [code](https://en.wikipedia.org/wiki/Computer_program) to
executable instructions and then executes these instructions.

[Documentation](https://metacpan.org/dist/Zero-Emulator/view/Emulator.pod)

## N-Way-Tree

An implementation of N-Way-Trees in Zero assembler.

[Documentation](https://metacpan.org/dist/Zero-Emulator/view/NWayTree.pod)

Can you reduce the number of instructions required to perform ```107``` inserts
into an N-Way-Tree? Please raise an issue if you can stating your terms for
your enhancememt.

```
  add               => 159,
  array             => 247,
  arrayCountGreater => 2,
  arrayCountLess    => 262,
  arrayIndex        => 293,
  dec               => 30,
  inc               => 726,
  jEq               => 894,
  jGe               => 648,
  jLe               => 461,
  jLt               => 565,
  jmp               => 878,
  jNe               => 908,
  mov               => 7619,
  moveLong          => 171,
  not               => 631,
  resize            => 161,
  shiftUp           => 300,
  subtract          => 501,
```

# The Zero [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) programming language

## Hello World

"Hello World" in the Zero [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) programming language:

```
  Start 1;

  Out "hello World";

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, ["hello World"];
```

```Start``` starts a [program](https://en.wikipedia.org/wiki/Computer_program) using a specified version of the language.

```Out``` writes a message to the ```out``` channel.

```Execute``` causes the [program](https://en.wikipedia.org/wiki/Computer_program) to be assembled and then executed.  The execution results are stored in the [Perl](http://www.perl.org/) data structure returned by this instruction.

## Addresses

Each [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) instruction can potentially affect a target [memory](https://en.wikipedia.org/wiki/Computer_memory) location specified by
the target operand known as the "left hand" address.  Each [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) instruction can potentially read zero, one or two source operands to locate the
data to be processed by the instruction.

Each address indexes an [array](https://en.wikipedia.org/wiki/Dynamic_array) in [memory](https://en.wikipedia.org/wiki/Computer_memory). Each [array](https://en.wikipedia.org/wiki/Dynamic_array) has a non unique name to
confirm that we are reading or writing to the right kind of [memory](https://en.wikipedia.org/wiki/Computer_memory). 

## Left hand addresses

```
  [Array, address, name]

  Mov [1, 2, 'array name'], 99

```

A left hand address specifies the address of a location in an [array](https://en.wikipedia.org/wiki/Dynamic_array) in [memory](https://en.wikipedia.org/wiki/Computer_memory). Left hand addresses always occur first in the written specification of an
instruction.  In the example above, the value 99 is being moved to location 2
in [array](https://en.wikipedia.org/wiki/Dynamic_array) 1 operating under the name of 'array name'.

If the [array](https://en.wikipedia.org/wiki/Dynamic_array) number is preceded by ```\``` as in ```\1``` then the number of
the [array](https://en.wikipedia.org/wiki/Dynamic_array) will be retrieved from location ```1``` the current stack frame. This
mechanism allows for indirect addressing of [array](https://en.wikipedia.org/wiki/Dynamic_array) names.

Likewise the index of the location in the [array](https://en.wikipedia.org/wiki/Dynamic_array) can either be specified as a
direct number as in ```2``` or indirectly as ```\2```.

The name of the [array](https://en.wikipedia.org/wiki/Dynamic_array) is used to check that we are accessing the expected type
of [array](https://en.wikipedia.org/wiki/Dynamic_array).  If the name does not match the expected name for the [array](https://en.wikipedia.org/wiki/Dynamic_array) being
accessed an error message will be written to the out channel and the execution
of the [program](https://en.wikipedia.org/wiki/Computer_program) will be terminated.

An address can also be specified as just as ```n``` meaning at location ```n```
in the current stack frame, or ```\n``` indicating an indirect location in the
current stack frame.

## Right hand addresses

### Right hand addresses as constants

```
  [Array, address, name]

  Mov 3, 99

```

The example above moves the constant 99 to the location 3 in the current stack
frame.

### Right hand addresses as indexes

```
  [Array, address, name]

  Mov 3, \4

```

The example above moves the contents of location 4 in the current stack frame
to location 3 in the current stack frame.

## Instructions

[The instruction set](https://metacpan.org/dist/Zero-Emulator/view/Emulator.pod)

## Macro Preprocessor

Every [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) needs a macro preocessor to generate [code](https://en.wikipedia.org/wiki/Computer_program) from macro
specifications as writing each instruction by hand is hard work. Using a [preprocessor](https://en.wikipedia.org/wiki/Preprocessor) saves programmer time by allowing common instruction sequences to
be captured as macros which can then be called upon as needed to generate the [code](https://en.wikipedia.org/wiki/Computer_program) for an application. The Zero [assembler](https://en.wikipedia.org/wiki/Assembly_language#Assembler) programming languages uses [Perl](http://www.perl.org/) as
its macro [preprocessor](https://en.wikipedia.org/wiki/Preprocessor). 

For documentation see: [CPAN](https://metacpan.org/pod/Zero::Emulator)