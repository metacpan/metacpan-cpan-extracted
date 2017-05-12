#------------------------------------------------
# Version 4.0 specific functions

=head1 VCFv4.0

VCFv4.0 specific functions

=cut

package VCF::V4_0;
$VCF::V4_0::VERSION = '1.003';
use base qw(VCF::Reader);

sub new
{
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    bless $self, ref($class) || $class;

    $$self{_defaults} =
    {
        version => '4.0',
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
        regex_ins   => qr/^[ACGTN]+$/,
        regex_del   => qr/^[ACGTN]+$/,
        regex_gtsep => qr{[|/]},                     # | /
        regex_gt    => qr{^(\.|\d+)([|/]?)(\.?|\d*)$},   # . ./. 0/1 0|1
        regex_gt2   => qr{^(\.|[0-9ACGTNacgtn]+|<[\w:.]+>)([|/]?)},   # . ./. 0/1 0|1 A/A A|A 0|<DEL:ME:ALU>
        gt_sep => [qw(| /)],
    };

    for my $key (keys %{$$self{_defaults}})
    {
        $$self{$key}=$$self{_defaults}{$key};
    }

    return $self;
}

sub format_header_line
{
    my ($self,$rec) = @_;

    my %tmp_rec = ( %$rec );
    if ( exists($tmp_rec{Number}) && $tmp_rec{Number} eq '-1' ) { $tmp_rec{Number} = '.' }
    my $value;
    if ( exists($tmp_rec{ID}) or $tmp_rec{key} eq 'PEDIGREE' )
    {
        my %has = ( key=>1, handler=>1, default=>1 );   # Internal keys not to be output
        my @items;
        for my $key (qw(ID Number Type Description), sort keys %tmp_rec)
        {
            if ( !exists($tmp_rec{$key}) or $has{$key} ) { next; }
            my $quote = ($key eq 'Description' or $tmp_rec{$key}=~/\s/) ? '"' : '';
            push @items, "$key=$quote$tmp_rec{$key}$quote";
            $has{$key}=1;
        }
        $value = '<' .join(',',@items). '>';
    }
    else { $value = $tmp_rec{value}; }

    my $line = "##$tmp_rec{key}=".$value."\n";
    return $line;
}

