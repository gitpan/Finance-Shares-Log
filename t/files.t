use Test;
BEGIN { plan tests => 5 };
use Finance::Shares::Log qw(:file);
ok(1);

my $name = 'files.txt';
my $filename = check_file( $name, "t" );
ok($filename);
ok(-e $filename);
ok( open($fh, "<", $filename) );
my $line = fetch_line($fh);
ok( $line eq 'hello world' );
close $fh;
