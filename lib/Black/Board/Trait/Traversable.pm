use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: gives you a parent and the ability to find root

role Black::Board::Trait::Traversable
    with MooseX::Clone
{ 
    # Samelessly taken from Bread::Board
    has 'parent' => (
        is        => 'rw',
        isa       => 'Black::Board::Trait::Traversable',
        weak_ref  => 1,
        clearer   => 'detach_from_parent',
        predicate => 'has_parent',
    );
    method get_root_container {
        $self = $self->parent while $self->has_parent;
        return $self;
    }   
}

1;


__END__
=pod

=head1 NAME

Black::Board::Trait::Traversable - gives you a parent and the ability to find root

=head1 VERSION

version 0.0001

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

