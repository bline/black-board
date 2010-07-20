use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: C<param> based Message for L<Bread::Board>

class Black::Board::Message
    with MooseX::Param
    with Black::Board::Trait::Traversable
{
    use Moose::Autobox;
    use MooseX::Clone;

    has 'bubble' => (
        is => 'rw',
        isa => 'Bool',
        traits => [ 'NoClone' ],
        default => 1,
    );


    method cancel_bubble( @args ) {
        return $self->clone( bubble => 0, @args );
    }


    method clone_with_params( HashRef $params, @args ) {
        return $self->clone(
            params => scalar( $self->params->merge( $params ) ),
            @args
        );
    }
}


1;


__END__
=pod

=head1 NAME

Black::Board::Message - C<param> based Message for L<Bread::Board>

=head1 VERSION

version 0.0002

=head1 ATTRIBUTES

=head2 C<bubble>

L<Black::Board::Subscriber> uses this flag to know if it should continue
dispatching the current subscription message.

=head1 METHODS

=head2 C<cancel_bubble>

This makes sense from the context of a L<Black::Board::Subscriber> subscription
callback. It allows you to cancel the current chain of subscriber dispatch.
This is usually done in end-point* subscribers. This object is cloned and bubble
set to false in the clone.

Any extra arguments passed to this method will be passed off to C<clone()>.

* An example of an end-point is the subscriber in a C<LogDispatch> subscription
chain that dispatches to the log object. 

=head2 C<clone_with_params>

Returns a clone of this object setting C<<->params>>. Takes a C<HashRef> of parameters
which will be merged with the current C<<->params>>.

Any extra arguments passed to this method will be passed off to C<clone()>.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Publisher> - publishes Messages to L<Topics|Black::Board::Topic>

=item *

L<Black::Board::Topic> - delivers Messages to L<Subscribers|Black::Board::Subscriber>

=item *

L<Black::Board::Subscriber> - receives a Message

=item *

L<Black::Board> - provides sugar syntax to do all this

=back

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

