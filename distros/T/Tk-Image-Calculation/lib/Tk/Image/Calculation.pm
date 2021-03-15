package Tk::Image::Calculation;

use strict;
use warnings;

#-------------------------------------------------
$Tk::Image::Calculation::VERSION = '0.05';
#-------------------------------------------------

sub new
{
    my ($class, @args) = @_;
    my $self = {@args};
    bless($self, $class || ref($class));

    #-------------------------------------------------
    if(defined($self->{-points}) && defined($self->{-form}))
    {
        FORM:
        {
            $self->{-subset} = "all" if(!(defined($self->{-subset})));
            
            ($self->{-form} eq "oval")      && do
            {
                OVAL:
                {
                    ($self->{-subset} eq "lines_outside")   && do
                    {
                        $self->GetLinesOutOval(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_outside")  && do 
                    {
                        $self->GetPointsOutOval(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_inside")   && do
                    {
                        $self->GetPointsInOval(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "lines_inside")    && do
                    {
                        $self->GetLinesInOval(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "all")     && do
                    {
                        $self->GetPointsOval(@{$self->{-points}});
                        last(FORM);
                    };
                }
            };
            
            ($self->{-form} eq "circle")        && do
            {
                CIRCLE:
                {
                    ($self->{-subset} eq "lines_outside")   && do
                    {
                        $self->GetLinesOutCircle(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_outside")  && do
                    {
                        $self->GetPointsOutCircle(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_inside")   && do
                    {
                        $self->GetPointsInCircle(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "lines_inside")    && do
                    {
                        $self->GetLinesInCircle(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "all")     && do
                    {
                        $self->GetPointsCircle(@{$self->{-points}});
                        last(FORM);
                    };
                }
            };
            
            ($self->{-form} eq "polygon")   && do
            {
                POLYGON:
                {
                    ($self->{-subset} eq "lines_outside")   && do
                    {
                        $self->GetLinesOutPolygon(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_outside") && do
                    {
                        $self->GetPointsOutPolygon(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "lines_inside")    && do
                    {
                        $self->GetLinesInPolygon(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "points_inside")   && do
                    {
                        $self->GetPointsInPolygon(@{$self->{-points}});
                        last(FORM);
                    };
                    ($self->{-subset} eq "all")     && do
                    {
                        $self->GetPointsPolygon(@{$self->{-points}});
                        last(FORM);
                    };
                }
            };
            
            warn("wrong args in call to Tk::Image::Calculation::new()\n");
        }
    }
    #-------------------------------------------------
    return($self);
}

#-------------------------------------------------
# OVAL
#-------------------------------------------------
sub GetPointsOval
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my (@points_out, @points_in, @lines_out, @lines_in);
    my ($pos_x_p, $pos_x_n, $pos_y1, $pos_y2);
    my ($y, $y1, $y2);
    my $diff;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2);
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);
    
    if(($width < 5) || ($height < 5))
    {
        $self->{points_outside} = [];
        $self->{points_inside}  = [];
        $self->{lines_outside}  = [];
        $self->{lines_inside}   = [];
        
        return({
            points_outside  => [],
            points_inside   => [],
            lines_outside   => [],
            lines_inside    => []
        });
    }
    
    my $a = ($width / 2);
    my $a2  = $a ** 2;
    my $b = ($height / 2);
    my $c = ($b / $a);
    my $pos_x = ($a + $p_x1);
    
    for(my $x = 0; $x <= $a; $x++)
    {
        $diff = int($c * sqrt($a2 - ($x ** 2)));
        $y1 = ($b - $diff);
        $y2 = ($b + $diff);
        $pos_y1 = ($y1 + $p_y1);
        $pos_y2 = ($y2 + $p_y1);
        $pos_x_p = int($x + $pos_x);
        $pos_x_n = int(-$x + $pos_x);
        
        push(@lines_out, [$pos_x_p, $p_y1, $pos_x_p, $pos_y1]);
        push(@lines_out, [$pos_x_n, $p_y1, $pos_x_n, $pos_y1]);
        push(@lines_in, [$pos_x_p, $pos_y1, $pos_x_p, $pos_y2]);
        push(@lines_in, [$pos_x_n, $pos_y1, $pos_x_n, $pos_y2]);
        push(@lines_out, [$pos_x_p, $pos_y2, $pos_x_p, $p_y2]);
        push(@lines_out, [$pos_x_n, $pos_y2, $pos_x_n, $p_y2]);
        
        for($y = 0; $y <= $y1; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_out, [$pos_x_p, $pos_y1]);
            push(@points_out, [$pos_x_n, $pos_y1]);
        }
        
        for($y = $y1; $y <= $y2; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_in, [$pos_x_p, $pos_y1]);
            push(@points_in, [$pos_x_n, $pos_y1]);
        }
        
        for($y = $y2; $y <= $height; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_out, [$pos_x_p, $pos_y1]);
            push(@points_out, [$pos_x_n, $pos_y1]);
        }
    }
    $self->{points_outside} = \@points_out;
    $self->{points_inside}  = \@points_in;
    $self->{lines_outside}  = \@lines_out;
    $self->{lines_inside}   = \@lines_in;
    
    return({
        points_outside  => \@points_out, 
        points_inside   => \@points_in, 
        lines_outside   => \@lines_out, 
        lines_inside    => \@lines_in
    });
}

#-------------------------------------------------
sub GetPointsInOval
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($pos_x_p, $pos_x_n, $pos_y1);
    my ($y, $y1, $y2);
    my $diff;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2);
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);
    
    if(($width < 5) || ($height < 5))
    {
        $self->{points_inside} = [];
        return([]);
    }

    my $a = ($width / 2);
    my $a2  = ($a**2);
    my $b = ($height / 2);
    my $c = ($b / $a);
    my $pos_x = ($a + $p_x1);
    my @points_in;

    for(my $x = 0; $x <= $a; $x++)
    {
        $diff = int($c * sqrt($a2 - ($x**2)));
        $y1 = ($b - $diff);
        $y2 = ($b + $diff);
        $pos_x_p = int($x + $pos_x);
        $pos_x_n = int(-$x + $pos_x);
        
        for($y = $y1; $y <= $y2; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_in, [$pos_x_p, $pos_y1]);
            push(@points_in, [$pos_x_n, $pos_y1]);
        }
    }
    $self->{points_inside} = \@points_in;
    return(\@points_in);
}

#-------------------------------------------------
sub GetPointsOutOval
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($pos_x_p, $pos_x_n, $pos_y1);
    my ($y, $y1, $y2);
    my $diff;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2);
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{points_outside} = [];
        return([]);
    }

    my $a = ($width / 2);
    my $a2  = ($a**2);
    my $b = ($height / 2);
    my $c = ($b / $a);
    my $pos_x = ($a + $p_x1);
    my @points_out;

    for(my $x = 0; $x <= $a; $x++)
    {
        $diff = int($c * sqrt($a2 - ($x**2)));
        $y1 = ($b - $diff);
        $y2 = ($b + $diff);
        $pos_x_p = int($x + $pos_x);
        $pos_x_n = int(-$x + $pos_x);

        for($y = 0; $y <= $y1; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_out, [$pos_x_p, $pos_y1]);
            push(@points_out, [$pos_x_n, $pos_y1]);
        } 

        for($y = $y2; $y <= $height; $y++)
        {
            $pos_y1 = ($y + $p_y1);
            push(@points_out, [$pos_x_p, $pos_y1]);
            push(@points_out, [$pos_x_n, $pos_y1]);
        }
    }
    
    $self->{points_outside} = \@points_out;
    return(\@points_out);
}

#-------------------------------------------------
sub GetLinesInOval
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($pos_x_p, $pos_x_n, $pos_y1, $pos_y2);
    my ($y, $y1, $y2);
    my $diff;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2);
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);
    
    if(($width < 5) || ($height < 5))
    {
        $self->{lines_inside} = [];
        return([]);
    }
    
    my $a = ($width / 2);
    my $a2  = ($a**2);
    my $b = ($height / 2);
    my $c = ($b / $a);
    my $pos_x = ($a + $p_x1);
    my @lines_in;

    for(my $x = 0; $x <= $a; $x++)
    {
        $diff = int($c * sqrt($a2 - ($x**2)));
        $y1 = ($b - $diff);
        $y2 = ($b + $diff);
        $pos_x_p = int($x + $pos_x);
        $pos_x_n = int(-$x + $pos_x);
        $pos_y1 = ($y1 + $p_y1);
        $pos_y2 = ($y2 + $p_y1);
        push(@lines_in, [$pos_x_p, $pos_y1, $pos_x_p, $pos_y2]);
        push(@lines_in, [$pos_x_n, $pos_y1, $pos_x_n, $pos_y2]);
    }

    $self->{lines_inside} = \@lines_in;
    return(\@lines_in);
}

