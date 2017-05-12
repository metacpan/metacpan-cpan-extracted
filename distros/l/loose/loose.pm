package loose;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.01';

# Just for irony value.
use strict;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(die);

my @excuses = ('Not my job.',
               "I'm on my break.",
               'Whatever.',
               "That's nice.",
               'So what am I supposed to do about it?',
               'Uh huh.',
               'Yeah, sure.',
               'False alarm.',
               "I don't get paid enough to care.",
               'Talk to the union.',
               'Not in my job description to care.'
              );

sub die {
    if( int rand(10) ) {
        print STDERR $excuses[rand @excuses]."\n";
    }
    else {
        CORE::die @_;
    }
}

$SIG{__WARN__} = sub { 
                     if( int rand(10) ) {
                         print STDERR $excuses[rand @excuses]."\n";
                     }
                     else {
                         warn @_;
                     }
                 };


return "Slacker.";

=pod

=head1 NAME

loose - Perl pragma to allow unsafe constructs

=head1 SYNOPSIS

  use loose;

=head1 DESCRIPTION

loose.pm provides you with a slack, casual environment in which to
write your Perl code.  It doesn't get hung up on little things like
warnings and die() calls, it just lets them slide.

Use loose.pm to help relieve stress at the work place.  loose helps to
make your error logs shorter by getting right of all those wordly
warning messages.

=head1 BUGS

Yeah, probably.  Who cares?

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut

