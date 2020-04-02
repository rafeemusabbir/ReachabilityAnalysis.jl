"""
    GLGM06{N, AM} <: AbstractContinuousPost

Implementation of Girard - Le Guernic - Maler algorithm for reachability of
uncertain linear systems using zonotopes.

## Fields

- `δ`            -- step-size of the discretization
- `approx_model` -- (optional, default `_DEFAULT_APPROX_MODEL_GLGM06`) approximation model
                    for the discretization of the ODE; see `Notes` below
- `max_order`    -- (optional, default: `10`) maximum zonotope order

## Notes

The type fields are:

- `N`  -- number type of the step-size
- `AM` -- approximation model

## References

See [xxx] and [yyy]
"""
@with_kw struct GLGM06{N, AM} <: AbstractContinuousPost
    δ::N
    # TODO: use set-operations option
    # nota: la opcion set_operations="zonotope" es ignorada (?)
    approx_model::AM=Forward(sih=:concrete, exp=:base, phi2=:base, setops=:lazy)
    max_order::Int=10
end

step_size(alg::GLGM06) = alg.δ

include("post.jl")
include("reach.jl")
#include("check.jl")