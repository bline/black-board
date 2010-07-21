#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok( 'Black::Board::Subscriber' );
    use_ok( "Black::Board::Message" );
    use_ok( "Black::Board::Topic" );
    use_ok( "Black::Board::Publisher" );
    use_ok( "Black::Board" );
}

my $sub = sub {
    $_->test( 'message' );
    for my $m ( qw( topic publisher ) ) {
        $_->$m()->test( $m );
    }
    return $_;
};

isa_ok( my $s1 = Black::Board::Subscriber->new( subscription => $sub ),
    'Black::Board::Subscriber', 'Subscriber->new return' );

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

$t->register_subscriber( $s1 );

isa_ok( $p->publish( $t, $m ), 'MyMessage', 'Publisher->publisher returned Message type' );

my %c = ( message => $m, topic => $t, publisher => $p );
for ( keys %c ) {
    is( $c{$_}->test, $_, 'subscription callback called with ' . $_ );
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

    around '_build_message_class' => sub {
        return 'MyMessage';
    };

    package MyPublisher;
    use Moose;
    extends 'Black::Board::Publisher';
    has 'test' => ( is => 'rw' );

    Black::Board->PublisherClass( 'MyPublisher' );
    Black::Board->TopicClass( 'MyTopic' );
}

1;

