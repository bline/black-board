use MooseX::Declare;

class Black::Board::Message
    with MooseX::Param
    with Black::Board::Trait::Traversable
{

    has 'bubble' => (
        is => 'rw',
        isa => 'Bool',
        traits => [ 'NoClone' ],
        default => 1,
    );


    method cancel_bubble {
        $self->bubble(0);
        return $self;
    }
}

1;


__END__
=pod

=head1 NAME

Black::Board::Message

=head1 VERSION

version 0.0001

=head1 ATTRIBUTES

=head2 C<bubble>

L<Black::Board::Subscriber> uses this flag to know if it should continue
dispatching the current subscription message.

=head1 METHODS

=head2 C<cancel_bubble>

This makes sense from the context of a L<Black::Board::Subscriber> subscription
callback. It allows you to cancel the current chain of subscriber dispatch.
This is usually done in end-point subscribers. An example of an end-point is
the subscriber in a LogDispatch subscription chain that dispatches to the log
object. 

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

