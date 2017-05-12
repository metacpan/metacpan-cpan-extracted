package Text::Livedoor::Wiki::Plugin::Inline;

use warnings;
use strict;
use base qw(Class::Data::Inheritable);
use Text::Livedoor::Wiki::Utils;

__PACKAGE__->mk_classdata('regex');
__PACKAGE__->mk_classdata('n_args');
__PACKAGE__->mk_classdata('dependency');

sub process { die 'implement me' }
sub process_mobile { shift->process(@_) }

sub uid {
    return $Text::Livedoor::Wiki::scratchpad->{core}{inline_uid};
}
sub opts {
    return $Text::Livedoor::Wiki::opts;
}
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline - Inline Plugin Base Class

=head1 DESCRIPTION

you can use this class as base to create Inline Plugin. 

=head1 SYNOPSIS

 package Text::Livedoor::Wiki::Plugin::Inline::Del;
 
 use warnings;
 use strict;
 use base qw(Text::Livedoor::Wiki::Plugin::Inline);
 
 __PACKAGE__->regex(q{%%([^%]*)%%});
 __PACKAGE__->n_args(1);
 __PACKAGE__->dependency( 'Text::Livedoor::Wiki::Plugin::Inline::Underbar' );
 
 sub process {
     my ( $class , $inline , $line ) = @_;
     $line = $inline->parse($line);
     return "<del>$line</del>";
 }
 1;

=head1 FUNCTION

=head2 regex

set regex for your inline formatter rule

=head2 n_args

set how many args you take

=head2 dependency

set dependency plugin which must check before your plugin

=head2 process

return HTML you want to display

=head2  process_mobile

If you did not use it, then $class->process() is run.

=head2  uid

get unique id

=head2 opts

get opts 

=head1 AUTHOR

polocky

=cut
