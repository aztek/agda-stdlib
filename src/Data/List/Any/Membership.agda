------------------------------------------------------------------------
-- The Agda standard library
--
-- Properties related to list membership
------------------------------------------------------------------------

-- List membership is defined in Data.List.Any. This module does not
-- treat the general variant of list membership, parametrised on a
-- setoid, only the variant where the equality is fixed to be
-- propositional equality.

module Data.List.Any.Membership where

open import Algebra
open import Category.Monad
open import Data.Bool
open import Data.Empty
open import Function
open import Function.Equality using (_⟨$⟩_)
open import Function.Equivalence using (module Equivalence)
import Function.Injection as Inj
open import Function.Inverse as Inv using (_↔_; module Inverse)
import Function.Related as Related
open import Function.Related.TypeIsomorphisms
open import Data.List as List
open import Data.List.Any as Any using (Any; here; there)
open import Data.List.Any.Properties
open import Data.Nat as Nat
import Data.Nat.Properties as NatProp
open import Data.Product as Prod
open import Data.Sum as Sum
open import Relation.Binary
open import Relation.Binary.PropositionalEquality as P
  using (_≡_; refl; _≗_)
import Relation.Binary.Properties.DecTotalOrder as DTOProperties
import Relation.Binary.Sigma.Pointwise as Σ
open import Relation.Unary using (_⟨×⟩_)
open import Relation.Nullary
open import Relation.Nullary.Negation

open Any.Membership-≡
private
  module ×⊎ {k ℓ} = CommutativeSemiring (×⊎-CommutativeSemiring k ℓ)
  open module ListMonad {ℓ} = RawMonad (List.monad {ℓ = ℓ})

------------------------------------------------------------------------
-- Properties relating _∈_ to various list functions

-- Isomorphisms.

map-∈↔ : ∀ {a b} {A : Set a} {B : Set b} {f : A → B} {y xs} →
         (∃ λ x → x ∈ xs × y ≡ f x) ↔ y ∈ List.map f xs
map-∈↔ {a} {b} {f = f} {y} {xs} =
  (∃ λ x → x ∈ xs × y ≡ f x)  ↔⟨ Any↔ {a = a} {p = b} ⟩
  Any (λ x → y ≡ f x) xs      ↔⟨ map↔ {a = a} {b = b} {p = b} ⟩
  y ∈ List.map f xs           ∎
  where open Related.EquationalReasoning

concat-∈↔ : ∀ {a} {A : Set a} {x : A} {xss} →
            (∃ λ xs → x ∈ xs × xs ∈ xss) ↔ x ∈ concat xss
concat-∈↔ {a} {x = x} {xss} =
  (∃ λ xs → x ∈ xs × xs ∈ xss)  ↔⟨ Σ.cong {a₁ = a} {b₁ = a} {b₂ = a} Inv.id $ ×⊎.*-comm _ _ ⟩
  (∃ λ xs → xs ∈ xss × x ∈ xs)  ↔⟨ Any↔ {a = a} {p = a} ⟩
  Any (Any (_≡_ x)) xss         ↔⟨ concat↔ {a = a} {p = a} ⟩
  x ∈ concat xss                ∎
  where open Related.EquationalReasoning

>>=-∈↔ : ∀ {ℓ} {A B : Set ℓ} {xs} {f : A → List B} {y} →
         (∃ λ x → x ∈ xs × y ∈ f x) ↔ y ∈ (xs >>= f)
>>=-∈↔ {ℓ} {xs = xs} {f} {y} =
  (∃ λ x → x ∈ xs × y ∈ f x)  ↔⟨ Any↔ {a = ℓ} {p = ℓ} ⟩
  Any (Any (_≡_ y) ∘ f) xs    ↔⟨ >>=↔ {ℓ = ℓ} {p = ℓ} ⟩
  y ∈ (xs >>= f)              ∎
  where open Related.EquationalReasoning

⊛-∈↔ : ∀ {ℓ} {A B : Set ℓ} (fs : List (A → B)) {xs y} →
       (∃₂ λ f x → f ∈ fs × x ∈ xs × y ≡ f x) ↔ y ∈ fs ⊛ xs
