use strict;
use warnings;
package provide;

use Exporter; # we shove it onto other people's @ISA, so we should load it ourselves

our $VERSION = 0.03;

sub import {
  my ($class, @args) = @_;

  my ($calling_class) = caller;

  my $match = pick_module_to_load(@args);
  die "Couldn't parse @args, are you sure I know what I'm doing?" if !$match;
  load($match);

  # set up the calling class as though it inherited from Exporter
  {
    no strict 'refs';
    push @{"$calling_class\::ISA"}, qw(Exporter);
    push @{"$calling_class\::EXPORT"}, @{"$match\::EXPORT"};
  }

  # export functions from $match to $calling_class so that users of $calling_class get them as
  # though they were implemented in $calling_class, not in $match
  {
    no strict 'refs';
    for my $function (@{"$match\::EXPORT"}) {
      *{"$calling_class\::$function"} = \&{"$match\::$function"};
    }
  }
}

sub looks_like_a_module { return shift() =~ m{^[\w:]+} }

# try to load a module or die trying
sub load {
  my ($module) = @_;

  if (looks_like_a_module($module)) {
    local $@;
    eval "use $module";
    die $@ if $@;
  } else {
    die "hit $module but it doesn't look like a module name, refusing to load it";
  }
}

sub pick_module_to_load {
  my (@args) = @_;

  my @clauses = ([]);

  foreach (@args) {
    push @{$clauses[-1]}, $_;
    push @clauses, [] if $clauses[-1][0] =~ /if|elsif/ && @{$clauses[-1]} == 4;
  }

  my %condition = (
    gt => sub { $] >  shift() },
    ge => sub { $] >= shift() },
    eq => sub { $] == shift() },
    ne => sub { $] != shift() },
    le => sub { $] <= shift() },
    lt => sub { $] <  shift() },
  );

  foreach (@clauses) {
    if (@$_ == 4) {
      my ($if, $condition, $version, $module) = @$_;

      die "can't handle line: @$_\n" unless
        ($if =~ /if|elsif/) &&
        exists $condition{$condition} &&
        $version =~ /^\d[\.\d]*$/ &&
        looks_like_a_module($module);

      return $module if $condition{$condition}->($version);
    } elsif (@$_ == 2) {
      my ($else, $module) = @$_;

      die "can't handle line: @$_\n" unless
        $else eq 'else' &&
        looks_like_a_module($module);

      return $module;
    }
  }
}

1;

__END__

=head1 NAME

provide - easily switch between different implementations depending on which version of Perl is detected

=head1 SYNOPSIS

    package My::Module;

    use provide (
        if => ge => '5.013000' => 'My::Module::v5_013000',
        else                   => 'My::Module::v5_080000',
    );

=head1 DESCRIPTION

Good code is free of side effects, avoids tight coupling, and solves a useful problem in an understandable way.
This module, on the other hand, is ball of frightened octopuses clinging together.

The simple act of adding

    use provide (...)

to an otherwise well-behaved class performs the following changes to it:

=over 4

=item * The calling module automatically inherits from Exporter.

=item * provide.pm finds suitable modules to load and loads them.

=item * Any functions exported by the loaded modules get re-exported by the calling module.

=back

This module is marginally useful if you are implementing your own module and you end up stumbling over some
bug in your code caused by a change to the Perl core. Here's a worked example of when you might use this module:

=head2 hash_pop v1.0 - pass by value

Let's pretend you want to implement your own version of pop, but for hashes: it'll return the last key+value
pair of the hash (whatever "last" means in the context of an inherently unordered list!). You might start
out like this:

    use strict;
    use warnings;
    package My::Module;
    use base qw(Exporter);

    our @EXPORT = qw(hash_pop);

    sub hash_pop {
        my (%hash) = @_;
        my ($last_key) = reverse keys %hash;
        return ($last_key, delete $hash{$last_key});
    }

    1;

    __END__

Well, this is about as good an implementation as you can expect. It is easy enough to call:

    my %hash = (1..10); # Belden's default "just give me some kind of hash" hash

    my ($last_key, $last_value) = hash_pop(%hash);

But unlike the C<pop> that we're mimicking, our C<hash_pop> doesn't mutate the %hash that we pass in, so it's not very C<pop>-like yet.

=head2 hash_pop v1.1 - explicit pass by reference

To mutate our subject %hash, we'll need to pass by reference:

    sub hash_pop {
        my $hash = shift;
        my ($last_key) = reverse keys %$hash;
        return ($last_key, delete $hash->{$last_key});
    }

And since we're passing by reference, we'd darn well better change our call pattern:

    my %hash = (1..10);

    my ($last_key, $last_value) = hash_pop(\%hash);

=head2 hash_pop v1.2 - implicit pass by reference

If only there were a way to implicitly pass %hash by reference to C<hash_pop> - then we'd have the
best of both worlds, wouldn't we? (Would we? I really don't know.)

Ruby and Python aren't the only languages that have built-in documentation; look at this marvelous
interaction with the Perl debugger:

    $ perl -de 1
      DB<1> p prototype 'CORE::keys'
    \%

