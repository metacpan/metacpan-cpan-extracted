package Whatif;

use strict;
use POSIX ();
use Carp qw(croak);
use base qw(Exporter DynaLoader);
use vars qw(@EXPORT $VERSION $ERR);
@EXPORT = qw(whatif ifonly);


$VERSION = '1.3';


$ERR = undef;


bootstrap Whatif $VERSION;


# do all the magic
sub whatif (&;$) {
    my ($whatif, $ifonly) = @_;

    $ERR = undef;
    my $dollardollar = $$;
    
    # the way to communicate between the two different versions
    my ($in, $out);
    pipe $in, $out;

    # SPLITTERS!
    my $pid = fork;
    die "couldn't fork" unless defined $pid;


    # parent
    if ($pid) {
        close $out;
        my $got = <$in>;

        # child succeded, we shut up shop and wait for it to die
        unless ($got)  {
            # close all open file handles
            foreach (0..POSIX::sysconf(&POSIX::_SC_OPEN_MAX)) { 
                POSIX::close($_);
            }

            # wait for the child to die so that we can
            waitpid($pid, 0);
            POSIX::_exit(0);
        } 


        # the child failed, set the error ...
        $Whatif::ERR = $got; 

        # ... and if we've been given an ifonly block then run it
        $ifonly->() if (defined $ifonly);
   

    # child
    } else { 
        close $in;
        # run the code we been given

        # some shennanigans, knicked from PPerl
        if ($] > 5.006001) {
            setreadonly('$', $dollardollar);
        } else {
            $$ = $dollardollar;
        }
    
        eval { $whatif->() };
        print $out $@;
        close $out;

        POSIX::_exit(0) if $@;
    }
}      

# hack
sub ifonly (&) { $_[0] }


1;

=pod

=head1 NAME

Whatif - provides rollbacks, second chances and ways to overcomes regrets in code

=head1 SYNOPSIS

  my $foo = "foo";

  whatif {    
    $foo = "bar";
  }; # foo is now "bar"


  whatif {
    $foo = "quux";
    die;
  }; # foo is still "bar", the call got rolled backed


  whatif {
    $foo = "yoo hoo!";
  } ifonly {
    $foo = "erk";
  }; # foo will be "yoo hoo"

  whatif {
    $foo = "here";
    die "Aaaargh\n";
  } ifonly {
    $foo = "there";
    print Whatif::ERR; # prints Aaaargh
  }; # foo will be "there"

  print Whatif::ERR; # also prints Aaaargh

  whatif {
    die;
  };
  print Whatif::ERR; # prints undef

  $foo = "outer";
  whatif {
    $foo = "middle";
    whatif { $foo = "inner" };
  }; # $foo is "inner";

  $foo = "outer";
  whatif {
    $foo = "middle";
    whatif { $foo = "inner"; die };
  }; # $foo is "middle";


      
B<PLEASE NOTE> the semi-colon after the I<whatif{};> block - without it you may get odd results;


=head1 DESCRIPTION

Whatif provides database-like rollbacks but for code instead of
database transactions. Think of I<whatif {}> blocks as being like
I<try{} catch{}> blocks but on steroids.

Essentially, if you die within a I<whatif {}> block then all code up
until that point will be undone. Let's face it we all have regrets and
if we can't solve them in software then where can we solve them?

But that's not all. Whatif not only provides a way out of that
horrible 'OHMYGOD! What have I done?' moments but also gives you a
second chance using our special sauce 'Guardian Angel[tm]' technology 
(patent pending). 

Simply place an I<ifonly {}> block after a I<whatif {}> block and,
should the I<whatif {}> block fail, all the code in the I<ifonly {}>
block will be executed. Que convenient!

If only life itself could be like that.

=head1 BUGS

This won't work on systems that don't have fork(). Sorry. I tried to
come up with some code that worked by intercepting all writes to %:: but
that just became a nightmare and B<Simon Cozens> advised me against it.
Then I tried something like 


  void do_magic(SV* coderef)
  {
        PerlInterpreter *orig, *copy;

        orig = Perl_get_context();
        copy = perl_clone(orig, FALSE);

        PERL_SET_CONTEXT(copy);
        perl_call_sv(coderef, G_DISCARD|G_NOARGS|G_EVAL);

         /* Errk, it failed */
        if (SvTRUE(ERRSV)) {
                fprintf(stderr, "Errrrk\n");
                PERL_SET_CONTEXT(orig);
                perl_free(copy);
        /* ooh, it was fine */
        } else {
        perl_free(orig);
        }

  }


but that would have only worked on threaded Perls (i.e 5.8) and, err,
didn't work anyway. And after a few hours poking through perlguts and
various websites I just went with the current approach.

This also won't work where you touch the world outside of Perl's
control. Basically if you write something to a socket or a file or a DB
then you're going to have to undo your mess yourself. That's what the
I<ifonly{}> block is for. There's nothing I can do about that. Deal.


=head1 NOTES AND THANKS

B<Mark Fowler> and I came up with the idea not, surprisingly, down the
pub but whilst trying to sanitise the house we were moving out of. I imagine
that the fumes probably had something to do with it and also suspect 
he deliberately planted the most crack fuelled idea he could
think of into my brain, wound me up and let me go.

The current method of I<fork>-ing was devised by B<Richard Clamp> who
basically gave me pretty much the whole module short of packaging it and
providing the I<ifonly {}> implementation. However he has more sense
than I do.

B<Tom 'jerakeen' Insam> helped with the I<perl_clone()> testing by
patiently typing in semi-lucid commands that I barked at him via IRC
whilst I tried random things out without the benefit of my own threaded
5.8 box.

B<Matt 'hardest working man in perl' Sergeant>'s PPerl provided the code 
for setting readonly variables thanks to patches from the ever helpful 
B<Richard Clamp>. This means that your PID stays the same even after a 
successful I<whatif {}> block.

I'd also like to thank my make up B<stylist>, my B<publisher> and you, the B<fans>
for making all this possible.



=head1 COPYING

(C)opyright 2002, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably destroy your life,
kill your friends, burn your house and bring about the apocalypse 

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=cut


