use MooseX::Declare;

role Black::Board::Message
    with Black::Board::Trait::Traversable
{
=attr C<bubble>

L<Black::Board::Subscriber> uses this flag to know if it should continue
dispatching the current subscription message.


=cut

    has 'bubble' => (
        is => 'rw',
        isa => 'Bool',
        traits => [ 'NoClone' ],
        default => 1,
    );

=method C<cancel_bubble>

This makes sense from the context of a L<Black::Board::Subscriber> subscription
callback. It allows you to cancel the current chain of subscriber dispatch.
This is usually done in end-point subscribers. An example of an end-point is
the subscriber in a LogDispatch subscription chain that dispatches to the log
object. 

=cut

    method cancel_bubble {
        $self->bubble(0);
        return $self;
    }
}

1;

