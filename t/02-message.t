
use Test::More 'no_plan';

use_ok( 'Black::Board::Message' );

isa_ok( my $m1 = Black::Board::Message->new, 'Black::Board::Message', 'Message->new return isa Message' );
ok( $m1->bubble, 'Message object defaults bubble to true' );
isa_ok( my $m2 = $m1->cancel_bubble(), 'Black::Board::Message', 'Message->cancel_bubble return isa Message' );
isnt( $m2, $m1, 'Message->cancel_bubble return is a different object' );
ok( !$m2->bubble, 'Message->cancel_bubble changes sets bubble attribute to false' );
ok( $m1->bubble, 'Message->cancel_bubble does not change original objects bubble attribute' );

ok( $m2->clone->bubble, 'Message->clone does not clone bubble attribute' );

$m2->params->{p1} = "p1";
$m2->params->{p2} = "p2";
isa_ok( my $m3 = $m2->clone_with_params( { p1 => "modified" } ), 'Black::Board::Message', 'Message->clone_with_params return isa Message' );
is_deeply( $m3->params, { p1 => "modified", p2 => "p3" }, 'Message->clone_with_params Message return has params setup correctly' );
is_deeply( $m1->params, { p1 => "p1", p2 => "p2" }, 'Message->clone_with_params does not modify the params of the cloned message' );

$m3->params->{p2} = Foo->new( a => 1 );
is( $m3->params->{p2}, $m3->clone->params->{p2}, 'clone does not deeply clone params' );

BEGIN {
package Foo;
use Moose;

has 'a' => ( is => 'rw' );
has 'b' => ( is => 'rw' );
has 'c' => ( is => 'rw' );

}


1;