=head2 parse_header_line

    Usage   : $vcf->parse_header_line(q[##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">])
              $vcf->parse_header_line(q[reference=1000GenomesPilot-NCBI36])
    Args    :
    Returns :

=cut

sub parse_header_line
{
    my ($self,$line) = @_;

    chomp($line);
    $line =~ s/^##//;

    if ( !($line=~/^([^=]+)=/) ) { $self->throw("Expected key=value pair in the header: $line\n"); }
    my $key   = $1;
    my $value = $';

    if ( !($value=~/^<(.+)>\s*$/) )
    {
        # Simple sanity check for subtle typos
        if ( $key eq 'INFO' or $key eq 'FILTER' or $key eq 'FORMAT' or $key eq 'ALT' )
        {
            $self->throw("Hmm, is this a typo? [$key] [$value]");
        }
        return { key=>$key, value=>$value };
    }

    my $rec = { key=>$key };
    my $tmp = $1;
    my ($attr_key,$attr_value,$quoted);
    while ($tmp ne '')
    {
        if ( !defined $attr_key )
        {
            if ( $tmp=~/^([^=]+)="/ ) { $attr_key=$1; $quoted=1; $tmp=$'; next; }
            elsif ( $tmp=~/^([^=]+)=/ ) { $attr_key=$1; $quoted=0; $tmp=$'; next; }
            else { $self->throw(qq[Could not parse header line: $line\nStopped at [$tmp].\n]); }
        }

        if ( $tmp=~/^[^,\\"]+/ ) { $attr_value .= $&; $tmp = $'; }
        if ( $tmp=~/^\\\\/ ) { $attr_value .= '\\\\'; $tmp = $'; next; }
        if ( $tmp=~/^\\"/ ) { $attr_value .= '\\"'; $tmp = $'; next; }
        if ( $tmp eq '' or ($tmp=~/^,/ && !$quoted) or $tmp=~/^"/ )
        {
            if ( $attr_key=~/^\s+/ or $attr_key=~/\s+$/ or $attr_value=~/^\s+/ or $attr_value=~/\s+$/ )
            {
                $self->warn("Leading or trailing space in attr_key-attr_value pairs is discouraged:\n\t[$attr_key] [$attr_value]\n\t$line\n");
                $attr_key =~ s/^\s+//;
                $attr_key =~ s/\s+$//;
                $attr_value =~ s/^\s+//;
                $attr_value =~ s/\s+$//;
            }
            $$rec{$attr_key} = $attr_value;
            $tmp = $';
            if ( $quoted && $tmp=~/^,/ ) { $tmp = $'; }
            $attr_key = $attr_value = $quoted = undef;
            next;
        }
        if ( $tmp=~/^,/ ) { $attr_value .= $&; $tmp = $'; next; }
        $self->throw(qq[Could not parse header line: $line\nStopped at [$tmp].\n]);
    }

    if ( $key eq 'INFO' or $key eq 'FILTER' or $key eq 'FORMAT' )
    {
        if ( $key ne 'PEDIGREE' && !exists($$rec{ID}) ) { $self->throw("Missing the ID tag in $line\n"); }
        if ( !exists($$rec{Description}) ) { $self->warn("Missing the Description tag in $line\n"); }
    }
    if ( exists($$rec{Number}) && $$rec{Number} eq '-1' ) { $self->warn("The use of -1 for unknown number of values is deprecated, please use '.' instead.\n\t$line\n"); }
    if ( exists($$rec{Number}) && $$rec{Number} eq '.' ) { $$rec{Number}=-1; }

    return $rec;
}

sub validate_ref_field
{
    my ($self,$ref) = @_;
    if ( !($ref=~/^[ACGTN]+$/) )
    {
        my $offending = $ref;
        $offending =~ s/[ACGTN]+//g;
        return "Expected combination of A,C,G,T,N for REF, got [$ref], the offending chars were [$offending]\n";
    }
    return undef;
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
        if ( !($item=~/^[ACTGN]+$|^<[^<>\s]+>$/) ) { push @err,$item; next; }
        if ( $item=~/^<[^<>\s]+>$/ ) { next; }
        if ( $ref_len==length($item) ) { next; }
        if ( substr($item,0,1) ne $ref1 ) { $msg=', first base does not match the reference.'; push @err,$item; next; }
    }
    if ( !@err ) { return undef; }
    return 'Could not parse the allele(s) [' .join(',',@err). ']' . $msg;
}


=head2 fill_ref_alt_mapping

    About   : A tool for merging VCFv4.0 records. The subroutine unifies the REFs and creates a mapping
                from the original haplotypes to the haplotypes based on the new REF. Consider the following
                example:
                    REF ALT
                    G    GA
                    GT   G
                    GT   GA
                    GT   GAA
                    GTC  G
                    G    <DEL>
                my $map={G=>{GA=>1},GT=>{G=>1,GA=>1,GAA=>1},GTC=>{G=>1},G=>{'<DEL>'=>1}};
                my $new_ref=$vcf->fill_ref_alt_mapping($map);

              The call returns GTC and $map is now
                    G    GA     ->      GTC  GATC
                    GT   G      ->      GTC  GC
                    GT   GA     ->      GTC  GAC
                    GT   GAA    ->      GTC  GAAC
                    GTC  G      ->      GTC  G
                    G    <DEL>  ->      GTC  <DEL>
    Args    :
    Returns : New REF string and fills the hash with appropriate ALT or undef on error.

=cut

sub fill_ref_alt_mapping
{
    my ($self,$map) = @_;

    my $max_len = 0;
    my $new_ref;
    for my $ref (keys %$map)
    {
        my $len = length($ref);
        if ( $max_len<$len )
        {
            $max_len = $len;
            $new_ref = $ref;
        }
        $$map{$ref}{$ref} = 1;
    }
    for my $ref (keys %$map)
    {
        my $rlen = length($ref);
        if ( substr($new_ref,0,$rlen) ne $ref ) { $self->warn("The reference prefixes do not agree: $ref vs $new_ref\n"); return undef; }
        for my $alt (keys %{$$map{$ref}})
        {
            # The second part of the regex is for VCF>4.0, but does no harm for v<=4.0
            if ( $alt=~/^<.+>$/ or $alt=~/\[|\]/ ) { $$map{$ref}{$alt} = $alt; next; }
            my $new = $alt;
            if ( $rlen<$max_len ) { $new .= substr($new_ref,$rlen); }
            $$map{$ref}{$alt} = $new;
        }
    }
    return $new_ref;
}

=head2 normalize_alleles

    About   : Makes REF and ALT alleles more compact if possible (e.g. TA,TAA -> T,TA)
    Usage   : my $line = $vcf->next_data_array();
              ($ref,@alts) = $vcf->normalize_alleles($$line[3],$$line[4]);

=cut

sub normalize_alleles
{
    my ($self,$ref,$alt) = @_;

    my $rlen = length($ref);
    if ( $rlen==1 or length($alt)==1 )  { return ($ref,split(/,/,$alt)); }

    my @als = split(/,/,$alt);
    my $i = 1;
    my $done = 0;
    while ( $i<$rlen )
    {
        my $r = substr($ref,$rlen-$i,1);
        for my $al (@als)
        {
            my $len = length($al);
            if ( $i>=$len ) { $done = 1; }
            my $c = substr($al,$len-$i,1);
            if ( $c ne $r ) { $done = 1; last; }
        }
        if ( $done ) { last; }
        $i++;
    }
    if ( $i>1 )
    {
        $i--;
        $ref = substr($ref,0,$rlen-$i);
        for (my $j=0; $j<@als; $j++) { $als[$j] = substr($als[$j],0,length($als[$j])-$i); }
    }
    return ($ref,@als);
}

sub normalize_alleles_pos
{
    my ($self,$ref,$alt) = @_;
    my @als;
    ($ref,@als) = $self->normalize_alleles($ref,$alt);

    my $rlen = length($ref);
    if ( $rlen==1 ) { return (0,$ref,@als); }
    my $i = 0;
    my $done = 0;
    while ( $i+1<$rlen )
    {
        my $r = substr($ref,$i,1);
        for my $al (@als)
        {
            my $len = length($al);
            if ( $i+1>=$len ) { $done = 1; last; }
            my $c = substr($al,$i,1);
            if ( $c ne $r ) { $done = 1; last; }
        }
        if ( $done ) { last; }
        $i++;
    }
    if ( $i<0 ) { $i = 0; }
    if ( $i>0 )
    {
        substr($ref,0,$i,'');
        for (my $j=0; $j<@als; $j++) { substr($als[$j],0,$i,''); }
    }
    return ($i,$ref,@als);
}

sub event_type
{
    my ($self,$rec,$allele) = @_;

    my $ref = $rec;
    if ( ref($rec) eq 'HASH' )
    {
        if ( exists($$rec{_cached_events}{$allele}) ) { return (@{$$rec{_cached_events}{$allele}}); }
        $ref = $$rec{REF};
    }

    if ( $allele=~/^<[^>]+>$/ )
    {
        if ( ref($rec) eq 'HASH' ) { $$rec{_cached_events}{$allele} = ['u',0,$allele]; }
        return ('u',0,$allele);
    }
    if ( $allele eq '.' )
    {
        if ( ref($rec) eq 'HASH' ) { $$rec{_cached_events}{$allele} = ['r',0,$ref]; }
        return ('r',0,$ref);
    }

    my $reflen = length($ref);
    my $len = length($allele);
    my $ht;
    my $type;
    if ( $len==$reflen )
    {
        # This can be a reference, a SNP, or multiple SNPs
        my $mism = 0;
        for (my $i=0; $i<$len; $i++)
        {
            if ( substr($ref,$i,1) ne substr($allele,$i,1) ) { $mism++; }
        }
        if ( $mism==0 ) { $type='r'; $len=0; }
        else { $type='s'; $len=$mism; }
    }
    else
    {
        ($len,$ht)=$self->is_indel($ref,$allele);
        if ( $len )
        {
            # Indel
            $type = 'i';
            $allele = $ht;
        }
        else
        {
            $type = 'o'; $len = $len>$reflen ? $len-1 : $reflen-1;
        }
    }

    if ( ref($rec) eq 'HASH' )
    {
        $$rec{_cached_events}{$allele} = [$type,$len,$allele];
    }
    return ($type,$len,$allele);
}

# The sequences start at the same position, which simplifies things greatly.
# Returns length of the indel (+ insertion, - deletion), the deleted/inserted sequence
#   and the position of the first base after the shared sequence
sub is_indel
{
    my ($self,$seq1,$seq2) = @_;

    my $len1 = length($seq1);
    my $len2 = length($seq2);
    if ( $len1 eq $len2 ) { return (0,'',0); }

    my ($del,$len,$LEN);
    if ( $len1<$len2 )
    {
        $len = $len1;
        $LEN = $len2;
        $del = 1;
    }
    else
    {
        $len = $len2;
        $LEN = $len1;
        $del = -1;
        my $tmp=$seq1; $seq1=$seq2; $seq2=$tmp;
    }

    my $ileft;
    for ($ileft=0; $ileft<$len; $ileft++)
    {
        if ( substr($seq1,$ileft,1) ne substr($seq2,$ileft,1) ) { last; }
    }
    if ( $ileft==$len )
    {
        return ($del*($LEN-$len), substr($seq2,$ileft), $ileft);
    }

    my $iright;
    for ($iright=0; $iright<$len; $iright++)
    {
        if ( substr($seq1,$len-$iright,1) ne substr($seq2,$LEN-$iright,1) ) { last; }
    }
    if ( $iright+$ileft<=$len ) { return (0,'',0); }

    return ($del*($LEN-$len),substr($seq2,$ileft,$LEN-$len),$ileft);
}

1;
