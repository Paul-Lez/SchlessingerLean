/-
Copyright (c) 2023 Calle Sönne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Calle Sönne, Paul Lezeau
-/

import LS.FiberStructures

universe u₁ v₁ u₂ v₂ u₃ w

open CategoryTheory Functor Category

variable {𝒮 : Type u₁} {𝒳 : Type u₂} {𝒴 : Type u₃} [Category 𝒳] [Category 𝒮] [Category 𝒴]

namespace Fibered

-- @[simps] fails.. "target [anonymous]" is not a structure
structure Morphism (p : 𝒳 ⥤ 𝒮) (q : 𝒴 ⥤ 𝒮) extends CategoryTheory.Functor 𝒳 𝒴 where
  (w : toFunctor ⋙ q = p)

/-- A notion of functor between FiberStructs. It is given by a functor F : 𝒳 ⥤ 𝒴 such that F ⋙ q = p,
  and a collection of functors fiber_functor S between the fibers of p and q over S in 𝒮 such that
  .... -/
class IsFiberMorphism {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q] (F : Morphism p q) where
  (fiber_functor (S : 𝒮) : hp.Fib S ⥤ hq.Fib S)
  (comp_eq : ∀ (S : 𝒮), (fiber_functor S) ⋙ (hq.ι S) = (hp.ι S) ⋙ F.toFunctor) -- TRY AESOP_CAT BY DEFAULT HERE?

/-- A notion of functor between FiberedStructs. It is furthermore required to preserve pullbacks  -/
class IsFiberedMorphism {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberedStruct p] [hq : FiberedStruct q] (F : Morphism p q)
    extends IsFiberMorphism F where
  (preservesPullbacks {R S : 𝒮} {f : R ⟶ S} {φ : a ⟶ b} (_ : IsPullback p f φ) : IsPullback q f (F.map φ))

@[simp]
lemma Morphism.obj_proj {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q) (a : 𝒳) : q.obj (F.obj a) = p.obj a := by
  rw [←comp_obj, F.w]

@[simp]
lemma Morphism.fiber_proj {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p]
    (F : Morphism p q) {S : 𝒮} (a : hp.Fib S) : q.obj (F.obj ((hp.ι S).obj a)) = S := by
  rw [Morphism.obj_proj F ((hp.ι S).obj a), FiberStructObjLift]

-- NEED TO THINK ABOUT DOMAINS HERE...
-- lemma IsFiberMorphism.congr_hom {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q]
--     (F : Morphism p q) [hF : IsFiberMorphism F] {S : 𝒮} {a b : hp.Fib S} (φ : a ⟶ b ):
--     (hq.ι S).map ((hF.fiber_functor S).map φ) = F.map ((hp.ι S).map φ) := by
--     rw [←comp_obj, congr_obj (hF.comp_eq S), comp_obj]

/-- TODO -/
lemma Morphism.IsHomLift_map  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q)
    {a b : 𝒳} (φ : a ⟶ b) : IsHomLift q (p.map φ) (F.map φ) where
  ObjLiftDomain := Morphism.obj_proj F a
  ObjLiftCodomain := Morphism.obj_proj F b
  HomLift := ⟨by simp [congr_hom F.w.symm]⟩

lemma Morphism.pres_IsHomLift  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q)
    {R S : 𝒮} {a b : 𝒳} {φ : a ⟶ b} {f : R ⟶ S} (hφ : IsHomLift p f φ) : IsHomLift q f (F.map φ) where
  ObjLiftDomain := Eq.trans (Morphism.obj_proj F a) hφ.ObjLiftDomain
  ObjLiftCodomain := Eq.trans (Morphism.obj_proj F b) hφ.ObjLiftCodomain
  HomLift := ⟨by
    rw [←Functor.comp_map, congr_hom F.w]
    simp [hφ.3.1] ⟩