#-------------------------------------------------
sub GetLinesOutOval
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($pos_x_p, $pos_x_n, $pos_y1, $pos_y2);
    my ($y, $y1, $y2);
    my $diff;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2);
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{lines_outside} = [];
        return([]);
    }

    my $a = ($width / 2);
    my $a2  = ($a**2);
    my $b = ($height / 2);
    my $c = ($b / $a);
    my $pos_x = ($a + $p_x1);
    my @lines_out;

    for(my $x = 0; $x <= $a; $x++)
    {
        $diff = int($c * sqrt($a2 - ($x**2)));
        $y1 = ($b - $diff);
        $y2 = ($b + $diff);
        $pos_x_p = int($x + $pos_x);
        $pos_x_n = int(-$x + $pos_x);
        $pos_y1 = ($y1 + $p_y1);
        $pos_y2 = ($y2 + $p_y1);
        push(@lines_out, [$pos_x_p, $p_y1, $pos_x_p, $pos_y1]);
        push(@lines_out, [$pos_x_n, $p_y1, $pos_x_n, $pos_y1]); 
        push(@lines_out, [$pos_x_p, $pos_y2, $pos_x_p, $p_y2]);
        push(@lines_out, [$pos_x_n, $pos_y2, $pos_x_n, $p_y2]);
    }

    $self->{lines_outside} = \@lines_out;
    return(\@lines_out);
}

