#------------------------------------------------
# Version 4.1 specific functions

=head1 VCFv4.1

VCFv4.1 specific functions

=cut

package VCF::V4_1;
$VCF::V4_1::VERSION = '1.003';
use base qw(VCF::V4_0);

sub new
{
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    bless $self, ref($class) || $class;

    $$self{_defaults} =
    {
        version => '4.1',
        drop_trailings => 1,
        filter_passed  => 'PASS',

        defaults =>
        {
            QUAL    => '.',
            Flag    => undef,
            GT      => '.',
            default => '.',
        },
        reserved =>
        {
            FILTER  => { 0=>1 },
        },

        handlers =>
        {
            Integer    => \&VCF::Reader::validate_int,
            Float      => \&VCF::Reader::validate_float,
            Character  => \&VCF::Reader::validate_char,
            String     => undef,
            Flag      => undef,
        },

        regex_snp   => qr/^[ACGTN]$|^<[\w:.]+>$/i,
        regex_ins   => qr/^[ACGTN]+$/i,
        regex_del   => qr/^[ACGTN]+$/i,
        regex_gtsep => qr{[|/]},                     # | /
        regex_gt    => qr{^(\.|\d+)([|/]?)(\.?|\d*)$},   # . ./. 0/1 0|1
        regex_gt2   => qr{^(\.|[0-9ACGTNacgtn]+|<[\w:.]+>)([|/]?)},   # . ./. 0/1 0|1 A/A A|A 0|<DEL:ME:ALU>
        gt_sep => [qw(| /)],
    };

    $$self{ignore_missing_GT} = 1;

    for my $key (keys %{$$self{_defaults}})
    {
        $$self{$key}=$$self{_defaults}{$key};
    }

    return $self;
}

sub validate_header
{
    my ($self) = @_;
    my $lines = $self->get_header_line(key=>'reference');
    if ( !@$lines ) { $self->warn("The header tag 'reference' not present. (Not required but highly recommended.)\n"); }
}

sub validate_line
{
    my ($self,$line) = @_;

    if ( !$$self{_contig_validated}{$$line{CHROM}} )
    {
        my $lines = $self->get_header_line(key=>'contig',ID=>$$line{CHROM});
        if ( !@$lines ) { $self->warn("The header tag 'contig' not present for CHROM=$$line{CHROM}. (Not required but highly recommended.)\n"); }
        $$self{_contig_validated}{$$line{CHROM}} = 1;
    }

    if ( index($$line{CHROM},':')!=-1 ) { $self->warn("Colons not allowed in chromosome names: $$line{CHROM}\n"); }

    # Is the ID composed of alphanumeric chars
    if ( !($$line{ID}=~/^\S+$/) ) { $self->warn("Expected non-whitespace ID at $$line{CHROM}:$$line{POS}, but got [$$line{ID}]\n"); }
}

sub validate_alt_field
{
    my ($self,$values,$ref) = @_;

    if ( @$values == 1 && $$values[0] eq '.' ) { return undef; }

    my $ret = $self->_validate_alt_field($values,$ref);
    if ( $ret ) { return $ret; }

    my $ref_len = length($ref);
    my $ref1 = substr($ref,0,1);

    my @err;
    my $msg = '';
    for my $item (@$values)
    {
        if ( $item=~/^(.*)\[(.+)\[(.*)$/ or $item=~/^(.*)\](.+)\](.*)$/ )
        {
            if ( $1 ne '' && $3 ne '' ) { $msg=', two replacement strings given (expected one)'; push @err,$item; next; }
            my $rpl;
            if ( $1 ne '' )
            {
                $rpl  = $1;
                if ( $rpl ne '.' )
                {
                    my $rref = substr($rpl,0,1);
                    if ( $rref ne $ref1 ) { $msg=', the first base of the replacement string does not match the reference'; push @err,$item; next; }
                }
            }
            else
            {
                $rpl  = $3;
                if ( $rpl ne '.' )
                {
                    my $rref = substr($rpl,-1,1);
                    if ( $rref ne $ref1 ) { $msg=', the last base of the replacement string does not match the reference'; push @err,$item; next; }
                }
            }
            my $pos = $2;
            if ( !($rpl=~/^[ACTGNacgtn]+$/) && $rpl ne '.' ) { $msg=', replacement string not valid (expected [ACTGNacgtn]+)'; push @err,$item; next; }
            if ( !($pos=~/^\S+:\d+$/) ) { $msg=', cannot parse sequence:position'; push @err,$item; next; }
            next;
        }
        if ( $item=~/^\.[ACTGNactgn]*([ACTGNactgn])$/ ) { next; }
        elsif ( $item=~/^([ACTGNactgn])[ACTGNactgn]*\.$/ ) { next; }
        if ( !($item=~/^[ACTGNactgn]+$|^<[^<>\s]+>$/) ) { push @err,$item; next; }
    }
    if ( !@err ) { return undef; }
    return 'Could not parse the allele(s) [' .join(',',@err). ']' . $msg;
}

sub next_data_hash
{
    my ($self,@args) = @_;

    my $out = $self->SUPER::next_data_hash(@args);
    if ( !defined $out or $$self{assume_uppercase} ) { return $out; }

    # Case-insensitive ALT and REF bases
    $$out{REF} = uc($$out{REF});
    my $nalt = @{$$out{ALT}};
    for (my $i=0; $i<$nalt; $i++)
    {
        if ( $$out{ALT}[$i]=~/^</ ) { next; }
        $$out{ALT}[$i] = uc($$out{ALT}[$i]);
    }

    return $out;
}

sub next_data_array
{
    my ($self,@args) = @_;

    my $out = $self->SUPER::next_data_array(@args);
    if ( !defined $out or $$self{assume_uppercase} ) { return $out; }

    # Case-insensitive ALT and REF bases
    $$out[3] = uc($$out[3]);
    my $alt  = $$out[4];
    $$out[4] = '';
    my $pos = 0;
    while ( $pos<length($alt) && (my $start=index($alt,'<',$pos))!=-1 )
    {
        my $end = index($alt,'>',$start+1);
        if ( $end==-1 ) { $self->throw("Could not parse ALT [$alt]\n") }
        if ( $start>$pos )
        {
            $$out[4] .= uc(substr($alt,$pos,$start-$pos));
        }
        $$out[4] .= substr($alt,$start,$end-$start+1);
        $pos = $end+1;
    }
    if ( $pos<length($alt) )
    {
        $$out[4] .= uc(substr($alt,$pos));
    }
    return $out;
}

sub event_type
{
    my ($self,$rec,$allele) = @_;

    my $len = length($allele);
    if ( $len==1 ) { return $self->SUPER::event_type($rec,$allele); }

    my $c = substr($allele,0,1);
    if ( $c eq '<' ) { return ('u',0,$allele); }
    elsif ( $c eq '[' or $c eq ']' or $c eq '.' ) { return 'b'; }

    $c = substr($allele,-1,1);
    if ( $c eq '[' or $c eq ']' or $c eq '.' ) { return 'b'; }
    elsif ( index($allele,'[')!=-1 or index($allele,']')!=-1 ) { return 'b'; }

    return $self->SUPER::event_type($rec,$allele);
}

1;
