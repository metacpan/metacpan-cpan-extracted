package VS::RuleEngine::Constants;

use strict;
use warnings;

use constant KV_ABORT		=> 0;
use constant KV_CONTINUE	=> 1;

use constant KV_NO_MATCH    => 0;
use constant KV_MATCH       => 1;
use constant KV_SKIP        => 2;

use constant KV_SELF		=> 0;
use constant KV_INPUT       => 1;
use constant KV_GLOBAL		=> 2;
use constant KV_LOCAL		=> 3;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    KV_ABORT
    KV_CONTINUE
    
    KV_MATCH
    KV_NO_MATCH
    KV_SKIP
    
    KV_GLOBAL
    KV_INPUT
    KV_LOCAL
    KV_SELF
);

our @EXPORT_OK = @EXPORT;

our %EXPORT_TAGS = (
	constants => [@EXPORT],
);

1;
__END__

=head1 NAME

VS::RuleEngine::Constants - Constants used by the engine

=head1 EXPORTED SYMBOLS

=head2 Hook return codes

=over 4

=item KV_ABORT

Used to indicate execution of the engine should be aborted.

=item KV_CONTINUE

Used to indicate execution of the engine should continue.

=back

=head2 Rule return codes

=over 4

=item KV_NO_MATCH

Used to indicate a rule didn't match.

=item KV_MATCH

Used to indicate a rule matched.

=back

=head2 Arguments
 
=over 4

=item KV_SELF

The invoked object - that is the rule-, input-, output-, action- etc. instance.

=item KV_GLOBAL

The global data for the engine.

=item KV_LOCAL

The local iteration data for the engine.

=item KV_INPUT

The engine inputs.

=back

=cut