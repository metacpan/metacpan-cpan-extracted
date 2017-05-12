package Text::ClearSilver::FunctionSet;
use strict;
use warnings;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(usage);

sub usage {
    require Carp;
    Carp::croak("Usage: @_");
}


sub load {
    my($self, $monikers) = @_;

    my %set;

    foreach my $moniker(ref($monikers) ? @{$monikers} : $monikers) {
        my $module = "Text/ClearSilver/FunctionSet/$moniker.pm";
        $module =~ s{::}{/}g; # $moniker can include '::'

        require $module;

        my $package = __PACKAGE__ . '::' . $moniker . '::';
        my $stash = do {
            no strict 'refs';
            \%{$package};
        };

        while(my $key = each %{$stash}){
            if($key =~ s/^_function_//){
                $set{$key} = do {
                    no strict 'refs';
                    \&{$package . '_function_' . $key};
                };
            }
        }
    }

    return \%set;
}

1;
__END__

=head1 NAME

Text::ClearSilver::FunctionSet - The function set provider for Text::ClearSilver

=head1 SYNOPSIS

    use Text::ClearSilver;

    my $tcs = Text::ClearSilver->new(
        functions => [qw(string html)]
    );

=head1 INTERFACE

=head2 C<< Text::ClearSilver::FunctionSet->load(@monikers) :HASH >>

=head1 SEE ALSO

L<Text::ClearSilver>

=cut
