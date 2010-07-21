#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';

use_ok( 'Black::Board::Message' );

isa_ok( my $m1 = Black::Board::Message->new( with_meta => Foo->meta ), 'Black::Board::Message', 'Message->new return isa Message' );
can_ok( $m1, qw(
    bubble
    cancel_bubble
    merge_params

    params
    param

    parent
    has_parent
    detach_from_parent
    get_root_container
) );
ok( $m1->bubble, 'Message object defaults bubble to true' );
isa_ok( my $m2 = $m1->cancel_bubble(), 'Black::Board::Message', 'Message->cancel_bubble return isa Message' );
isnt( $m2, $m1, 'Message->cancel_bubble return is a different object' );
ok( !$m2->bubble, 'Message->cancel_bubble changes sets bubble attribute to false' );
ok( $m1->bubble, 'Message->cancel_bubble does not change original objects bubble attribute' );

ok( $m2->clone->bubble, 'Message->clone does not clone bubble attribute' );

use Data::Dumper;
$m2->params->{p1} = "p1";
$m2->params->{p2} = "p2";
isa_ok( $m2->merge_params( { p1 => "modified" } ), 'Black::Board::Message', 'Message->merge_params return' );
is_deeply( $m2->params, { p1 => "modified", p2 => "p2" }, 'Message->merge_params merged' );

$m3->params->{p2} = Foo->new( a => 1 );

BEGIN {
package Foo;
use Moose;

has 'a' => ( is => 'rw' );
has 'b' => ( is => 'rw' );
has 'c' => ( is => 'rw' );

}


1;

