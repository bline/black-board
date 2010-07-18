use MooseX::Declare;

#ABSTRACT: Subscriber class for L<Black::Board>

class Black::Board::Subscriber
    with Black::Board::Trait::Traversable
    with MooseX::Param
{
    use Black::Board::Types qw( Publisher Topic Message );




    has 'subscription' => (
        is => 'ro',
        isa => 'CodeRef',
        required => 1,
    );


    method deliver( Message :$message, Topic :$topic, Publisher :$publisher ) {
        # For the subscription the more important bit of information is the
        # message. We provide it in $_ and as the first argument. This
        # naturally creates a priority for the rest of the bits of information
        local $_ = $message;
        return $self->subscription->(
            message    => $message,
            subscriber => $self,
            topic      => $topic,
            publisher  => $publisher
        );
    }
}

1;


__END__
=pod

=head1 NAME

Black::Board::Subscriber - Subscriber class for L<Black::Board>

=head1 VERSION

version 0.0001

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
        my %args = @_;
        return $args{message}->clone(
            params => $args{message}->params->merge({
                message => '[Prefix1] ' . $args{message}->params->{message}
            })
        )
    };

    subscriber Logging => sub {
        return $_->clone(
            params => $_->params->merge({
                message => '[Prefix2] ' . $_->params->{message}
            })
        )
    };

=head1 DESCRIPTION

This is the L<Subscriber|Black::Board::Types/TYPES/Subscriber> class for
L<Black::Board>. This is the class that represents a subscription to a specific
L<Topic|Black::Board::Topic>. It provides a delivery interface for dispatching
a L<Message|Black::Board::Message> to a C<CodeRef>.

=head1 ATTRIBUTES

=head2 C<subscription>

C<subscription> is an attribute which contains the C<CodeRef> called to deliver a
message. This C<CodeRef> should expect four named arguments.

    Black::Board::Subscriber->new(
        subscription => sub {
            my %args = @_;
            # $_ = Black::Board::Message;
            # %args = (
            #   message    => Black::Board::Message,
            #   subscriber => Black::Board::Subscriber,
            #   topic      => Black::Board::Topic,
            #   publisher  => Black::Board::Publisher
            # );
        }
    );

The first argument C<message> C<isa> L<Black::Board::Message> object. This
object is also passed in via C<$_>. The second argument, C<subscriber>, is the
L<Black::Board::Subscriber> object. The C<topic> argument is next, which is a
L<Topic|Black::Board::Topic> object.  This is the topic object which this
subscription is subscribed. Th last argument C<publisher>, is (You Guessed it!)
a L<Publisher|Black::Board::Publisher> object. The C<publisher> is the main
dispatch object which holds all the topics.

=head1 METHODS

=head2 C<deliver>

This method is usually called by L<Black::Board::Topic/METHODS/deliver>. It
takes three positional/named parameters. The first argument is C<message>, the
L<Message|Black::Board::Message> object which is being delivered. The next
argument is C<topic>,  the L<Topic|Black::Board::Topic> the
L<Message|Black::Board::Message> is being dispatched to. The last argument is
C<publisher>, the L<Publisher|Black::Board::Publisher> object that is
dispatching this L<Message|Black::Board::Message>.

See L</ATTRIBUTES/subscription> to see how the subscription is dispatched.

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board>

=back

=cut