#-------------------------------------------------
# CIRCLE
#-------------------------------------------------
sub GetPointsCircle
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my (@points_out, @points_in, @lines_out, @lines_in);
    my ($x2py2, $pos_x, $pos_y1, $pos_y2);
    my ($i_x2, $i_y);
    my $diff_y;
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2); 
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{points_outside} = [];
        $self->{points_inside}  = [];
        $self->{lines_outside}  = [];
        $self->{lines_inside}   = [];

        return({
            points_outside  => [],
            points_inside   => [],
            lines_outside   => [],
            lines_inside    => []
        });
    }

    my $r = int($width / 2);
    my $r2 = ($r**2);  
    my $coord_x = ($p_x1 + $r);
    my $coord_y = ($p_y1 + $r);
    for(my $i_x = -$r; $i_x <= $r; $i_x++)
    {
        $i_x2 = ($i_x ** 2);
        $diff_y = int(sqrt($r2 - $i_x2));
        $pos_x = ($coord_x + $i_x);
        $pos_y1 = ($coord_y + $diff_y);
        $pos_y2 = ($coord_y - $diff_y);

        push(@lines_out, [$pos_x, $p_y1, $pos_x, $pos_y2]);
        push(@lines_out, [$pos_x, $pos_y1, $pos_x, $p_y2]);
        push(@lines_in, [$pos_x, $pos_y2, $pos_x, $pos_y1]);

        for($i_y = $r; $i_y >= -$r; $i_y--)
        {
            $pos_y1 = ($coord_y + $i_y);
            $x2py2 = ($i_x2 + ($i_y ** 2));

            if($x2py2 < $r2)
            {
                push(@points_in, [$pos_x, $pos_y1]);
            }
            elsif($x2py2 > $r2)
            {
                push(@points_out, [$pos_x, $pos_y1]);
            }
        } 
    }

    $self->{points_outside} = \@points_out;
    $self->{points_inside}  = \@points_in;
    $self->{lines_outside}  = \@lines_out;
    $self->{lines_inside}   = \@lines_in;

    return({
        points_outside  => \@points_out,
        points_inside   =>  \@points_in, 
        lines_outside   => \@lines_out, 
        lines_inside    => \@lines_in
    });
}