⊛-∈↔ {ℓ} fs {xs} {y} =
  (∃₂ λ f x → f ∈ fs × x ∈ xs × y ≡ f x)       ↔⟨ Σ.cong {a₁ = ℓ} {b₁ = ℓ} {b₂ = ℓ} Inv.id (∃∃↔∃∃ {a = ℓ} {b = ℓ} {p = ℓ} _) ⟩
  (∃ λ f → f ∈ fs × ∃ λ x → x ∈ xs × y ≡ f x)  ↔⟨ Σ.cong {a₁ = ℓ} {b₁ = ℓ} {b₂ = ℓ}
                                                         Inv.id ((_ ∎) ⟨ ×⊎.*-cong {ℓ = ℓ} ⟩ Any↔ {a = ℓ} {p = ℓ}) ⟩
  (∃ λ f → f ∈ fs × Any (_≡_ y ∘ f) xs)        ↔⟨ Any↔ {a = ℓ} {p = ℓ} ⟩
  Any (λ f → Any (_≡_ y ∘ f) xs) fs            ↔⟨ ⊛↔ ⟩
  y ∈ fs ⊛ xs                                  ∎
  where open Related.EquationalReasoning

⊗-∈↔ : ∀ {A B : Set} {xs ys} {x : A} {y : B} →
       (x ∈ xs × y ∈ ys) ↔ (x , y) ∈ (xs ⊗ ys)
⊗-∈↔ {A} {B} {xs} {ys} {x} {y} =
  (x ∈ xs × y ∈ ys)                ↔⟨ ⊗↔′ ⟩
  Any (_≡_ x ⟨×⟩ _≡_ y) (xs ⊗ ys)  ↔⟨ Any-cong helper (_ ∎) ⟩
  (x , y) ∈ (xs ⊗ ys)              ∎
  where
  open Related.EquationalReasoning

  helper : (p : A × B) → (x ≡ proj₁ p × y ≡ proj₂ p) ↔ (x , y) ≡ p
  helper (x′ , y′) = record
    { to         = P.→-to-⟶ (uncurry $ P.cong₂ _,_)
    ; from       = P.→-to-⟶ < P.cong proj₁ , P.cong proj₂ >
    ; inverse-of = record
      { left-inverse-of  = λ _ → P.cong₂ _,_ (P.proof-irrelevance _ _)
                                             (P.proof-irrelevance _ _)
      ; right-inverse-of = λ _ → P.proof-irrelevance _ _
      }
    }

-- Other properties.

filter-∈ : ∀ {a} {A : Set a} (p : A → Bool) (xs : List A) {x} →
           x ∈ xs → p x ≡ true → x ∈ filter p xs
filter-∈ p []       ()          _
filter-∈ p (x ∷ xs) (here refl) px≡true rewrite px≡true = here refl
filter-∈ p (y ∷ xs) (there pxs) px≡true with p y
... | true  = there (filter-∈ p xs pxs px≡true)
... | false =        filter-∈ p xs pxs px≡true

------------------------------------------------------------------------
-- Properties relating _∈_ to various list functions

-- Various functions are monotone.

mono : ∀ {a p} {A : Set a} {P : A → Set p} {xs ys} →
       xs ⊆ ys → Any P xs → Any P ys
mono xs⊆ys =
  _⟨$⟩_ (Inverse.to Any↔) ∘′
  Prod.map id (Prod.map xs⊆ys id) ∘
  _⟨$⟩_ (Inverse.from Any↔)

map-mono : ∀ {a b} {A : Set a} {B : Set b} (f : A → B) {xs ys} →
           xs ⊆ ys → List.map f xs ⊆ List.map f ys
map-mono f xs⊆ys =
  _⟨$⟩_ (Inverse.to map-∈↔) ∘
  Prod.map id (Prod.map xs⊆ys id) ∘
  _⟨$⟩_ (Inverse.from map-∈↔)

_++-mono_ : ∀ {a} {A : Set a} {xs₁ xs₂ ys₁ ys₂ : List A} →
            xs₁ ⊆ ys₁ → xs₂ ⊆ ys₂ → xs₁ ++ xs₂ ⊆ ys₁ ++ ys₂
_++-mono_ xs₁⊆ys₁ xs₂⊆ys₂ =
  _⟨$⟩_ (Inverse.to ++↔) ∘
  Sum.map xs₁⊆ys₁ xs₂⊆ys₂ ∘
  _⟨$⟩_ (Inverse.from ++↔)