lemma Morphism.HomLift_ofImage  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q) {S R : 𝒮} {a b : 𝒳}
    {φ : a ⟶ b} {f : R ⟶ S} (hφ : IsHomLift q f (F.map φ)) : IsHomLift p f φ where
  ObjLiftDomain := F.obj_proj a ▸ hφ.ObjLiftDomain
  ObjLiftCodomain := F.obj_proj b ▸ hφ.ObjLiftCodomain
  HomLift := ⟨by
    rw [congr_hom F.w.symm]
    simp only [Functor.comp_map, assoc, eqToHom_trans, hφ.HomLift.1, eqToHom_trans_assoc]⟩

@[default_instance]
instance Morphism.IsFiber_canonical {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q) :
    IsFiberMorphism F where
  fiber_functor := fun S => {
    obj := fun a => ⟨F.obj a.1, by rw [F.obj_proj, a.2]⟩
    map := @fun a b φ => ⟨F.map φ.val, Morphism.pres_IsHomLift F φ.2⟩
    map_id := by
      intro a
      -- TODO THIS SHOULD ALL BE SIMP SOMEHOW..
      simp [FiberCategory_id_coe p S a]
      rw [←Subtype.val_inj, FiberCategory_id_coe q S _]
    map_comp := by
      intro x y z φ ψ
      -- THIS SHOULD ALSO ALL BE SIMP SOMEHOW...
      simp [FiberCategory_comp_coe p S φ ψ]
      rw [←Subtype.val_inj, FiberCategory_comp_coe q S _ _]
  }
  comp_eq := by aesop_cat

-- NEED MORE COMMSQUARES API....
-- ALSO NEED MORE API FOR PULLING BACK TO FIBERS

/-- If a morphism F is faithFul, then it is also faithful fiberwise -/
lemma FiberwiseFaithfulofFaithful  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q]
    (F : Morphism p q) [hF : IsFiberMorphism F] [Faithful F.toFunctor] : ∀ (S : 𝒮),
    Faithful (hF.fiber_functor S) := by
    intro S
    haveI h : Faithful ((hF.fiber_functor S) ⋙ (hq.ι S)) := (hF.comp_eq S).symm ▸ Faithful.comp (hp.ι S) F.toFunctor
    apply Faithful.of_comp _ (hq.ι S)

