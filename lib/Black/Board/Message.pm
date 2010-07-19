use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: param based Message for L<Bread::Board>

class Black::Board::Message
    with MooseX::Param
    with Black::Board::Trait::Traversable
{
    use MooseX::Clone;
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
This is usually done in end-point* subscribers. This object is cloned and bubble
set to false in the clone.

* An example of an end-point is the subscriber in a LogDispatch subscription
chain that dispatches to the log object. 

=cut

    method cancel_bubble {
        return $self->clone( bubble => 0 );
    }

=method C<clone_with_params>

=cut

    method clone_with_params( HashRef $params ) {
        return $self->clone(
            params => $self->params->merge( $params )
        );
    }
}

=head1 SEE ALSO

=for :list
* L<Black::Board::Publisher> - publishes Messages to L<Topics|Black::Board::Topic>
* L<Black::Board::Topic> - delivers Messages to L<Subscribers|Black::Board::Subscriber>
* L<Black::Board::Subscriber> - receives a Message
* L<Black::Board> - provides sugar syntax to do all this

=cut

1;

