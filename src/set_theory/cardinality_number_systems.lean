/-
Copyright (c) 2019 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn

The cardinality of various number systems, like pnat, int, rat and real.
-/

import data.real.basic set_theory.ordinal analysis.specific_limits

open cardinal nat set
noncomputable theory
namespace cardinal

lemma mk_pnat : cardinal.mk ℕ+ = omega :=
begin
  rw [←mk_nat],
  apply le_antisymm,
  { apply mk_subtype_le },
  { fapply mk_le_of_injective succ_pnat_injective }
end

lemma mk_int : cardinal.mk ℤ = omega :=
begin
  rw [←mk_nat],
  apply le_antisymm,
  { have : ∀(k : ℤ), ∃(n : ℕ × ℕ), (n.1 : ℤ) - n.2 = k,
    { rintro (k|k), use ⟨k, 0⟩, refl, use ⟨0, k.succ⟩, refl },
    rw [←mul_eq_self (ge_of_eq mk_nat)], apply mk_le_of_surjective this },
  { fapply mk_le_of_injective nat.cast_injective; apply_instance }
end

lemma mk_rat : cardinal.mk ℚ = omega :=
begin
  apply le_antisymm,
  { have : ∀(k : ℚ), ∃(n : ℤ × ℕ+), rat.mk_pnat n.1 n.2 = k,
    { rintro ⟨n, m, hm, hnm⟩, use ⟨n, ⟨m, hm⟩⟩, dsimp [coprime] at hnm, simp [rat.mk_pnat, hnm] },
    have := mk_le_of_surjective this,
    rwa [←cardinal.mul_def, mk_int, mk_pnat, mul_eq_self (le_refl _)] at this },
  { rw [←mk_nat], fapply mk_le_of_injective nat.cast_injective; apply_instance }
end

lemma mk_real_le : cardinal.mk ℝ ≤ 2 ^ omega.{0} :=
begin
  dsimp [real],
  apply le_trans mk_quotient_le,
  apply le_trans mk_subtype_le,
  rw [←power_def, mk_nat, mk_rat, power_self_eq (le_refl _)]
end

variables {c : ℝ} {f g : ℕ → bool} {n : ℕ}

def cantor_function_aux (c : ℝ) (f : ℕ → bool) (n : ℕ) : ℝ := cond (f n) (c ^ n) 0

@[simp] lemma cantor_function_aux_tt (h : f n = tt) : cantor_function_aux c f n = c ^ n :=
by simp [cantor_function_aux, h]

@[simp] lemma cantor_function_aux_ff (h : f n = ff) : cantor_function_aux c f n = 0 :=
by simp [cantor_function_aux, h]

lemma cantor_function_aux_nonneg (h : 0 ≤ c) : 0 ≤ cantor_function_aux c f n :=
by { cases h' : f n; simp [h'], apply pow_nonneg h }

lemma cantor_function_aux_eq (h : f n = g n) :
  cantor_function_aux c f n = cantor_function_aux c g n :=
by simp [cantor_function_aux, h]

lemma cantor_function_aux_succ (f : ℕ → bool) :
  (λ n, cantor_function_aux c f (n + 1)) = λ n, c * cantor_function_aux c (λ n, f (n + 1)) n :=
by { ext n, cases h : f (n + 1); simp [h, _root_.pow_succ] }

lemma summable_cantor_function (f : ℕ → bool) (h1 : 0 ≤ c) (h2 : c < 1) :
  summable (cantor_function_aux c f) :=
begin
  apply summable_of_summable_of_sub _ _ (summable_geometric h1 h2),
  intro n, cases h : f n; simp [h]
end

def cantor_function (c : ℝ) (f : ℕ → bool) : ℝ := tsum $ cantor_function_aux c f

lemma cantor_function_le (h1 : 0 ≤ c) (h2 : c < 1) (h3 : ∀ n, f n → g n) :
  cantor_function c f ≤ cantor_function c g :=
begin
  apply tsum_le_tsum _ (summable_cantor_function f h1 h2) (summable_cantor_function g h1 h2),
  intro n, cases h : f n, simp [h, cantor_function_aux_nonneg h1],
  replace h3 : g n = tt := h3 n h, simp [h, h3]
end

