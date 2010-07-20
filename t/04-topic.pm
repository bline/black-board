#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

BEGIN {
    use_ok( "Black::Board" );
    use_ok( 'Black::Board::Subscriber' );
    use_ok( "Black::Board::Message" );
    use_ok( "Black::Board::Topic" );
    use_ok( "Black::Board::Publisher" );
}

dies_ok { MyTopic->new } 'Topic->new dies with no name parameter';
isa_ok( my $t1 = MyTopic->new( name => 't1' ), 'Black::Board::Topic' );
Black::Board->Publisher->add_topic( $t1 );

can_ok( $t1, qw(
    name

    subscribers
    has_subscribers
    register_subscriber
    subscriber_list

    initializers
    has_initializers
    register_initializer
    initializer_list
    dequeue_initializer

    message_class
    wants_message
    valid_message
    deliver

    parent
    has_parent
    detach_from_parent
    get_root_container
) );

is( $t1->name, 't1', 'Topic->name set in constructor' );
dies_ok { $t1->name( 't2' ) } 'Topic->name is readonly';
is( $t1->name, 't1', 'Topic->name readonly exception did not change Topic->name' );

dies_ok { $t1->register_subscription( '' ) } 'Topic->register_subscription dies on non-CodeRef';

my %sub;
my $called = 0;
for ( 1, 2 ) {
    my $subname = "sub$_";
    $t1->register_subscription(
        MySubscriber->new(
            subscription => $sub{$subname} = sub {
                $called++;
                my %p = @_;
                for ( qw( message subscriber topic publisher ) ) {
                    $p{$_}->test( "$_|$subnum|$called" ) if exists $p{$_} and $p{$_}->can( 'test' );
                }
                return $p{message};
            }
        )
    );
    my $i = keys %sub;
    is( $t1->has_subscribers, $i, "Topic->has_subscribers returns correct count with $i value" );
}

my %isub;
my $icalled = 0;
my @icount;
for ( 1, 2 ) {
    my $subname = "isub$_";
    my $i = keys %isub;
    push @icount, $i;
    $t1->register_initializer(
        $isub{$subname} = sub {
            $icalled++;
            my %p = @_;

            my $icount = pop @icount;
            is( $p{topic}->has_initializers, $icount, 'Topic->has_initializers count going down' );

            for ( qw( topic publisher ) ) {
                if ( exists $p{$_} and my $test_cr = $p{$_}->can( 'test' ) ) {
                    $test = $p{$_}->$test_cr->{$subname};
                    $test .= "\t" if $test;
                    $test //= '';
                    $p{$_}->$test_cr->{$subname} = ( $test .  "$_|$called" );
                }
            }
            return $p{message};
        }
    );
    is( $t1->has_initializers, $i + 1, "Topic->has_subscribers returns correct count with $i value" );
}

my $m = $t1->parent->publish(
    topic   => $t1,
    message => MyMessage->new
);
isa_ok( $m, 'MyMessage', 'Publisher->publish returns the message passed in' );
use Data::Dumper;
warn Dumper( $t1->test );

BEGIN {

    package MyMessage;
    use Moose;
    extends 'Black::Board::Message';
    has 'test' => ( is => 'rw', isa => 'HashRef' );

    package MyTopic;
    use Moose;
    extends 'Black::Board::Topic';
    has 'test' => ( is => 'rw', isa => 'HashRef' );

    has '+message_class' => (
        default => 'MyMessage'
    );

    package MyPublisher;
    use Moose;
    extends 'Black::Board::Publisher';
    has 'test' => ( is => 'rw', isa => 'HashRef' );

    Black::Board->PublisherClass( 'MyPublisher' );
    Black::Board->TopicClass( 'MyTopic' );
}

1;

