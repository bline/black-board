use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: Topic module for L<Black::Board>, meshes L<Messages|Black::Board::Message> with L<Subscribers|Black::Board::Subscriber>

=pod

=head1 SYNOPSIS


    my $logger = new Log::Dispatch(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    topic LogDispatch => sub {
        $logger->log( %{ $_->params } );
        return $_->cancel_bubble;
    };

    subscriber LogDispatch => sub {
        return $_->clone_with_params(
            message => '[Prefix] ' . $_->params->{message}
        )
    };

    publish LogDispatch => 
        message => "Something that needs logging",
        level => "alert";


=head1 DESCRIPTION

A topic has a list of subscribers.  It also has a say in what kinds of messages
will be going to said subscribers.  A topic is registered to a specific
L<Publisher|Black::Board::Publisher>. The publisher takes care of finding which
topic to publish to and passes off the L<Message|Black::Board::Message> to the
individual L<Topic|Black::Board::Topic> objects.  If the message is modified by
the subscriber, a clone of the message with the modifications is expected to be
returned.

This is one of the pieces in the puzzle.

=cut

class Black::Board::Topic
    with Black::Board::Trait::Traversable
{
    use MooseX::Types::Moose qw( ClassName ArrayRef CodeRef );
    use Black::Board::Types qw(
        Message
        TopicName
        Subscriber
        SubscriberList
        Publisher
    );
    use Moose::Autobox;

=attr C<name>

Each topic must have a name and this attribute contains the name. The name is
used to identify the Topic for message dispatch and subscription.

=cut

    has 'name' => (
        is => 'ro',
        isa => TopicName,
        required => 1
    );

=attr C<subscribers>

This attribute holds an array of subscribers which have subscribed to this
topic.

=cut

    has 'subscribers' => (
        is => 'rw',
        traits => [ 'Array' ],
        isa => SubscriberList,
        default => sub { [] },
        coerce => 1,
        handles => {
            has_subscribers     => 'count',
            register_subscriber => 'push',
            subscriber_list     => 'elements'
        }
    );

    # argument prototype check type
    before register_subscriber( Subscriber $subscriber ) {
    }

=attr C<initializers>

List of registered initializers, code that is ran the first
time a message is published to this topic.

=cut

    has 'initializers' => (
        is => 'rw',
        traits => [ 'Array' ],
        isa => ArrayRef[CodeRef],
        default => sub { [] },
        handles => {
            has_initializers      => 'count',
            register_initializer  => 'push',
            initializer_list      => 'elements',
            dequeue_initializer   => 'pop',
        }
    );
    # argument prototype check type
    before register_initializer( CodeRef $initializer ) {
    }


=attr C<message_class>

This is the class of the message object this topic's subscribers expect to get.
This defaults to L<Black::Board::Message::Simple>, a message with a C<param()>
interface.

=cut

    has 'message_class' => (
        is => 'rw',
        isa => ClassName,
        default => 'Black::Board::Message'
    );

=method C<wants_message>

A softer version of L</METHODS/valid_message>. Returning false from here will
cause L</METHODS/deliver> to skip the current topic. The default returns true.

=cut

    method wants_message( Message $message ) {
        return 1;
    }

=method C<valid_message>

Returning false will cause L</METHODS/deliver> to throw
an exception. The default implementation of this just check that the message C<isa()>
C<message_class()>.

=cut

    method valid_message( Message $message ) {
        return $message->isa( $self->message_class );
    }

=method C<deliver>

This method is usually called by L<Black::Board::Publisher/METHODS/publish>. It
takes two positional/named parameters. The first is C<publisher>. This should
be the publisher object that is dispatching this message. The second argument is
the L<Message|Black::Board::Message> object which is being delivered.

This method skips messages which are not wanted by the Topic.
    return unless $self->wants_message( $message );
This method will throw an exception if a call to
    $self->valid_message( $message );
fails.

See L<Black::Board::Subscriber/ATTRIBUTES/subscription> to see how the
subscription is dispatched.

=cut

    method deliver( Subscriber :$subscriber, Message :$message, Publisher :$publisher ) {

        # run onetime initialization code
        while ( my $init = $self->dequeue_initializer ) {
            $init->(
                topic     => $self,
                publisher => $publisher
            );
        }

        # first give a chance for soft failure
        return unless $self->wants_message( $message );

        # the message was sent directly to these topics
        # it is a logic error at this point for messages
        # to be invalid for the topic
        confess "Invalid message $message for $self"
            unless $self->valid_message( $message );

        return $subscriber->deliver(
            message   => $message,
            topic     => $self,
            publisher => $publisher
        );
    }
}

=head1 SEE ALSO

=for :list
* L<Black::Board::Publisher> - publishes Messages to Topics
* L<Black::Board::Subscriber> - the object a Topic delivers a message to
* L<Black::Board> - provides sugar syntax to do all this

=cut

1;