#-------------------------------------------------
sub GetPointsInCircle
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($x2py2, $i_y);
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2); 
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{points_inside} = [];
        return([]);
    }

    my $r = int($width / 2);
    my $r2 = ($r ** 2);  
    my $coord_x = ($p_x1 + $r);
    my $coord_y = ($p_y1 + $r);
    my @points_in;

    for(my $i_x = -$r; $i_x <= $r; $i_x++)
    {
        for($i_y = $r; $i_y >= -$r; $i_y--)
        {
            $x2py2 = (($i_x ** 2) + ($i_y ** 2));
            if($x2py2 < $r2)
            {
                push(@points_in, [($coord_x + $i_x), ($coord_y + $i_y)]);
            }           
        } 
    }

    $self->{points_inside} = \@points_in;
    return(\@points_in);
}

#-------------------------------------------------
sub GetPointsOutCircle
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($x2py2, $i_y);
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2); 
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{points_outside} = [];
        return([]);
    }

    my $r = int($width / 2);
    my $r2 = ($r ** 2);  
    my $coord_x = ($p_x1 + $r);
    my $coord_y = ($p_y1 + $r);
    my @points_out;

    for(my $i_x = -$r; $i_x <= $r; $i_x++)
    {
        for($i_y = $r; $i_y >= -$r; $i_y--)
        {
            $x2py2 = (($i_x ** 2) + ($i_y ** 2));
            if($x2py2 > $r2)
            {
                push(@points_out, [($coord_x + $i_x), ($coord_y + $i_y)]);
            }
        } 
    }

    $self->{points_outside} = \@points_out;
    return(\@points_out);
}

#-------------------------------------------------
sub GetLinesInCircle
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($x2py2, $pos_x, $diff_y);
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2); 
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);
    
    if(($width < 5) || ($height < 5))
    {
        $self->{lines_inside} = [];
        return([]);
    }
    
    my $r = int($width / 2);
    my $r2 = ($r ** 2);  
    my $coord_x = ($p_x1 + $r);
    my $coord_y = ($p_y1 + $r);
    my @lines_in;
    
    for(my $i_x = -$r; $i_x <= $r; $i_x++)
    {
        $pos_x = ($coord_x + $i_x);
        $diff_y = int(sqrt($r2 - ($i_x ** 2)));
        push(@lines_in, [$pos_x, ($coord_y - $diff_y), $pos_x, ($coord_y + $diff_y)]);
    }
    
    $self->{lines_inside} = \@lines_in;
    return(\@lines_in);
}

#-------------------------------------------------
sub GetLinesOutCircle
{
    my ($self, $p_x1, $p_y1, $p_x2, $p_y2) = @_;
    my ($x2py2, $pos_x, $diff_y);
    ($p_x1, $p_x2) = ($p_x2, $p_x1) if($p_x1 > $p_x2); 
    ($p_y1, $p_y2) = ($p_y2, $p_y1) if($p_y1 > $p_y2);
    my $width = ($p_x2 - $p_x1);
    my $height= ($p_y2 - $p_y1);

    if(($width < 5) || ($height < 5))
    {
        $self->{lines_outside} = [];
        return([]);
    }

    my $r = int($width / 2);
    my $r2 = ($r ** 2);  
    my $coord_x = ($p_x1 + $r);
    my $coord_y = ($p_y1 + $r);
    my @lines_out;

    for(my $i_x = -$r; $i_x <= $r; $i_x++)
    {
        $pos_x = ($coord_x + $i_x);
        $diff_y = int(sqrt($r2 - ($i_x ** 2)));
        push(@lines_out, [$pos_x, $p_y1, $pos_x, ($coord_y - $diff_y)]);
        push(@lines_out, [$pos_x, ($coord_y + $diff_y), $pos_x, $p_y2]);
    }

    $self->{lines_outside} = \@lines_out;
    return(\@lines_out);
}

