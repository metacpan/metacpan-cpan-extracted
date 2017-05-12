package uny2k;

use strict;
use warnings;

our $VERSION = '19.1080828';

use Carp;

use overload '+' => \&add,
             '%' => \&mod,
             ''  => \&stringize,
             '0+'=> \&numize,
             'fallback' => 'TRUE';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my($year, $reaction) = @_;

    my $self = {};
    $self->{_Year}      = $year;
    $self->{_Reaction}  = $reaction || 'die';

    return bless $self => $class;
}


sub stringize {
    return shift->{_Year};
}


sub numize {
    return shift->{_Year};
}


sub _mk_localtime {
    my($reaction) = shift;
	
    return sub {
        return @_  ? localtime($_[0]) : localtime() unless wantarray;
        my @t = @_ ? localtime($_[0]) : localtime();
        $t[5] = __PACKAGE__->new($t[5], $reaction);
        @t;
    }
}

sub _mk_gmtime {
    my($reaction) = shift;

    return sub {
        return @_  ? gmtime($_[0]) : gmtime() unless wantarray;
        my @t = @_ ? gmtime($_[0]) : gmtime();
        $t[5] = __PACKAGE__->new($t[5], $reaction);
        @t;
    }
}


sub import {
    () = shift; # Dump the package.
    my $reaction = shift;
    my $caller = caller;
	
    $reaction = ':DIE' unless defined $reaction;

    $reaction = $reaction eq ':WARN' ? 'warn' : 'die';
	
    {
        no strict 'refs';
        *{$caller . '::localtime'} = _mk_localtime($reaction);
        *{$caller . '::gmtime'}    = _mk_gmtime($reaction);
    }

    return 1;
}

sub add {
    my($self, $a2) = @_;

    if( $a2 == 1900 ) {
        carp("Possible y2k fix found!  Unfixing.");
        return "19" . $self->{_Year};
    }
    else {
        return $self->{_Year} + $a2;
    }
}

sub mod {
    my($self, $modulus) = @_;

    if( $modulus == 100 ) {
        carp("Possible y2k fix found!  Unfixing.");
        return $self->{_Year};
    }
    else {
        return $self->{_Year} % $modulus;
    }
}

sub concat {
    my($self, $a2, $rev) = @_;

    if ($rev) {
    	return $a2 . $self->{_Year};
    } else {
    	return $self->{_Year} . $a2;
    }

    return $self->{_Year};
}


=head1 NAME

uny2k - Removes y2k fixes

=head1 SYNOPSIS

  use uny2k;

  $year = (localtime)[5];
  printf "In the year %d, computers will everything for us!\n", 
      $year += 1900;

=head1 DESCRIPTION

Y2K has come and gone and none of the predictions of Doom and Gloom
came to past.  As the crisis is over, you're probably wondering why
you went through all that trouble to make sure your programs are "Y2K
compliant".  uny2k.pm is a simple module to remove the now unnecessary
y2k fixes from your code.

Y2K was a special case of date handling, and we all know that special
cases make programs more complicated and slower.  Also, most Y2K fixes
will fail around 2070 or 2090 (depending on how careful you were when
writing the fix) so in order to avert a future crisis it would be best
to remove the broken "fix" now.

uny2k will remove the most common y2k fixes in Perl:

=for example
use uny2k;
my $year = (localtime)[5];

=also begin example

    $full_year = $year + 1900;

    $two_digit_year = $year % 100;

=also end example

It will change them back to their proper post-y2k values, 19100 and
100 respectively.

=for example_testing
my $real_year = (CORE::localtime)[5];
is( $full_year,      '19'.$real_year,   "undid + 1900 fix" );
is( $two_digit_year, $real_year,        "undid % 100 fix"  );


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> 
with apologies to Mark "I am not ominous" Dominus for further abuse 
of his code.


=head1 LICENSE and COPYRIGHT

Copyright 2001-2008 Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself (though why you
would want to is beyond me).

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

y2k.pm, D'oh::Year, a good therapist

=cut

"Yes, this code is a joke.";
