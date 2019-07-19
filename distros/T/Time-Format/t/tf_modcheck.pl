
=head1 NAME

tf_modcheck.pl - Script to check module availability.

=head1 DESCRIPTION

This is a hacky little script for unit tests to use in order to determine whether a
given module exists -- without the unit test having to load the module itself.
Instead the module is loaded here, in a separate perl process.  Why?  Because some
tests should only be run if certain modules have been installed, but Time::Format is
supposed to detect and load those modules itself.  If the unit test loaded them, it
would affect Time::Format's operation.

This script should be run via the tf_module_check function of the special-purpose
TimeFormat_MC module, which invokes the script and interprets its results.

=cut

use strict;

my $GOOD = 'yes';               # Module was loaded successfully
my $BAD  = 'no';                # Module was not found
my $ERR  = 'err';               # An error occurred
my %RV = (
          # Program return values (exit status)
          $GOOD => 0,
          $BAD  => 1,
          $ERR  => 2,
         );


sub output
{
    my ($code) = @_;

    print "$code\n";
    my $rv = $RV{$code} // $RV{$ERR};
    exit($rv);
}

sub output2
{
    my ($code1, $code2) = @_;

    print "$code1 $code2\n";
    my $rv;
    $rv = $RV{$GOOD}  if $code1 eq $GOOD  ||  $code2 eq $GOOD;
    $rv = $RV{$ERR}   if $code1 eq $ERR   ||  $code2 eq $ERR;
    $rv //= $RV{$BAD};
    exit($rv);
}


output $ERR
    unless @ARGV;

my $mod = shift @ARGV;
my $chunkpat = qr/ [_[:alpha:]]+ [_[:alnum:]]* /x;

output $ERR
    unless $mod =~ /\A $chunkpat (?: :: $chunkpat)* \z/x;

output $BAD
    unless eval "require $mod; 1";

# Annoying special case for Date::Manip.
# If we can load Date::Manip, we can do some of the tests.
# Other tests require that Date::Manip can also determine the current time zone.
# So we have to return two values here.
if ($mod eq 'Date::Manip')
{
    # Get the local time zone
    if (eval ('Date::Manip::Date_TimeZone (); 1'))
    {
        output2 $GOOD, $GOOD;
    }
    else
    {
        output2 $GOOD, $BAD;
    }
}

output $GOOD;