concat-mono : ∀ {a} {A : Set a} {xss yss : List (List A)} →
              xss ⊆ yss → concat xss ⊆ concat yss
concat-mono {a} xss⊆yss =
  _⟨$⟩_ (Inverse.to $ concat-∈↔ {a = a}) ∘
  Prod.map id (Prod.map id xss⊆yss) ∘
  _⟨$⟩_ (Inverse.from $ concat-∈↔ {a = a})

>>=-mono : ∀ {ℓ} {A B : Set ℓ} (f g : A → List B) {xs ys} →
           xs ⊆ ys → (∀ {x} → f x ⊆ g x) →
           (xs >>= f) ⊆ (ys >>= g)
>>=-mono {ℓ} f g xs⊆ys f⊆g =
  _⟨$⟩_ (Inverse.to $ >>=-∈↔ {ℓ = ℓ}) ∘
  Prod.map id (Prod.map xs⊆ys f⊆g) ∘
  _⟨$⟩_ (Inverse.from $ >>=-∈↔ {ℓ = ℓ})

_⊛-mono_ : ∀ {ℓ} {A B : Set ℓ}
             {fs gs : List (A → B)} {xs ys : List A} →
           fs ⊆ gs → xs ⊆ ys → (fs ⊛ xs) ⊆ (gs ⊛ ys)
_⊛-mono_ {fs = fs} {gs} fs⊆gs xs⊆ys =
  _⟨$⟩_ (Inverse.to $ ⊛-∈↔ gs) ∘
  Prod.map id (Prod.map id (Prod.map fs⊆gs (Prod.map xs⊆ys id))) ∘
  _⟨$⟩_ (Inverse.from $ ⊛-∈↔ fs)

_⊗-mono_ : {A B : Set} {xs₁ ys₁ : List A} {xs₂ ys₂ : List B} →
           xs₁ ⊆ ys₁ → xs₂ ⊆ ys₂ → (xs₁ ⊗ xs₂) ⊆ (ys₁ ⊗ ys₂)
xs₁⊆ys₁ ⊗-mono xs₂⊆ys₂ =
  _⟨$⟩_ (Inverse.to ⊗-∈↔) ∘
  Prod.map xs₁⊆ys₁ xs₂⊆ys₂ ∘
  _⟨$⟩_ (Inverse.from ⊗-∈↔)

any-mono : ∀ {a} {A : Set a} (p : A → Bool) →
           ∀ {xs ys} → xs ⊆ ys → T (any p xs) → T (any p ys)
any-mono {a} p xs⊆ys =
  _⟨$⟩_ (Equivalence.to $ any⇔ {a = a}) ∘
  mono xs⊆ys ∘
  _⟨$⟩_ (Equivalence.from $ any⇔ {a = a})

map-with-∈-mono :
  ∀ {a b} {A : Set a} {B : Set b}
    {xs : List A} {f : ∀ {x} → x ∈ xs → B}
    {ys : List A} {g : ∀ {x} → x ∈ ys → B}
  (xs⊆ys : xs ⊆ ys) → (∀ {x} → f {x} ≗ g ∘ xs⊆ys) →
  map-with-∈ xs f ⊆ map-with-∈ ys g
map-with-∈-mono {f = f} {g = g} xs⊆ys f≈g {x} =
  _⟨$⟩_ (Inverse.to map-with-∈↔) ∘
  Prod.map id (Prod.map xs⊆ys (λ {x∈xs} x≡fx∈xs → begin
    x               ≡⟨ x≡fx∈xs ⟩
    f x∈xs          ≡⟨ f≈g x∈xs ⟩
    g (xs⊆ys x∈xs)  ∎)) ∘
  _⟨$⟩_ (Inverse.from map-with-∈↔)
  where open P.≡-Reasoning

-- Other properties.

filter-⊆ : ∀ {a} {A : Set a} (p : A → Bool) →
           (xs : List A) → filter p xs ⊆ xs
filter-⊆ _ []       = λ ()
filter-⊆ p (x ∷ xs) with p x | filter-⊆ p xs
... | false | hyp = there ∘ hyp
... | true  | hyp =
  λ { (here  eq)      → here eq
    ; (there ∈filter) → there (hyp ∈filter)
    }

