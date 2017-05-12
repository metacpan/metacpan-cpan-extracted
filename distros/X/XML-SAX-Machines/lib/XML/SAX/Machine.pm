package XML::SAX::Machine;
{
  $XML::SAX::Machine::VERSION = '0.46';
}
# ABSTRACT: Manage a collection of SAX processors



use strict;

use constant has_named_regexp_character_classes => $] > 5.006000;

use Carp;
use UNIVERSAL;
use XML::SAX::EventMethodMaker qw( :all );
use XML::SAX::Machines;

## Tell the config stuff what options we'll be requesting, so we
## don't get typoes in this code.  Very annoying, but I mispelt it
## so often, that adding one statement like this seemed like a low
## pain solution, since testing options like this can be long and
## bothersome.
XML::SAX::Machines->expected_processor_class_options(qw(
    ConstructWithHashedOptions
));



sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my @options_if_any = @_ && ref $_[-1] eq "HASH" ? %{pop()} : ();
    my $self = bless { @options_if_any }, $class;

    $self->{Parts} = [];
    $self->{PartsByName} = {};  ## Mapping of names to parts

    $self->_compile_specs( @_ );

    ## Set this last in case any specs have handler "Exhaust"
    $self->set_handler( $self->{Handler} ) if $self->{Handler};

    return $self;
}