lemma cantor_function_tt (h1 : 0 ≤ c) (h2 : c < 1) : cantor_function c (λ n, tt) = 1 / (1 - c) :=
tsum_geometric h1 h2

lemma cantor_function_succ (f : ℕ → bool) (h1 : 0 ≤ c) (h2 : c < 1) :
  cantor_function c f = cond (f 0) 1 0 + c * cantor_function c (λ n, f (n+1)) :=
begin
  rw [cantor_function, tsum_eq_zero_add (summable_cantor_function f h1 h2)],
  rw [cantor_function_aux_succ, tsum_mul_left _ (summable_cantor_function _ h1 h2)], refl
end

lemma increasing_cantor_function (h1 : 0 < c) (h2 : c < 1 / 2) {n : ℕ} {f g : ℕ → bool}
  (hn : ∀(k < n), f k = g k) (fn : f n = ff) (gn : g n = tt) :
  cantor_function c f < cantor_function c g :=
begin
  have h3 : c < 1, { apply lt_trans h2, norm_num },
  induction n with n ih generalizing f g,
  { let f_max : ℕ → bool := λ n, nat.rec ff (λ _ _, tt) n,
    have hf_max : ∀n, f n → f_max n,
    { intros n hn, cases n, rw [fn] at hn, contradiction, apply rfl },
    let g_min : ℕ → bool := λ n, nat.rec tt (λ _ _, ff) n,
    have hg_min : ∀n, g_min n → g n,
    { intros n hn, cases n, rw [gn], apply rfl, contradiction },
    apply lt_of_le_of_lt (cantor_function_le (le_of_lt h1) h3 hf_max),
    apply lt_of_lt_of_le _ (cantor_function_le (le_of_lt h1) h3 hg_min),
    have : c * (1 / (1 - c)) < 1,
    { have : 1 / (1 - c) ≤ 2,
      { rw [div_le_iff, ←div_le_iff', le_sub_iff_add_le, ←le_sub_iff_add_le'],
        convert le_of_lt h2, norm_num, norm_num, rw [sub_pos], exact h3 },
      convert mul_lt_mul h2 this _ _, norm_num,
      apply div_pos, norm_num, rw [sub_pos], exact h3, norm_num },
    convert this,
    { rw [cantor_function_succ _ (le_of_lt h1) h3, ←tsum_geometric (le_of_lt h1) h3],
      apply zero_add },
    { apply tsum_eq_single 0, intros n hn, cases n, contradiction, refl, apply_instance }},
  rw [cantor_function_succ f (le_of_lt h1) h3, cantor_function_succ g (le_of_lt h1) h3],
  rw [hn 0 $ zero_lt_succ n],
  apply add_lt_add_left, rw mul_lt_mul_left h1, exact ih (λ k hk, hn _ $ succ_lt_succ hk) fn gn
end

lemma injective_cantor_function (h1 : 0 < c) (h2 : c < 1 / 2) :
  function.injective (cantor_function c) :=
begin
  intros f g hfg, classical, by_contra h, revert hfg,
  have : ∃n, f n ≠ g n,
  { rw [←not_forall], intro h', apply h, ext, apply h' },
  let n := nat.find this,
  have hn : ∀ (k : ℕ), k < n → f k = g k,
  { intros k hk, apply of_not_not, exact nat.find_min this hk },
  cases fn : f n,
  { apply ne_of_lt, refine increasing_cantor_function h1 h2 hn fn _,
    apply eq_tt_of_not_eq_ff, rw [←fn], apply ne.symm, exact nat.find_spec this },
  { apply ne_of_gt, refine increasing_cantor_function h1 h2 (λ k hk, (hn k hk).symm) _ fn,
    apply eq_ff_of_not_eq_tt, rw [←fn], apply ne.symm, exact nat.find_spec this }
end

lemma mk_real : cardinal.mk ℝ = 2 ^ omega.{0} :=
begin
  apply le_antisymm mk_real_le,
  convert mk_le_of_injective (injective_cantor_function _ _),
  rw [←power_def, mk_bool, mk_nat], exact 1 / 3, norm_num, norm_num
end

lemma not_countable_real : ¬ countable (univ : set ℝ) :=
by { rw [countable_iff, not_le, mk_univ, mk_real], apply cantor }

end cardinal