------------------------------------------------------------------------
-- Other properties

-- Only a finite number of distinct elements can be members of a
-- given list.

finite : ∀ {a} {A : Set a}
         (f : Inj.Injection (P.setoid ℕ) (P.setoid A)) →
         ∀ xs → ¬ (∀ i → Inj.Injection.to f ⟨$⟩ i ∈ xs)
finite         inj []       ∈[]   with ∈[] zero
... | ()
finite {A = A} inj (x ∷ xs) ∈x∷xs = excluded-middle helper
  where
  open Inj.Injection inj

  module DTO = DecTotalOrder Nat.decTotalOrder
  module STO = StrictTotalOrder
                 (DTOProperties.strictTotalOrder Nat.decTotalOrder)
  module CS  = CommutativeSemiring NatProp.commutativeSemiring

  not-x : ∀ {i} → ¬ (to ⟨$⟩ i ≡ x) → to ⟨$⟩ i ∈ xs
  not-x {i} ≢x with ∈x∷xs i
  ... | here  ≡x  = ⊥-elim (≢x ≡x)
  ... | there ∈xs = ∈xs

  helper : ¬ Dec (∃ λ i → to ⟨$⟩ i ≡ x)
  helper (no ≢x)        = finite inj  xs (λ i → not-x (≢x ∘ _,_ i))
  helper (yes (i , ≡x)) = finite inj′ xs ∈xs
    where
    open P

    f : ℕ → A
    f j with STO.compare i j
    f j | tri< _ _ _ = to ⟨$⟩ suc j
    f j | tri≈ _ _ _ = to ⟨$⟩ suc j
    f j | tri> _ _ _ = to ⟨$⟩ j

    ∈-if-not-i : ∀ {j} → i ≢ j → to ⟨$⟩ j ∈ xs
    ∈-if-not-i i≢j = not-x (i≢j ∘ injective ∘ trans ≡x ∘ sym)

    lemma : ∀ {k j} → k ≤ j → suc j ≢ k
    lemma 1+j≤j refl = NatProp.1+n≰n 1+j≤j

    ∈xs : ∀ j → f j ∈ xs
    ∈xs j with STO.compare i j
    ∈xs j  | tri< (i≤j , _) _ _ = ∈-if-not-i (lemma i≤j ∘ sym)
    ∈xs j  | tri> _ i≢j _       = ∈-if-not-i i≢j
    ∈xs .i | tri≈ _ refl _      =
      ∈-if-not-i (NatProp.m≢1+m+n i ∘
                  subst (_≡_ i ∘ suc) (sym $ proj₂ CS.+-identity i))

    injective′ : Inj.Injective {B = P.setoid A} (→-to-⟶ f)
    injective′ {j} {k} eq with STO.compare i j | STO.compare i k
    ... | tri< _ _ _         | tri< _ _ _         = cong pred                                   $ injective eq
    ... | tri< _ _ _         | tri≈ _ _ _         = cong pred                                   $ injective eq
    ... | tri< (i≤j , _) _ _ | tri> _ _ (k≤i , _) = ⊥-elim (lemma (DTO.trans k≤i i≤j)           $ injective eq)
    ... | tri≈ _ _ _         | tri< _ _ _         = cong pred                                   $ injective eq
    ... | tri≈ _ _ _         | tri≈ _ _ _         = cong pred                                   $ injective eq
    ... | tri≈ _ i≡j _       | tri> _ _ (k≤i , _) = ⊥-elim (lemma (subst (_≤_ k) i≡j k≤i)       $ injective eq)
    ... | tri> _ _ (j≤i , _) | tri< (i≤k , _) _ _ = ⊥-elim (lemma (DTO.trans j≤i i≤k)     $ sym $ injective eq)
    ... | tri> _ _ (j≤i , _) | tri≈ _ i≡k _       = ⊥-elim (lemma (subst (_≤_ j) i≡k j≤i) $ sym $ injective eq)
    ... | tri> _ _ (j≤i , _) | tri> _ _ (k≤i , _) =                                               injective eq

    inj′ = record
      { to        = →-to-⟶ {B = P.setoid A} f
      ; injective = injective′
      }
