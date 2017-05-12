#
# $Id: dTemplate.pm 132 2006-10-21 15:52:44Z dlux $
# 
# $URL: http://svn.dlux.hu/public/dTemplate/trunk/dTemplate.pm $ 
#

package dTemplate;
use strict;
use DynaLoader;
use vars qw($VERSION @ISA %ENCODERS $ENCODERS %parse 
    $START_DELIMITER $END_DELIMITER $ENCODER_SEP $PRINTF_SEP $VAR_PATH_SEP
    $ENCODER_PARAM_START $ENCODER_PARAM_END);

@ISA = qw(DynaLoader);

$VERSION             = '2.5';
$START_DELIMITER     = '\$';
$END_DELIMITER       = '\$';
$VAR_PATH_SEP        = '\.';
$ENCODER_SEP         = '\*+';
$ENCODER_PARAM_START = '\/';
$ENCODER_PARAM_END   = '';
$PRINTF_SEP          = '%+';

dTemplate->bootstrap($VERSION);

# Constructors ...

sub new {
    my $obj = shift;
    my $type = shift or die "Invalid constructor call. Use: new dTemplate type => ...";
    return ((ref $obj || $obj)."::Template")->new(@_) if        $type eq "file";
    return ((ref $obj || $obj)."::Choose")->new(@_) if          $type eq "choose" || $type eq "select";
    return ((ref $obj || $obj)."::Template")->new_raw(@_) if    $type eq "text";
    die "Invalid type in dTemplate constructor: $type";
}

sub define { shift->new(file   => @_) }
sub choose { shift->new(choose => @_) }
sub select { shift->new(choose => @_) }
sub text   { shift->new(text   => @_) }

sub encode { 
  my $encoder = shift;
  return $ENCODERS{$encoder}->(shift());
};

$ENCODERS{''}   = sub { shift() };

$ENCODERS{u}  = sub { 
    require URI::Escape;     # autoload URI::Escape module
    $ENCODERS{u} = sub {
        URI::Escape::uri_escape(defined $_[0] ? $_[0] : "","^a-zA-Z0-9_.!~*'()"); 
    };
    $ENCODERS{u}->(shift);
};

$ENCODERS{h} = sub { 
    require HTML::Entities;  # autoload HTML::Entities module
    $ENCODERS{h}=sub {
        HTML::Entities::encode(defined $_[0] ? $_[0] : "","^\n\t !\#\$%-;=?-~") ; 
    };
    $ENCODERS{h}->(shift);
};

$ENCODERS{uc} = sub { uc($_[0]) };

$ENCODERS{lc} = sub { lc($_[0]) };

$ENCODERS{ha} = sub { # Advanced html encoding: \n => <BR> , tabs => spaces
    my $e=$ENCODERS->{'h'}->($_[0]);
    $e =~ s/\n/<BR>/g;
    $e =~ s/\t/&nbsp;&nbsp;&nbsp;/go;
    $e;
};

$ENCODERS{eq} = sub { # equality check
    return $_[0] eq $_[1];
};

$ENCODERS{if} = sub { # returns the second parameter if the first is true
    return $_[1] if $_[0];
};

$ENCODERS{printf} = sub { # returns the printf-formatted output
    return sprintf("%".$_[1], $_[0]);
};

$ENCODERS=\%ENCODERS; # for compatibility of older versions

package dTemplate::Template;
use strict;
use vars qw(%ENCODERS $ENCODERS);
use locale;

sub spf {
    my $format = shift;
    return sprintf $format,@_;
}

*ENCODERS = *dTemplate::ENCODERS;

sub FILENAME  { 0 };
sub TEXT      { 1 };
sub COMPILED  { 2 };
sub PARSEHASH { 3 };

# use this constant to determinene the last field for subclassing dTemplate
sub LAST_FIELD { PARSEHASH };

sub new { my ($class,$filename)=@_;
    return undef if ! -r $filename;
    my $s=[$filename];
    bless ($s,$class);
};

sub new_raw { my $class=shift;
  my $txt=shift;
  my $s=[undef, (ref($txt) ? $txt : \$txt)];
  bless ($s,$class);
};

sub style  { return undef };

