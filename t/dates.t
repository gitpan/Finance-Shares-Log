use Test;
BEGIN { plan tests => 9 };
use Finance::Shares::Log qw(:date);
ok(1);

my $days = today_as_days();
my $string = today_as_string();
my $tday = 731143;
my $tstr = '2002-10-20';
my @tymd = (2002, 10, 20);
ok( $days >= $tday );
ok( $string ge $tstr );
ok( string_from_days($tday) eq $tstr );
ok( days_from_string($tstr) == $tday );
my @ymd = ymd_from_days($tday);
ok( $ymd[0] == $tymd[0] and $ymd[1] == $tymd[1] and $ymd[2] == $tymd[2]);
ok( days_from_ymd(@tymd) == $tday );
@ymd = ymd_from_string($tstr);
ok( $ymd[0] == $tymd[0] and $ymd[1] == $tymd[1] and $ymd[2] == $tymd[2]);
ok( string_from_ymd(@tymd) eq $tstr );

