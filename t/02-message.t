#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';

use_ok( 'Black::Board::Message' );

isa_ok( my $m1 = Black::Board::Message->new( with_meta => Foo->meta ), 'Black::Board::Message', 'Message->new return isa Message' );
is( $m1->with_meta, Foo->meta, 'Message->with_meta initialized correctly' );
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
isa_ok( $m1->cancel_bubble(), 'Black::Board::Message', 'Message->cancel_bubble return isa Message' );
ok( !$m1->bubble, 'Message->cancel_bubble sets bubble attribute to false' );

$m1->params->{p1} = "p1";
$m1->params->{p2} = "p2";
isa_ok( $m1->merge_params( { p1 => "modified" } ), 'Black::Board::Message', 'Message->merge_params return' );
is_deeply( $m1->params, { p1 => "modified", p2 => "p2" }, 'Message->merge_params merged' );


BEGIN {
package Foo;
use Moose;

has 'a' => ( is => 'rw' );
has 'b' => ( is => 'rw' );
has 'c' => ( is => 'rw' );

}


1;

