package A::Base;

use strict;
use warnings;

require Exporter;
our @ISA = qw[ Exporter ];

sub import {

    my $class = $_[0];

    {
        no strict 'refs';
	no warnings 'redefine';
        *{ join( '::', $class, 'tattle' ) }    = sub () { qq[$class] };
        *{ join( '::', $class, 'tattle_ok' ) } = sub () { qq[ok: $class] };

        *{ join( '::', $class, 'EXPORT' ) }    = [qw[ tattle ]];
        *{ join( '::', $class, 'EXPORT_OK' ) } = [qw[ tattle_ok ]];

	# print STDERR "importing $class\n";

    }

    $class->export_to_level( 1, @_);
}

sub tattle () { __PACKAGE__ }
sub tattle_ok () { 'ok: ' . __PACKAGE__ }

1;


package A;
our @ISA = qw[ A::Base ];

our @inner_packages = qw[ A::Base A::C A::C::E ];
our @other_packages = qw[ D ];

sub required { 1 }


package A::C;
our @ISA = qw[ A::Base ];


package A::C::E;
our @ISA = qw[ A::Base ];

package D;
our @ISA = qw[ A::Base ];



1;
