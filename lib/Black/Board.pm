use MooseX::Declare;

#ABSTRACT: publish messages and subscribe to topics

class Black::Board {

=head1 SYNOPSIS

    use Log::Dispatch;
    use Black::Board;

    my $publisher = Black::Board::Publisher->new;

    my $log_topic = Black::Board::Topic->new(
        name => "LogDispatch"
    );

    $publisher->add_topic( $log_topic );

    my $logger = Log::Dispatch->new(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    $log_topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                $logger->log( %{ $_->params } );
                return $_->cancel_bubble;
            }
        )
    );

    $log_topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                return $_->clone(
                    params => $_->params->merge( {
                        message => '[Prefix] ' . $_->params->{message}
                    } )
                )
            }
        )
    );

    $publisher->publish(
        topics  => [ 'LogDispatch' ],
        message => $log_topic->create_message(
            params => {
                message => "Something that needs logging",
                level   => "alert"
            }
        )
    );

    # -- OR -- #


    my $logger = Log::Dispatch->(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    # any arguments beyond the first are passed off to subscriber
    topic LogDispatch => sub {
        $logger->log( %{ $_->params } );
        return $_->cancel_bubble;
    };

    subscriber LogDispatch => sub {
        return $_->clone(
            params => $_->params->merge( {
                message => '[Prefix] ' . $_->params->{message}
            } )
        )
    };

    publish LogDispatch => 
        params => {
            message => "Something that needs logging",
            level   => "alert"
        };

=head1 DESCRIPTION

=head2 WARNING WARNING WARNING

This is alpha quality code. It's a running experiment at the moment. When
things are flushed out a little I can make a few more promises on future
changes. For now I can make no promises. Use at your own risk!

=back

This code is inspired by L<Bread::Board> and even a few bits were stolen from
it.

The purpose of this module is to provide ...

=cut


    use Scalar::Util qw( blessed reftype );

    use Moose;
    use Moose::Autobox;
    use Moose::Exporter;
    use MooseX::ClassAttribute;

    use Black::Board::Types qw( Publisher );
    use Black::Board::Publisher;
    use Black::Board::Subscriber;
    use Black::Board::Message;

    Moose::Exporter->setup_import_methods(
        with_meta  => [ qw( topic ) ],
        as_as      => [ qw( subscriber publish topic ) ]
    );

    class_has Publisher => (
        is => 'ro',
        isa => Publisher,
        lazy_build => 1,
    );

    sub _build_Publisher {
        return Black::Board::Publisher->new;
    }

=method C<topic>

First argument is the topic name to create. All other arguments are passed off
to L</METHODS/subscriber> as new subscription callbacks.

=cut

    sub topic ($$) {
        my $name = shift;
        my $topic = Black::Board::Topic->new(
            name => $name,
        );
        __PACKAGE__->Publisher->add_topic( $topic );
        subscriber( $topic, $_ ) for @_;
        return $topic;
    }

=method C<subscriber>

Create a new L<Black::Board::Subscription> object and adds it to the topic
specified.  First argument is a L<Black::Board::Topic> or the name of one
already registered.  The second argument should be a code reference. The code
reference is passed off to L<Black::Board::Subscriber> as the C<subscription>
callback.

=cut

    sub subscriber ($&) {
        my $topic = shift;
        ($topic) = __PACKAGE__->Publisher->find_topics( $topic )
            unless blessed( $topic );

        my $subscription = shift;
        confess "Invalid subscription '$subscription'"
            unless reftype( $subscription ) eq 'CODE';

        $subscription = Black::Board::Subscriber->new(
            subscription => $subscription
        );
        $topic->add_subscription( $subscription );
        return $subscription;
    }

=method C<publish>

Publishes the given message to the given topics. The first argument can be the
topic name or an array reference of topic names to publish to. The second
argument should be the message object we are publishing. If you specify a hash
reference here it will be coerced into a L<Black::Board::Message> object
correct for this L<Topic|Black::Board::Topic>.

=cut

    sub publish ($@) {
        my $topics = shift;
        $topics = [ $topics ] unless reftype( $topics ) eq 'ARRAY';
        my $message;
        if ( @_ == 1 && blessed( $_[0] ) ) {
            $message = shift;
        }
        unless ( $message ) {
            my $args = @_ == 1 && reftype( $_[0] ) eq 'HASH' ? %{ $_[0] } : { @_ };
            $message = $topics->first->create_message( $args );
        }
        $message = $topics->first->parent->publish(
            topics  => $topics,
            message => $message
        );
        return $message;
    }
}

1;

