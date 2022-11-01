#!/usr/env/perl
use strict;
use warnings;
use v5.10;

$|++;

use Webservice::Judobase;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $srv = Webservice::Judobase->new;

my %annual_data;
my %data;
my @countries = (
    qw/
        ANT
        AUS
        BAH
        BAN
        BAR
        BIZ
        BOT
        BRU
        CAM
        CAN
        CYP
        DOM
        FIJ
        GAM
        GHA
        GRN
        GUY
        IND
        JAM
        KEN
        KIR
        LES
        MAW
        MAS
        MLT
        MRI
        MOZ
        NAM
        NZL
        NGR
        PAK
        PNG
        RWA
        SKN
        LCA
        VIN
        SAM
        SEY
        SLE
        SGP
        SIN
        SOL
        RSA
        SRI
        TAN
        TGA
        TTO
        TRI
        TUV
        UGA
        GBR
        VAN
        ZAM
        /
);

my @event_ids = (
    1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101,
    1103, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1117, 1118,
    1119, 1120, 1121, 1122, 1123, 1126, 1127, 1128, 1129, 1130, 1131, 1134,
    1135, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1146, 1147, 1148, 1149,
    1150, 1153, 1156, 1158, 1159, 1160, 1162, 1165, 1166, 1167, 1168, 1169,
    1170, 1171, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1181, 1182, 1183,
    1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196,
    1197, 1198, 1199, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208,
    1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220,
    1221, 1222, 1223, 1224, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233,
    1234, 1235, 1236, 1237, 1238, 1239, 1240, 1241, 1242, 1243, 1244, 1245,
    1246, 1247, 1248, 1249, 1250, 1251, 1254, 1255, 1256, 1257, 1259, 1260,
    1261, 1262, 1263, 1266, 1267, 1270, 1271, 1272, 1273, 1274, 1279, 1280,
    1281, 1282, 1284, 1287, 1288, 1290, 1291, 1293, 1294, 1295, 1297, 1299,
    1300, 1301, 1302, 1307, 1308, 1309, 1311, 1313, 1314, 1315, 1316, 1317,
    1318, 1320, 1321, 1322, 1323, 1324, 1325, 1326, 1327, 1328, 1329, 1330,
    1331, 1332, 1333, 1334, 1335, 1336, 1337, 1338, 1339, 1340, 1341, 1342,
    1343, 1347, 1349, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359,
    1360, 1361, 1362, 1363, 1364, 1365, 1366, 1367, 1368, 1369, 1370, 1371,
    1372, 1375, 1376, 1377, 1379, 1380, 1381, 1382, 1383, 1386, 1388, 1389,
    1391, 1392, 1393, 1395, 1396, 1397, 1398, 1399, 1400, 1401, 1403, 1404,
    1405, 1406, 1407, 1409, 1410, 1411, 1412, 1413, 1414, 1415, 1417, 1421,
    1422, 1424, 1425, 1426, 1428, 1429, 1430, 1431, 1437, 1439, 1440, 1441,
    1442, 1443, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453,
    1454, 1455, 1457, 1458, 1459, 1460, 1461, 1462, 1463, 1464, 1465, 1466,
    1467, 1468, 1470, 1471, 1472, 1473, 1475, 1476, 1477, 1479, 1480, 1481,
    1482, 1483, 1484, 1485, 1486, 1487, 1488, 1489, 1491, 1492, 1493, 1495,
    1496, 1498, 1499, 1500, 1501, 1502, 1503, 1504, 1505, 1506, 1507, 1510,
    1511, 1512, 1515, 1516, 1517, 1518, 1519, 1520, 1521, 1522, 1523, 1524,
    1527, 1528, 1529, 1531, 1534, 1535, 1536, 1537, 1538, 1539, 1540, 1541,
    1542, 1543, 1545, 1546, 1547, 1548, 1549, 1551, 1553, 1554, 1555, 1558,
    1559, 1560, 1561, 1562, 1563, 1564, 1565, 1566, 1567, 1568, 1569, 1570,
    1571, 1572, 1573, 1574, 1575, 1576, 1577, 1578, 1579, 1581, 1582, 1583,
    1584, 1585, 1586, 1587, 1588, 1589, 1591, 1592, 1594, 1595, 1597, 1598,
    1599, 1600, 1601, 1602, 1603, 1605, 1606, 1608, 1609, 1610, 1611, 1612,
    1613, 1614, 1615, 1616, 1617, 1619, 1620, 1621, 1622, 1623, 1624, 1625,
    1626, 1627, 1628, 1629, 1630, 1631, 1633, 1634, 1635, 1636, 1637, 1638,
    1639, 1640, 1641, 1642, 1643, 1644, 1645, 1646, 1647, 1648, 1649, 1650,
    1652, 1653, 1654, 1658, 1659, 1660, 1661, 1662, 1664, 1666, 1667, 1668,
    1669, 1670, 1671, 1672, 1673, 1675, 1677, 1678, 1679, 1680, 1681, 1688,
    1691, 1692, 1695, 1696, 1697, 1699
);

my $total_events                = 0;
my $total_contests              = 0;
my $total_commonwealth_athletes = 0;
my $total_commonwealth_contests = 0;
my @events;
my %years;

for my $event_id (@event_ids) {
    print "x";
    my $event = $srv->general->competition( id => $event_id );
    next unless defined $event;
    #say ref($event);
    next unless ref($event) eq "HASH";

    next if $event && $event->{year} && $event->{year} > 2018;
    next if $event && $event->{year} && $event->{year} < 2013;

    my $contests = $srv->contests->competition( id => $event_id );
    next unless scalar @{$contests};

    $total_events++;

    for ( @{$contests} ) {
        $total_contests++;
        $years{total_contests}++;
        $years{ $_->{comp_year} }{total_all_nations}++;

        my $white_nation = $_->{country_short_white};
        my $blue_nation  = $_->{country_short_blue};

        if ( $blue_nation && grep /^$blue_nation$/, @countries ) {
            $data{$blue_nation}
                {"$_->{family_name_blue} $_->{given_name_blue}"}++;
            $years{ $_->{comp_year} }{total_commonwealth}++;
            $years{ $_->{comp_year} }{$blue_nation}++;
        }

        if ( $white_nation && grep /^$white_nation$/, @countries ) {
            $data{$white_nation}
                {"$_->{family_name_white} $_->{given_name_white}"}++;
            $years{ $_->{comp_year} }{total_commonwealth}++;
            $years{ $_->{comp_year} }{$white_nation}++;
        }

    }

}

say Dumper \%years;

say " ";

for my $nation ( keys %data ) {
    for my $athlete ( keys %{ $data{$nation} } ) {
        #say "$nation,$athlete,$data{$nation}{$athlete}";
        $total_commonwealth_athletes++;
        $total_commonwealth_contests += $data{$nation}{$athlete};
    }
}

say "Total Events: $total_events";
say "Total Athletes: ",               $data{All}{Athletes};
say "Total Commonwealth Countries: ", "" . ( keys %data ) - 1;
say "Total Commonwealth Athletes: ",  $total_commonwealth_athletes;

say "Total Contests: $total_contests";
say "Total Commonwealth Contests: $total_commonwealth_contests";

1;
