package overload::eval;
use strict;
use warnings;
use 5.009_004;
use feature ':5.10';
use XSLoader;

our $GLOBAL = 0;

sub import {
    my ( undef, $callback ) = @_;

    $callback //= 'eval';
    given ($callback) {
        when (/^-p(?:rint)?\z/) {
            $^H{'overload::eval'} = 'overload::eval::_print';
            _global();
        }
        when (/^-p(?:e|rint-eval)\z/) {
            $^H{'overload::eval'} = 'overload::eval::_print_eval';
            _global();
        }
        default { $^H{'overload::eval'} = "$callback" };
    }

    return;
}

sub unimport {
    delete $^H{'overload::eval'};
    return;
}

sub _print {
    print @_ or die "Can't print: $!";
    exit;
}

sub _print_eval {
    print @_ or die "Can't print: $!";
    return eval "@_";
}

sub _global {
    $GLOBAL = 1;
}

our $init_done;
sub _install_eval; # Provided by eval.xs

our $VERSION = '0.10';
XSLoader::load( 'overload::eval', $VERSION );
_install_eval();

q[With great powers come laser eyebeams.];

__END__

=head1 NAME

overload::eval - Hooks the native string eval() function

=head1 SYNOPSIS

As a command line tool:

  uneval obfuscated.pl

As a module:

  use overload::eval 'my_callback';
  sub my_callback { print and eval for $_[0] }

  sub rot13 {
      local $_ = shift;
      tr[A-Za-z][N-ZA-Mn-za-m];
      return $_;
  }
  eval(rot13());

=head1 DESCRIPTION

This module hooks the native eval() function and sends it to your
function instead. The eval() function operates normally within your
function.

This module requires user pragmas which are a feature present only in
5.9.4+.

Using this module is simplicity itself. If you've declared the hook,
any uses of string eval in that lexical scope are going to be
redirected to the function you named.

  {
      use overload::eval;
      eval '...';
  }
  sub eval {
      # eval goes here
  }

If you declare a hook name, execution is redirected to that named
function instead of C<eval>.

  {
      use overload::eval 'hook';
      eval '...';
  }
  sub hook {
      # eval goes here because we declared 'hook'
  }

=head1 BUILTIN-HOOKS

There are some built-in hooks. They are accessed by importing them by
name. This can also be done on the command line.

=over

=item -p

=item -print

The C<-print> option prints the source code of the eval() and then
exits the program. I expect this option is most useful when untangling
obfuscated programs. Use of this option changes the pragma so it
operates globally. B<All> evals are now hooked.

C<-p> is a synonym for C<-print>.

The program:

  perl -Moverload::eval=-p obfuscated.pl

when run on:

  $_='cevag "Uryyb jbeyq!\a"';tr/A-Za-z/N-ZA-Mn-za-m/;eval;

prints the following and exits:

  print "Hello world!\n"

=item -pe

=item -print-eval

The C<-print-eval> option prints the source code of the eval() before
running it. Use of this option changes the pragma so it operates globally. B<All> evals are now hooked.

C<-pe> is a synonym for C<-print-eval>.

The program:

  perl -Moverload::eval=-print-eval obfuscated.pl

when run on:

  $_='cevag "Uryyb jbeyq!\a"';tr/A-Za-z/N-ZA-Mn-za-m/;eval;

prints the following:

  print "Hello world!\n"

and then runs the code which prints:

  Hello world!

=back

=head1 DISPELLING MAGIC

This module overloads eval() only with the lexical scope you've
requested. To avoid triggering this module, either create a new
lexical scope or just disable the overloading.

  {
    use overload::eval;
    eval '...'; # Overloaded;
  }
  eval '...'; # NOT overloaded

Or...

  use overload::eval;
  eval '...'; # Overloaded;
  
  no overload::eval;
  eval '...'; # NOT overloaded.

=head1 CAVEATS

This module does not overload the block form of eval. Sorry. That's an
entirely different kind of technology.

  eval { ... };

=head1 AUTHOR

Josh Jore - jjore@cpan.org

=head1 LICENSE

This module is available under the same licences as perl, the Artistic license and the GPL.
