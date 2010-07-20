#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok( "Black::Board" );
    use_ok( 'Black::Board::Subscriber' );
    use_ok( "Black::Board::Message" );
    use_ok( "Black::Board::Topic" );
    use_ok( "Black::Board::Publisher" );
}

my $sub = sub {
    my %p = @_;
    for ( qw( message subscriber topic publisher ) ) {
        $p{$_}->test( $_ ) if exists $p{$_} and $p{$_}->can( 'test' );
    }
    return $p{message};
};

isa_ok( my $s1 = Black::Board::Subscriber->new( subscription => $sub ),
    'Black::Board::Subscriber', 'Subscriber->new return isa Subscriber' );

can_ok( $s1, qw(
    subscription
    deliver

    params
    param

    parent
    has_parent
    detach_from_parent
    get_root_container
) );

my ( $m, $t, $p ) = ( MyMessage->new, MyTopic->new( name => 't1' ), MyPublisher->new );
my %c = ( message => $m, topic => $t, publisher => $p );
isa_ok( $s1->deliver( %c ), 'MyMessage', 'Subscriber->deliver returned Message type' );

for ( keys %c ) {
    is( $c{$_}->test, $_, 'subscription callback called with ' . $_ )
}


BEGIN {

    package MyMessage;
    use Moose;
    extends 'Black::Board::Message';
    has 'test' => ( is => 'rw' );

    package MyTopic;
    use Moose;
    extends 'Black::Board::Topic';
    has 'test' => ( is => 'rw' );

    has '+message_class' => (
        default => 'MyMessage'
    );

    package MyPublisher;
    use Moose;
    extends 'Black::Board::Publisher';
    has 'test' => ( is => 'rw' );

    Black::Board->PublisherClass( 'MyPublisher' );
    Black::Board->TopicClass( 'MyTopic' );
}

1;