/-- A FiberMorphism F is faithful if it is so pointwise. For proof see [Olsson] -/
lemma FaithfulofFiberwiseFaithful {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} {hp : FiberedStruct p} {hq : FiberedStruct q}
    {F : Morphism p q} [hF : IsFiberedMorphism F] (hF₁ : ∀ (S : 𝒮), Faithful (hF.fiber_functor S)) :
    Faithful F.toFunctor where
  map_injective := by
    intro a b φ φ' heq
    /- We start by reducing to a setting when the domains lie in some fiber of the FiberStruct.
    We do this by finding some Φ : a' ≅ a by essential surjectivity of the fiber structures,
    and then defining φ₁ := Φ.hom ≫ φ and φ₁' := Φ.hom ≫ φ'. -/
    rcases FiberStructEssSurj' (rfl (a := p.obj a)) with ⟨a', Φ, _⟩
    let φ₁ := Φ.hom ≫ φ
    let φ₁' := Φ.hom ≫ φ'
    suffices φ₁ = φ₁' by rwa [←CategoryTheory.Iso.cancel_iso_hom_left Φ]
    -- We also have that F(φ₁) = F(φ₁')
    have heq₁ : F.map φ₁ = F.map φ₁' := by
      simp only [F.map_comp]
      apply congrArg (F.map Φ.hom ≫ ·) heq
    /- The goal is now to factor φ₁ and φ₁' through some pullback to reduce to checking
    two morphisms τ and τ' in the fibers are equal, which will then follow from fiber-wise
    faithfulness. -/
    let h : p.obj a ⟶ p.obj b := eqToHom ((FiberStructObjLift a').symm) ≫ p.map φ₁
    -- Let ψ : c ⟶ b be a pullback over h such that c : Fib (p.obj a)
    rcases FiberStructPullback' hp rfl h with ⟨c, ψ, hψ⟩
    -- Both φ₁ and φ₁' are lifts of h
    have hφ₁ : IsHomLift p h φ₁ := IsHomLift_eqToHom_comp' (IsHomLift_self p φ₁) _
    have hφ₁' : IsHomLift p h φ₁' :=  by
      apply IsHomLift_eqToHom_comp'
      rw [congr_hom F.w.symm, Functor.comp_map, heq₁, ←Functor.comp_map, ←congr_hom F.w.symm]
      apply IsHomLift_self p φ₁'
    -- Let τ, τ' be the induced maps from a' to c given by φ and φ'
    rcases FiberStructFactorization hφ₁ hψ with ⟨τ, hτ⟩
    rcases FiberStructFactorization hφ₁' hψ with ⟨τ', hτ'⟩
    -- Thus, it suffices to show that τ = τ'
    suffices τ = τ' by rw [←hτ, ←hτ', this]
    have hψ' : IsPullback q h (F.map ψ) := hF.preservesPullbacks hψ
    -- F(τ) and F(τ') both solve the same pullback problem in 𝒴
    have hτ₁ : F.map ((hp.ι (p.obj a)).map τ) ≫ F.map ψ = F.map φ₁ := by rw [←Functor.map_comp, hτ]
    have hτ'₁ : F.map ((hp.ι (p.obj a)).map τ') ≫ F.map ψ = F.map φ₁ := by
      rw [←Functor.map_comp, hτ']
      apply heq₁.symm
    -- Hence we get that F(τ) = F(τ'), so we can conclude by fiberwise injectivity
    have hτ₂ := IsPullbackInducedMap_unique hψ' ((id_comp h).symm)
      (Morphism.pres_IsHomLift F hφ₁) (Morphism.pres_IsHomLift F (FiberStructHomLift τ)) hτ₁
    have hτ'₂ := IsPullbackInducedMap_unique hψ' ((id_comp h).symm)
      (Morphism.pres_IsHomLift F hφ₁) (Morphism.pres_IsHomLift F (FiberStructHomLift τ')) hτ'₁
    have heqττ' : F.map ((hp.ι (p.obj a)).map τ) = F.map ((hp.ι (p.obj a)).map τ') := by rw [hτ₂, hτ'₂]
    have heqττ'₁ : (hF.fiber_functor _).map τ = (hF.fiber_functor _).map τ' := by
      apply Functor.map_injective (hq.ι (p.obj a))
      simp_rw [←Functor.comp_map, congr_hom (hF.comp_eq (p.obj a)), Functor.comp_map]
      rw [heqττ']
    apply Functor.map_injective (hF.fiber_functor (p.obj a)) heqττ'₁

lemma PreimageIsHomLift {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} (F : Morphism p q) [hF₁ : Full F.toFunctor]
    {a b : 𝒳} {φ : F.obj a ⟶ F.obj b} {R S : 𝒮} {f : R ⟶ S} (hφ : IsHomLift q f φ) :
    IsHomLift p f (hF₁.preimage φ) := (hF₁.witness φ ▸ Morphism.HomLift_ofImage F) hφ

/-
Ideas for simplifying the following proof: develop some general preimage wrt fiber API.
But maybe thats better to be developed after proving these lemmas... (so one knows that
fibers are always full also?)

TODO:
1. Break out standalone lemma from below
2. Create the preimage below outside "FiberwisepreimageofFull"?
3. Show its a homlift
4. Define fiberwise preimage?
-/


/- We now show that a morphism F is full if and only if its full fiberwise -/

def fiber_functor_to_functor_congr {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q]
    (F : Morphism p q) [hF : IsFiberMorphism F] {S : 𝒮} {a b : hp.Fib S}
    (φ : (hF.fiber_functor S).obj a ⟶ (hF.fiber_functor S).obj b) :
    (hp.ι S ⋙ F.toFunctor).obj a ⟶ (hp.ι S ⋙ F.toFunctor).obj b :=
    eqToHom (congr_obj (hF.comp_eq S) a).symm ≫ ((hq.ι S).map φ) ≫ eqToHom (congr_obj (hF.comp_eq S) b)

lemma preimage_of_fiber_IsHomLift {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q]
    {F : Morphism p q} [hF : IsFiberMorphism F] [hF₁ : Full F.toFunctor] {S : 𝒮} {a b : hp.Fib S}
    (φ : (hF.fiber_functor S).obj a ⟶ (hF.fiber_functor S).obj b) :
    IsHomLift p (𝟙 S) (hF₁.preimage (fiber_functor_to_functor_congr F φ)) := by
  apply PreimageIsHomLift
  simp only [fiber_functor_to_functor_congr, FiberStructHomLift φ,
    IsHomLift_eqToHom_comp, IsHomLift_comp_eqToHom]

noncomputable def FiberPreimageOfFull {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [FiberStruct q]
    {F : Morphism p q} [hF : IsFiberMorphism F] [Full F.toFunctor] {S : 𝒮} {a b : hp.Fib S}
    (φ : (hF.fiber_functor S).obj a ⟶ (hF.fiber_functor S).obj b) : a ⟶ b :=
  Classical.choose (FiberStructFull (preimage_of_fiber_IsHomLift φ))

lemma FiberPreimageIsPreimage {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [hp : FiberStruct p] [hq : FiberStruct q]
    {F : Morphism p q} [hF : IsFiberMorphism F] [Full F.toFunctor] {S : 𝒮} {a b : hp.Fib S}
    (φ : (hF.fiber_functor S).obj a ⟶ (hF.fiber_functor S).obj b) :
    (hF.fiber_functor S).map (FiberPreimageOfFull φ) = φ := by
  apply Functor.map_injective (hq.ι S)
  -- Maybe its worth making this standalone
  rw [←Functor.comp_map, congr_hom (hF.comp_eq S), Functor.comp_map]
  simp [FiberPreimageOfFull, fiber_functor_to_functor_congr,
    Classical.choose_spec (FiberStructFull (preimage_of_fiber_IsHomLift φ))]

lemma FiberwiseFullofFull  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} [FiberStruct p] [FiberStruct q]
    (F : Morphism p q) [hF : IsFiberMorphism F] [Full F.toFunctor] : ∀ (S : 𝒮),
    Full (hF.fiber_functor S) :=
  fun _ => {
    preimage := fun φ => FiberPreimageOfFull φ
    witness := fun φ => FiberPreimageIsPreimage φ }

lemma FullofFullFiberwise  {p : 𝒳 ⥤ 𝒮} {q : 𝒴 ⥤ 𝒮} {hp : FiberedStruct p} {hq : FiberedStruct q}
    {F : Morphism p q} [hF : IsFiberedMorphism F] (hF₁ : ∀ (S : 𝒮), Full (hF.fiber_functor S)) :
    Full F.toFunctor where
  preimage := by
    intro a b φ

    let R := p.obj a
    let S := p.obj b

    -- Reduce to checking when domain is in a fiber
    -- TODO TRICKY AS THIS IS BY NO MEANS UNIQUE (actually might not matter?)
    let a' := Classical.choose (FiberStructEssSurj' (rfl (a:=R)))
    let Φ := Classical.choose (Classical.choose_spec (FiberStructEssSurj' (rfl (a := R))))
    let hΦ := Classical.choose_spec (Classical.choose_spec (FiberStructEssSurj' (rfl (a := R))))

    let h : R ⟶ S := eqToHom (Morphism.obj_proj F a).symm ≫ q.map φ ≫ eqToHom (Morphism.obj_proj F b)

    -- Let ψ : c ⟶ b be a pullback over h such that c : Fib R
    let c := Classical.choose (FiberStructPullback' hp rfl h)
    let ψ := Classical.choose (Classical.choose_spec (FiberStructPullback' hp rfl h))
    let hψ := Classical.choose_spec (Classical.choose_spec (FiberStructPullback' hp rfl h))

    -- Now consider φ₁ : F.obj a' ⟶ F.obj b
    have ha' : (hq.ι R).obj ((hF.fiber_functor R).obj a') = F.obj ((hp.ι R).obj a') := by
      rw [←comp_obj, ←comp_obj, hF.comp_eq]
    let φ₁ : (hq.ι R).obj ((hF.fiber_functor R).obj a') ⟶ F.obj b :=
      eqToHom ha' ≫ (F.mapIso Φ).hom ≫ φ

    have hφ₁ : IsHomLift q h φ₁ := by
      have H := IsHomLift_self q φ₁

      simp only [φ₁, F.mapIso_hom]
      apply IsHomLift_eqToHom_comp' _
      apply IsHomLift_comp_eqToHom' _
      apply IsHomLift_comp_eqToHom _

      have h₁ := Morphism.pres_IsHomLift F hΦ
      -- API FOR THIS? Comp w/ homlift id is homlift
      sorry

    -- TODO: define "FromFiberObj" and "FromFiberHom" and use them to formulate FiberStructFactorization
    have hc : (hq.ι R).obj ((hF.fiber_functor R).obj c) = F.obj ((hp.ι R).obj c) := by
      rw [←comp_obj, ←comp_obj, hF.comp_eq]
    let ψ' := eqToHom hc ≫ F.map ψ

    -- NEED: IsPullback comp eqToHom...!
    have hψ' : IsPullback q h ψ' := by
      have := hF.preservesPullbacks hψ
      sorry -- hF.preservesPullbacks hψ + compiso pullback

    -- Let τ be the induced map from a' to c given by φ₁
    let τ := Classical.choose (FiberStructFactorization hφ₁ hψ')
    have hτ := Classical.choose_spec (FiberStructFactorization hφ₁ hψ')

    let π := (hF₁ R).preimage τ

    exact Φ.inv ≫ (hp.ι R).map π ≫ ψ


  witness := by
    intro a b φ
    simp only [map_comp] -- hhF.comp_eq, (hF₁ (p.obj a)).witness]
    rw [←Functor.comp_map, congr_hom (hF.comp_eq (p.obj a)).symm]
    rw [Functor.comp_map, (hF₁ (p.obj a)).witness]
    -- NEED API FOR THIS....

    rw [Category.assoc, Category.assoc]
    -- TODO: need way to get rid of extra goals here (problably via better API)
    -- Maybe OK once sorries above have been resolved?
    rw [Classical.choose_spec (FiberStructFactorization _ _)]
    simp
    rw [←Category.assoc, ←Functor.mapIso_inv, ←Functor.mapIso_hom]
    rw [Iso.inv_hom_id, id_comp]
    all_goals sorry


/-
TODO:
2. Full if fibers are full
3. Equivalence iff equivalence on fibers
  -- NOTE THIS REQUIRES NEW DEFINITION OF EQUIVALENCE!!! (inverse needs to also preserve fibers. Immediate?)
-/

-- class IsFiberedNatTrans (p : 𝒳 ⥤ 𝒮) (q : 𝒴 ⥤ 𝒮) [hp : IsFibered p] [hq : IsFibered q] {F : 𝒳 ⥤ 𝒴}
--   {G : 𝒳 ⥤ 𝒴} [IsFiberedMorphism p q F] [IsFiberedMorphism p q G] (α : F ⟶ G) : Prop where
--   (pointwiseInFiber : ∀ (a : 𝒳), q.map (α.app a) = eqToHom (IsFiberedMorphismPresFiberObj p q F G a))
