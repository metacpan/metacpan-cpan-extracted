use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'URI::XSEscape',
    VERSION_FROM   => 'lib/URI/XSEscape.pm',
    ABSTRACT_FROM  => 'lib/URI/XSEscape.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM      => {
        'XSLoader'    => 0,
    },
    TEST_REQUIRES  => {
        'Test::More'            => 0,
        'Data::Dumper'          => 0,
        'URI::Escape'           => 0,
        'URI::Escape::XS'       => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    LIBS           => [''],
#    DEFINE         => '-DGMEM_CHECK',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:gonzus/uri-xsescape',
                web  => 'https://github.com/gonzus/uri-xsescape',
            },
        },
    },
);

# Add options CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -std=c89';             # Compile according to C89 standard
    $self->{CCFLAGS} .= ' -pedantic';            # Make sure non-C89 constructs are flagged
    $self->{CCFLAGS} .= ' -Wall';                # Flag all warnings

#    $self->{CCFLAGS} .= ' -Werror';              # Warnings become errors
#
#    # Turn off these warnings, they appear in Perl library code
#    $self->{CCFLAGS} .= ' -Wno-gnu-statement-expression';
#    $self->{CCFLAGS} .= ' -Wno-variadic-macros';
#    $self->{CCFLAGS} .= ' -Wno-long-long';

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
