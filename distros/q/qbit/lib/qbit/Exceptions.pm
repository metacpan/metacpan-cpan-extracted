
=head1 Name

qbit::Exceptions - qbit exceptions

=cut

package qbit::Exceptions;
$qbit::Exceptions::VERSION = '2.5';
=head1 Synopsis

Usage:

 package Exception::Sample;
 use base qw(Exception);

 package Sample;
 use qbit;

 sub ttt {
     throw 'Fatal error';

      # or
      # throw Exception::Sample;

      # or
      # throw Exception::Sample 'Some text describing problem';
 };

 1;

One more sample. Here we are not catching proper exception, and the program
stops. Finally blocks are always executed.

 package Exception::Sample;
 use base qw(Exception);

 package Exception::OtherSample;
 use base qw(Exception);

 package Sample;
 use qbit;

 sub ttt {
  my ($self) = @_;

  try {
   print "try\n";
   throw Exception::Sample 'Exception message';
  }
  catch Exception::OtherSample with {
   print "catch\n";
  }
  finally {
   print "finally\n";
  };

  print "end\n";
 }

 1;

And one more code example. Here we have exception hierarchy. We are throwing
a complex exception but we can catch it with it's parents.

 package Exception::Basic;
 use base qw(Exception);

 package Exception::Complex;
 use base qw(Exception::Basic);

 package Sample;
 use qbit;

 sub ttt {
  my ($self) = @_;

  try {
   print "try\n";
   throw Exception::Complex 'Exception message';
  }
  catch Exception::Basic with {
   print "catch\n";
  }
  finally {
   print "finally\n";
  };

  print "end\n";
 }

 1;

In catch and finally blocks you can access $@ that stores exception object.

=cut

use strict;
use warnings;

use base qw(Exporter);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT    = qw(try catch with finally throw);
    @EXPORT_OK = @EXPORT;
}

sub try(&;$) {
    my ($sub, $catch) = @_;

    eval {$sub->()};

    my $cur_catch = $catch;
    my $find_catch = !defined($catch) || $catch->[0] eq '::FINALLY::';

    my $first_exception = '';
    if ($@) {
        $@ = Exception::SysDie->new($@)
          unless ref($@) && $@->isa('Exception');

        $first_exception = $@;

        while (defined($cur_catch)) {
            last if $cur_catch->[0] eq '::FINALLY::';
            if ($find_catch || $@->isa($cur_catch->[0])) {
                $find_catch = 1;
                if (ref($cur_catch->[1]) eq 'CODE') {
                    eval {$cur_catch->[1]($first_exception)};

                    if ($@) {
                        $find_catch = 0;

                        $@ = Exception::SysDie->new($@)
                          unless ref($@) && $@->isa('Exception');
                    }

                    last;
                } else {
                    $cur_catch = $cur_catch->[1];
                }
            } else {
                $cur_catch = $cur_catch->[ref($cur_catch->[1]) eq 'CODE' ? 2 : 1];
            }
        }
    }

    $cur_catch = $cur_catch->[ref($cur_catch->[1]) eq 'CODE' ? 2 : 1]
      while ref($cur_catch) && defined($cur_catch) && $cur_catch->[0] ne '::FINALLY::';

    die("Expected semicolon after catch block (" . join(", ", (caller())[1, 2]) . ")\n")
      if defined($cur_catch) && ref($cur_catch) ne 'ARRAY';

    $cur_catch->[1]($first_exception) if defined($cur_catch);

    die $@ if $@ && !$find_catch;
}

sub catch(&;$) {
    return [Exception => @_];
}

sub with(&;$) {
    return @_;
}

sub finally(&;$) {
    if (defined($_[1])) {die("Expected semicolon after finally block (" . join(", ", (caller())[1, 2]) . ")\n");}
    return ['::FINALLY::' => @_];
}

sub throw($) {
    my ($exception) = @_;
    $exception = Exception->new($exception) unless ref($exception);
    die $exception;
}

sub die_handler {
    die @_ unless defined($^S);    # Perl parser errors

    my ($exception) = @_;

    $exception = Exception::SysDie->new($exception) unless ref($exception);

    die $exception;
}

package Exception;
$Exception::VERSION = '2.5';
use strict;
use warnings;
use overload '""' => sub {shift->as_string()};

use Scalar::Util qw(blessed);

sub new {
    my ($this, $text, %data) = @_;
    my $class = ref($this) || $this;

    $text = '' if !defined $text;

    my @call_stack = ();
    my $i          = 0;

    while (1) {

        package DB;
$DB::VERSION = '2.5';
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) =
          caller($i);

        last if !defined($package);

        push(
            @call_stack,
            {
                package    => $package,
                filename   => $filename,
                line       => $line,
                subroutine => $subroutine,
                args       => [@DB::args],
            }
          )
          if $package ne 'qbit::Exceptions'
              && $subroutine ne 'qbit::Exceptions::try';

        ++$i;
    }

    my $caller = shift(@call_stack);
    my $self   = {
        %data,
        (
            blessed($text) && $text->isa('Exception')
            ? (text => $text->{'text'}, parent => $text)
            : (text => $text)
        ),
        filename  => $caller->{'filename'},
        package   => $caller->{'package'},
        line      => $caller->{'line'},
        callstack => \@call_stack,
    };

    bless $self, $class;
    return $self;
}

sub catch {
    return \@_;
}

sub throw {
    qbit::Exceptions::throw(shift->new(@_));
}

sub message {
    return shift->{'text'};
}

sub as_string {
    my ($self) = @_;

    return
        ref($self)
      . ": $self->{'text'}\n"
      . "    Package: $self->{'package'}\n"
      . "    Filename: $self->{'filename'} (line $self->{'line'})\n"
      . "    CallStack:\n"
      . '        '
      . join("\n        ",
        map {$_->{'subroutine'} . "() called at '$_->{'filename'}' line $_->{'line'}"} @{$self->{'callstack'}})
      . "\n"
      . ($self->{'parent'} ? "\n$self->{'parent'}\n" : '');
}

package Exception::SysDie;
$Exception::SysDie::VERSION = '2.5';
use base qw(Exception);

use strict;
use warnings;

sub new {
    my ($self, $text) = @_;

    chomp($text);

    return $self->SUPER::new($text);
}

package Exception::BadArguments;
$Exception::BadArguments::VERSION = '2.5';
use base qw(Exception);

package Exception::Denied;
$Exception::Denied::VERSION = '2.5';
use base qw(Exception);

1;
