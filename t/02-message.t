
use Test::More 'no_plan';

use_ok( 'Black::Board::Message' );

isa_ok( my $m = Black::Board::Message->new, 'Black::Board::Message', 'Message->new return isa Message' );
ok( $m->bubble, 'Message object defaults bubble to true' );
isa_ok( my $c = Black::Board::Message->cancel_bubble, 'Black::Board::Message', 'Message->cancel_bubble return isa Message' );
isnt( $c, $m, 'Message->cancel_bubble return is a different object' );
ok( !$c->bubble, 'Message->cancel_bubble changes sets bubble attribute to false' );
ok( $m->bubble, 'Message->cancel_bubble does not change original objects bubble attribute' );

ok( $c->clone->bubble, 'Message->clone does not clone bubble attribute' );

1;