sub compile { my $s=shift;
    return if $s->[COMPILED];
    $s->load_file;

    # template parsing 

    my %varhash;
    my @comp=({});
    ${ $s->[TEXT] } =~ s{ (.*?) ( 
        (?:$dTemplate::START_DELIMITER) ( (?:\w|(?:$dTemplate::VAR_PATH_SEP))* ) 
        ( (?:$dTemplate::PRINTF_SEP) (.*?[\w]) )? 
        ( (?:$dTemplate::ENCODER_SEP) (.*?) )?
        (?:$dTemplate::END_DELIMITER) | $ 
    ) }{
        my ($pre,$full_matched,$varname,$full_format,$format,
            $full_encoding,$encoding) = ($1,$2,$3,$4,$5,$6,$7);
        my $clast = $comp[-1] ||= {};
        if ($full_matched eq '$$') { # $$ sign
            $clast->{text} .= $pre.'$';
        } else {
            $clast->{text} .= $pre;
            if ($varname) {
                $clast->{full_matched} = $full_matched;
                my (@varp) = split (/$dTemplate::VAR_PATH_SEP/, 
                    $varname);
                my $varn = $varp[0];
                $clast->{varn} = $varn;
                $varhash{$varn}++;
                $clast->{varp} = \@varp;
                $clast->{format} = defined $format ? "%".$format : "";
                $clast->{encoding}=$encoding;
                push @comp,{};
            };
        };
        "";
    }gxse;

    # assigning ID-s for variables

    my @variables = sort { 
        $varhash{$b} <=> $varhash{$a} || length($a) <=> length($b) 
    } keys %varhash;
    my %varids;
    for (my $i=0; $i<@variables; $i++) {
        $varids{$variables[$i]} = $i;
    }

    # settings up the compiled scalar:
    # variable parameter hash + inverted index

    my ($var_list, $var_index) = ("","");
    foreach my $varname (@variables) {
        my $varlen = length($varname);
        my $addspc = $varlen >= 4 ? 0 : 4 - $varlen;
        my $var_list_add = " ".$varname.(" " x $addspc);
        $var_list  .= $var_list_add;
        my $var_index_add = "\0" x length($var_list_add);
        substr($var_index_add,0,4) = pack("l", $varids{$varname});
        $var_index .= $var_index_add;
    }
    my $compiled = pack("l",scalar(@variables)). $var_list. " \0". $var_index."";

    # chunks

    foreach my $chunk (@comp) {
        $compiled .= pack("l", length($chunk->{text})).$chunk->{text};
        if ($chunk->{full_matched}) {
            $compiled .= $chunk->{full_matched}."\0". # full matched string
                pack("l",$varids{ $chunk->{varn} }).  # variable ID
                join("",map { $_."\0" } @{ $chunk->{varp}})."\0". 
                                                      # variable path in hash
                join("",map { $_."\0" }               # encoding:
                    map { /^(.*?)                     #   encoder name
                        (?:
                            (?:$dTemplate::ENCODER_PARAM_START)
                            (.*)                      #   encoder parameter
                            (?:$dTemplate::ENCODER_PARAM_END)
                        )?$/x }
                    (split(/$dTemplate::ENCODER_SEP/, 
                        $chunk->{encoding} || ""))
                )."\0".                               # encoding
                $chunk->{format}."\0"
        } else {
            $compiled .= "\0";
        }
    }

    $s->[COMPILED] = $compiled;
    $s->[TEXT]=undef; # free up some memory
};

sub load_file { my $s=shift;
    return if $s->[COMPILED] || defined $s->[TEXT] || !defined $s->[FILENAME];
    if (!open(FILE,$s->[FILENAME])) {
        warn "Cannot load template file: ".$s->[FILENAME];
        $s->[TEXT]=\"";
    close (FILE);
    return;
    };
    local $/=undef;
    my $text=<FILE>;
    $s->[TEXT]=\$text;
    close (FILE);
};

sub parsehash: lvalue { shift->[PARSEHASH] ||= {} }

package dTemplate::Choose;
use strict;

sub style_hash { 0 };
sub styles     { 1 };

sub new { my $class=shift;
  my $s=[shift,{}];
  bless($s,$class);
  $s->add(@_);
  $s;
};

sub add { my $s=shift;
  while (@_) {
    my $a=shift;
    my $b=shift;
    $s->define_style($s->[styles], ref($b) ? $b : \$b ,sort split(/\+/,$a));
  };
  $s;
};

sub define_style { my ($s,$root,$template,@path)=@_;
  if (@path) {
    my $i=shift @path;
    $root->{$i}||={};
    $s->define_style($root->{$i},$template,@path);
  } else {
    $root->{''}=$template;
  };
};

sub parse { my $s=shift;
  my $template=$s->get_template;
  return defined $template ? $template->parse(@_) : undef;
};

sub style { my $s=shift; @_ ? $s->[style_hash]=$_[0] : $s->[style_hash] };

sub get_template { my ($s)=@_;
  return undef if !$s->[styles];
  my @walk=([ $s->[styles] ]);
  my @svals = sort (grep ( { $_ } values %{ $s->[style_hash] } ));
  # Finds the best-matching template
  foreach my $i (@svals) {
    for (my $depth=$#walk; $depth>=0; $depth--) {
      foreach my $act (@{$walk[$depth]}) {
        push @{ $walk[$depth+1] }, $act->{$i}
          if exists $act->{$i};
      };
    };
  };
  my $retval;
  FINDTEMPLATE:
  for (my $depth=$#walk; $depth>=0; $depth--) {
    foreach my $act (@{$walk[$depth]}) {
      if (exists $act->{''}) {
        $retval=$act->{''};
        last FINDTEMPLATE;
      };
    };
  };
  return ref($retval) eq 'SCALAR' ? $$retval : $retval;
};

1;

