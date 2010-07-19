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

