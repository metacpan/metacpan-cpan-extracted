package PPIx::Utils::Classification;

use strict;
use warnings;
use B::Keywords;
use Exporter 'import';
use Scalar::Util 'blessed';

use PPIx::Utils::Traversal qw(first_arg parse_arg_list);
# Functions also used by PPIx::Utils::Traversal
use PPIx::Utils::_Common qw(
    is_ppi_expression_or_generic_statement
    is_ppi_simple_statement
);

our $VERSION = '0.003';

our @EXPORT_OK = qw(
    is_assignment_operator
    is_class_name
    is_function_call
    is_hash_key
    is_in_void_context
    is_included_module_name
    is_integer
    is_label_pointer
    is_method_call
    is_package_declaration
    is_perl_bareword
    is_perl_builtin
    is_perl_builtin_with_list_context
    is_perl_builtin_with_multiple_arguments
    is_perl_builtin_with_no_arguments
    is_perl_builtin_with_one_argument
    is_perl_builtin_with_optional_argument
    is_perl_builtin_with_zero_and_or_one_arguments
    is_perl_filehandle
    is_perl_global
    is_qualified_name
    is_subroutine_name
    is_unchecked_call
    is_ppi_expression_or_generic_statement
    is_ppi_generic_statement
    is_ppi_statement_subclass
    is_ppi_simple_statement
    is_ppi_constant_element
    is_subroutine_declaration
    is_in_subroutine
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# From Perl::Critic::Utils
sub _name_for_sub_or_stringified_element {
    my $elem = shift;

    if ( blessed $elem and $elem->isa('PPI::Statement::Sub') ) {
        return $elem->name();
    }

    return "$elem";
}

my %BUILTINS = map { $_ => 1 } @B::Keywords::Functions;

sub is_perl_builtin {
    my $elem = shift;
    return undef if !$elem;

    return exists $BUILTINS{ _name_for_sub_or_stringified_element($elem) };
}

my %BAREWORDS = map { $_ => 1 } @B::Keywords::Barewords;

sub is_perl_bareword {
    my $elem = shift;
    return undef if !$elem;

    return exists $BAREWORDS{ _name_for_sub_or_stringified_element($elem) };
}

sub _build_globals_without_sigils {
    my @globals =
        map { substr $_, 1 }
            @B::Keywords::Arrays,
            @B::Keywords::Hashes,
            @B::Keywords::Scalars;

    # Not all of these have sigils
    foreach my $filehandle (@B::Keywords::Filehandles) {
        (my $stripped = $filehandle) =~ s< \A [*] ><>x;
        push @globals, $stripped;
    }

    return @globals;
}

my %GLOBALS = map { $_ => 1 } _build_globals_without_sigils();

sub is_perl_global {
    my $elem = shift;
    return undef if !$elem;
    my $var_name = "$elem"; #Convert Token::Symbol to string
    $var_name =~ s{\A [\$@%*] }{}x;  #Chop off the sigil
    return exists $GLOBALS{ $var_name };
}

my %FILEHANDLES = map { $_ => 1 } @B::Keywords::Filehandles;

sub is_perl_filehandle {
    my $elem = shift;
    return undef if !$elem;

    return exists $FILEHANDLES{ _name_for_sub_or_stringified_element($elem) };
}

# egrep '=item.*LIST' perlfunc.pod
my %BUILTINS_WHICH_PROVIDE_LIST_CONTEXT =
    map { $_ => 1 }
        qw{
            chmod
            chown
            die
            exec
            formline
            grep
            import
            join
            kill
            map
            no
            open
            pack
            print
            printf
            push
            reverse
            say
            sort
            splice
            sprintf
            syscall
            system
            tie
            unlink
            unshift
            use
            utime
            warn
        };

sub is_perl_builtin_with_list_context {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_PROVIDE_LIST_CONTEXT{
                _name_for_sub_or_stringified_element($elem)
            };
}

# egrep '=item.*[A-Z],' perlfunc.pod
my %BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS =
    map { $_ => 1 }
        qw{
            accept
            atan2
            bind
            binmode
            bless
            connect
            crypt
            dbmopen
            fcntl
            flock
            gethostbyaddr
            getnetbyaddr
            getpriority
            getservbyname
            getservbyport
            getsockopt
            index
            ioctl
            link
            listen
            mkdir
            msgctl
            msgget
            msgrcv
            msgsnd
            open
            opendir
            pipe
            read
            recv
            rename
            rindex
            seek
            seekdir
            select
            semctl
            semget
            semop
            send
            setpgrp
            setpriority
            setsockopt
            shmctl
            shmget
            shmread
            shmwrite
            shutdown
            socket
            socketpair
            splice
            split
            substr
            symlink
            sysopen
            sysread
            sysseek
            syswrite
            truncate
            unpack
            vec
            waitpid
        },
        keys %BUILTINS_WHICH_PROVIDE_LIST_CONTEXT;

sub is_perl_builtin_with_multiple_arguments {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS{
                _name_for_sub_or_stringified_element($elem)
            };
}

my %BUILTINS_WHICH_TAKE_NO_ARGUMENTS =
    map { $_ => 1 }
        qw{
            endgrent
            endhostent
            endnetent
            endprotoent
            endpwent
            endservent
            fork
            format
            getgrent
            gethostent
            getlogin
            getnetent
            getppid
            getprotoent
            getpwent
            getservent
            setgrent
            setpwent
            split
            time
            times
            wait
            wantarray
        };

sub is_perl_builtin_with_no_arguments {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{
                _name_for_sub_or_stringified_element($elem)
            };
}

my %BUILTINS_WHICH_TAKE_ONE_ARGUMENT =
    map { $_ => 1 }
        qw{
            closedir
            dbmclose
            delete
            each
            exists
            fileno
            getgrgid
            getgrnam
            gethostbyname
            getnetbyname
            getpeername
            getpgrp
            getprotobyname
            getprotobynumber
            getpwnam
            getpwuid
            getsockname
            goto
            keys
            local
            prototype
            readdir
            readline
            readpipe
            rewinddir
            scalar
            sethostent
            setnetent
            setprotoent
            setservent
            telldir
            tied
            untie
            values
        };

sub is_perl_builtin_with_one_argument {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{
                _name_for_sub_or_stringified_element($elem)
            };
}

my %BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT =
    map { $_ => 1 }
        grep { not exists $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{ $_ } }
        grep { not exists $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{ $_ } }
        grep { not exists $BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS{ $_ } }
        @B::Keywords::Functions;

sub is_perl_builtin_with_optional_argument {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT{
                _name_for_sub_or_stringified_element($elem)
            };
}

sub is_perl_builtin_with_zero_and_or_one_arguments {
    my $elem = shift;

    return undef if not $elem;

    my $name = _name_for_sub_or_stringified_element($elem);

    return (
            exists $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{ $name }
        or  exists $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{ $name }
        or  exists $BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT{ $name }
    );
}

sub is_qualified_name {
    my $name = shift;

    return undef if not $name;

    return index ( $name, q{::} ) >= 0;
}

sub _is_followed_by_parens {
    my $elem = shift;
    return undef if !$elem;

    my $sibling = $elem->snext_sibling() || return undef;
    return $sibling->isa('PPI::Structure::List');
}

sub is_hash_key {
    my $elem = shift;
    return undef if !$elem;

    #If followed by an argument list, then its a function call, not a literal
    return undef if _is_followed_by_parens($elem);

    #Check curly-brace style: $hash{foo} = bar;
    my $parent = $elem->parent();
    return undef if !$parent;
    my $grandparent = $parent->parent();
    return undef if !$grandparent;
    return 1 if $grandparent->isa('PPI::Structure::Subscript');


    #Check declarative style: %hash = (foo => bar);
    my $sib = $elem->snext_sibling();
    return undef if !$sib;
    return 1 if $sib->isa('PPI::Token::Operator') && $sib eq '=>';

    return undef;
}

sub is_included_module_name {
    my $elem  = shift;
    return undef if !$elem;
    my $stmnt = $elem->statement();
    return undef if !$stmnt;
    return undef if !$stmnt->isa('PPI::Statement::Include');
    return $stmnt->schild(1) == $elem;
}

sub is_integer {
    my ($value) = @_;
    return 0 if not defined $value;

    return $value =~ m{ \A [+-]? [0-9]+ \z }x;
}

sub is_label_pointer {
    my $elem = shift;
    return undef if !$elem;

    my $statement = $elem->statement();
    return undef if !$statement;

    my $psib = $elem->sprevious_sibling();
    return undef if !$psib;

    return $statement->isa('PPI::Statement::Break')
        && $psib =~ m/(?:redo|goto|next|last)/x;
}

sub _is_dereference_operator {
    my $elem = shift;
    return undef if !$elem;

    return $elem->isa('PPI::Token::Operator') && $elem eq q{->};
}

sub is_method_call {
    my $elem = shift;
    return undef if !$elem;

    return _is_dereference_operator( $elem->sprevious_sibling() );
}

sub is_class_name {
    my $elem = shift;
    return undef if !$elem;

    return _is_dereference_operator( $elem->snext_sibling() )
        && !_is_dereference_operator( $elem->sprevious_sibling() );
}

sub is_package_declaration {
    my $elem  = shift;
    return undef if !$elem;
    my $stmnt = $elem->statement();
    return undef if !$stmnt;
    return undef if !$stmnt->isa('PPI::Statement::Package');
    return $stmnt->schild(1) == $elem;
}

sub is_subroutine_name {
    my $elem  = shift;
    return undef if !$elem;
    my $sib   = $elem->sprevious_sibling();
    return undef if !$sib;
    my $stmnt = $elem->statement();
    return undef if !$stmnt;
    return $stmnt->isa('PPI::Statement::Sub') && $sib eq 'sub';
}

sub is_function_call {
    my $elem = shift or return undef;

    return undef if is_perl_bareword($elem);
    return undef if is_perl_filehandle($elem);
    return undef if is_package_declaration($elem);
    return undef if is_included_module_name($elem);
    return undef if is_method_call($elem);
    return undef if is_class_name($elem);
    return undef if is_subroutine_name($elem);
    return undef if is_label_pointer($elem);
    return undef if is_hash_key($elem);

    return 1;
}

sub is_in_void_context {
    my ($token) = @_;

    # If part of a collective, can't be void.
    return undef if $token->sprevious_sibling();

    my $parent = $token->statement()->parent();
    if ($parent) {
        return undef if $parent->isa('PPI::Structure::List');
        return undef if $parent->isa('PPI::Structure::For');
        return undef if $parent->isa('PPI::Structure::Condition');
        return undef if $parent->isa('PPI::Structure::Constructor');
        return undef if $parent->isa('PPI::Structure::Subscript');

        my $grand_parent = $parent->parent();
        if ($grand_parent) {
            return undef if
                    $parent->isa('PPI::Structure::Block')
                and not $grand_parent->isa('PPI::Statement::Compound');
        }
    }

    return 1;
}

my %ASSIGNMENT_OPERATORS = map { $_ => 1 } qw( = **= += -= .= *= /= %= x= &= |= ^= <<= >>= &&= ||= //= );

sub is_assignment_operator {
    my $elem = shift;

    return exists $ASSIGNMENT_OPERATORS{ $elem };
}

sub is_unchecked_call {
    my $elem = shift;

    return undef if not is_function_call( $elem );

    # check to see if there's an '=' or 'unless' or something before this.
    if( my $sib = $elem->sprevious_sibling() ){
        return undef if $sib;
    }


    if( my $statement = $elem->statement() ){

        # "open or die" is OK.
        # We can't check snext_sibling for 'or' since the next siblings are an
        # unknown number of arguments to the system call. Instead, check all of
        # the elements to this statement to see if we find 'or' or '||'.

        my $or_operators = sub  {
            my (undef, $elem) = @_;
            return undef if not $elem->isa('PPI::Token::Operator');
            return undef if $elem ne q{or} && $elem ne q{||};
            return 1;
        };

        return undef if $statement->find( $or_operators );


        if( my $parent = $elem->statement()->parent() ){

            # Check if we're in an if( open ) {good} else {bad} condition
            return undef if $parent->isa('PPI::Structure::Condition');

            # Return val could be captured in data structure and checked later
            return undef if $parent->isa('PPI::Structure::Constructor');

            # "die if not ( open() )" - It's in list context.
            if ( $parent->isa('PPI::Structure::List') ) {
                if( my $uncle = $parent->sprevious_sibling() ){
                    return undef if $uncle;
                }
            }
        }
    }

    return undef if _is_fatal($elem);

    # Otherwise, return. this system call is unchecked.
    return 1;
}

# Based upon autodie 2.10.
my %AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP = (
    # Map builtins to themselves.
    (
        map { ($_ => { $_ => 1 }) }
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen exec fcntl fileno flock fork getsockopt ioctl
                link listen mkdir msgctl msgget msgrcv msgsnd open opendir
                pipe read readlink recv rename rmdir seek semctl semget semop
                send setsockopt shmctl shmget shmread shutdown socketpair
                symlink sysopen sysread sysseek system syswrite truncate umask
                unlink
            >
    ),

    # Generate these using tools/dump-autodie-tag-contents
    ':threads'      => { map { $_ => 1 } qw< fork                        > },
    ':system'       => { map { $_ => 1 } qw< exec system                 > },
    ':dbm'          => { map { $_ => 1 } qw< dbmclose dbmopen            > },
    ':semaphore'    => { map { $_ => 1 } qw< semctl semget semop         > },
    ':shm'          => { map { $_ => 1 } qw< shmctl shmget shmread       > },
    ':msg'          => { map { $_ => 1 } qw< msgctl msgget msgrcv msgsnd > },
    ':file'     => {
        map { $_ => 1 }
            qw<
                binmode chmod close fcntl fileno flock ioctl open sysopen
                truncate
            >
    },
    ':filesys'      => {
        map { $_ => 1 }
            qw<
                chdir closedir link mkdir opendir readlink rename rmdir
                symlink umask unlink
            >
    },
    ':ipc'      => {
        map { $_ => 1 }
            qw<
                msgctl msgget msgrcv msgsnd pipe semctl semget semop shmctl
                shmget shmread
            >
    },
    ':socket'       => {
        map { $_ => 1 }
            qw<
                accept bind connect getsockopt listen recv send setsockopt
                shutdown socketpair
            >
    },
    ':io'       => {
        map { $_ => 1 }
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen fcntl fileno flock getsockopt ioctl link
                listen mkdir msgctl msgget msgrcv msgsnd open opendir pipe
                read readlink recv rename rmdir seek semctl semget semop send
                setsockopt shmctl shmget shmread shutdown socketpair symlink
                sysopen sysread sysseek syswrite truncate umask unlink
            >
    },
    ':default'      => {
        map { $_ => 1 }
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen fcntl fileno flock fork getsockopt ioctl link
                listen mkdir msgctl msgget msgrcv msgsnd open opendir pipe
                read readlink recv rename rmdir seek semctl semget semop send
                setsockopt shmctl shmget shmread shutdown socketpair symlink
                sysopen sysread sysseek syswrite truncate umask unlink
            >
    },
    ':all'      => {
        map { $_ => 1 }
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen exec fcntl fileno flock fork getsockopt ioctl
                link listen mkdir msgctl msgget msgrcv msgsnd open opendir
                pipe read readlink recv rename rmdir seek semctl semget semop
                send setsockopt shmctl shmget shmread shutdown socketpair
                symlink sysopen sysread sysseek system syswrite truncate umask
                unlink
            >
    },
);

sub _is_fatal {
    my ($elem) = @_;

    my $top = $elem->top();
    return undef if not $top->isa('PPI::Document');

    my $includes = $top->find('PPI::Statement::Include');
    return undef if not $includes;

    for my $include (@{$includes}) {
        next if 'use' ne $include->type();

        if ('Fatal' eq $include->module()) {
            my @args = parse_arg_list($include->schild(1));
            foreach my $arg (@args) {
                return 1 if $arg->[0]->isa('PPI::Token::Quote') && $elem eq $arg->[0]->string();
            }
        }
        elsif ('Fatal::Exception' eq $include->module()) {
            my @args = parse_arg_list($include->schild(1));
            shift @args;  # skip exception class name
            foreach my $arg (@args) {
                return 1 if $arg->[0]->isa('PPI::Token::Quote') && $elem eq $arg->[0]->string();
            }
        }
        elsif ('autodie' eq $include->pragma()) {
            return _is_covered_by_autodie($elem, $include);
        }
    }

    return undef;
}

sub _is_covered_by_autodie {
    my ($elem, $include) = @_;

    my $autodie = $include->schild(1);
    my @args = parse_arg_list($autodie);
    my $first_arg = first_arg($autodie);

    # The first argument to any `use` pragma could be a version number.
    # If so, then we just discard it. We only want the arguments after it.
    if ($first_arg and $first_arg->isa('PPI::Token::Number')){ shift @args };

    if (@args) {
        foreach my $arg (@args) {
            my $builtins =
                $AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP{
                    $arg->[0]->string
                };

            return 1 if $builtins and $builtins->{$elem->content()};
        }
    }
    else {
        my $builtins =
            $AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP{':default'};

        return 1 if $builtins and $builtins->{$elem->content()};
    }

    return undef;
}
# End from Perl::Critic::Utils

# From Perl::Critic::Utils::PPI
sub is_ppi_generic_statement {
    my $element = shift;

    my $element_class = blessed($element);

    return undef if not $element_class;
    return undef if not $element->isa('PPI::Statement');

    return $element_class eq 'PPI::Statement';
}

sub is_ppi_statement_subclass {
    my $element = shift;

    my $element_class = blessed($element);

    return undef if not $element_class;
    return undef if not $element->isa('PPI::Statement');

    return $element_class ne 'PPI::Statement';
}

sub is_ppi_constant_element {
    my $element = shift or return undef;

    blessed( $element ) or return undef;

    # TODO implement here documents once PPI::Token::HereDoc grows the
    # necessary PPI::Token::Quote interface.
    return
            $element->isa( 'PPI::Token::Number' )
        ||  $element->isa( 'PPI::Token::Quote::Literal' )
        ||  $element->isa( 'PPI::Token::Quote::Single' )
        ||  $element->isa( 'PPI::Token::QuoteLike::Words' )
        ||  (
                $element->isa( 'PPI::Token::Quote::Double' )
            ||  $element->isa( 'PPI::Token::Quote::Interpolate' ) )
            &&  $element->string() !~ m< (?: \A | [^\\] ) (?: \\\\)* [\$\@] >smx
        ;
}

sub is_subroutine_declaration {
    my $element = shift;

    return undef if not $element;

    return 1 if $element->isa('PPI::Statement::Sub');

    if ( is_ppi_generic_statement($element) ) {
        my $first_element = $element->first_element();

        return 1 if
                $first_element
            and $first_element->isa('PPI::Token::Word')
            and $first_element->content() eq 'sub';
    }

    return undef;
}

sub is_in_subroutine {
    my ($element) = @_;

    return undef if not $element;
    return 1 if is_subroutine_declaration($element);

    while ( $element = $element->parent() ) {
        return 1 if is_subroutine_declaration($element);
    }

    return undef;
}
# End from Perl::Critic::Utils::PPI

1;

=head1 NAME

PPIx::Utils::Classification - Utility functions for classification of PPI
elements

=head1 SYNOPSIS

    use PPIx::Utils::Classification ':all';

=head1 DESCRIPTION

This package is a component of L<PPIx::Utils> that contains functions for
classification of L<PPI> elements.

=head1 FUNCTIONS

All functions can be imported by name, or with the tag C<:all>.

=head2 is_assignment_operator

    my $bool = is_assignment_operator($element);

Given a L<PPI::Token::Operator> or a string, returns true if that
token represents one of the assignment operators (e.g.
C<= &&= ||= //= += -=> etc.).

=head2 is_perl_global

    my $bool = is_perl_global($element);

Given a L<PPI::Token::Symbol> or a string, returns true if that token
represents one of the global variables provided by the L<English>
module, or one of the builtin global variables like C<%SIG>, C<%ENV>,
or C<@ARGV>.  The sigil on the symbol is ignored, so things like
C<$ARGV> or C<$ENV> will still return true.

=head2 is_perl_builtin

    my $bool = is_perl_builtin($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8.

=head2 is_perl_bareword

    my $bool = is_perl_bareword($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a bareword (e.g. "if", "else",
"sub", "package") defined in Perl 5.8.8.

=head2 is_perl_filehandle

    my $bool = is_perl_filehandle($element);

Given a L<PPI::Token::Word>, or string, returns true if that token
represents one of the global filehandles (e.g. C<STDIN>, C<STDERR>,
C<STDOUT>, C<ARGV>) that are defined in Perl 5.8.8.  Note that this
function will return false if given a filehandle that is represented
as a typeglob (e.g. C<*STDIN>)

=head2 is_perl_builtin_with_list_context

    my $bool = is_perl_builtin_with_list_context($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that provide a list context to the
following tokens.

=head2 is_perl_builtin_with_multiple_arguments

    my $bool = is_perl_builtin_with_multiple_arguments($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that B<can> take multiple arguments.

=head2 is_perl_builtin_with_no_arguments

    my $bool = is_perl_builtin_with_no_arguments($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that B<cannot> take any arguments.

=head2 is_perl_builtin_with_one_argument

    my $bool = is_perl_builtin_with_one_argument($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that takes B<one and only one>
argument.

=head2 is_perl_builtin_with_optional_argument

    my $bool = is_perl_builtin_with_optional_argument($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that takes B<no more than one>
argument.

The sets of values for which
L</is_perl_builtin_with_multiple_arguments>,
L</is_perl_builtin_with_no_arguments>,
L</is_perl_builtin_with_one_argument>, and
L</is_perl_builtin_with_optional_argument> return true are disjoint
and their union is precisely the set of values that
L</is_perl_builtin> will return true for.

=head2 is_perl_builtin_with_zero_and_or_one_arguments

    my $bool = is_perl_builtin_with_zero_and_or_one_arguments($element);

Given a L<PPI::Token::Word>, L<PPI::Statement::Sub>, or string,
returns true if that token represents a call to any of the builtin
functions defined in Perl 5.8.8 that takes no and/or one argument.

Returns true if any of L</is_perl_builtin_with_no_arguments>,
L</is_perl_builtin_with_one_argument>, and
L</is_perl_builtin_with_optional_argument> returns true.

=head2 is_qualified_name

    my $bool = is_qualified_name($name);

Given a string, L<PPI::Token::Word>, or L<PPI::Token::Symbol>, answers
whether it has a module component, i.e. contains "::".

=head2 is_hash_key

    my $bool = is_hash_key($element);

Given a L<PPI::Element>, returns true if the element is a literal hash
key.  PPI doesn't distinguish between regular barewords (like keywords
or subroutine calls) and barewords in hash subscripts (which are
considered literal).  So this subroutine is useful if your Policy is
searching for L<PPI::Token::Word> elements and you want to filter out
the hash subscript variety.  In both of the following examples, "foo"
is considered a hash key:

    $hash1{foo} = 1;
    %hash2 = (foo => 1);

But if the bareword is followed by an argument list, then perl treats
it as a function call.  So in these examples, "foo" is B<not>
considered a hash key:

    $hash1{ foo() } = 1;
    &hash2 = (foo() => 1);

=head2 is_included_module_name

    my $bool = is_included_module_name($element);

Given a L<PPI::Token::Word>, returns true if the element is the name
of a module that is being included via C<use>, C<require>, or C<no>.

=head2 is_integer

    my $bool = is_integer($value);

Answers whether the parameter, as a string, looks like an integral
value.

=head2 is_class_name

    my $bool = is_class_name($element);

Given a L<PPI::Token::Word>, returns true if the element that
immediately follows this element is the dereference operator "->".
When a bareword has a "->" on the B<right> side, it usually means that
it is the name of the class (from which a method is being called).

=head2 is_label_pointer

    my $bool = is_label_pointer($element);

Given a L<PPI::Token::Word>, returns true if the element is the label
in a C<next>, C<last>, C<redo>, or C<goto> statement.  Note this is
not the same thing as the label declaration.

=head2 is_method_call

    my $bool = is_method_call($element);

Given a L<PPI::Token::Word>, returns true if the element that
immediately precedes this element is the dereference operator "->".
When a bareword has a "->" on the B<left> side, it usually means that
it is the name of a method (that is being called from a class).

=head2 is_package_declaration

    my $bool = is_package_declaration($element);

Given a L<PPI::Token::Word>, returns true if the element is the name
of a package that is being declared.

=head2 is_subroutine_name

    my $bool = is_subroutine_name($element);

Given a L<PPI::Token::Word>, returns true if the element is the name
of a subroutine declaration.  This is useful for distinguishing
barewords and from function calls from subroutine declarations.

=head2 is_function_call

    my $bool = is_function_call($element);

Given a L<PPI::Token::Word> returns true if the element appears to be
call to a static function.  Specifically, this function returns true
if L</is_hash_key>, L</is_method_call>, L</is_subroutine_name>,
L</is_included_module_name>, L</is_package_declaration>,
L</is_perl_bareword>, L</is_perl_filehandle>, L</is_label_pointer> and
L</is_subroutine_name> all return false for the given element.

=head2 is_in_void_context

    my $bool = is_in_void_context($token);

Given a L<PPI::Token>, answer whether it appears to be in a void
context.

=head2 is_unchecked_call

    my $bool = is_unchecked_call($element);

Given a L<PPI::Element>, test to see if it contains a function call
whose return value is not checked.

=head2 is_ppi_expression_or_generic_statement

    my $bool = is_ppi_expression_or_generic_statement($element);

Answers whether the parameter is an expression or an undifferentiated
statement.  I.e. the parameter either is a
L<PPI::Statement::Expression> or the class of the parameter is
L<PPI::Statement> and not one of its subclasses other than
C<Expression>.

=head2 is_ppi_generic_statement

    my $bool = is_ppi_generic_statement($element);

Answers whether the parameter is an undifferentiated statement, i.e.
the parameter is a L<PPI::Statement> but not one of its subclasses.

=head2 is_ppi_statement_subclass

    my $bool = is_ppi_statement_subclass($element);

Answers whether the parameter is a specialized statement, i.e. the
parameter is a L<PPI::Statement> but the class of the parameter is not
L<PPI::Statement>.

=head2 is_ppi_simple_statement

    my $bool = is_ppi_simple_statement($element);

Answers whether the parameter represents a simple statement, i.e. whether the
parameter is a L<PPI::Statement>, L<PPI::Statement::Break>,
L<PPI::Statement::Include>, L<PPI::Statement::Null>,
L<PPI::Statement::Package>, or L<PPI::Statement::Variable>.

=head2 is_ppi_constant_element

    my $bool = is_ppi_constant_element($element);

Answers whether the parameter represents a constant value, i.e. whether the
parameter is a L<PPI::Token::Number>, L<PPI::Token::Quote::Literal>,
L<PPI::Token::Quote::Single>, or L<PPI::Token::QuoteLike::Words>, or
is a L<PPI::Token::Quote::Double> or L<PPI::Token::Quote::Interpolate>
which does not in fact contain any interpolated variables.

This subroutine does B<not> interpret any form of here document as a constant
value, and may not until L<PPI::Token::HereDoc> acquires the relevant
portions of the L<PPI::Token::Quote> interface.

This subroutine also does B<not> interpret entities created by the
L<ReadonlyX> module (or similar) or the L<constant> pragma as constants.

=head2 is_subroutine_declaration

    my $bool = is_subroutine_declaration($element);

Is the parameter a subroutine declaration, named or not?

=head2 is_in_subroutine

    my $bool = is_in_subroutine($element);

Is the parameter a subroutine or inside one?

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

Code originally from L<Perl::Critic::Utils> by Jeffrey Ryan Thalhammer
<jeff@imaginative-software.com> and L<Perl::Critic::Utils::PPI> by
Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2011 Imaginative Software Systems,
2007-2011 Elliot Shank, 2017 Dan Book.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Perl::Critic::Utils>, L<Perl::Critic::Utils::PPI>
