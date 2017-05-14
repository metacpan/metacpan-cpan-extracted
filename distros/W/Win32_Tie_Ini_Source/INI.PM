package Win32::Tie::Ini;

$PACKAGE = "Win32::Tie::Ini";

#
# Win32::Tie::Ini.pm
#   By Dave Roth <rothd@roth.net>
#	Courtesy of Roth Consulting
#	http://www.roth.net/consult

require Exporter;
require DynaLoader;

@ISA= qw( Exporter DynaLoader );
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    KEYWORD_FILE
    KEYWORD_SECTION
    KEYWORD_ARRAY
);

sub AUTOLOAD {
        #   Hacked to only return strings
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    #reset $! to zero to reset any current errors.
    $!=0;
    constant($constname, @_ ? $_[0] : 0);
}

bootstrap $PACKAGE;

    #   Next step is silly but will prevent the "possible typo" error
    #   when run with the -w switch.
    #   WE ARE PUTTING the version here since we are calling it from an
    #   extension function we need to have already bootstrapped.
$VERSION = $VERSION = Version();

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;

__END__

