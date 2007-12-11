------------------------------------------------------------------------
-- Functors
------------------------------------------------------------------------

-- Note that currently the functor laws are not included here.

module Category.Functor where

open import Data.Function

record RawFunctor (f : Set -> Set) : Set1 where
  infixl 4 _<$>_ _<$_

  field
    _<$>_ : forall {a b} -> (a -> b) -> f a -> f b

  _<$_ : forall {a b} -> a -> f b -> f a
  x <$ y = const x <$> y