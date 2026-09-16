use strict;
use warnings;

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which leading-zero literals the policy reports, and which it lets
through as file modes

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not, under the
default configuration and under one naming the functions trog-provisioner
passes modes to.  The second table matters as much as the first: a policy that
reports every C<chmod> gets switched off.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;
use Perl::Critic::Policy::ProhibitLeadingZeros;

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for
# a .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets -- which then fail for want of POD rather than for octal.
# Note the hyphen in -single-policy: -single_policy is accepted and silently
# ignored, leaving all 200-odd policies switched on.
# The anchored long name because -single-policy is a pattern, and a bare
# 'ProhibitLeadingZeros' also matches the core policy and the Plicease one.
my $POLICY = '^Perl::Critic::Policy::ProhibitLeadingZeros$';

sub critic_with {
    my ($profile) = @_;
    return Perl::Critic->new( -profile => $profile, '-single-policy' => $POLICY, -severity => 1 );
}

sub violations {
    my ( $critic, $source ) = @_;
    return scalar $critic->critique( \$source );
}

my $default = critic_with(q{});

my %prohibited = (
    'a bare octal'                   => q{my $z = 0032;},
    'underscored'                    => q{my $z = 0_600;},
    'a mask against a mode'          => q{$mode & 0777;},
    'a mask against stat'            => q{my $perms = (stat $f)[2] & 07777;},
    'compared in a test'             => q{is( $mode, 0600, 'label' );},
    'a mask inside chmod'            => q{chmod( ( stat("$from/$script") )[2] & 07777, "$to/$script" );},
    'a mask inside is'               => q{is( ( stat $manifest )[2] & 07777, $private, 'and the manifest is ours alone' );},
    'a function nobody allowed'      => q{foo(0600);},
    'a nested call decides'          => q{chmod( foo(0600), $f );},
    'a hash, not yet passed'         => q{my %args = ( mode => 0755 );},
    'a hash key named chmod'         => q{my %h = ( chmod => 0600 );},
    'a subscript'                    => q{$h{0600};},
    'a code ref, with no name'       => q{$code->(0600);},
    'a constant'                     => q{use constant MODE => 0600;},
    'after a low-precedence or'      => q{mkdir $dir or 0700;},
    'an unconfigured method'         => q{Test::MockFile->new_dir( $d, { mode => 0755 } );},
    'an unconfigured qualified call' => q{Provisioner::Utils::write_pem( $path, $pem, 0600 );},
);

foreach my $case ( sort keys %prohibited ) {
    is( violations( $default, $prohibited{$case} ), 1, "$case is a violation: $prohibited{$case}" );
}

my %allowed = (
    'umask'                          => q{umask 0022;},
    'umask with parens'              => q{umask(077);},
    'chmod as a list operator'       => q{chmod 0600, $half;},
    'chmod with parens'              => q{chmod( 0755, "$bin/curl", "$bin/update-ca-certificates" );},
    'a setgid bit'                   => q{chmod 02750, "$tmp/destination";},
    'chmod under a postfix if'       => q{chmod 0600, $f if $secret;},
    'chmod as a method'              => q{$path->chmod(0600);},
    'chmod as a class method'        => q{Some::Class->chmod(0600);},
    'CORE::chmod'                    => q{CORE::chmod( 0600, $f );},
    'mkdir, then or die'             => q{mkdir $dir, 0700 or die;},
    'mkdir after a call with parens' => q{mkdir catfile( $a, $b ), 0700;},
    'dbmopen'                        => q{dbmopen( %cache, $file, 0600 );},
    'sysopen'                        => q{sysopen( my $fh, $path, O_WRONLY | O_CREAT, 0600 );},
    'sysopen past a constant'        => q{sysopen my $fh, $path, O_CREAT, 0600;},
    'mkpath'                         => q{mkpath( '/bogus', 1, 0700 );},
    'mkpath as a method'             => q{dir()->mkpath( 1, 0700 );},
    'make_path with named arguments' => q{make_path( $dir, { mode => 0711 } );},
    'a mode as the whole of a paren' => q{chmod( (0600), $f );},
    'the last statement of a block'  => q{sub { chmod 0600, $f }},
    'zero'                           => q{my $x = 0;},
    'double zero'                    => q{my $x = 00;},
    'a float'                        => q{my $x = 0.5;},
    'hex'                            => q{my $x = 0x1f;},
    'binary'                         => q{my $x = 0b101;},
    'a decimal'                      => q{my $x = 100;},
);

foreach my $case ( sort keys %allowed ) {
    is( violations( $default, $allowed{$case} ), 0, "$case is not a violation: $allowed{$case}" );
}

is( violations( $default, q{my $z = 0032;  ## no critic (ProhibitLeadingZeros)} ), 0, 'an explicit no-critic is what signs it off' );

# The call sites in trog-provisioner that this was written for, named in its
# .perlcriticrc the way it names them.
{
    my $configured = critic_with( \"[ProhibitLeadingZeros]\nallow = Provisioner::Utils::write_pem Test::MockFile::new_dir set_mode\n" );

    my %configured_allowed = (
        'a qualified entry, called qualified'  => q{Provisioner::Utils::write_pem( $paths{key},  IO::Socket::SSL::Utils::PEM_key2string($key),   0600 );},
        'inside an exception block'            => q{ok( exception { Provisioner::Utils::write_pem( "$dir/no/such/dir/key.pem", "key\n", 0600 ) }, 'a directory that does not exist' );},
        'a qualified entry, as a class method' => q{my $td_mock = Test::MockFile->new_dir( $basedir, { mode => 0755 } );},
        'an unqualified entry, called bare'    => q{set_mode( $f, 0600 );},
        'an unqualified entry, qualified'      => q{My::Thing::set_mode( $f, 0600 );},
        'an unqualified entry, as a method'    => q{$obj->set_mode(0600);},
        'the defaults survive: umask'          => q{umask 0022;},
        'the defaults survive: chmod'          => q{chmod 0600, $half;},
    );

    foreach my $case ( sort keys %configured_allowed ) {
        is( violations( $configured, $configured_allowed{$case} ), 0, "configured: $case is not a violation" );
    }

    my %configured_prohibited = (
        'a qualified entry does not match bare'          => q{write_pem( $path, $pem, 0600 );},
        'a qualified entry does not match a package'     => q{Other::write_pem( $path, $pem, 0600 );},
        'a qualified entry does not match an object'     => q{$mock->new_dir( $d, { mode => 0755 } );},
        'nothing else got exempted: a comparison'        => q{is( $mode, 0600, 'label' );},
        'nothing else got exempted: a bare octal'        => q{my $z = 0032;},
        'nothing else got exempted: a mask'              => q{$mode & 0777;},
        'nothing else got exempted: a mask against stat' => q{my $perms = (stat $f)[2] & 07777;},
    );

    foreach my $case ( sort keys %configured_prohibited ) {
        is( violations( $configured, $configured_prohibited{$case} ), 1, "configured: $case" );
    }
}

# A call ending its block has no ';' after it, so its statement is one child short.
foreach my $source ( q{sub { foo(0600) }}, q{ok( exception { write_pem( $p, 1, 0600 ) }, "x" );} ) {
    my $count;
    my @warned = warnings { $count = violations( $default, $source ) };
    is( $count, 1, "still a violation: $source" );
    is_deeply( \@warned, [], "and no warning from critiquing it: $source" );
}

done_testing();
