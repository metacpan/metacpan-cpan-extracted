package rig::CmdBase;
{
  $rig::CmdBase::VERSION = '0.04';
}
use strict;

sub get_options {
    my $self = shift;
    my ( $last_opt, %hash );
    for my $opt (@_) {
        if ( $opt =~ m/^-+(.*)/ ) {
            $last_opt = $1;
            $hash{$last_opt} = [] unless ref $hash{$last_opt};
        }
        else {
			$opt = 	Encode::encode_utf8($opt) if Encode::is_utf8($opt);
            push @{ $hash{$last_opt} }, $opt; 
        }
    }
	# convert single option => scalar
	for( keys %hash ) {
		if( @{ $hash{$_} } == 1 ) {
			$hash{$_} = $hash{$_}->[0];	
		}
	}
    return wantarray ? %hash : \%hash;
}

sub pod_text {
    my ($self, $file ) = @_;
    return unless $file;
    require Pod::Text::Termcap;
    Pod::Text::Termcap->new->parse_from_file( $file );
}

1;
