use MooseX::Declare;

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
        return $_->clone(
            params => $_->params->merge( {
                message => '[Prefix] ' . $_->params->{message}
            } )
        )
    };

    publish LogDispatch => 
        params => {
            message => "Something that needs logging",
            level => "alert"
        };


=head1 DESCRIPTION

A topic has a list of subscribers. It also has a say in what kinds of messages
will be going to said subscribers. A topic is registered to a specific
publisher. The publisher takes care of finding which topic to publish to and
passes off the message to the individual subscribers. Each subscriber verifies
the message through the topic interface and then processes it. If the message is
modified by the subscriber, a clone of the message with the modifications is
expected to be returned.

This is one pieces in the puzzle.

B<<<Put reference to overview material here once it's written.>>>

=cut

class Black::Board::Topic
    with Black::Board::Trait::Traversable
{
    use Black::Board::Types qw(
        Message
        TopicName
        Subscriber
        Publisher
    );
    use Bread::Board::Types;
    use Moose::Autobox;
    use MooseX::Types::Perl qw( PackageName );

=attr C<name>

Each topic must have a name and this attribute contains the name. The name is
used to identify the Topic for message dispatch and subscrition.

=cut

    has 'name' => (
        is => 'ro',
        isa => TopicName,
        required => 1
    );

=attr C<subscribers>

This attribute holdes an array of subscribers which have subscribed to this
topic.

=cut

    has 'subscribers' => (
        is => 'rw',
        traits => [ 'Array' ],
        isa => SubscriberList,
        default => sub { [] },
        coerce,
        handles => {
            has_subscribers => 'length',
            add_subscriber  => 'push',
            subscriber_list => 'elements'
        }
    );

=attr C<message_class>

This is the class of the message object this topic's subscribers expect to get.
This defaults to L<Black::Board::Message::Simple>, a message with a C<param()>
interface.

=cut

    has 'message_class' => (
        is => 'rw',
        isa => PackageName,
        default => 'Black::Boad::Message::Simple'
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

=method C<create_message>

Constructs a message of class L</ATTRIBUTES/message_class> with the hash ref of
options specified.

=cut

    method create_message( HashRef $options = {} ) {
        return $self->message_class->new( $options );
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

    method deliver( Publisher :$publisher, Subscriber :$subscriber, Message :$message ) {

        # first give a chance for soft failure
        return unless $self->wants_message( $message );

        # the message was sent directly to these topics
        # it is a logic error at this point for messages
        # to be invalid for the topic
        confess "Invalid message $message for $topic"
            unless $self->valid_message( $message );

        return $subscriber->deliver(
            message   => $message,
            topic     => $self,
            publisher => $publisher
        );
    }
}

1;

