use MooseX::Declare;

#ABSTRACT: Subscriber class for L<Black::Board>

=head1 SYNOPSIS

    use Black::Board::Subscriber;
    use Black::Board::Topic;

    $topic = Black::Board::Topic->new( name => "Logging" );

    $topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                $logger->log( %{ $_->params } );
                return $_->cancel_bubble;
            }
        )
    );

    $topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                my ( $message, $topic, $publisher ) = @_;
                return $_->clone(
                    params => $_->params->merge({
                        message => '[Prefix1] ' . $_->params->{message}
                    })
                )
            }
        )
    );

    $topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                my ( $message, $topic, $publisher ) = @_;
                return $_->clone(
                    params => $_->params->merge({
                        message => '[Prefix2] ' . $_->params->{message}
                    })
                )
            }
        )
    );

    # --- OR --- #

    use Black::Board;

    topic "Logging";

    subscriber Logging => sub {
        $logger->log( %{ $_->params } );
        return $_->cancel_bubble;
    };

    subscriber Logging => sub {
        my ( $message, $topic, $publisher ) = @_;
        return $_->clone(
            params => $_->params->merge({
                message => '[Prefix1] ' . $_->params->{message}
            })
        )
    };

    subscriber Logging => sub {
        my ( $message, $topic, $publisher ) = @_;
        return $_->clone(
            params => $_->params->merge({
                message => '[Prefix2] ' . $_->params->{message}
            })
        )
    };


=head1 DESCRIPTION

=cut

class Black::Board::Subscriber
    with Black::Board::Trait::Traversable
    with MooseX::Param
{
    use Black::Board::Types qw( Publisher Topic Message );

=attr C<subscription>

Attribute which contains the C<CodeRef> which will be called to deliver a
message. This C<CodeRef> should expect four arguments. The first argument is an
object which consumes the role L<Black::Board::Message>, probably a
L<Black::Board::Message::Simple>. This object is also passed in via C<$_>. The
second argument is the L<Black::Board::Subscription> object. The third argument
is a L<Topic|Black::Board::Topic> object. This is the topic object which this
subscription is subscribed. The last argument is the
L<Publisher|Black::Board::Publisher> object. This is the main dispatch object
which holds all the topics.

=cut

    has 'subscription' => (
        is => 'ro',
        isa => 'CodeRef',
        required => 1,
    );

=method C<deliver>

This method is usually called by L<Black::Board::Topic/METHODS/deliver>. It
takes three positional/named parameters. The first is C<publisher>. This should
be the publisher object that is dispatching this message. The next argument is
C<topic>. This should be the L<Topic|Black::Board::Topic> the
L<Message|Black::Board::Message> is being dispatched to. The third argument is
the L<Message|Black::Board::Message> object which is being delivered.

See L</ATTRIBUTES/subscription> to see how the subscription is dispatched.

=cut

    method deliver( Publisher :$publisher, Topic :$topic, Message :$message ) {
        # For the subscription the more important bit of information is the
        # message. We provide it in $_ and as the first argument. This
        # naturally creates a priority for the rest of the bits of information
        local $_ = $message;
        return $self->subscription->( $message, $self, $topic, $publisher );
    }
}

1;

