package Log::Message::Config;
use strict;

use Params::Check qw[check];
use Module::Load;
use FileHandle;
use Locale::Maketext::Simple Style => 'gettext';

BEGIN {
    use vars        qw[$VERSION $AUTOLOAD];
    $VERSION    =   0.01;
}

sub new {
    my $class = shift;
    my %hash  = @_;

    ### find out if the user specified a config file to use
    ### and/or a default configuration object
    ### and remove them from the argument hash
    my %special =   map { lc, delete $hash{$_} }
                    grep /^config|default$/i, keys %hash;

    ### allow provided arguments to override the values from the config ###
    my $tmpl = {
        private => { default => undef,  },
        verbose => { default => 1       },
        tag     => { default => 'NONE', },
        level   => { default => 'log',  },
        remove  => { default => 0       },
        chrono  => { default => 1       },
    };

    my %lc_hash = map { lc, $hash{$_} } keys %hash;

    my $file_conf;
    if( $special{config} ) {
        $file_conf = _read_config_file( $special{config} )
                        or ( warn( loc(q[Could not parse config file!]) ), return );
    }

    my $def_conf = \%{ $special{default} || {} };

    ### make sure to only include keys that are actually defined --
    ### the checker will assign even 'undef' if you have provided that
    ### as a value
    ### priorities goes as follows:
    ### 1: arguments passed
    ### 2: any config file passed
    ### 3: any default config passed
    my %to_check =  map     { @$_ }
                    grep    { defined $_->[1] }
                    map     {   [ $_ =>
                                    defined $lc_hash{$_}        ? $lc_hash{$_}      :
                                    defined $file_conf->{$_}    ? $file_conf->{$_}  :
                                    defined $def_conf->{$_}     ? $def_conf->{$_}   :
                                    undef
                                ]
                            } keys %$tmpl;

    my $rv = check( $tmpl, \%to_check, 1 )
                or ( warn( loc(q[Could not validate arguments!]) ), return );

    return bless $rv, $class;
}

sub _read_config_file {
    my $file = shift or return;

    my $conf = {};
    my $FH = new FileHandle;
    $FH->open("$file") or (
                        warn(loc(q[Could not open config file '%1': %2],$file,$!)),
                        return {}
                    );

    while(<$FH>) {
        next if     /\s*#/;
        next unless /\S/;

        chomp; s/^\s*//; s/\s*$//;

        my ($param,$val) = split /\s*=\s*/;

        if( (lc $param) eq 'include' ) {
            load $val;
            next;
        }

        ### add these to the config hash ###
        $conf->{ lc $param } = $val;
    }
    close $FH;

    return $conf;
}

sub AUTOLOAD {
    $AUTOLOAD =~ s/.+:://;

    my $self = shift;

    return $self->{ lc $AUTOLOAD } if exists $self->{ lc $AUTOLOAD };

    die loc(q[No such accessor '%1' for class '%2'], $AUTOLOAD, ref $self);
}

sub DESTROY { 1 }

1;

__END__

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
