package clobber;
use Carp;
use Fcntl;
use strict; no strict 'refs';
use vars '$VERSION'; $VERSION = 0.04;
eval "require Term::ReadKey";

sub unimport { #no strict 'refs';
  *{'CORE::GLOBAL::open'}    = \&OPEN    unless exists($^H{clobber});
  *{'CORE::GLOBAL::sysopen'} = \&SYSOPEN unless exists($^H{clobber});
  $^H{clobber} = $ENV{'clobber.pm'} || 0;
}

sub import {
  $^H{clobber} = 1;
}


sub OPEN(*;$@){
  my($handle, $mode, $file) = @_;
  my($testmode, $pipein) = $mode;

  if( scalar(@_) == 1 ){ #no strict 'refs';
    $mode = ${caller(1).'::'.$handle};
  }

  if( scalar(@_) == 2 ){
    #Convert 2-arg to 3-arg...
    #Initially tried to simply pass @_ through to CORE::open,
    #but it's prototype didn't like that

    #put into sub for /x, and easier "testing"?
    if( $mode =~ /^(\+?(?:>{1,2}|<)|(?:>&=?|<&=?|\|))?\s*(.+)\s*(\|)?$/ ){
      ($testmode, $file, $pipein) = ($1, $2, $3);
    }
    else{
      croak "Failed to parse EXPR of 2-arg open: $_[1]";
    }

    $testmode = $1 eq '|' ? '|-' : $1;
    unless( defined $testmode ){
      $testmode = $pipein ? '-|' : '>';
    }
  }
  elsif( scalar(@_) > 2 ){
    ($testmode, $file) = @_[1,2];
  }

  prompt($file) if -e $file && $testmode =~ /\+[<>](?!>)|^>(?!&|>)/;

  splice(@_, 0, 3);

  #no strict 'refs';
  CORE::open(*{caller(0) . '::' . $handle}, $testmode, $file, @_);
}

sub SYSOPEN(*$$;$){
  my($handle, $file, $mode, $perms) = @_;

  #We don't use O_EXCL because sysopen's failure is not trappable
  prompt($file) if -e $file && $mode&(O_WRONLY|O_RDWR|O_TRUNC);

  #no strict 'refs';
  CORE::sysopen(*{caller(0) . '::' . $handle}, $file, $mode, $perms||0666);
}

sub prompt{
  my $clobber = 0;

  return if (caller 1)[10]->{clobber};

  if( -t STDIN && exists($INC{'Term/ReadKey.pm'}) ){

    select(STDERR); local $|=1;
    print STDERR "Allow modification of '$_[0]'? [yN] ";

    Term::ReadKey::ReadMode('cbreak'); $clobber = Term::ReadKey::ReadKey(0);

    Term::ReadKey::ReadMode('restore'); print STDERR "\n";

    $clobber =~ y/yY/1/; $clobber =~ y/1/0/c;
  }

  croak "$_[0]: File exists" unless $clobber;
}


1;
__END__

=pod

=head1 NAME

clobber - pragma to optionally prevent over-writing files

=head1 SYNOPSIS

  no clobber;

  #Fails if /tmp/xyzzy exists
  open(HNDL, '>/tmp/xyzzy');

  {
    use clobber;

    #It's clobberin' time
    open(HNDL, '>/tmp/xyzzy');
  }

=head1 DESCRIPTION

Do you occasionally get C<+E<gt>> and C<+E<lt>> mixed up, or accidentally
leave off an E<gt> in the mode of an C<open>? Want to run some relatively
trustworthy code--such as some spaghetti monster you created in the days
of yore--but can't be bothered to check it's semantics? Or perhaps you'd
like to add a level of protection to operations on user-supplied files
without coding the logic yourself.

Yes? Then this pragma could help you from blowing away valuable data.

Like the I<noclobber> variable of some shells, this module will prevent
the use of open modes which truncate if a file already exists. This behavior
can be controlled at the block level, as demonstrated in the L</SYNOPSIS>.

=head1 DIAGNOSTICS

The pragma may throw the following exceptions:

=over

=item %s: File exists

We saved data!

=item Failed to parse EXPR of 2-arg open: %s

The module could not figure out what mode was used,
and decided to bail for safety.

This shouldn't happen.

=back

=head1 ENVIRONMENT

You may disable clobber protection at compile-time by setting the environment
variable I<clobber.pm> to 1. This allows you to include F<clobber.pm> in
I<PERL5OPT> as B<-M-clobber> for general protection, but override it as needed
for programs invoked via a pipeline.

=head1 TODO

=over

=item TESTS!

I've done some basic-testing with 2- and 3-arg forms of read/write/append,
but more thorough testing of mode-parsing and/or invocation needs to be done.

Interactive ask to run the more complex tests, with timeout to skip them.

=item wrap other data-damaging functions such as unlink and truncate?

as optional "imports"

=back

=head1 AUTHOR

Jerrad Pierce E<lt>JPIERCE circle-a CPAN full-stop ORGE<gt>

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or, if you prefer:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
