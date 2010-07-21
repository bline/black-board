use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: Subscriber class for L<Black::Board>

class Black::Board::Subscriber
    with Black::Board::Trait::Traversable
    with MooseX::Param
{
    use Method::Signatures::Simple name => 'imethod';
    use Black::Board::Types qw( Publisher Topic Message );




    has 'subscription' => (
        is => 'ro',
        isa => 'CodeRef',
        required => 1,
    );


    imethod deliver( $message ) {

        local $message->{subscriber} = $self; # optimized

        # For the subscription the more important bit of information is the
        # message. We provide it in $_ and as the first argument.
        local $_ = $message;
        return $self->subscription->( $message );
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
message. This C<CodeRef> should expect the L<Black::Board::Message> object as it's
only argument. This object will also be localized into C<$_>.

    Black::Board::Subscriber->new(
        subscription => sub {
            my $message = shift;
            # -or-
            my $message = $_
        }
    );

=head1 METHODS

=head2 C<deliver>

This method is usually called by L<Black::Board::Topic/METHODS/deliver>. It
takes the L<Black::Board::Message> object to be delivered.

This method sets the current C<Subscriber> in the L<Message> instance to
this C<Subscriber> until this delivery is over (local()).

See L</ATTRIBUTES/subscription> to see how the subscription is dispatched.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Message> - object being delivered to Subscribers

=item *

L<Black::Board::Topic> - delivers L<Messages|Black::Board::Message> to Subscribers

=item *

L<Black::Board> - provides sugar syntax

=back

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