#-------------------------------------------------
# POLYGON
#-------------------------------------------------
sub GetPointsPolygon
{
    my ($self) = @_;
    my $ref_p_x = _CalculatePolygon(@_);
    my (@points_out, @points_in, @lines_out, @lines_in);
    my $i_1 = my $i_2 = my $i_3 = 0;
    my $p_x_temp;

    for(my $p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        $p_x_temp = $self->{min_x};
        for($i_2 = 0; $i_2 <= $#{$ref_p_x->[$i_1]}; $i_2 += 2)
        {
            push(@lines_in, [$ref_p_x->[$i_1][$i_2], $p_y, $ref_p_x->[$i_1][$i_2 + 1], $p_y]);
            for($i_3 = $ref_p_x->[$i_1][$i_2]; $i_3 <= $ref_p_x->[$i_1][$i_2 + 1]; $i_3++)
            {
                push(@points_in, [$i_3, $p_y]);
            }

            push(@lines_out, [$p_x_temp, $p_y, $ref_p_x->[$i_1][$i_2], $p_y]);
            for($i_3 = $p_x_temp; $i_3 <= $ref_p_x->[$i_1][$i_2]; $i_3++)
            {
                push(@points_out, [$i_3, $p_y]);
            }

            $p_x_temp = $ref_p_x->[$i_1][$i_2 + 1];
        }

        push(@lines_out, [$p_x_temp, $p_y, $self->{max_x}, $p_y]);
        for($i_3 = $p_x_temp; $i_3 <= $self->{max_x}; $i_3++)
        {
            push(@points_out, [$i_3, $p_y]);
        }

        $i_1++;
    }

    $self->{lines_outside}  = \@lines_out;
    $self->{lines_inside}   = \@lines_in;
    $self->{points_outside} = \@points_out;
    $self->{points_inside}  = \@points_in;

    return({
        lines_outside   => \@lines_out,
        lines_inside    => \@lines_in,
        points_outside  => \@points_out,
        points_inside   => \@points_in,
    });
}

#-------------------------------------------------
sub GetPointsInPolygon
{
    my ($self) = @_;
    my $ref_p_x = _CalculatePolygon(@_);
    my @points_in = ();
    my $i_1 = my $i_2 = my $i_3 = 0;

    for(my $p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        for($i_2 = 0; $i_2 <= $#{$ref_p_x->[$i_1]}; $i_2 += 2)
        {
            for($i_3 = $ref_p_x->[$i_1][$i_2]; $i_3 <= $ref_p_x->[$i_1][$i_2 + 1]; $i_3++)
            {
                push(@points_in, [$i_3, $p_y]);
            }
        }

        $i_1++;
    }

    $self->{points_inside} = \@points_in;
    return(\@points_in);
}

#-------------------------------------------------
sub GetPointsOutPolygon
{
    my ($self) = @_;
    my $ref_p_x = _CalculatePolygon(@_);
    my @points_out = ();
    my $i_1 = my $i_2 = my $i_3 = 0;
    my $p_x_temp;

    for(my $p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        $p_x_temp = $self->{min_x};
        for($i_2 = 0; $i_2 <= $#{$ref_p_x->[$i_1]}; $i_2 += 2)
        {
            for($i_3 = $p_x_temp; $i_3 <= $ref_p_x->[$i_1][$i_2]; $i_3++)
            {
                push(@points_out, [$i_3, $p_y]);
            }
            $p_x_temp = $ref_p_x->[$i_1][$i_2 + 1];
        }

        for($i_3 = $p_x_temp; $i_3 <= $self->{max_x}; $i_3++)
        {
            push(@points_out, [$i_3, $p_y]);
        }

        $i_1++;
    }

    $self->{points_outside} = \@points_out;
    return(\@points_out);
}

#-------------------------------------------------
sub GetLinesInPolygon
{
    my ($self) = @_;
    my $ref_p_x = _CalculatePolygon(@_);
    my @lines_in = ();
    my $i_1 = my $i_2 = 0;

    for(my $p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        for($i_2 = 0; $i_2 <= $#{$ref_p_x->[$i_1]}; $i_2 += 2)
        {
            push(@lines_in, [$ref_p_x->[$i_1][$i_2], $p_y, $ref_p_x->[$i_1][$i_2 + 1], $p_y]);
        }

        $i_1++;
    }

    $self->{lines_inside} = \@lines_in;
    return(\@lines_in);
}

#-------------------------------------------------
sub GetLinesOutPolygon
{
    my ($self) = @_;
    my $ref_p_x = _CalculatePolygon(@_);
    my @lines_out = ();
    my $i_1 = my $i_2 = 0;
    my $p_x_temp;

    for(my $p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        $p_x_temp = $self->{min_x};
        for($i_2 = 0; $i_2 <= $#{$ref_p_x->[$i_1]}; $i_2 += 2)
        {
            push(@lines_out, [$p_x_temp, $p_y, $ref_p_x->[$i_1][$i_2], $p_y]);
            $p_x_temp = $ref_p_x->[$i_1][$i_2 + 1];
        }

        push(@lines_out, [$p_x_temp, $p_y, $self->{max_x}, $p_y]);
        $i_1++;
    }

    $self->{lines_outside} = \@lines_out;
    return(\@lines_out);
}

#-------------------------------------------------
sub _CalculatePolygon
{
    my ($self, @points) = @_;
    my @p;

    for(my $i = 0; $i <= $#points; $i += 2)
    {
        push(@p, { x => $points[$i], y => $points[$i + 1]});
    }

    push(@p, {x => $points[0], y => $points[1]});
    my $points_count = $#p;
    return([]) if($points_count < 3);

    my ($index_1, $index_2,  $index_count); 
    my ($p_y, $p_y1, $p_y2, $p_x1, $p_x2, $p_x_temp);
    my @points_outline_x = ();
    my @all_points_outline_x = ();
    my ($i, $j);
    $self->{min_y} = $self->{max_y} = $p[0]{y};
    $self->{min_x} = $self->{max_x} = $p[0]{x};

    for(0..$#p)
    {
        $self->{min_y} = $p[$_]{y} if($self->{min_y} > $p[$_]{y});
        $self->{max_y} = $p[$_]{y} if($self->{max_y} < $p[$_]{y});
        $self->{min_x} = $p[$_]{x} if($self->{min_x} > $p[$_]{x});
        $self->{max_x} = $p[$_]{x} if($self->{max_x} < $p[$_]{x});
    }

    for($p_y = $self->{min_y}; $p_y <= $self->{max_y}; $p_y++)
    {
        $index_count = 0;
        @points_outline_x = ();
        for($i = 0; $i < $points_count; $i++)
        {
            if(!$i)
            {
                $index_1 = $points_count - 1;   
                $index_2 = 0;       
            }
            else
            {
                $index_1 = $i - 1;          
                $index_2 = $i;  
            }

            $p_y1 = $p[$index_1]{y};
            $p_y2 = $p[$index_2]{y};

            if($p_y1 < $p_y2)
            {
                $p_x1 = $p[$index_1]{x};
                $p_x2 = $p[$index_2]{x};
            }
            elsif ($p_y1 > $p_y2)
            {
                $p_y2 = $p[$index_1]{y};
                $p_y1 = $p[$index_2]{y};
                $p_x2 = $p[$index_1]{x};
                $p_x1 = $p[$index_2]{x};
            }
            else
            {
                next;
            }

            if(($p_y >= $p_y1) && ($p_y < $p_y2))
            {
                $points_outline_x[$index_count++] = int((($p_y - $p_y1) * ($p_x2 - $p_x1)) /  ($p_y2 - $p_y1) + 0.5 + $p_x1);
            }
            elsif(($p_y == $self->{max_y}) && ($p_y > $p_y1) && ($p_y <= $p_y2))
            {
                 $points_outline_x[$index_count++] = int((($p_y - $p_y1) * ($p_x2 - $p_x1)) / ($p_y2 - $p_y1) + 0.5 + $p_x1);
            }
        }
 
        for($i = 1; $i < $index_count; $i++) 
        {
            $p_x_temp = $points_outline_x[$i];
            $j = $i;

            while(($j > 0) && ($points_outline_x[$j - 1] > $p_x_temp)) 
            {
                $points_outline_x[$j] = $points_outline_x[$j - 1];
                $j--;
            }

            $points_outline_x[$j] = $p_x_temp;
        }

        push(@all_points_outline_x, [@points_outline_x]);
    }

    return(\@all_points_outline_x);
}

1; # /Tk::Image::Calculation



__END__

=head1 NAME

Tk::Image::Calculation - Perl extension for graphic calculations

=head1 SYNOPSIS

    use Tk::Image::Calculation;
    my @points_oval = (10, 10, 30, 50);
    my @points_circle = (20, 20, 60, 60);
    my @points_polygon = (136, 23, 231, 55, 463, 390, 338, 448, 182, 401, 148, 503, 15, 496, 9, 87);
    # polygon = (x1, y1, x2, y2, x3, y3, x4, y4, ... and so on)
    
    my $cal = Tk::Image::Calculation->new();    
    my $ref_array = $cal->GetPointsInOval(@points_oval);
    # my $ref_array = $cal->GetPointsOutOval(@points_oval);
    # my $ref_array = $cal->GetPointsInCircle(@points_circle);
    # my $ref_array = $cal->GetPointsOutCircle(@points_circle);
    # my $ref_array = $cal->GetPointsInPolygon(@points_polygon);
    # my $ref_array = $cal->GetPointsOutPolygon(@points_polygon);
    
    for(@{$ref_array})
    {
        print("x:$_->[0]    y:$_->[1]\n");
    }
    
    my $ref_array1 = $cal->GetLinesInOval(@points_oval);
    # my $ref_array1 = $cal->GetLinesOutOval(@points_oval);
    # my $ref_array1 = $cal->GetLinesInCircle(@points_circle);
    # my $ref_array1 = $cal->GetLinesOutCircle(@points_circle);
    # my $ref_array1 = $cal->GetLinesInPolygon(@points_polygon);
    # my $ref_array1 = $cal->GetLinesOutPolygon(@points_polygon);
    for(@{$ref_array1})
    {
        print("x1:$_->[0]   y1:$_->[1]  x2:$_->[2]  y2:$_->[3]\n");
    }
    
    #-------------------------------------------------
    my $cal1 = Tk::Image::Calculation->new(
        -points => \@points_circle,
        -form   => "circle", # or "oval" or "polygon"
    );
    for my $subset ("points_inside", "points_outside")
    {
        print("\n$subset circle : \n");
        for(@{$cal1->{$subset}})
        {
            print("x:$_->[0]    y:$_->[1]\n");
        }
    }
    for my $subset ("lines_inside", "lines_outside")
    {
        print("\n$subset circle : \n");
        for(@{$cal1->{$subset}})
        {
            print("x1:$_->[0]   y1:$_->[1]  x2:$_->[2]  y2:$_->[3]\n");
        }
    }
    
    #-------------------------------------------------
    my $cal2 = Tk::Image::Calculation->new(
        -points => \@points_polygon, # need three points at least
        -form   => "polygon", 
        -subset => "lines_outside", # defaults to "all"
    );
    
    use Tk;
    my $mw = MainWindow->new();
    my $canvas = $mw->Canvas(
        -width  => 800,
        -height => 600,
    )->pack();
    
    for(@{$cal2->{lines_outside}})
    {
        $canvas->createLine(@{$_});
    }
    MainLoop();
    
    #-------------------------------------------------
    use Tk;
    use Tk::JPEG;
    my $mw = MainWindow->new();
    my $image = $mw->Photo(-file => "test.jpg");
    my $cal3 = Tk::Image::Calculation->new();
    my $ref_points = $cal3->GetPointsOutCircle(50, 50, 150,  150);
    $image->put("#FFFFFF", -to => $_->[0], $_->[1]) for(@{$ref_points});
    $image->write("new.jpg", -from => 50, 50, 150, 150);
    #-------------------------------------------------

=head1 DESCRIPTION

This module calculates points and lines inside or outside from simple graphic objects.
At this time possible objects:

    "oval",
    "circle",
    "polygon"

=head1 CONSTRUCTOR

    my $object = Tk::Image::Calculation->new();

Returns an empty object just for calling the methods.

    my $object = Tk::Image::Calculation->new(
        -points => [$x1, $y1, $x2, $y2],    # required
        -form   => "oval",      # required
        -subset => "points_outside, # optional
    );

    -points    takes a arrayreference with points  required
    -form  takes one of the forms "oval", "circle" or "polygon" required
    -subset    takes one of the strings "points_outside", "points_inside", "lines_inside" or "lines_outside" 
    
    optional defaults to "all"

Returns a hashreference blessed as object with a key that was defined with the options -subset.
The value of the key is an arrayreferences with points or lines.

    Points [x, y]
    Lines [x1, y1, x2, y2]

Is the option -subset set to "all" the returned hash have the following keys.

    "points_outside",
    "points_inside",
    "lines_outside",
    "lines_inside"

=head1 METHODS

Two points are handed over to the functions for Oval or Circle. 
In the following form ($x1, $y1, $x2, $y2).
The first point to the left up and the second point to the right below of a thought rectangle,
in that the graphic object does fitting.
The returned values are array references of points or lines.

    Points [x, y]
    Lines [x1, y1, x2, y2]

=over

=item GetPointsOval

Takes over two points as parameters.
Returns a hashreferences with the following keys.

    "points_outside", 
    "points_inside",
    "lines_outside", 
    "lines_inside"

The values of the keys are arrayreferences with points or lines. 

=item GetPointsInOval, GetPointsOutOval, GetLinesInOval, GetLinesOutOval

Takes over two points as parameters.
Returns a array reference of Points or Lines inside or outside of the Oval. 

=item GetPointsCircle

Just the same as GetPointsOval.

=item GetPointsInCircle, GetPointsOutCircle, GetLinesInCircle, GetLinesOutCircle

Takes over two points as parameters.
Returns a array reference of Points or Lines inside or outside of the Circle. 

=item GetPointsPolygon

Takes over a list of points in the following way.

    my @polygon = (x1, y1, x2, y2, x3, y3, x4, y4, ... and so on)
    my $ref_hash = $object->GetPointsPolygon(@polygon);

Need at least three points.
Returns a hashreferences with the following keys.

    "points_outside", 
    "points_inside",
    "lines_outside", 
    "lines_inside"

The values of the keys are arrayreferences with points or lines. 

=item GetPointsInPolygon, GetPointsOutPolygon, GetLinesInPolygon, GetLinesOutPolygon

Takes over a list with at least three points.
Returns a array reference of Points or Lines inside or outside of the Circle.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Tk::Image::Cut>

=head1 KEYWORDS

graphic, calculation 

=head1  BUGS

Maybe you'll find some. Please let me know.

=head1 AUTHOR

Torsten Knorr

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

