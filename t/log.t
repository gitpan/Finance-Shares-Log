use Test;
BEGIN { plan tests => 4 };
use Finance::Shares::Log qw(:file);
ok(1);

my $name = 'logfile.txt';
unlink $name;
ok( not -e $name );
my $lf = Finance::Shares::Log->new($name);
ok( -e $name );

$lf->log(1, "Test message");
ok( -s $name );

