use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: C<param> based Message for L<Bread::Board>

class Black::Board::Message
    with MooseX::Param
    with Black::Board::Trait::Traversable
{
    use Method::Signatures::Simple name => 'imethod';

=attr C<publisher>

This is the L<Black::Board::Publisher> currently dispatching this message.
Subclasses can not override this because of optimizations.

=cut

    has 'publisher' => (
        is  => 'rw',
        isa => 'Black::Board::Publisher'
    );

=attr C<topic>

This is the L<Black::Board::Topic> currently dispatching this message.
Subclasses can not override this because of optimizations.

=cut

    has 'topic' => (
        is  => 'rw',
        isa => 'Black::Board::Topic'
    );

=attr C<subscriber>

This is the L<Black::Board::Subscriber> this message is currently being
dispatched to.
Subclasses can not override this because of optimizations.

=cut

    has 'subscriber' => (
        is => 'rw',
        isa => 'Black::Board::Subscriber'
    );

=attr C<bubble>

L<Black::Board::Subscriber> uses this flag to know if it should continue
dispatching the current subscription message.
Subclasses can not override this because of optimizations.


=cut

    has 'bubble' => (
        is => 'rw',
        isa => 'Bool',
        default => 1,
    );

=attr C<with_meta>

The meta object to make available to subscribers. If you used
L<Black::Board/FUNCTIONS/publish> to send this message, this is set
automatically to the calling packages meta object.
Subclasses can not override this because of optimizations.

=cut

    has 'with_meta' => (
        is  => 'rw',
        isa => 'Object',
    );

=method C<cancel_bubble>

This makes sense from the context of a L<Black::Board::Subscriber> subscription
callback. It allows you to cancel the current chain of subscriber dispatch.
This is usually done in end-point* subscribers. This object is returned with
bubble set to false.

* An example of an end-point is the subscriber in a C<LogDispatch> subscription
chain that dispatches to the log object. 

=cut

    imethod cancel_bubble() {
        $self->{bubble} = 0;
        return $self;
    }

=method C<merge_params>

Merges C<HashRef> passed in with current C<<Message->params>>, the C<HashRef>
taking precedence.  Returns self.

=cut

    imethod merge_params( $params ) {
        $self->{params} = { %{ $self->{params} //= {} }, %$params }; # optimized
        $self;
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