That's pretty good stuff! Take that, highly self-documenting languages! Now we know how to change C<hash_pop>:

    sub hash_pop (\%) {
        my $hash = shift;
        my ($last_key) = reverse keys %$hash;
        return ($last_key, delete $hash->{$last_key});
    }

And now here's someone using this ridiculous function:

    my %hash = (1..10);

    my ($last_key, $last_value) = hash_pop(%hash);

Sweet! All done, let's stick it on CPAN!

=head2 Uh-oh, implementing CORE::-like functions means we have to respect the CORE

Except: you're not done until you run it against every version of Perl you can shake a
L<perlbrew|http://perlbrew.pl> at. And when you go through and do that, you'll discover
a break between Perl v5.12 and v5.13:

    $ perlbrew list | \
      cut -b 3- | (while read ver; do \
          perlbrew use $ver; \
          perl -le 'print $] . "\t" . prototype q,CORE::keys,'; \
      done)

    __END__
    5.006002  \%
    5.008009  \%
    5.010001  \%
    5.012005  \[@%]
    5.014003  +
    5.016002  +
    5.017008  +

Aww, nerds! there's two difference prototypes in play here: \% and +. One valid option is to just
give up on supporting older versions of Perl. Another is to implement your own version-specific
loading code. And yet another option is to use this module to gloss away implementing your own
version-specific code:

=head2 hash_pop v1.3 - version-specific prototypes for implicit reference passing

    use strict;
    use warnings;
    package My::Module;

    use provide (
        if => ge => '5.013000' => 'My::Module::hash_pop::v5_013000',
        else                   => 'My::Module::hash_pop::v5_006000',
    );

    sub _hash_pop {
        my $hash = shift;
        my ($last_key) = reverse keys %$hash;
        return ($last_key, delete $hash->{$last_key});
    }

    1;

We're collecting common behavior between the two version-specific modules in My::Module::_hash_pop.

Now all that's left is to write your version-specific modules. Here's the one for v5.013000 and above:

    use strict;
    use warnings;
    package My::Module::hash_pop::v5_013000;

    our @EXPORT = qw(hash_pop);

    require My::Module;

    sub hash_pop (+) { goto &My::Module::_hash_pop }

    1;

The module for v5.006000 would be nearly identical:

    use strict;
    use warnings;
    package My::Module::hash_pop::v5_006000;

    our @EXPORT = qw(hash_pop);

    require My::Module;

    sub hash_pop (\%) { goto &My::Module::_hash_pop }

    1;

And now someone can go and use our module:

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use My::Module qw(hash_pop);

    my %hash = (1..10);
    my ($nine, $ten) = hash_pop %hash;

=head1 SYNTAX

Currently two statements are supported: C<if> and C<else>.

=head2 if => TEST => VALUE => RESULT

=head3 TEST

TEST may be any of:

    gt   "greater than"
    ge   "greater or equal to"
    eq   "equal to"
    ne   "not equal to"
    le   "less than or equal to"
    lt   "less than"

=head3 VALUE

VALUE should be a string which describes something you might get back in $]. See also: L<perldoc>.

=head3 RESULT

RESULT is the resulting module that will be loaded if this condition is true.

=head2 else                => RESULT

In the event that the preceding C<if> condition is false, the C<else> RESULT will be loaded.

=head1 BUGS

Please report bugs on this project's L<Github issues page|http://github.com/belden/perl-provide/issues>.

=head1 APOLOGY

Too often the explanation for crufty code is, "It seemed like a good idea at the time." To the contrary,
this seems like a strange idea.

I really don't know if this will be useful to anyone at all. One of the challenges to us portraying the Perl
community as actively growing is that there are so many well-tested implementations on CPAN to the various
Big Problems we all face: processing a CGI form, connecting to a DB_File, writing EBCDIC things (whatever
those are!); and more modernishly, Dancing with Mooses and Catalytic Test frameworks.

=head1 ACKNOWLEDGEMENTS

L<Sam Merrit|http://twitter.com/torgomatic> coined the phrase "a ball of frightened octopuses clinging together".

L<Logan Bell|http://twitter.com/epochbell> practically dared me to release this. Well, maybe he would if I were to
ask him.

L<John Napiorkowski|https://github.com/jjn1056> originally put in my head the notion that, "A CPAN module is a unit of
conversation between developers. It says, 'Here is a problem, and here is my take on how to solve it.'" This module is
the equivalent of me standing in a corner and mumbling to myself.

L<My employer|http://shutterstock.com/jobs.mhtml>, L<Shutterstock, Inc.|http://shutterstock.com>, is a
L<staunch supporter|http://code.shutterstock.com> of open-source software. It's a shame I've worked so hard
to link them to this amusing but disingenuous implementation.

=head1 CONTRIBUTING

Feel free to use and improve this software in whatever way you see fit. This code is hosted on Github.com
at L<http://github.com/belden/perl-provide>.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.
