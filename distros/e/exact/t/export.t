use Test2::V0;
use exact;

package ExportProvider {
    use exact;
    exact->export('answer');

    sub answer {
        return 42;
    }

    sub thx {
        return 1138;
    }
}

package ExportConsumer {
    use exact;
    ExportProvider->import;
}

is( ExportConsumer->answer, 42, 'exportable method' );
like( dies { ExportConsumer->thx }, qr/Can't locate object method "thx"/, 'not exportable method' );

package ExportableProvider {
    use exact;
    exact->exportable( 'answer', 'thx', { ':all' => [ qw( answer thx ) ] } );

    my $answer = 6 * 9;

    sub import {
        $answer = 42;
    }

    sub answer {
        return $answer;
    }

    sub thx {
        return 1138;
    }
}

package ExportableConsumer1 {
    use exact;
    ExportableProvider->import('answer');
}

package ExportableConsumer2 {
    use exact;
    ExportableProvider->import(':all');
}

is( ExportableConsumer1->answer, 42, 'exportable method' );
like( dies { ExportableConsumer1->thx }, qr/Can't locate object method "thx"/, 'not exportable method' );
is( ExportableConsumer2->thx, 1138, 'exportable method in bundle' );

done_testing;
