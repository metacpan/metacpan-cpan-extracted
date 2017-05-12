# ABSTRACT: Give special powers to only some keys in a hash
package Tie::ExecHash;
{
  $Tie::ExecHash::VERSION = '0.91';
}
use Tie::Hash;
use strict;
use warnings;

BEGIN { our @ISA = qw( Tie::ExtraHash ); }

sub STORE {
    if (    ref $_[2] eq 'ARRAY'
        and @{ $_[2] } == 2
        and ref $_[2][0] eq 'CODE'
        and ref $_[2][1] eq 'CODE' )
    {
        $_[0][1]{'set'}{ $_[1] } = $_[2][0];
        $_[0][1]{'get'}{ $_[1] } = $_[2][1];
        $_[0]->SUPER::STORE( $_[1], q{} );
    }
    elsif ( exists $_[0][1]{'set'}{ $_[1] } ) {
        return &{ $_[0][1]{'set'}{ $_[1] } }( $_[2] );
    }
    else {
        shift->SUPER::STORE(@_);
    }
}

sub FETCH {
    if ( exists $_[0][1]{'get'}{ $_[1] } ) {
        return &{ $_[0][1]{'get'}{ $_[1] } }();
    }
    else {
        shift->SUPER::FETCH(@_);
    }
}

sub DELETE {
    if ( exists $_[0][1]{'set'}{ $_[1] } ) {
        $_[0]->SUPER::DELETE( $_[1] );
        return &{ $_[0][1]{'set'}{ $_[1] } }();
    }
    else {
        shift->SUPER::DELETE(@_);
    }
}


1;


=pod

=head1 NAME

Tie::ExecHash - Give special powers to only some keys in a hash

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  use Tie::ExecHash;

  my %foo = ();
  tie( %foo, 'Tie::ExecHash');

  $foo{'bar'} = 1;
  print "$foo{'bar'}\n"; # 1

  my $baz = "red";

  $foo{'bar'} = [ sub { $baz = $_[0] }, sub { $baz } ];

  print "$foo{'bar'}\n"; # red

  $foo{'bar'} = "a suffusion of yellow";

  print "$baz\n"; # a suffusion of yellow

=head1 DESCRIPTION

What this does is allow you to have some hash values act like they are tied
scalars without actually having to go through the trouble of making them
really be tied scalars.

By default the tied hash works exactly like a normal hash.  Its behavior
changes when you assign a value of an arrayref with exactly two code blocks
in it.  When you do this it uses the first as the get routine and the second
as the set routine.  Any future gets or sets to this key will be mediated
via these subroutines.

=head1 SEE ALSO

L<Tie::Hash>

L<Tie::SentientHash>

=head1 HISTORY

This was originally written as part of the development of "friv", the command
line client for the Volity project. L<http://www.volity.org/>

=head1 AUTHOR

Becca <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

