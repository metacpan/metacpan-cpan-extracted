#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
# Subclassing to define the buffer variables
use strict;
use warnings;
use Test::More qw( no_plan );

ok(my $t = MyTTS->new,'object');
$t->DEBUG(0);

ok( $t->compile(q/Just a test/), 'Define output buffer variables');

package MyTTS;
use base qw(Text::Template::Simple);

# if you relied on the old interface or relied on the buffer var being $OUT,
# then you have to subclass the module to restore that behaviour.
# (not a good idea though)
sub _output_buffer_var { ## no critic (ProhibitUnusedPrivateSubroutines)
   my $self = shift;
   my $type = shift || 'scalar';
   return  $type eq 'hash'  ? '$OUT_HASH'  # map_keys buffer
         : $type eq 'array' ? '$OUT_ARRAY' # list     buffer
         :                    '$OUT'       # output   buffer
         ;
}
