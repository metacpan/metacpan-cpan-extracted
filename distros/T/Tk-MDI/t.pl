use Tk;
use Tk::MDI;

my $focus='click';
my $mw=new MainWindow;
my $frame=$mw->Frame->pack(-side=>'bottom',-fill=>'x',-expand=>1);

my $mdi=$mw->MDI(
		-menu=>'both',
		-focus=>$focus,
		-style=>'win32',
		-background=>'sienna');

$frame->Button(
		-text=>'New Window',
		-command=>sub{my $win = $mdi->add(
			-titletext=>'New Window',
			-titlebg=>'tan');
			$win->Scrolled('Text',-scrollbars=>'se')
				->pack(-expand=>1, -fill=>'both')}
		)->pack(-side=>'bottom',-fill=>'x');

$autoresize=$mdi->cget(-autoresize);

$frame->Checkbutton(
	-text=>'Resize on Smart Placement',
	-variable=>\$autoresize,
	-command=>sub{
		$mdi->configure(-autoresize=>$autoresize)
	})->pack(-side=>'left');


foreach (qw/click lazy strict/){
	$frame->Radiobutton(
		-text=>$_,
		-variable=>\$focus,
		-value=>$_,
		-command=>sub{
		$mdi->configure(-focus=>$focus)
		})->pack(-side=>'left');
}

MainLoop;