sub _find_part_rec {
    my $self = shift; 
    my ( $id ) = @_;

    if ( ref $id ) {
        return exists $self->{PartsByProcessor}->{$id}
            && $self->{PartsByProcessor}->{$id};
    }

    if ( $id =~ /^[+-]?\d+(?!\n)$/ ) {
        return undef
            if     $id >     $#{$self->{Parts}}
                || $id < - ( $#{$self->{Parts}} + 1 );
        return $self->{Parts}->[$id];
    }

    return $self->{PartsByName}->{$id}
        if exists $self->{PartsByName}->{$id};

    return undef;
}


sub find_part {
    my $self = shift; 
    my ( $spec ) = @_;

    return $self->{Handler} if $spec eq "Exhaust";

    my $part_rec;

    if ( 0 <= index $spec, "/" ) {
        ## Take the sloooow road...
        require File::Spec::Unix;
        croak "find_part() path not absolute: '$spec'"
            unless File::Spec::Unix->file_name_is_absolute( $spec );

        ## Cannonical-ize it, do /foo/../ => / conversion
        $spec = File::Spec::Unix->canonpath( $spec );
        1 while $spec =~ s{/[^/]+/\.\.(/|(?!\n\Z))}{$1};

        my @names = File::Spec::Unix->splitdir( $spec );
        pop @names while @names && ! length $names[-1];
        shift @names while @names && ! length $names[0];

        croak "invalid find_part() specification: '$spec'"
            unless File::Spec::Unix->file_name_is_absolute( $spec );

        my @audit_trail;
        my $proc = $self;
        for ( @names ) {
            push @audit_trail, $_;
            $part_rec = $proc->_find_part_rec( $_ );
            unless ( $part_rec ) {
                croak "find_path() could not find '",
                    join( "/", "", @audit_trail ),
                    "' in ", ref $self;
            }
            $proc = $part_rec->{Processor};
        }
    }
    else {
        $part_rec = $self->_find_part_rec( $spec );
    }

    croak "find_path() could not find '$spec' in ", ref $self
        unless $part_rec;

    my $proc = $part_rec->{Processor};

    ## Be paranoid here, just in case we have a bug somewhere.  I prefer
    ## getting reasonable bug reports...
    confess "find_path() found an undefined Processor reference as part '$_[0]' in ",
        ref $self
        unless defined $proc;

    confess "find_path() found '$proc' instead of a Processor reference as part '$_[0]' in ",
        ref $self
        unless ref $proc;

    confess "find_path() found a ",
        ref $proc,
        " reference instead of a Processor reference in part '$_[0]' in ",
        ref $self
        unless index( "SCALAR|ARRAY|HASH|Regexp|REF|CODE", ref $proc ) <= 0;

    return $proc;
}


use vars qw( $AUTOLOAD );

sub DESTROY {} ## Prevent AUTOLOADing of this.

my $alpha_first_char = has_named_regexp_character_classes
	    ? "^[[:alpha:]]"
	    : "^[a-zA-Z]";

sub AUTOLOAD {
    my $self = shift;

    $AUTOLOAD =~ s/.*://;

    my $fc = substr $AUTOLOAD, 0, 1;
    ## TODO: Find out how Perl determines "alphaness" and use that.
    croak ref $self, " does not provide method $AUTOLOAD"
        unless $fc eq uc $fc && $AUTOLOAD =~ /$alpha_first_char/o;

    my $found = $self->find_part( $AUTOLOAD );
    return $found;
}


sub parts {
    my $self = shift; 
    croak "Can't set parts for a '", ref( $self ), "'" if @_;
    confess "undef Parts" unless defined $self->{Parts};
    return map $_->{Processor}, @{$self->{Parts}};
}


## TODO: Detect deep recursion in _all_part_recs().  In fact, detect deep
## recursion when building the machine.

sub _all_part_recs {
    my $self = shift; 
    croak "Can't pass parms to ", ref( $self ), "->_all_part_recs" if @_;
    confess "undef Parts" unless defined $self->{Parts};
    my $proc;
    return map {
        $proc = $_->{Processor};
        UNIVERSAL::can( $proc, "all_parts" )
            ? ( $_, $proc->_all_part_recs )
            : $_;
    } @{$self->{Parts}};
}


sub all_parts {
    my $self = shift; 
    croak "Can't pass parms to ", ref( $self ), "->_all_parts" if @_;
    confess "undef Parts" unless defined $self->{Parts};
    return map $_->{Processor}, $self->_all_part_recs;
}


#=item add_parts
#
#    $m->add_parts( { Foo => $foo, Bar => $bar } );
#
#On linear machines:
#
#    $m->add_parts( @parts );
#
#Adds one or more parts to the machine.  Does not connect them, you need
#to do that manually (we need to add a $m->connect_parts() style API).
#
#=cut
#
#sub add_parts {
#    my $self = shift; 
#confess "TODO";
#}

#=item remove_parts
#
#    $m->remove_parts( qw( Foo Bar ) );
#
#Slower, but possible:
#
#    $m->remove_parts( $m->Foo, $m->Bar );
#
#On linear machines:
#
#    $m->remove_parts( 1, 3 );
#
#Removes one or more parts from the machine.  Does not connect them
#except on linear machines.  Attempts to disconnect any parts that
#point to them, and that they point to.  This attempt will fail for any
#part that does not provide a handler() or handlers() method.
#
#This is breadth-first recursive, like C<$m->find_part( $id )> is.  This
#will remove *all* parts with the given names from a complex
#machine (this does not apply to index numbers).
#
#Returns a list of the removed parts.
#
#If a name is not found, it is ignored.
#
#=cut
#
#sub remove_parts {
#    my $self = shift; 
#
#    my %names;
#    my @found;
#
#    for my $doomed ( @_ ) {
#        unless ( ref $doomed ) {
#            $names{$doomed} = undef;
#            if ( my $f = delete $self->{Parts}->{$doomed} ) {
#                push @found, $f;
#            }
#            else {
#                for my $c ( $self->parts ) {
#                    if ( $c->can( "remove_parts" ) 
#                       && ( my @f = $c->remove_parts( $doomed ) )
#                    ) {
#                        push @found, @f;
#                    }
#                }
#            }
#        }
#        else {
#            ## It's a reference.  Do this the slow, painful way.
#            for my $name ( keys %{$self->{Parts}} ) {
#                if ( $doomed == $self->{Parts}->{$name} ) {
#                    $names{$name} = undef;
#                    push @found, delete $self->{Parts}->{$name};
#                }
#            }
#
#            for my $c ( $self->parts ) {
#                if ( $c->can( "remove_parts" ) 
#                   && ( my @f = $c->remove_parts( $doomed ) )
#                ) {
#                    push @found, @f;
#                }
#            }
#        }
#    }
#
#    for my $c ( sort keys %{$self->{Connections}} ) {
#        if ( exists $names{$self->{Connections}->{$c}} ) {
###TODO: Unhook the processors if possible
#            delete $self->{Connections}->{$c};
#        }
#        if ( exists $names{$c} ) {
###TODO: Unhook the processors if possible
#            delete $self->{Connections}->{$c};
#        }
#    }
#
#    return @found;
#}


sub set_handler {
    my $self = shift;
    my ( $handler, $type ) = reverse @_;

    $type ||= "Handler";

    for my $part_rec ( @{$self->{Parts}} ) {
        my $proc = $part_rec->{Processor};
        my $hs = $part_rec->{Handlers};

        if ( grep ref $_ ? $_ == $self->{$type} : $_ eq "Exhaust", @$hs ) {
            if ( @$hs == 1 && $proc->can( "set_handler" ) ) {
                $proc->set_handler(
                    $type ne "Handler" ? $type : (),
                    $handler
                );
                next;
            }

            unless ( $proc->can( "set_handlers" ) ) {
                croak ref $proc,
                    @$hs == 1
                        ? " has no set_handler or set_handlers method"
                        : " has no set_handlers method"
            }

            $proc->set_handlers(
                map {
                    my $h;
                    my $t;
                    if ( ref $_ ) {
                        $h = $_;
                        $t = "Handler";
                    }
                    elsif ( $_ eq "Exhaust" ) {
                        $h = $handler;
                        $t = $type;
                    } else {
                        ( $h, $t ) = reverse split /=>/, $_;
                        $h = $self->find_part( $h );
                        $t = $type;
                        croak "Can't locate part $_ to be a handler for ",
                            $part_rec->string_description
                            unless $h;
                    }
                    { $type => $h }
                } @$hs
            );
        }
    }

    $self->{$type} = $handler;
}


my $warned_about_missing_sax_tracer;
sub trace_parts {
    my $self = shift;

    unless ( eval "require Devel::TraceSAX; 1" ) {
        warn $@ unless $warned_about_missing_sax_tracer++;
        return;
    }


    for ( @_ ? map $self->_find_part_rec( $_ ), @_ : @{$self->{Parts}} ) {
        Devel::TraceSAX::trace_SAX(
            $_->{Processor},
            $_->string_description
        );
    }

    ## some parts are created lazily, let's trace those, too
    $self->{TraceAdHocParts} ||= 1 unless @_;
}



sub trace_all_parts {
    my $self = shift;

    croak "Can't pass parms to trace_all_parts" if @_;

    unless ( eval "require Devel::TraceSAX; 1" ) {
        warn $@ unless $warned_about_missing_sax_tracer++;
        return;
    }

    for ( @{$self->{Parts}} ) {
        Devel::TraceSAX::trace_SAX(
            $_->{Processor},
            $_->string_description
        );
        $_->{Processor}->trace_all_parts
            if $_->{Processor}->can( "trace_all_parts" );
    }

    ## some parts are created lazily, let's trace those, too
    $self->{TraceAdHocParts} = 1;
}



sub untracify_parts {
    my $self = shift;
    for ( @_ ? map $self->find_part( $_ ), @_ : $self->parts ) {
        XML::SAX::TraceViaISA::remove_tracing_subclass( $_ );
    }
}



compile_methods __PACKAGE__, <<'EOCODE', sax_event_names "ParseMethods" ;
    sub <METHOD> {
        my $self = shift;
        my $h = $self->find_part( "Intake" );
        croak "SAX machine 'Intake' undefined"
            unless $h;

        if ( $h->can( "<METHOD>" ) ) {
            my ( $ok, @result ) = eval {
                ( 1, wantarray
                    ? $h-><METHOD>( @_ )
                    : scalar $h-><METHOD>( @_ )
                );
            };
            
            ## Not sure how/where causes me to need this next line, but
            ## in perl5.6.1 it seems necessary.
            return wantarray ? @result : $result[0] if $ok;
            die $@ unless $@ =~ /No .*routine defined/;
            undef $@;

            if ( $h->isa( "XML::SAX::Base" ) ) {
                ## Due to a bug in old versions of X::S::B, we need to reset
                ## this so that it will pass events on.
                ## TODO: when newer X::S::B's are common, jack up the
                ## version in Makefile.PL's PREREQ_PM :).
                delete $h->{ParseOptions};
            }
        }

        require XML::SAX::ParserFactory;
        $self->{Parser} = XML::SAX::ParserFactory->parser(
            Handler => $h
        );

        Devel::TraceSAX::trace_SAX(
            $self->{Parser},
            "Ad hoc parser (" . ref( $self->{Parser} ) . ")"
        ) if $self->{TraceAdHocParts};

        return $self->{Parser}-><METHOD>(@_);
    }
EOCODE


compile_methods __PACKAGE__, <<'EOCODE', sax_event_names ;
    sub <EVENT> {
        my $self = shift;
        my $h = $self->find_part( "Intake" );
        croak "SAX machine 'Intake' undefined"
            unless $h;

        return $h-><EVENT>( @_ ) if $h->can( "<EVENT>" );
    }
EOCODE



my %basic_types = (
    ARRAY  => undef,
    CODE   => undef,
    GLOB   => undef,
    HASH   => undef,
    REF    => undef,  ## Never seen this one, but it's listed in perlfunc
    Regexp => undef,
    SCALAR => undef,
);


sub _resolve_spec {
    my $self = shift;
    my ( $spec ) = @_;

    croak "undef passed instead of a filter to ", ref( $self ), "->new()"
        unless defined $spec;

    croak "Empty filter name ('') passed to ", ref( $self ), "->new()"
        unless length $spec;

    my $type = ref $spec;

    if (
           $type eq "SCALAR"
## TODO:         || $type eq "ARRAY"  <== need XML::SAX::Writer to supt this.
        || $type eq "GLOB"
        || UNIVERSAL::isa( $spec, "IO::Handle" )
        || ( ! $type && $spec =~ /^\s*([>|]|\+>)/ )
    ) {
## Cheat until XML::SAX::Writer cat grok it
if ( ! $type ) {
    use Symbol;
    my $fh = gensym;
    open $fh, $spec or croak "$! opening '$spec'" ;
    $spec = $fh;
}
        require XML::SAX::Writer;
        $spec = XML::SAX::Writer->new( Output => $spec );
    }
    elsif ( !$type ) {
        if ( $spec !~ /^\s*<|\|\s*(?!\n)$/ ) {
            ## Doesn't look like the caller wants to slurp a file
            ## Let's require it now to catch errors early, then
            ## new() it later after all requires are done.
            ## delaying the new()s might help us from doing things
            ## like blowing away output files and then finding
            ## errors, for instance.
            croak $@ unless $spec->can( "new" ) || eval "require $spec";
        }
    }
    else {
        croak "'$type' not supported in a SAX machine specification\n"
            if exists $basic_types{$type};
    }

    return $spec;
}

my $is_name_like = has_named_regexp_character_classes
	    ? '^[[:alpha:]]\w*(?!\n)$'
	    :    '^[a-zA-Z]\w*(?!\n)$';

sub _valid_name($) {
    my ( $prospect ) = @_;
    return 0 unless defined $prospect && length $prospect;
    my $fc = substr $prospect, 0, 1;
    ## I wonder how close to valid Perl method names this is?
    ( $fc eq uc $fc && $prospect =~ /$is_name_like/o ) ? 1 : 0;
}


sub _push_spec {
    my $self = shift;
    my ( $name, $spec, @handlers ) = 
        ref $_[0]
            ? ( undef, @_ )       ## Implictly unnamed: [ $obj, ... ]
            : @_;                 ## Named or explicitly unnamed: [ $name, ...]

    my $part = XML::SAX::Machine::Part->new(
        Name      => $name,
        Handlers  => \@handlers,
    );

#    if ( grep $_ eq "Exhaust", @handlers ) {
#        $self->{OverusedNames}->{Exhaust} ||= undef
#            if exists $self->{PartsByName}->{Exhaust};
#
#        $self->{PartsByName}->{Exhaust} = $self->{Parts}->[-1];
#
#        @handlers = grep $_ ne "Exhaust", @handlers;
#    }

    ## NOTE: This may
    ## still return a non-reference, which is the type of processor
    ## wanted here.  We construct those lazily below; see the docs
    ## about order of construction.
    my $proc = $self->_resolve_spec( $spec );
    $part->{Processor} = $proc;
    croak "SAX machine BUG: couldn't resolve spec '$spec'"
        unless defined $proc;

    push @{$self->{Parts}}, $part;
    $part->{Number} = $#{$self->{Parts}};

    if ( defined $name ) {
        $self->{OverusedNames}->{$name} ||= undef
            if exists $self->{PartsByName}->{$name};

        $self->{IllegalNames}->{$name} ||= undef
            unless _valid_name $name && $name ne "Exhaust";

        $self->{PartsByName}->{$name} = $self->{Parts}->[-1];
    }

    ## This HASH is used to detect cycles even if the user uses 
    ## preconstructed references instead of named parts.
    $self->{PartsByProcessor}->{$proc} = $part
        if ref $proc;
}


sub _names_err_msgs {
    my ( $s, @names ) = @_ ;
    @names = map ref $_ eq "HASH" ? keys %$_ : $_, @names;
    return () unless @names;

    @names = keys %{ { map { ( $_ => undef ) } @names } };

    if ( @names == 1 ) {
        $s =~ s/%[A-Z]+//g;
    }
    else {
        $s =~ s/%([A-Z]+)/\L$1/g;
    }

    return $s . join ", ", map "'$_'", sort @names ;
}


sub _build_part {
    my $self = shift;
    my ( $part ) = @_;

    my $part_num = $part->{Number};

    return if $self->{BuiltParts}->[$part_num];

    confess "SAX machine BUG: cycle found too late"
        if $self->{SeenParts}->[$part_num];
    ++$self->{SeenParts}->[$part_num];

    ## We retun a list of all cycles that have been discovered but
    ## not yet completed.  We don't return cycles that have been
    ## completely discovered; those are placed in DetectedCycles.
    my @open_cycles;

    eval {
        ## This eval is to make sure we decrement SeenParts so that
        ## we don't encounter spurious cycle found too late exceptions.

        ## Build any handlers, detect cycles
        my @handler_procs;

## I decided not to autolink one handler to the next in order to keep
## from causing hard to diagnose errors when unintended machines are
## passed in.  The special purpose machines, like Pipeline, have
## that logic built in.
##        ## Link any part with no handlers to the next part.
##        push @{$part->{Handlers}}, $part->{Number} + 1
##            if ! @{$part->{Handlers}} && $part->{Number} < $#{$self->{Parts}};

        for my $handler_spec ( @{$part->{Handlers}} ) {

            my $handler;

            if ( ref $handler_spec ) {
                ## The caller specified a handler with a real reference, so
                ## we don't need to build it, but we do need to do
                ## cycle detection. _build_part won't build it in this case
                ## but it will link it and do cycle detection.
                $handler = $self->{PartsByProcessor}->{$handler_spec}
                    if exists $self->{PartsByProcessor}->{$handler_spec};

                if ( ! defined $handler ) {
                    ## It's a processor not in this machine.  Hope the
                    ## caller knows what it's doing.
                    push @handler_procs, $handler_spec;
                    next;
                }
            }
            else {
                $handler = $self->_find_part_rec( $handler_spec );
                ## all handler specs were checked earlier, so "survive" this
                ## failure and let the queued error message tell the user
                ## about it.
                next unless defined $handler;
            }

            if ( $self->{SeenParts}->[$handler->{Number}] ) {
                ## Oop, a cycle, and we don't want to recurse or we'll
                ## recurse forever.
                push @open_cycles, $part eq $handler
                    ? [ $handler ] 
                    : [ $part, $handler ];
                next;
            }

            my @nested_cycles = $self->_build_part( $handler );

            my $handler_proc = $handler->{Processor};

            confess "SAX machine BUG: found a part with no processor: ",
                $handler->string_description
                unless defined $handler_proc;

            confess "SAX machine BUG: found a unbuilt '",
                $handler->{Processor},
                "' processor: ",
                $handler->string_description
                unless ref $handler_proc;

            push @handler_procs, $handler_proc;

            for my $nested_cycle ( @nested_cycles ) {
                if ( $nested_cycle->[-1] == $part ) {
                    ## the returned cycle "ended" with our part, so
                    ## we have a complete description of the cycle, log it
                    ## and move on.
                    push @{$self->{DetectedCycles}}, $nested_cycle;
                }
                else {
                    ## This part is part of this cycle but not it's "beginning"
                    push @open_cycles, [ $part, $nested_cycle ];
                }
            }
        }

        ## Create this processor if need be, otherwise just set the handlers.
        my $proc = $part->{Processor};
        confess "SAX machine BUG: undefined processor for ",
            $part->string_description
            unless defined $proc;

        unless ( ref $proc ) {
            ## TODO: Figure a way to specify the type of handler, probably
            ## using a DTDHandler=>Name syntax, not sure.  Perhaps
            ## using a hash would be best.

            if ( $proc =~ /^\s*<|\|\s*(?!\n)$/ ) {
                ## Looks like the caller wants to slurp a file
                ## We open it ourselves to get all of Perl's magical
                ## "open" goodness.  TODO: also check for a URL scheme
                ## and handle that :).

                ## TODO: Move this in to a/the parse method so it can
                ## be repeated.
                require Symbol;
                my $fh = Symbol::gensym;
                open $fh, $proc or croak "$! opening '$proc'";
                require XML::SAX::ParserFactory;
                require IO::Handle;
                $proc = XML::SAX::ParserFactory->parser(
                    Source => {
                        ByteStream => $fh,
                    },
                    map {
                        ( Handler => $_ ),
                    } @handler_procs
                );

            }
            elsif (
                XML::SAX::Machines->processor_class_option(
                    $proc,
                    "ConstructWithHashedOptions"
                )
            ) {
                ## This is designed to build options in a format compatible
                ## with SAXT style constructors when multiple handlers are
                ## defined.
                $proc = $proc->new(
                    map {
                        { Handler => $_ }, ## Hashes
                    } @handler_procs       ## 0 or more of 'em
                );
            }
            else {
                ## More common Foo->new( Handler => $h );
                croak "$proc->new doesn't allow multiple handlers.\nSet ConstructWithOptionsHashes => 1 in XML::SAX::Machines::ConfigDefaults if need be"
                    if @handler_procs > 1;
                $proc = $proc->new(
                    map {
                        ( Handler => $_ ),  ## A plain list
                    } @handler_procs        ## with 0 or 1 elts
                );
            }
            $self->{PartsByProcessor}->{$proc} = $part;
        }
        elsif ( @handler_procs ) {
            if ( $proc->can( "set_handlers" ) ) {
                $proc->set_handlers( @handler_procs );
            }
            elsif ( $proc->can( "set_handler" ) ) {
                if ( @handler_procs == 1 ) {
                    $proc->set_handler( @handler_procs );
                }
                else {
                    die "SAX machine part ", $part->string_description,
                    " can only take one handler at a time\n";
                }
            }
            else {
                die "SAX machine part ", $part->string_description,
                " does not provide a set_handler() or set_handlers() method\n"
            }
        }

        $part->{Processor} = $proc;
    };

    --$self->{SeenParts}->[$part->{Number}];
    $self->{BuiltParts}->[$part_num] = 1;


    if ( $@ ) {
        chomp $@;
        $@ .= "\n        ...while building " . $part->string_description . "\n";
        die $@;
    }

    return @open_cycles;
}


sub _compile_specs {
    my $self = shift;

    my @errors;

    ## Init the permanent structures
    $self->{Parts}            = [];
    $self->{PartsByName}      = {};
    $self->{PartsByProcessor} = {};

    ## And some temporary structures.
    $self->{IllegalNames}  = {};
    $self->{OverusedNames} = {};

    ## Scan the specs and figure out the connectivity, names and load
    ## any requirements, etc.
    for my $spec ( @_ ) {
        eval {
            $self->_push_spec(
                ref $spec eq "ARRAY"
                    ? @$spec
                    : ( undef, $spec )
            );
        };
        ## This could be ugly if $@ contains a stack trace, but it'll have
        ## to do.
        if ( $@ ) {
            chomp $@;
            push @errors, $@;
        }
    }

    push @errors, (
        _names_err_msgs(
            "illegal SAX machine part name%S ",
            $self->{IllegalNames}
        ),
        _names_err_msgs(
            "undefined SAX machine part%S specified as handler%S ",
            grep defined && ! $self->_find_part_rec( $_ ),
                grep ! ref && $_ ne "Exhaust",
                    map @{$_->{Handlers}},
                        @{$self->{Parts}}
        ),
        _names_err_msgs(
            "multiple SAX machine parts named ",
            $self->{OverusedNames}
        )
    );

    ## Free some memory and make object dumps smaller
    delete $self->{IllegalNames};
    delete $self->{OverusedNames};

    ## If we made it this far, all classes have been loaded and all
    ## non-processor refs have been converted in to processors.
    ## Now
    ## we need to build and that were specified by type name and do
    ## them in reverse order so we can pass the
    ## Handler option(s) in.
    ## If multiple handlers are defined, then
    ## we assume that the constructor takes a SAXT like parameter list.
    ## TODO: figure out how to allow DocumentHandler, etc.  Perhaps allow
    ## HASH refs in ARRAY syntax decls.
    
    ## Some temporaries
    $self->{BuiltParts}     = [];
    $self->{SeenParts}      = [];
    $self->{DetectedCycles} = [];

    ## _build_part is recursive and builds any downstream handlers
    ## needed to build a part.
    for ( @{$self->{Parts}} ) {
        eval {
            push @{$self->{DetectedCycles}}, $self->_build_part( $_ );
        };
        if ( $@ ) {
            chomp $@;
            push @errors, $@;
        }
    }

#    $self->{PartsByName}->{Intake}  ||= $self->{Parts}->[0];
#    $self->{PartsByName}->{Exhaust} ||= $self->{Parts}->[-1];

    if ( @{$self->{DetectedCycles}} ) {
        ## Remove duplicate (cycles are found once for each processor in
        ## the cycle.
        my %unique_cycles;

        for my $cycle ( @{$self->{DetectedCycles}} ) {
            my $start = 0;
            for ( 1..$#$cycle ) {
                $start = $_
                    if $cycle->[$_]->{Number} < $cycle->[$start]->{Number};
            }
            my $key = join(
                ",",
                map $_->{Number},
                    @{$cycle}[$start..($#$cycle),0..($start-1)]
            );
            $unique_cycles{$key} ||= $cycle;
        }
        
        push @errors, map {
            "Cycle detected in SAX machine: " .
                join(
                    "->",
                    map $_->string_description, $_->[-1], @$_
                );
        } map $unique_cycles{$_}, sort keys %unique_cycles;
    }

    delete $self->{SeenParts};
    delete $self->{BuiltParts};
    delete $self->{DetectedCycles};

    croak join "\n", @errors if @errors;
}


sub _SAX2_attrs {
    my %a = @_;

    return {
        map {
            defined $a{$_}
                ? ( $_ => {
                    LocalName => $_,
                    Name      => $_,
                    Value     => $a{$_},
                } )
                : () ;
        } keys %a
    };
}


my %ids;
sub _idify($) {
    $ids{$_[0]} = keys %ids unless exists $ids{$_[0]};
    return $ids{$_[0]};
}


sub pointer_elt {
    my $self = shift;
    my ( $elt_type, $h_spec, $options ) = @_;

    my $part_rec;

    $h_spec = $self->{Handler}
        if $h_spec eq "Exhaust" && defined $self->{Handler};

    ## Look locally first in case the name is not
    ## unique among parts in RootMachine.
    $part_rec = $self->_find_part_rec( $h_spec )
        if ! $part_rec;

    ## Don't look for indexes in RootMachine
    $part_rec = $options->{RootMachine}->_find_part_rec(
        $h_spec
    ) if ! $part_rec
        && defined $options->{RootMachine}
        && $h_spec != /^-?\d+$/ ;

    my %attrs;

    if ( $part_rec ) {
        %attrs = (
            name           => $part_rec->{Name} || $h_spec,
            "handler-id"   => _idify $part_rec->{Processor},
        );
    }
    else {
        if ( ref $h_spec ) {
            %attrs = (
                type         => ref $h_spec,
                "handler-id" => _idify $h_spec,
            );
        }
        else {
            %attrs = (
                name => $h_spec,
            );
        }
    }

    return {
        Name       => $elt_type,
        LocalName  => $elt_type,
        Attributes => _SAX2_attrs( %attrs ),
    };
}


sub generate_part_descriptions {
    my $self = shift;
    my ( $options ) = @_;

    my $h = $options->{Handler};
    croak "No Handler passed" unless $h;

    for my $part_rec ( @{$self->{Parts}} ) {
        my $proc = $part_rec->{Processor};

        if ( $proc->can( "generate_description" ) ) {
            $proc->generate_description( {
                %$options,
                Name        => $part_rec->{Name},
                Description => $part_rec->string_description,
            } );
        }
        else {
            my $part_elt = {
                LocalName  => "part",
                Name       => "part",
                Attributes => _SAX2_attrs(
                    id          => _idify $proc,
                    type        => ref $part_rec,
                    name        => $part_rec->{Name},
                    description => $part_rec->string_description,
                ),
            };
            $h->start_element( $part_elt );
            for my $h_spec ( @{$part_rec->{Handlers}} ) {
                my $handler_elt = $self->pointer_elt( "handler", $h_spec );

                $h->start_element( $handler_elt );
                $h->end_element(   $handler_elt );
            }
            $h->end_element( $part_elt );
        }
    }
}


sub generate_description {
    my $self = shift;

    my $options =
        @_ == 1
            ? ref $_[0] eq "HASH"
                ? { %{$_[0]} }
                : {
                    Handler =>
                        ref $_[0]
                            ? $_[0]
                            : $self->_resolve_spec( $_[0] )
                }
            : { @_ };

    my $h = $options->{Handler};
    croak "No Handler passed" unless $h;

    unless ( $options->{Depth} ) {
        %ids = ();
        $options->{RootMachine} = $self;

        $h->start_document({});
    }

    ++$options->{Depth};
    my $root_elt = {
        LocalName => "sax-machine",
        Name      => "sax-machine",
        Attributes => _SAX2_attrs(
            id          => _idify $self,
            type        => ref $self,
            name        => $options->{Name},
            description => $options->{Description},
        ),
    };

    $h->start_element( $root_elt );

    ## Listing the handler first so it doesn't look like a part's
    ## handler (which it kinda does if it's hanging out *after* a <part .../>
    ## tag :).  Also makes following the links by hand a tad easier.
    if ( defined $self->{Handler} ) {
        my $handler_elt = $self->pointer_elt( "handler", $self->{Handler} );
        $handler_elt->{Attributes}->{name} = {
            Name      => "name",
            LocalName => "name",
            Value     => "Exhaust"
        } unless exists $handler_elt->{Attributes}->{Name};
            
        $h->start_element( $handler_elt );
        $h->end_element(   $handler_elt );
    }

    for ( sort keys %{$self->{PartsByName}} ) {
        if ( $self->{PartsByName}->{$_}->{Name} ne $_ ) {
        warn $self->{PartsByName}->{$_}->{Name}, " : ", $_;
            my $handler_elt = $self->pointer_elt( "alias", $_ );
            %{$handler_elt->{Attributes}} = (
                %{$handler_elt->{Attributes}},
                %{_SAX2_attrs( alias => $_ )},
            );
            $h->start_element( $handler_elt );
            $h->end_element(   $handler_elt );
        }
    }

    $self->generate_part_descriptions( $options );
    $h->end_element( $root_elt );

    --$options->{Depth};
    $h->end_document({}) unless $options->{Depth};
}


##
## This is a private class, only this class should use it directly.
##
package XML::SAX::Machine::Part;
{
  $XML::SAX::Machine::Part::VERSION = '0.46';
}

use fields (
    'Name',       ## The caller-given name of the part
    'Number',     ## Where it sits in the parts list.
    'Processor',  ## The actual SAX processor
    'Handlers',   ## The handlers the caller specified
);


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;
    
    my %options = @_ ;
    $self->{$_} = $options{$_} for keys %options;

    return $self;
}


sub string_description {
    my $self = shift;

    return join( 
        "",
        $self->{Name}
            ? $self->{Name}
            : ( "#", $self->{Number} ),
        " (",
        $self->{Processor}
            ? ( ref $self->{Processor} || $self->{Processor} )
            : "<undefined processor>",
        ")"
    );
}

1;

__END__

=pod

=head1 NAME

XML::SAX::Machine - Manage a collection of SAX processors

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    ## Note: See XML::SAX::Pipeline and XML::SAX::Machines first,
    ## this is the gory, detailed interface.

    use My::SAX::Machines qw( Machine );
    use My::SAX::Filter2;
    use My::SAX::Filter3;

    my $filter3 = My::SAX::Filter3->new;

    ## A simple pipeline.  My::SAX::Filter1 will be autoloaded.
    my $m = Machine(
        #
        # Name   => Class/object            => handler(s)
        #
        [ Intake => "My::SAX::Filter1"      => "B"        ],
        [ B      => My::SAX::Filter2->new() => "C"        ],
        [ C      => $filter3                => "D"        ],
        [ D      => \*STDOUT                              ],
    );

    ## A parser will be created unless My::SAX::Filter1 can parse_file
    $m->parse_file( "foo.revml" );

    my $m = Machine(
        [ Intake   => "My::SAX::Filter1"  => qw( Tee     ) ],
        [ Tee      => "XML::Filter::SAXT" => qw( Foo Bar ) ],
        [ Foo      => "My::SAX::Filter2"  => qw( Out1    ) ],
        [ Out1     => \$log                                ],
        [ Bar      => "My::SAX::Filter3"  => qw( Exhaust ) ],
    );

=head1 DESCRIPTION

B<WARNING>: This API is alpha!!!  It I<will> be changing.

A generic SAX machine (an instance of XML::SAX::Machine) is a container
of SAX processors (referred to as "parts") connected in arbitrary ways.

Each parameter to C<Machine()> (or C<XML::SAX::Machine->new()>)
represents one top level part of the machine.  Each part has a name, a
processor, and one or more handlers (usually specified by name, as shown
in the SYNOPSIS).

Since SAX machines may be passed in as single top level parts, you can
also create nested, complex machines ($filter3 in the SYNOPSIS could be
a Pipeline, for example).

A SAX machines can act as a normal SAX processors by connecting them to
other SAX processors:

    my $w = My::Writer->new();
    my $m = Machine( ...., { Handler => $w } );
    my $g = My::Parser->new( Handler => $w );

=head2 Part Names

Although it's not required, each part in a machine can be named.  This
is useful for retrieving and manipulating the parts (see L</part>, for
instance), and for debugging, since debugging output (see
L</trace_parts> and L</trace_all_parts>) includes the names.

Part names must be valid Perl subroutine names, beginning with an
uppercase character.  This is to allow convenience part accessors
methods like

    $c = $m->NameOfAFilter;

to work without ever colliding with the name of a method (all method
names are completely lower case).  Only filters named like this can be
accessed using the magical accessor functions.

=head2 Reserved Names: Intake and Exhaust

The names c<Intake> and C<Exhaust> are reserved.  C<Intake> refers to
the first part in the processing chain.  This is not necessarily the
first part in the constructor list, just the first part to receive
external events.

C<Exhaust> refers to the output of the machine; no part may be named
C<Exhaust>, and any parts with a handler named C<Exhaust> will deliver
their output to the machine's handler.  Normally, only one part should
deliver it's output to the Exhaust port.

Calling $m->set_handler() alters the Exhaust port, assuming any
processors pointing to the C<Exhaust> provide a C<set_handler()> method
like L<XML::SAX::Base>'s.

C<Intake> and C<Exhaust> are usually assigned automatically by
single-purpose machines like L<XML::SAX::Pipeline> and
L<XML::SAX::Manifold>.

=head2 SAX Processor Support

The XML::SAX::Machine class is very agnostic about what SAX processors
it supports; about the only constraint is that it must be a blessed
reference (of any type) that does not happen to be a Perl IO::Handle
(which are assumed to be input or output filehandles).

The major constraint placed on SAX processors is that they must provide
either a C<set_handler> or C<set_handlers> method (depending on how many
handlers a processor can feed) to allow the SAX::Machine to disconnect
and reconnect them.  Luckily, this is true of almost any processor
derived from XML::SAX::Base.  Unfortunately, many SAX older (SAX1)
processors do not meet this requirement; they assume that SAX processors
will only ever be connected together using their constructors.

=head2 Connections

SAX machines allow you to connect the parts however you like; each part
is given a name and a list of named handlers to feed.  The number of
handlers a part is allowed depends on the part; most filters only allow
once downstream handler, but filters like L<XML::Filter::SAXT> and
L<XML::Filter::Distributor> are meant to feed multiple handlers.

Parts may not be connected in loops ("cycles" in graph theory terms).
The machines specified by:

    [ A => "Foo" => "A" ],  ## Illegal!

and 

    [ A => "Foo" => "B" ],  ## Illegal!
    [ B => "Foo" => "A" ],

.  Configuring a machine this way would cause events to flow in an
infinite loop, and/or cause the first processor in the cycle to start
receiving events from the end of the cycle before the input document was
complete.  Besides, it's not a very useful topology :).

SAX machines detect loops at construction time.

=head1 NAME

    XML::SAX::Machine - Manage a collection of SAX processors

=head1 API

=head2 Public Methods

These methods are meant to be used by users of SAX machines.

=over

=item new()

    my $m = $self->new( @machine_spec, \%options );

Creates $self using %options, and compiles the machine spec.  This is
the longhand form of C<Machines( ... )>.

=item find_part

Gets a part contained by this machine by name, number or object reference:

    $c = $m->find_part( $name );
    $c = $m->find_part( $number );
    $c = $m->find_part( $obj );    ## useful only to see if $obj is in $m

If a machine contains other machines, parts of the contained machines
may be accessed by name using unix directory syntax:

    $c = $m->find_part( "/Intake/Foo/Bar" );

(all paths must be absolute).

Parts may also be accessed by number using array indexing:

    $c = $m->find_part(0);  ## Returns first part or undef if none
    $c = $m->find_part(-1); ## Returns last part or undef if none
    $c = $m->find_part( "Foo/0/1/-1" );

There is no way to guarantee that a part's position number means
anything, since parts can be reconnected after their position numbers
are assigned, so using a part name is recommended.

Throws an exception if the part is not found, so doing things like

   $m->find_part( "Foo" )->bar()

garner informative messages when "Foo" is not found.  If you want to
test a result code, do something like

    my $p = eval { $m->find_part };
    unless ( $p ) {
        ...handle lookup failure...
    }

=item parts

    for ( $m->parts ) { ... }

Gets an arbitrarily ordered list of top level parts in this machine.
This is all of the parts directly contained by this machine and none of
the parts that may be inside them.  So if a machine contains an
L<XML::SAX::Pipeline> as one of it's parts, the pipeline will be
returned but not the parts inside the pipeline.

=item all_parts

    for ( $m->all_parts ) { ... }

Gets all parts in this machine, not just top level ones. This includes
any machines contained by this machine and their parts.

=item set_handler

    $m->set_handler( $handler );
    $m->set_handler( DTDHandler => $handler );

Sets the machine's handler and sets the handlers for all parts that
have C<Exhaust> specified as their handlers.  Requires that any such
parts provide a C<set_handler> or (if the part has multiple handlers)
a C<set_handlers> method.

NOTE: handler types other than "Handler" are only supported if they are
supported by whatever parts point at the C<Exhaust>.  If the handler type is
C<Handler>, then the appropriate method is called as:

    $part->set_handler( $handler );
    $part->set_handlers( $handler0, $handler1, ... );

If the type is some other handler type, these are called as:

    $part->set_handler( $type => $handler );
    $part->set_handlers( { $type0 => $handler0 }, ... );

=item trace_parts

    $m->trace_parts;          ## trace all top-level parts
    $m->trace_parts( @ids );  ## trace the indicated parts

Uses Devel::TraceSAX to enable tracing of all events received by the parts of
this machine.  Does not enable tracing of parts contained in machines in this
machine; for that, see trace_all_parts.

=item trace_all_parts

    $m->trace_all_parts;      ## trace all parts

Uses Devel::TraceSAX to trace all events received by the parts of this
machine.

=item untracify_parts

    $m->untracify_parts( @ids );

Converts the indicated parts to SAX processors with tracing enabled.
This may not work with processors that use AUTOLOAD.

=back

=head1 Events and parse routines

XML::SAX::Machine provides all SAX1 and SAX2 events and delgates them to the
processor indicated by $m->find_part( "Intake" ).  This adds some overhead, so
if you are concerned about overhead, you might want to direct SAX events
directly to the Intake instead of to the machine.

It also provides parse...() routines so it can whip up a parser if need
be.  This means: parse(), parse_uri(), parse_string(), and parse_file()
(see XML::SAX::EventMethodMaker for details).  There is no way to pass
methods directly to the parser unless you know that the Intake is a
parser and call it directly.  This is not so important for parsing,
because the overhead it takes to delegate is minor compared to the
effort needed to parse an XML document.

=head2 Internal and Helper Methods

These methods are meant to be used/overridden by subclasses.

=over

=item _compile_specs

    my @comp = $self->_compile_specs( @_ );

Runs through a list of module names, output specifiers, etc., and builds
the machine.

    $scalar     --> "$scalar"->new
    $ARRAY_ref  --> pipeline @$ARRAY_ref
    $SCALAR_ref --> XML::SAX::Writer->new( Output => $SCALAR_ref )
    $GLOB_ref   --> XML::SAX::Writer->new( Output => $GLOB_ref )

=item generate_description

    $m->generate_description( $h );
    $m->generate_description( Handler => $h );
    $m->generate_description( Pipeline ... );

Generates a series of SAX events to the handler of your choice.

See L<XML::Handler::Machine2GraphViz> on CPAN for a way of visualizing
machine innards.

=back

=head1 TODO

=over

=item *

Separate initialization from construction time; there should be somthing
like a $m->connect( ....machine_spec... ) that new() calls to allow you
to delay parts speficication and reconfigure existing machines.

=item *

Allow an XML doc to be passed in as a machine spec.

=back

=head1 LIMITATIONS

=over

=back

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 LICENSE

Artistic or GPL, any version.

=head1 AUTHORS

=over 4

=item *

Barry Slaymaker

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Barry Slaymaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
