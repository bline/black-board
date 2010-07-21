#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 38;
use Test::Exception;

BEGIN {
    use_ok( 'Black::Board::Subscriber' );
    use_ok( "Black::Board::Message" );
    use_ok( "Black::Board::Topic" );
    use_ok( "Black::Board::Publisher" );
    use_ok( "Black::Board" );
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

dies_ok { $t1->register_subscriber( '' ) } 'Topic->register_subscriber dies on non-Subscriber type';
dies_ok { $t1->register_initializer( '' ) } 'Topic->register_initializer dies on non-CodeRef type';

my %sub;
my $called = 0;
for ( 1 .. 4 ) {
    my $subname = "sub$_";
    $t1->register_subscriber(
        MySubscriber->new(
            subscription => $sub{$subname} = sub {
                $called++;
                if ( $_->can( 'test' ) ) {
                    $_->$test_cr->{$subname} ||= [];
                    push @{ $_->$test_cr->{$subname} }, $called;
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
for ( 1 .. 4 ) {
    my $subname = "isub$_";
    my $i = keys %isub;
    push @icount, $i;
    $t1->register_initializer(
        $isub{$subname} = sub {
            $icalled++;
            my %p = @_;

            my $icount = pop @icount;
            is( $p{topic}->has_initializers, $icount, 'Topic->has_initializers count going down ' . $icount );

            for ( qw( topic ) ) {
                if ( exists $p{$_} and my $test_cr = $p{$_}->can( 'test' ) ) {
                    $p{$_}->$test_cr->{$subname} ||= [];
                    push @{ $p{$_}->$test_cr->{$subname} }, $icalled;
                }
            }
            return $p{message};
        }
    );
    is( $t1->has_initializers, $i + 1, "Topic->has_subscribers returns correct count with $i value" );
}

my $m1 = MyMessage->new;
my $first = 0;
for my $subscriber ( $t1->subscribers->reverse->flatten ) {
    my $m2 = $t1->deliver(
        subscriber => $subscriber,
        message    => $m1,
        publisher  => Black::Board->Publisher
    );
    isa_ok( $m1, 'MyMessage', 'Topic->deliver returned' );
    is( $m1, $m2, 'Topic->deliver without clone return same object' );
    if ( $first++ ) {
        my $h = 4;
        for my $l ( 1 .. 4 ) {
            is( $t1->test->{"isub$l"}, $h, 'initializer ' . $l . ' called ' . $h );
            $h--;
        }
    }

);
my $h = 4;
for my $l ( 1 .. 4 ) {
    is( $m->test->{"sub$l"}, $h, 'subscription ' . $l . '  called ' . $h );
    $h--;
}

BEGIN {
    package MyTestRole;
    use Moose::Role;
    has 'test' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

    package MySubscriber;
    use Moose;
    extends 'Black::Board::Subscriber';
    with 'MyTestRole';

    package MyMessage;
    use Moose;
    extends 'Black::Board::Message';
    with 'MyTestRole';

    package MyTopic;
    use Moose;
    extends 'Black::Board::Topic';
    with 'MyTestRole';

    has '+message_class' => (
        default => 'MyMessage'
    );

    package MyPublisher;
    use Moose;
    extends 'Black::Board::Publisher';
    with 'MyTestRole';

    Black::Board->PublisherClass( 'MyPublisher' );
    Black::Board->TopicClass( 'MyTopic' );
}

1;

