package Monkey;
    sub banana {
    }

    sub eat {
        banana();
    }

    sub focus {
    }

    sub look {
        focus('lady monkey');
    }

    sub swing {
    }

    sub fight {
        swing();
    }

    sub itch {}

    sub scratch {
        itch('bite');
    }

    sub cigar {}

    sub smoke {
        eval {
            cigar();
        };

        chomp($@);
        return 'oops!' if ($@ eq 'kaboom!');

        return 'ahh, nicotine';
    }

    sub diet {
    }
1;

